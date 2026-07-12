/// CSV-based workflow for reviewing and applying structured content sources.
library;

import 'dart:convert';
import 'dart:io';

import 'package:hee_no_tane_app/content_validation/content_validator.dart';
import 'package:hee_no_tane_app/content_validation/source_auditor.dart';
import 'package:hee_no_tane_app/domain/models/source_metadata.dart';

const contentReviewColumns = <String>[
  'questionId',
  'cardId',
  'category',
  'question',
  'answer',
  'explanation',
  'sourceTitle',
  'sourcePublisher',
  'sourceUrl',
  'verifiedAt',
  'verificationLevel',
  'reviewStatus',
  'reviewNote',
];

class ContentReviewException implements Exception {
  final String message;

  const ContentReviewException(this.message);

  @override
  String toString() => message;
}

class ContentReviewChange {
  final String questionId;
  final String cardId;
  final String previousStatus;
  final String nextStatus;

  const ContentReviewChange({
    required this.questionId,
    required this.cardId,
    required this.previousStatus,
    required this.nextStatus,
  });
}

class ContentReviewImportPlan {
  final String questionsJson;
  final String cardsJson;
  final List<ContentReviewChange> changes;

  const ContentReviewImportPlan({
    required this.questionsJson,
    required this.cardsJson,
    required this.changes,
  });

  bool get hasChanges => changes.isNotEmpty;

  String get summary {
    if (changes.isEmpty) return 'JSONに反映する差分はありません。';
    final approved = changes.where((item) => item.nextStatus == 'approved').length;
    return '${changes.length}組を変更します（承認済みへ変更: $approved組）。';
  }
}

class CategoryApprovalProgress {
  final String category;
  final int approved;
  final int total;

  const CategoryApprovalProgress({
    required this.category,
    required this.approved,
    required this.total,
  });

  double get ratio => total == 0 ? 0 : approved / total;
}

class ContentRiskEntry {
  final String questionId;
  final String cardId;
  final String category;
  final List<String> reasons;
  final String question;
  final String answer;
  final String explanation;
  final String cardTitle;
  final String cardDetail;

  const ContentRiskEntry({
    required this.questionId,
    required this.cardId,
    required this.category,
    required this.reasons,
    required this.question,
    required this.answer,
    required this.explanation,
    required this.cardTitle,
    required this.cardDetail,
  });
}

class ContentReviewWorkflow {
  const ContentReviewWorkflow();

  String exportCsv({
    required String questionsJson,
    required String cardsJson,
  }) {
    final questions = _decodeCollection(questionsJson, 'questions');
    final cards = _decodeCollection(cardsJson, 'cards');
    final cardsById = _byId(cards, 'cards');
    final rows = <List<String>>[contentReviewColumns];

    for (final question in questions) {
      final questionId = _requiredString(question, 'id', 'question');
      final cardId = _requiredString(question, 'relatedCardId', questionId);
      final card = cardsById[cardId];
      if (card == null) {
        throw ContentReviewException(
          'question $questionId references missing card $cardId',
        );
      }
      final choices = _stringList(question['choices'], '$questionId.choices');
      final answerIndex = question['answerIndex'];
      if (answerIndex is! int || answerIndex < 0 || answerIndex >= choices.length) {
        throw ContentReviewException('$questionId has an invalid answerIndex');
      }
      final source = _sourceForExport(question, card);
      rows.add([
        questionId,
        cardId,
        _requiredString(question, 'category', questionId),
        _requiredString(question, 'question', questionId),
        choices[answerIndex],
        _requiredString(question, 'explanation', questionId),
        source.title,
        source.publisher,
        source.url ?? '',
        source.verifiedAt ?? '',
        source.verificationLevel,
        source.reviewStatus == 'legacy' ? 'pending' : source.reviewStatus,
        _sourceDiffers(question, card)
            ? 'QUESTION_CARD_SOURCE_METADATA_DIFF'
            : '',
      ]);
    }

    return _encodeCsv(rows);
  }

