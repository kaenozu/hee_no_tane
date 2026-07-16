/// CSV workflow for claim-level content review and approval.
library;

import 'dart:convert';
import 'dart:io';

import 'package:hee_no_tane_app/content_validation/content_fingerprint.dart';
import 'package:hee_no_tane_app/content_validation/content_validator.dart';
import 'package:hee_no_tane_app/domain/models/image_review_metadata.dart';
import 'package:hee_no_tane_app/domain/models/source_metadata.dart';

const contentReviewColumns = <String>[
  'questionId',
  'cardId',
  'category',
  'difficulty',
  'question',
  'choice0',
  'choice1',
  'choice2',
  'choice3',
  'answerIndex',
  'explanation',
  'cardTitle',
  'cardShortText',
  'cardDetailText',
  'cardRarity',
  'imageAsset',
  'imageReviewStatus',
  'imageReviewedAt',
  'imageReviewNote',
  'sourceTitle',
  'sourcePublisher',
  'sourceUrl',
  'verifiedAt',
  'verificationLevel',
  'reviewStatus',
  'reviewNote',
  'contentHash',
];

class ContentReviewException implements Exception {
  final String message;
  const ContentReviewException(this.message);

  @override
  String toString() => message;
}

abstract interface class ContentReviewFileStore {
  Future<String> readAsString(String path);

  Future<void> writeAsString(
    String path,
    String content, {
    bool flush = false,
  });

  Future<void> rename(String sourcePath, String targetPath);

  Future<bool> exists(String path);

  Future<void> delete(String path);
}

final class IoContentReviewFileStore implements ContentReviewFileStore {
  const IoContentReviewFileStore();

  @override
  Future<String> readAsString(String path) => File(path).readAsString();

  @override
  Future<void> writeAsString(
    String path,
    String content, {
    bool flush = false,
  }) async {
    await File(path).writeAsString(content, flush: flush);
  }

  @override
  Future<void> rename(String sourcePath, String targetPath) async {
    await File(sourcePath).rename(targetPath);
  }

  @override
  Future<bool> exists(String path) async => File(path).exists();

  @override
  Future<void> delete(String path) => File(path).delete();
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
  String get summary =>
      changes.isEmpty ? 'JSONに反映する差分はありません。' : '${changes.length}組を変更します。';
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

