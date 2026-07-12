/// Audit support for structured content source metadata.
library;

import 'dart:convert';

import 'package:hee_no_tane_app/domain/models/source_metadata.dart';

class SourceAuditEntry {
  final String collection;
  final int index;
  final String id;
  final String label;
  final String sourceNote;
  final SourceMetadata metadata;
  final List<String> findings;
  final bool invalidMetadata;

  const SourceAuditEntry({
    required this.collection,
    required this.index,
    required this.id,
    required this.label,
    required this.sourceNote,
    required this.metadata,
    required this.findings,
    required this.invalidMetadata,
  });

  bool get isApproved => !invalidMetadata && metadata.isApproved;
  bool get needsReview => !isApproved;
}

class SourceAuditResult {
  final List<SourceAuditEntry> entries;
  final List<String> globalIssues;

  const SourceAuditResult({
    required this.entries,
    required this.globalIssues,
  });

  int get totalCount => entries.length;
  int get approvedCount => entries.where((entry) => entry.isApproved).length;
  int get pendingCount => entries.where((entry) => entry.needsReview).length;
  int get invalidCount =>
      entries.where((entry) => entry.invalidMetadata).length +
      globalIssues.length;

  bool get hasInvalidMetadata => invalidCount > 0;
  bool get allApproved => !hasInvalidMetadata && pendingCount == 0;

  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# コンテンツ出典監査レポート')
      ..writeln()
      ..writeln('- 総件数: $totalCount')
      ..writeln('- 承認済み: $approvedCount')
      ..writeln('- 要確認: $pendingCount')
      ..writeln('- メタデータ不正: $invalidCount')
      ..writeln();

    if (globalIssues.isNotEmpty) {
      buffer
        ..writeln('## 全体エラー')
        ..writeln();
      for (final issue in globalIssues) {
        buffer.writeln('- $issue');
      }
      buffer.writeln();
    }

    buffer
      ..writeln('## 一覧')
      ..writeln()
      ..writeln('| 種別 | ID | 内容 | 出典 | 状態 | 指摘 |')
      ..writeln('|---|---|---|---|---|---|');

    for (final entry in entries) {
      final status = entry.isApproved
          ? '承認済み'
          : entry.invalidMetadata
          ? '不正'
          : '要確認';
      final finding = entry.findings.isEmpty ? '-' : entry.findings.join(' / ');
      buffer.writeln(
        '| ${_escape(entry.collection)} '
        '| ${_escape(entry.id)} '
        '| ${_escape(entry.label)} '
        '| ${_escape(entry.metadata.displayLabel)} '
        '| $status '
        '| ${_escape(finding)} |',
      );
    }

    return buffer.toString();
  }

  static String _escape(String value) {
    return value.replaceAll('|', r'\|').replaceAll('\n', ' ');
  }
}

class ContentSourceAuditor {
  const ContentSourceAuditor();

  SourceAuditResult auditJsonStrings({
    required String questionsJson,
    required String cardsJson,
  }) {
    final globalIssues = <String>[];
    final questionRoot = _decodeRoot(questionsJson, 'questions', globalIssues);
    final cardRoot = _decodeRoot(cardsJson, 'cards', globalIssues);

    final questions = _auditCollection(
      root: questionRoot,
      collection: 'question',
      labelField: 'question',
    );
    final cards = _auditCollection(
      root: cardRoot,
      collection: 'card',
      labelField: 'title',
    );

    _auditQuestionCardConsistency(questionRoot, questions, cards, globalIssues);

    return SourceAuditResult(
      entries: List.unmodifiable([...questions, ...cards]),
      globalIssues: List.unmodifiable(globalIssues),
    );
  }

  List<dynamic> _decodeRoot(
    String source,
    String label,
    List<String> globalIssues,
  ) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is List<dynamic>) return decoded;
      globalIssues.add('$label: root must be a JSON array');
    } on FormatException catch (error) {
      globalIssues.add('$label: invalid JSON: ${error.message}');
    }
    return const [];
  }

  List<SourceAuditEntry> _auditCollection({
    required List<dynamic> root,
    required String collection,
    required String labelField,
  }) {
    final entries = <SourceAuditEntry>[];

    for (var index = 0; index < root.length; index++) {
      final item = root[index];
      if (item is! Map<String, dynamic>) {
        entries.add(
          SourceAuditEntry(
            collection: collection,
            index: index,
            id: '$collection-$index',
            label: 'JSON object expected',
            sourceNote: '',
            metadata: const SourceMetadata.legacy('出典不明'),
            findings: const ['content item is not a JSON object'],
            invalidMetadata: true,
          ),
        );
        continue;
      }

      final id = _string(item['id']) ?? '$collection-$index';
      final label = _string(item[labelField]) ?? '(名称なし)';
      final sourceNote = _string(item['sourceNote']) ?? '出典不明';
      final source = item['source'];
      final findings = <String>[];
      var invalidMetadata = false;
      SourceMetadata metadata;

      if (source == null) {
        metadata = SourceMetadata.legacy(sourceNote);
        findings.add('構造化されたsourceが未設定');
      } else if (source is! Map<String, dynamic>) {
        metadata = SourceMetadata.legacy(sourceNote);
        findings.add('sourceはJSON objectである必要があります');
        invalidMetadata = true;
      } else {
        try {
          metadata = SourceMetadata.fromJson(source);
          _appendApprovalFindings(metadata, findings);
          if (metadata.reviewStatus == 'approved' && !metadata.isApproved) {
            invalidMetadata = true;
            findings.add('approvedですが必須情報が不足しています');
          }
        } on FormatException catch (error) {
          metadata = SourceMetadata.legacy(sourceNote);
          findings.add(error.message);
          invalidMetadata = true;
        }
      }

      entries.add(
        SourceAuditEntry(
          collection: collection,
          index: index,
          id: id,
          label: label,
          sourceNote: sourceNote,
          metadata: metadata,
          findings: List.unmodifiable(findings),
          invalidMetadata: invalidMetadata,
        ),
      );
    }

    return entries;
  }

  void _appendApprovalFindings(
    SourceMetadata metadata,
    List<String> findings,
  ) {
    if (metadata.reviewStatus != 'approved') {
      findings.add('reviewStatus=${metadata.reviewStatus}');
    }
    if (metadata.verificationLevel == 'unverified') {
      findings.add('verificationLevelがunverified');
    }
    if (metadata.sourceUri == null) {
      findings.add('有効な出典URLがありません');
    }
    if (metadata.verifiedAt == null) {
      findings.add('確認日がありません');
    }
  }

  void _auditQuestionCardConsistency(
    List<dynamic> questionRoot,
    List<SourceAuditEntry> questions,
    List<SourceAuditEntry> cards,
    List<String> globalIssues,
  ) {
    final cardsById = {for (final card in cards) card.id: card};

    for (var index = 0; index < questionRoot.length; index++) {
      final item = questionRoot[index];
      if (item is! Map<String, dynamic> || index >= questions.length) continue;
      final relatedCardId = _string(item['relatedCardId']);
      if (relatedCardId == null) continue;
      final question = questions[index];
      final card = cardsById[relatedCardId];
      if (card == null || !question.isApproved || !card.isApproved) continue;

      if (question.metadata.url != card.metadata.url) {
        globalIssues.add(
          'question ${question.id} and card $relatedCardId have different '
          'approved source URLs',
        );
      }
    }
  }

  String? _string(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