  ContentReviewImportPlan planImport({
    required String csv,
    required String questionsJson,
    required String cardsJson,
  }) {
    final questions = _decodeCollection(questionsJson, 'questions');
    final cards = _decodeCollection(cardsJson, 'cards');
    final questionsById = _byId(questions, 'questions');
    final cardsById = _byId(cards, 'cards');
    final rows = _decodeReviewCsv(csv);

    if (rows.length != questions.length) {
      throw ContentReviewException(
        'CSV must contain every question exactly once: '
        'expected ${questions.length}, found ${rows.length}',
      );
    }

    final seenQuestions = <String>{};
    final seenCards = <String>{};
    final changes = <ContentReviewChange>[];

    for (final row in rows) {
      final questionId = row['questionId']!.trim();
      final cardId = row['cardId']!.trim();
      if (!seenQuestions.add(questionId)) {
        throw ContentReviewException('duplicate questionId in CSV: $questionId');
      }
      if (!seenCards.add(cardId)) {
        throw ContentReviewException('duplicate cardId in CSV: $cardId');
      }

      final question = questionsById[questionId];
      final card = cardsById[cardId];
      if (question == null) {
        throw ContentReviewException('unknown questionId: $questionId');
      }
      if (card == null) {
        throw ContentReviewException('unknown cardId: $cardId');
      }
      final relatedCardId = _requiredString(
        question,
        'relatedCardId',
        questionId,
      );
      if (relatedCardId != cardId) {
        throw ContentReviewException(
          '$questionId must remain paired with $relatedCardId, not $cardId',
        );
      }

      _requireUnchanged(
        field: 'category',
        expected: _requiredString(question, 'category', questionId),
        actual: row['category']!,
        questionId: questionId,
      );
      _requireUnchanged(
        field: 'question',
        expected: _requiredString(question, 'question', questionId),
        actual: row['question']!,
        questionId: questionId,
      );
      _requireUnchanged(
        field: 'explanation',
        expected: _requiredString(question, 'explanation', questionId),
        actual: row['explanation']!,
        questionId: questionId,
      );
      final choices = _stringList(question['choices'], '$questionId.choices');
      final answerIndex = question['answerIndex'];
      if (answerIndex is! int || answerIndex < 0 || answerIndex >= choices.length) {
        throw ContentReviewException('$questionId has an invalid answerIndex');
      }
      _requireUnchanged(
        field: 'answer',
        expected: choices[answerIndex],
        actual: row['answer']!,
        questionId: questionId,
      );

      final oldSource = _canonicalSource(question['source']);
      final previousStatus = _statusOf(question['source']);
      final nextSource = _sourceFromRow(row, questionId);
      final nextCanonical = _canonicalSource(nextSource);
      if (oldSource != nextCanonical ||
          _canonicalSource(card['source']) != nextCanonical) {
        changes.add(
          ContentReviewChange(
            questionId: questionId,
            cardId: cardId,
            previousStatus: previousStatus,
            nextStatus: row['reviewStatus']!.trim(),
          ),
        );
      }

      if (nextSource == null) {
        question.remove('source');
        card.remove('source');
      } else {
        question['source'] = Map<String, dynamic>.from(nextSource);
        card['source'] = Map<String, dynamic>.from(nextSource);
      }
    }

    if (seenQuestions.length != questionsById.length ||
        !seenQuestions.containsAll(questionsById.keys)) {
      throw const ContentReviewException(
        'CSV question IDs do not match the bundled question IDs',
      );
    }

    final updatedQuestions = _prettyJson(questions);
    final updatedCards = _prettyJson(cards);
    _validateUpdatedContent(updatedQuestions, updatedCards);

    return ContentReviewImportPlan(
      questionsJson: updatedQuestions,
      cardsJson: updatedCards,
      changes: List.unmodifiable(changes),
    );
  }