  String exportCsv({required String questionsJson, required String cardsJson}) {
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
      if (choices.length != 4) {
        throw ContentReviewException('$questionId must have four choices');
      }
      final answerIndex = question['answerIndex'];
      if (answerIndex is! int || answerIndex < 0 || answerIndex >= 4) {
        throw ContentReviewException('$questionId has an invalid answerIndex');
      }
      final source = _sourceForExport(question, card);
      final image = _imageReviewForExport(card);
      final fingerprint = ContentFingerprint.forPair(
        question: question,
        card: card,
      );
      rows.add(<String>[
        questionId,
        cardId,
        _requiredString(question, 'category', questionId),
        _requiredString(question, 'difficulty', questionId),
        _requiredString(question, 'question', questionId),
        ...choices,
        '$answerIndex',
        _requiredString(question, 'explanation', questionId),
        _requiredString(card, 'title', cardId),
        _requiredString(card, 'shortText', cardId),
        _requiredString(card, 'detailText', cardId),
        _requiredString(card, 'rarity', cardId),
        card['imageAsset'] is String ? card['imageAsset'] as String : '',
        image.status,
        image.reviewedAt,
        image.note,
        source?.title ?? '',
        source?.publisher ?? '',
        source?.url ?? '',
        source?.verifiedAt ?? '',
        source?.verificationLevel ?? 'unverified',
        source?.reviewStatus ?? SourceMetadata.pendingStatus,
        source?.reviewNote ?? '',
        fingerprint,
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
        throw ContentReviewException(
          'duplicate questionId in CSV: $questionId',
        );
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
      if (question['relatedCardId'] != cardId) {
        throw ContentReviewException('$questionId is not paired with $cardId');
      }

      final choices = _stringList(question['choices'], '$questionId.choices');
      final immutable = <String, String>{
        'category': _requiredString(question, 'category', questionId),
        'difficulty': _requiredString(question, 'difficulty', questionId),
        'question': _requiredString(question, 'question', questionId),
        for (var i = 0; i < 4; i++) 'choice$i': choices[i],
        'answerIndex': '${question['answerIndex']}',
        'explanation': _requiredString(question, 'explanation', questionId),
        'cardTitle': _requiredString(card, 'title', cardId),
        'cardShortText': _requiredString(card, 'shortText', cardId),
        'cardDetailText': _requiredString(card, 'detailText', cardId),
        'cardRarity': _requiredString(card, 'rarity', cardId),
        'imageAsset': card['imageAsset'] is String
            ? card['imageAsset'] as String
            : '',
      };
      for (final entry in immutable.entries) {
        _requireUnchanged(
          field: entry.key,
          expected: entry.value,
          actual: row[entry.key]!,
          questionId: questionId,
        );
      }

      final expectedHash = ContentFingerprint.forPair(
        question: question,
        card: card,
      );
      if (row['contentHash']!.trim() != expectedHash) {
        throw ContentReviewException(
          '$questionId contentHash does not match the current question/card text',
        );
      }

      final nextSource = _sourceFromRow(row, questionId, expectedHash);
      final nextImage = _imageReviewFromRow(row, cardId);
      final previousStatus = _statusOf(question['source']);
      final nextStatus =
          nextSource?['reviewStatus'] as String? ?? SourceMetadata.pendingStatus;
      final nextVerified = nextStatus == SourceMetadata.approvedStatus;
      final oldQuestionSource = _canonical(question['source']);
      final oldCardSource = _canonical(card['source']);
      final oldImage = _canonical(card['imageReview']);
      final nextCanonical = _canonical(nextSource);
      final nextImageCanonical = _canonical(nextImage);

      if (oldQuestionSource != nextCanonical ||
          oldCardSource != nextCanonical ||
          oldImage != nextImageCanonical ||
          question['verified'] != nextVerified) {
        changes.add(
          ContentReviewChange(
            questionId: questionId,
            cardId: cardId,
            previousStatus: previousStatus,
            nextStatus: nextStatus,
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
      card['imageReview'] = Map<String, dynamic>.from(nextImage);
      question['verified'] = nextVerified;
    }

    final encodedQuestions = _prettyJson(questions);
    final encodedCards = _prettyJson(cards);
    final validation = const ContentValidator().validateJsonStrings(
      questionsJson: encodedQuestions,
      cardsJson: encodedCards,
      assetExists: (_) => true,
      requirePlayable: false,
    );
    if (!validation.isValid) {
      throw ContentReviewException(
        'imported content is invalid: '
        '${validation.issues.map((issue) => issue.toString()).join(' | ')}',
      );
    }

    return ContentReviewImportPlan(
      questionsJson: encodedQuestions,
      cardsJson: encodedCards,
      changes: List<ContentReviewChange>.unmodifiable(changes),
    );
  }

  Future<ContentReviewImportPlan> applyCsvToFiles({
    required String csv,
    required String questionsPath,
    required String cardsPath,
    required bool write,
    ContentReviewFileStore fileStore = const IoContentReviewFileStore(),
  }) async {
    final plan = planImport(
      csv: csv,
      questionsJson: await fileStore.readAsString(questionsPath),
      cardsJson: await fileStore.readAsString(cardsPath),
    );
    if (write && plan.hasChanges) {
      await _replacePairRecoverably(
        fileStore: fileStore,
        questionsPath: questionsPath,
        cardsPath: cardsPath,
        questionsJson: plan.questionsJson,
        cardsJson: plan.cardsJson,
      );
    }
    return plan;
  }

  Future<void> _replacePairRecoverably({
    required ContentReviewFileStore fileStore,
    required String questionsPath,
    required String cardsPath,
    required String questionsJson,
    required String cardsJson,
  }) async {
    final tempQuestions = '$questionsPath.tmp';
    final tempCards = '$cardsPath.tmp';
    final backupQuestions = '$questionsPath.bak';
    final backupCards = '$cardsPath.bak';

    if (await fileStore.exists(backupQuestions) ||
        await fileStore.exists(backupCards)) {
      throw const ContentReviewException(
        'A previous content update backup exists. Restore or remove the .bak files before retrying.',
      );
    }

    await _deleteIfExists(fileStore, tempQuestions);
    await _deleteIfExists(fileStore, tempCards);
    await fileStore.writeAsString(tempQuestions, questionsJson, flush: true);
    await fileStore.writeAsString(tempCards, cardsJson, flush: true);

    var questionsBackedUp = false;
    var cardsBackedUp = false;
    var questionsInstalled = false;
    var cardsInstalled = false;
    var committed = false;

    try {
      await fileStore.rename(questionsPath, backupQuestions);
      questionsBackedUp = true;
      await fileStore.rename(cardsPath, backupCards);
      cardsBackedUp = true;
      await fileStore.rename(tempQuestions, questionsPath);
      questionsInstalled = true;
      await fileStore.rename(tempCards, cardsPath);
      cardsInstalled = true;
      committed = true;
    } catch (error, stackTrace) {
      final rollbackErrors = <Object>[];
      try {
        if (questionsInstalled && await fileStore.exists(questionsPath)) {
          await fileStore.delete(questionsPath);
        }
      } catch (rollbackError) {
        rollbackErrors.add(rollbackError);
      }
      try {
        if (cardsInstalled && await fileStore.exists(cardsPath)) {
          await fileStore.delete(cardsPath);
        }
      } catch (rollbackError) {
        rollbackErrors.add(rollbackError);
      }
      try {
        if (cardsBackedUp && await fileStore.exists(backupCards)) {
          await fileStore.rename(backupCards, cardsPath);
          cardsBackedUp = false;
        }
      } catch (rollbackError) {
        rollbackErrors.add(rollbackError);
      }
      try {
        if (questionsBackedUp && await fileStore.exists(backupQuestions)) {
          await fileStore.rename(backupQuestions, questionsPath);
          questionsBackedUp = false;
        }
      } catch (rollbackError) {
        rollbackErrors.add(rollbackError);
      }

      if (rollbackErrors.isNotEmpty) {
        throw ContentReviewException(
          'Content update failed and rollback was incomplete. Preserve the .bak files and restore them manually. Original error: $error',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      await _tryDelete(fileStore, tempQuestions);
      await _tryDelete(fileStore, tempCards);
      if (committed) {
        await _tryDelete(fileStore, backupQuestions);
        await _tryDelete(fileStore, backupCards);
      }
    }
  }

  Future<void> _deleteIfExists(
    ContentReviewFileStore fileStore,
    String path,
  ) async {
    if (await fileStore.exists(path)) await fileStore.delete(path);
  }

  Future<void> _tryDelete(
    ContentReviewFileStore fileStore,
    String path,
  ) async {
    try {
      await _deleteIfExists(fileStore, path);
    } catch (_) {
      // Cleanup failures leave recoverable temp/backup files and must not turn a
      // successfully committed pair into a reported failed transaction.
    }
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
      final category = _requiredString(question, 'category', 'question');
      totals.update(category, (value) => value + 1, ifAbsent: () => 1);
      final card = cardsById[question['relatedCardId']];
      if (card == null) continue;
      final qSource = _trySource(question['source']);
      final cSource = _trySource(card['source']);
      final expected = ContentFingerprint.forPair(
        question: question,
        card: card,
      );
      final image = _tryImageReview(card['imageReview']);
      if (question['verified'] == true &&
          qSource?.isReleaseApproved == true &&
          cSource?.isReleaseApproved == true &&
          qSource!.url == cSource!.url &&
          qSource.contentHash == expected &&
          cSource.contentHash == expected &&
          image?.isReleaseReady == true) {
        approved.update(category, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final categories = totals.keys.toList()..sort();
    return <CategoryApprovalProgress>[
      for (final category in categories)
        CategoryApprovalProgress(
          category: category,
          approved: approved[category] ?? 0,
          total: totals[category]!,
        ),
    ];
  }

  List<ContentRiskEntry> risks({
    required String questionsJson,
    required String cardsJson,
  }) {
    final questions = _decodeCollection(questionsJson, 'questions');
    final cardsById = _byId(_decodeCollection(cardsJson, 'cards'), 'cards');
    final result = <ContentRiskEntry>[];
    for (final question in questions) {
      final card = cardsById[question['relatedCardId']];
      if (card == null) continue;
      final choices = _stringList(question['choices'], 'choices');
      final answerIndex = question['answerIndex'] as int;
      final text = <String>[
        _requiredString(question, 'question', 'question'),
        ...choices,
        _requiredString(question, 'explanation', 'question'),
        _requiredString(card, 'title', 'card'),
        _requiredString(card, 'detailText', 'card'),
      ].join(' ');
      final reasons = <String>[];
      if (RegExp(r'[0-9０-９%％]').hasMatch(text)) reasons.add('numeric');
      if (RegExp(r'一番|最も|最大|最小|世界一|日本一').hasMatch(text)) {
        reasons.add('ranking');
      }
      if (RegExp(r'病気|医療|治療|薬|心臓|血液|脳|健康').hasMatch(text)) {
        reasons.add('medical');
      }
      if (reasons.isEmpty) continue;
      result.add(
        ContentRiskEntry(
          questionId: question['id'] as String,
          cardId: card['id'] as String,
          category: question['category'] as String,
          reasons: List<String>.unmodifiable(reasons),
          question: question['question'] as String,
          answer: choices[answerIndex],
          explanation: question['explanation'] as String,
          cardTitle: card['title'] as String,
          cardDetail: card['detailText'] as String,
        ),
      );
    }
    return List<ContentRiskEntry>.unmodifiable(result);
  }

  String riskCsv({required String questionsJson, required String cardsJson}) {
    final rows = <List<String>>[
      const <String>[
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
      for (final risk in risks(
        questionsJson: questionsJson,
        cardsJson: cardsJson,
      ))
        <String>[
          risk.questionId,
          risk.cardId,
          risk.category,
          risk.reasons.join('|'),
          risk.question,
          risk.answer,
          risk.explanation,
          risk.cardTitle,
          risk.cardDetail,
        ],
    ];
    return _encodeCsv(rows);
  }

  SourceMetadata? _sourceForExport(
    Map<String, dynamic> question,
    Map<String, dynamic> card,
  ) {
    final questionSource = _trySource(question['source']);
    final cardSource = _trySource(card['source']);
    if (questionSource == null) return cardSource;
    if (cardSource == null) return questionSource;
    return _canonical(question['source']) == _canonical(card['source'])
        ? questionSource
        : SourceMetadata(
            title: questionSource.title,
            publisher: questionSource.publisher,
            url: questionSource.url,
            verifiedAt: questionSource.verifiedAt,
            verificationLevel: questionSource.verificationLevel,
            reviewStatus: SourceMetadata.pendingStatus,
            reviewNote: 'QUESTION_CARD_SOURCE_METADATA_DIFF',
          );
  }

  ImageReviewMetadata _imageReviewForExport(Map<String, dynamic> card) =>
      _tryImageReview(card['imageReview']) ??
      const ImageReviewMetadata.unchecked();

  Map<String, dynamic>? _sourceFromRow(
    Map<String, String> row,
    String questionId,
    String expectedHash,
  ) {
    final status = row['reviewStatus']!.trim();
    if (!SourceMetadata.allowedReviewStatuses.contains(status)) {
      throw ContentReviewException(
        '$questionId has invalid reviewStatus: $status',
      );
    }
    final title = row['sourceTitle']!.trim();
    final publisher = row['sourcePublisher']!.trim();
    final url = row['sourceUrl']!.trim();
    final verifiedAt = row['verifiedAt']!.trim();
    final level = row['verificationLevel']!.trim();
    final note = row['reviewNote']!.trim();
    if (status != SourceMetadata.approvedStatus &&
        title.isEmpty &&
        publisher.isEmpty &&
        url.isEmpty &&
        verifiedAt.isEmpty &&
        note.isEmpty) {
      return null;
    }
    final metadata = SourceMetadata(
      title: title.isEmpty ? '出典確認中' : title,
      publisher: publisher.isEmpty ? '確認中' : publisher,
      url: url.isEmpty ? null : url,
      verifiedAt: verifiedAt.isEmpty ? null : verifiedAt,
      verificationLevel: level,
      reviewStatus: status,
      reviewNote: note.isEmpty ? null : note,
      contentHash: status == SourceMetadata.approvedStatus ? expectedHash : null,
    );
    if (!SourceMetadata.allowedVerificationLevels.contains(level)) {
      throw ContentReviewException(
        '$questionId has invalid verificationLevel: $level',
      );
    }
    if (status == SourceMetadata.approvedStatus &&
        !metadata.isReleaseApproved) {
      throw ContentReviewException(
        '$questionId approved source is missing required evidence',
      );
    }
    return metadata.toJson();
  }

  Map<String, dynamic> _imageReviewFromRow(
    Map<String, String> row,
    String cardId,
  ) {
    try {
      return ImageReviewMetadata.fromJson(<String, dynamic>{
        'status': row['imageReviewStatus']!.trim(),
        'reviewedAt': row['imageReviewedAt']!.trim(),
        'note': row['imageReviewNote']!.trim(),
      }).toJson();
    } catch (error) {
      throw ContentReviewException('$cardId has invalid image review: $error');
    }
  }

  List<Map<String, String>> _decodeReviewCsv(String csv) {
    final table = _parseCsv(csv);
    if (table.isEmpty || !_sameStrings(table.first, contentReviewColumns)) {
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
      rows.add(<String, String>{
        for (var column = 0; column < contentReviewColumns.length; column++)
          contentReviewColumns[column]: values[column],
      });
    }
    return rows;
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
    return <Map<String, dynamic>>[
      for (var index = 0; index < decoded.length; index++)
        if (decoded[index] is Map)
          Map<String, dynamic>.from(decoded[index] as Map)
        else
          throw ContentReviewException('$label[$index] must be an object'),
    ];
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

  String _requiredString(
    Map<String, dynamic> item,
    String field,
    String label,
  ) {
    final value = item[field];
    if (value is! String || value.trim().isEmpty) {
      throw ContentReviewException('$label.$field must be a non-empty string');
    }
    return value.trim();
  }

  List<String> _stringList(Object? value, String label) {
    if (value is! List || value.any((item) => item is! String)) {
      throw ContentReviewException('$label must be a string array');
    }
    return List<String>.from(value);
  }

  SourceMetadata? _trySource(Object? value) =>
      SourceMetadata.tryFromJson(value);

  ImageReviewMetadata? _tryImageReview(Object? value) {
    if (value is! Map) return null;
    try {
      return ImageReviewMetadata.fromJson(Map<String, dynamic>.from(value));
    } catch (_) {
      return null;
    }
  }

  String _statusOf(Object? source) =>
      _trySource(source)?.reviewStatus ?? SourceMetadata.pendingStatus;

  String _canonical(Object? value) => value == null ? '' : jsonEncode(value);

  void _requireUnchanged({
    required String field,
    required String expected,
    required String actual,
    required String questionId,
  }) {
    if (actual != expected) {
      throw ContentReviewException(
        '$questionId changed immutable CSV field $field',
      );
    }
  }

  String _prettyJson(Object value) =>
      '${const JsonEncoder.withIndent('  ').convert(value)}\n';

  String _encodeCsv(List<List<String>> rows) =>
      '${rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n')}\r\n';

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
    for (var index = 0; index < source.length; index++) {
      final char = source[index];
      if (inQuotes) {
        if (char == '"') {
          if (index + 1 < source.length && source[index + 1] == '"') {
            field.write('"');
            index++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(char);
        }
      } else if (char == '"') {
        inQuotes = true;
      } else if (char == ',') {
        row.add(field.toString());
        field = StringBuffer();
      } else if (char == '\n') {
        if (field.isNotEmpty || row.isNotEmpty) {
          row.add(field.toString().replaceAll(RegExp(r'\r$'), ''));
          rows.add(row);
        }
        row = <String>[];
        field = StringBuffer();
      } else {
        field.write(char);
      }
    }
    if (inQuotes) throw const ContentReviewException('CSV has an open quote');
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
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