  List<CategoryApprovalProgress> progress({
    required String questionsJson,
    required String cardsJson,
  }) {
    final questions = _decodeCollection(questionsJson, 'questions');
    final cards = _decodeCollection(cardsJson, 'cards');
    final cardsById = _byId(cards, 'cards');
    final totals = <String, int>{};
    final approved = <String, int>{};

    for (final question in questions) {
      final questionId = _requiredString(question, 'id', 'question');
      final category = _requiredString(question, 'category', questionId);
      final cardId = _requiredString(question, 'relatedCardId', questionId);
      final card = cardsById[cardId];
      totals.update(category, (value) => value + 1, ifAbsent: () => 1);
      if (card != null && _pairIsApproved(question, card)) {
        approved.update(category, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    final categories = totals.keys.toList()..sort();
    return List.unmodifiable(
      categories.map(
        (category) => CategoryApprovalProgress(
          category: category,
          approved: approved[category] ?? 0,
          total: totals[category]!,
        ),
      ),
    );
  }

  List<ContentRiskEntry> risks({
    required String questionsJson,
    required String cardsJson,
  }) {
    final questions = _decodeCollection(questionsJson, 'questions');
    final cards = _decodeCollection(cardsJson, 'cards');
    final cardsById = _byId(cards, 'cards');
    final results = <ContentRiskEntry>[];

    for (final question in questions) {
      final questionId = _requiredString(question, 'id', 'question');
      final cardId = _requiredString(question, 'relatedCardId', questionId);
      final card = cardsById[cardId];
      if (card == null) continue;
      final choices = _stringList(question['choices'], '$questionId.choices');
      final answerIndex = question['answerIndex'];
      if (answerIndex is! int || answerIndex < 0 || answerIndex >= choices.length) {
        continue;
      }
      final text = [
        question['question'],
        choices[answerIndex],
        question['explanation'],
        card['title'],
        card['shortText'],
        card['detailText'],
      ].whereType<String>().join(' ');
      final reasons = _riskReasons(text);
      if (reasons.isEmpty) continue;
      results.add(
        ContentRiskEntry(
          questionId: questionId,
          cardId: cardId,
          category: _requiredString(question, 'category', questionId),
          reasons: List.unmodifiable(reasons),
          question: _requiredString(question, 'question', questionId),
          answer: choices[answerIndex],
          explanation: _requiredString(question, 'explanation', questionId),
          cardTitle: _requiredString(card, 'title', cardId),
          cardDetail: _requiredString(card, 'detailText', cardId),
        ),
      );
    }

    return List.unmodifiable(results);
  }

  String riskCsv({
    required String questionsJson,
    required String cardsJson,
  }) {
    final rows = <List<String>>[
      const [
        'questionId',
        'cardId',
        'category',
        'riskReasons',
        'question',
        'answer',
        'explanation',
        'cardTitle',
        'cardDetail',
      ],
    ];
    for (final risk in risks(
      questionsJson: questionsJson,
      cardsJson: cardsJson,
    )) {
      rows.add([
        risk.questionId,
        risk.cardId,
        risk.category,
        risk.reasons.join('|'),
        risk.question,
        risk.answer,
        risk.explanation,
        risk.cardTitle,
        risk.cardDetail,
      ]);
    }
    return _encodeCsv(rows);
  }

  Future<ContentReviewImportPlan> applyCsvToFiles({
    required String csv,
    required String questionsPath,
    required String cardsPath,
    required bool write,
  }) async {
    final questionsFile = File(questionsPath);
    final cardsFile = File(cardsPath);
    final originalQuestions = await questionsFile.readAsString();
    final originalCards = await cardsFile.readAsString();
    final plan = planImport(
      csv: csv,
      questionsJson: originalQuestions,
      cardsJson: originalCards,
    );
    if (!write || !plan.hasChanges) return plan;

    await _atomicReplace({
      questionsFile: plan.questionsJson,
      cardsFile: plan.cardsJson,
    });
    return plan;
  }

  List<Map<String, String>> _decodeReviewCsv(String source) {
    final table = _parseCsv(source);
    if (table.isEmpty) {
      throw const ContentReviewException('CSV is empty');
    }
    if (!_sameStrings(table.first, contentReviewColumns)) {
      throw ContentReviewException(
        'CSV header must exactly match: ${contentReviewColumns.join(',')}',
      );
    }
    final rows = <Map<String, String>>[];
    for (var index = 1; index < table.length; index++) {
      final values = table[index];
      if (values.every((value) => value.isEmpty)) continue;
      if (values.length != contentReviewColumns.length) {
        throw ContentReviewException(
          'CSV row ${index + 1} has ${values.length} columns; '
          'expected ${contentReviewColumns.length}',
        );
      }
      rows.add({
        for (var column = 0; column < contentReviewColumns.length; column++)
          contentReviewColumns[column]: values[column],
      });
    }
    return rows;
  }

  Map<String, dynamic>? _sourceFromRow(
    Map<String, String> row,
    String questionId,
  ) {
    final title = row['sourceTitle']!.trim();
    final publisher = row['sourcePublisher']!.trim();
    final url = row['sourceUrl']!.trim();
    final verifiedAt = row['verifiedAt']!.trim();
    final verificationLevel = row['verificationLevel']!.trim();
    final reviewStatus = row['reviewStatus']!.trim();

    if (!const {'primary', 'secondary', 'unverified'}.contains(
      verificationLevel,
    )) {
      throw ContentReviewException(
        '$questionId has invalid verificationLevel: $verificationLevel',
      );
    }
    if (!const {'approved', 'pending', 'rejected'}.contains(reviewStatus)) {
      throw ContentReviewException(
        '$questionId has invalid reviewStatus: $reviewStatus',
      );
    }

    final hasAnySourceField =
        title.isNotEmpty ||
        publisher.isNotEmpty ||
        url.isNotEmpty ||
        verifiedAt.isNotEmpty;
    if (!hasAnySourceField) {
      if (reviewStatus != 'pending' || verificationLevel != 'unverified') {
        throw ContentReviewException(
          '$questionId without source details must remain pending/unverified',
        );
      }
      return null;
    }
    if (title.isEmpty || publisher.isEmpty) {
      throw ContentReviewException(
        '$questionId requires sourceTitle and sourcePublisher together',
      );
    }

    final source = <String, dynamic>{
      'title': title,
      'publisher': publisher,
      if (url.isNotEmpty) 'url': url,
      if (verifiedAt.isNotEmpty) 'verifiedAt': verifiedAt,
      'verificationLevel': verificationLevel,
      'reviewStatus': reviewStatus,
    };
    SourceMetadata metadata;
    try {
      metadata = SourceMetadata.fromJson(source);
    } on FormatException catch (error) {
      throw ContentReviewException('$questionId: ${error.message}');
    }
    if (reviewStatus == 'approved' && !metadata.isApproved) {
      throw ContentReviewException(
        '$questionId approved source requires title, publisher, HTTP(S) URL, '
        'verifiedAt, and primary/secondary verification',
      );
    }
    return source;
  }

  void _validateUpdatedContent(String questionsJson, String cardsJson) {
    final validation = const ContentValidator().validateJsonStrings(
      questionsJson: questionsJson,
      cardsJson: cardsJson,
      assetExists: (_) => true,
    );
    if (!validation.isValid) {
      throw ContentReviewException(
        'updated JSON failed content validation: '
        '${validation.issues.take(5).join('; ')}',
      );
    }
    final audit = const ContentSourceAuditor().auditJsonStrings(
      questionsJson: questionsJson,
      cardsJson: cardsJson,
    );
    if (audit.hasInvalidMetadata) {
      final details = [
        ...audit.globalIssues,
        ...audit.entries
            .where((entry) => entry.invalidMetadata)
            .expand((entry) => entry.findings.map((item) => '${entry.id}: $item')),
      ];
      throw ContentReviewException(
        'updated JSON failed source audit: ${details.take(5).join('; ')}',
      );
    }
  }

  Future<void> _atomicReplace(Map<File, String> replacements) async {
    final nonce = '${DateTime.now().microsecondsSinceEpoch}-$pid';
    final tempFiles = <File, File>{};
    final backupFiles = <File, File>{};
    final installed = <File>{};

    try {
      for (final entry in replacements.entries) {
        final target = entry.key;
        final temp = File('${target.path}.content-review-$nonce.tmp');
        final backup = File('${target.path}.content-review-$nonce.bak');
        await temp.writeAsString(entry.value, flush: true);
        tempFiles[target] = temp;
        backupFiles[target] = backup;
      }
      for (final target in replacements.keys) {
        await target.rename(backupFiles[target]!.path);
      }
      for (final target in replacements.keys) {
        await tempFiles[target]!.rename(target.path);
        installed.add(target);
      }
      for (final backup in backupFiles.values) {
        if (await backup.exists()) await backup.delete();
      }
    } catch (error) {
      for (final target in replacements.keys.toList().reversed) {
        final backup = backupFiles[target];
        if (installed.contains(target) && await target.exists()) {
          await target.delete();
        }
        if (backup != null && await backup.exists()) {
          await backup.rename(target.path);
        }
      }
      throw ContentReviewException('failed to replace JSON atomically: $error');
    } finally {
      for (final temp in tempFiles.values) {
        if (await temp.exists()) await temp.delete();
      }
      for (final backup in backupFiles.values) {
        if (await backup.exists()) await backup.delete();
      }
    }
  }

  List<Map<String, dynamic>> _decodeCollection(String source, String label) {
    dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw ContentReviewException('$label JSON is invalid: ${error.message}');
    }
    if (decoded is! List) {
      throw ContentReviewException('$label JSON root must be an array');
    }
    final result = <Map<String, dynamic>>[];
    for (var index = 0; index < decoded.length; index++) {
      final item = decoded[index];
      if (item is! Map) {
        throw ContentReviewException('$label[$index] must be an object');
      }
      result.add(Map<String, dynamic>.from(item));
    }
    return result;
  }

  Map<String, Map<String, dynamic>> _byId(
    List<Map<String, dynamic>> items,
    String label,
  ) {
    final result = <String, Map<String, dynamic>>{};
    for (final item in items) {
      final id = _requiredString(item, 'id', label);
      if (result.containsKey(id)) {
        throw ContentReviewException('duplicate ID in $label: $id');
      }
      result[id] = item;
    }
    return result;
  }

  SourceMetadata _sourceForExport(
    Map<String, dynamic> question,
    Map<String, dynamic> card,
  ) {
    final questionSource = _trySource(question['source']);
    final cardSource = _trySource(card['source']);
    return questionSource ??
        cardSource ??
        SourceMetadata.legacy(
          _requiredString(question, 'sourceNote', question['id'].toString()),
        );
  }

  bool _pairIsApproved(
    Map<String, dynamic> question,
    Map<String, dynamic> card,
  ) {
    final questionSource = _trySource(question['source']);
    final cardSource = _trySource(card['source']);
    return questionSource?.isApproved == true &&
        cardSource?.isApproved == true &&
        questionSource!.url == cardSource!.url;
  }

  bool _sourceDiffers(
    Map<String, dynamic> question,
    Map<String, dynamic> card,
  ) {
    return _canonicalSource(question['source']) !=
        _canonicalSource(card['source']);
  }

  SourceMetadata? _trySource(Object? source) {
    if (source is! Map) return null;
    try {
      return SourceMetadata.fromJson(Map<String, dynamic>.from(source));
    } on FormatException {
      return null;
    }
  }

  String _statusOf(Object? source) {
    return _trySource(source)?.reviewStatus ?? 'legacy';
  }

  String _canonicalSource(Object? source) {
    if (source == null) return '';
    if (source is! Map) return jsonEncode(source);
    final sorted = <String, dynamic>{};
    final keys = source.keys.map((key) => key.toString()).toList()..sort();
    for (final key in keys) {
      sorted[key] = source[key];
    }
    return jsonEncode(sorted);
  }

  String _prettyJson(List<Map<String, dynamic>> items) {
    return '${const JsonEncoder.withIndent('  ').convert(items)}\n';
  }

  String _requiredString(
    Map<String, dynamic> item,
    String field,
    String label,
  ) {
    final value = item[field];
    if (value is! String || value.isEmpty) {
      throw ContentReviewException('$label.$field must be a non-empty string');
    }
    return value;
  }

  List<String> _stringList(Object? value, String label) {
    if (value is! List || value.any((item) => item is! String)) {
      throw ContentReviewException('$label must be a string array');
    }
    return List<String>.from(value);
  }

  void _requireUnchanged({
    required String field,
    required String expected,
    required String actual,
    required String questionId,
  }) {
    if (expected != actual) {
      throw ContentReviewException(
        '$questionId changed immutable CSV field $field',
      );
    }
  }

  List<String> _riskReasons(String text) {
    final reasons = <String>[];
    if (RegExp(r'[0-9０-９]|[%％]|約\s*[一二三四五六七八九十百千万億兆]').hasMatch(text)) {
      reasons.add('numeric');
    }
    if (RegExp(r'最も|いちばん|一番|世界一|日本一|最大|最小|最多|最少|ランキング|第[0-9０-９]+位').hasMatch(text)) {
      reasons.add('ranking');
    }
    if (RegExp(r'現在|現職|首相|大統領|知事|市長|社長|CEO|会長').hasMatch(text)) {
      reasons.add('current_role');
    }
    if (RegExp(r'病気|医療|治療|薬|症状|健康|死亡|寿命|心臓|血液|脳|がん|癌|感染|ウイルス|細菌|栄養').hasMatch(text)) {
      reasons.add('medical');
    }
    if (RegExp(r'法律|法令|違法|罰金|刑罰|権利|義務|裁判|契約|税制|税金').hasMatch(text)) {
      reasons.add('legal');
    }
    if (RegExp(r'金融|投資|株式|為替|金利|銀行|保険|ローン|通貨|価格|資産|年金').hasMatch(text)) {
      reasons.add('financial');
    }
    return reasons;
  }

  String _encodeCsv(List<List<String>> rows) {
    return '${rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n')}\r\n';
  }

  String _escapeCsv(String value) {
    if (!value.contains(RegExp(r'[,"\r\n]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  List<List<String>> _parseCsv(String input) {
    var source = input;
    if (source.startsWith('\ufeff')) source = source.substring(1);
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var inQuotes = false;
    var quoteClosed = false;

    void finishField() {
      row.add(field.toString());
      field = StringBuffer();
      quoteClosed = false;
    }

    void finishRow() {
      finishField();
      rows.add(row);
      row = <String>[];
    }

    for (var index = 0; index < source.length; index++) {
      final char = source[index];
      if (inQuotes) {
        if (char == '"') {
          if (index + 1 < source.length && source[index + 1] == '"') {
            field.write('"');
            index++;
          } else {
            inQuotes = false;
            quoteClosed = true;
          }
        } else {
          field.write(char);
        }
        continue;
      }
      if (quoteClosed && char != ',' && char != '\r' && char != '\n') {
        throw ContentReviewException(
          'unexpected character after closing quote at offset $index',
        );
      }
      if (char == '"') {
        if (field.isNotEmpty) {
          throw ContentReviewException(
            'unexpected quote in unquoted field at offset $index',
          );
        }
        inQuotes = true;
      } else if (char == ',') {
        finishField();
      } else if (char == '\n') {
        finishRow();
      } else if (char == '\r') {
        if (index + 1 < source.length && source[index + 1] == '\n') index++;
        finishRow();
      } else {
        field.write(char);
      }
    }
    if (inQuotes) {
      throw const ContentReviewException('CSV contains an unclosed quoted field');
    }
    if (field.isNotEmpty || row.isNotEmpty || quoteClosed) finishRow();
    if (rows.isNotEmpty && rows.last.every((value) => value.isEmpty)) {
      rows.removeLast();
    }
    return rows;
  }

  bool _sameStrings(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
