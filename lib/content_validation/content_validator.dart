/// Validation for the bundled question and card JSON content.
library;

import 'dart:convert';

typedef AssetExists = bool Function(String path);

class ContentValidationIssue {
  final String path;
  final String message;

  const ContentValidationIssue(this.path, this.message);

  @override
  String toString() => '$path: $message';
}

class ContentValidationResult {
  final List<ContentValidationIssue> issues;
  final int questionCount;
  final int cardCount;

  const ContentValidationResult({
    required this.issues,
    required this.questionCount,
    required this.cardCount,
  });

  bool get isValid => issues.isEmpty;
}

class ContentValidator {
  static const allowedCategories = <String>{
    'nature_geography',
    'living_things',
    'history',
    'science',
    'food',
    'language',
    'daily_life',
  };

  static const allowedDifficulties = <String>{'easy', 'normal', 'hard'};
  static const allowedRarities = <String>{'normal', 'rare'};

  const ContentValidator();

  ContentValidationResult validateJsonStrings({
    required String questionsJson,
    required String cardsJson,
    required AssetExists assetExists,
  }) {
    final issues = <ContentValidationIssue>[];
    final questionRoot = _decodeRoot(questionsJson, 'questions', issues);
    final cardRoot = _decodeRoot(cardsJson, 'cards', issues);

    final questions = _validateQuestions(questionRoot, issues);
    final cards = _validateCards(cardRoot, issues, assetExists);
    _validateRelationships(questions, cards, issues);

    return ContentValidationResult(
      issues: List.unmodifiable(issues),
      questionCount: questions.length,
      cardCount: cards.length,
    );
  }

  List<dynamic>? _decodeRoot(
    String source,
    String label,
    List<ContentValidationIssue> issues,
  ) {
    dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      issues.add(
        ContentValidationIssue(label, 'invalid JSON: ${error.message}'),
      );
      return null;
    }

    if (decoded is! List<dynamic>) {
      issues.add(ContentValidationIssue(label, 'root must be a JSON array'));
      return null;
    }
    return decoded;
  }

  List<_QuestionRecord> _validateQuestions(
    List<dynamic>? root,
    List<ContentValidationIssue> issues,
  ) {
    if (root == null) return const [];

    final records = <_QuestionRecord>[];
    final seenIds = <String>{};

    for (var index = 0; index < root.length; index++) {
      final path = 'questions[$index]';
      final item = root[index];
      if (item is! Map<String, dynamic>) {
        issues.add(ContentValidationIssue(path, 'must be a JSON object'));
        continue;
      }

      final id = _requiredString(item, 'id', path, issues, maxLength: 80);
      final category = _requiredString(
        item,
        'category',
        path,
        issues,
        maxLength: 40,
      );
      final difficulty = _requiredString(
        item,
        'difficulty',
        path,
        issues,
        maxLength: 20,
      );
      _requiredString(item, 'question', path, issues, maxLength: 100);
      _requiredString(item, 'explanation', path, issues, maxLength: 240);
      final relatedCardId = _requiredString(
        item,
        'relatedCardId',
        path,
        issues,
        maxLength: 80,
      );
      _requiredString(item, 'sourceNote', path, issues, maxLength: 120);

      if (id != null && !seenIds.add(id)) {
        issues.add(ContentValidationIssue('$path.id', 'duplicate id "$id"'));
      }
      if (category != null && !allowedCategories.contains(category)) {
        issues.add(
          ContentValidationIssue(
            '$path.category',
            'must be one of ${allowedCategories.join(', ')}, got "$category"',
          ),
        );
      }
      if (difficulty != null && !allowedDifficulties.contains(difficulty)) {
        issues.add(
          ContentValidationIssue(
            '$path.difficulty',
            'must be one of ${allowedDifficulties.join(', ')}, got "$difficulty"',
          ),
        );
      }

      _validateChoices(item['choices'], path, issues);
      _validateAnswerIndex(item['answerIndex'], path, issues);

      final verified = item['verified'];
      if (verified is! bool) {
        issues.add(ContentValidationIssue('$path.verified', 'must be a boolean'));
      } else if (!verified) {
        issues.add(
          ContentValidationIssue(
            '$path.verified',
            'must be true for bundled production content',
          ),
        );
      }

      records.add(
        _QuestionRecord(
          index: index,
          category: category,
          relatedCardId: relatedCardId,
        ),
      );
    }

    return records;
  }

  List<_CardRecord> _validateCards(
    List<dynamic>? root,
    List<ContentValidationIssue> issues,
    AssetExists assetExists,
  ) {
    if (root == null) return const [];

    final records = <_CardRecord>[];
    final seenIds = <String>{};

    for (var index = 0; index < root.length; index++) {
      final path = 'cards[$index]';
      final item = root[index];
      if (item is! Map<String, dynamic>) {
        issues.add(ContentValidationIssue(path, 'must be a JSON object'));
        continue;
      }

      final id = _requiredString(item, 'id', path, issues, maxLength: 80);
      final category = _requiredString(
        item,
        'category',
        path,
        issues,
        maxLength: 40,
      );
      _requiredString(item, 'title', path, issues, maxLength: 60);
      _requiredString(item, 'shortText', path, issues, maxLength: 140);
      _requiredString(item, 'detailText', path, issues, maxLength: 500);
      final imageAsset = _stringField(
        item,
        'imageAsset',
        path,
        issues,
        allowEmpty: true,
        maxLength: 240,
      );
      final rarity = _requiredString(
        item,
        'rarity',
        path,
        issues,
        maxLength: 20,
      );
      _requiredString(item, 'sourceNote', path, issues, maxLength: 120);

      if (id != null && !seenIds.add(id)) {
        issues.add(ContentValidationIssue('$path.id', 'duplicate id "$id"'));
      }
      if (category != null && !allowedCategories.contains(category)) {
        issues.add(
          ContentValidationIssue(
            '$path.category',
            'must be one of ${allowedCategories.join(', ')}, got "$category"',
          ),
        );
      }
      if (rarity != null && !allowedRarities.contains(rarity)) {
        issues.add(
          ContentValidationIssue(
            '$path.rarity',
            'must be one of ${allowedRarities.join(', ')}, got "$rarity"',
          ),
        );
      }
      if (imageAsset != null && imageAsset.isNotEmpty && !assetExists(imageAsset)) {
        issues.add(
          ContentValidationIssue(
            '$path.imageAsset',
            'file does not exist: "$imageAsset"',
          ),
        );
      }

      records.add(_CardRecord(index: index, id: id, category: category));
    }

    return records;
  }

  void _validateChoices(
    Object? value,
    String path,
    List<ContentValidationIssue> issues,
  ) {
    if (value is! List<dynamic>) {
      issues.add(ContentValidationIssue('$path.choices', 'must be an array'));
      return;
    }

    if (value.length != 4) {
      issues.add(
        ContentValidationIssue(
          '$path.choices',
          'must contain exactly 4 choices, got ${value.length}',
        ),
      );
    }

    final normalized = <String>[];
    for (var index = 0; index < value.length; index++) {
      final choicePath = '$path.choices[$index]';
      final choice = value[index];
      if (choice is! String) {
        issues.add(ContentValidationIssue(choicePath, 'must be a string'));
        continue;
      }
      final trimmed = choice.trim();
      if (trimmed.isEmpty) {
        issues.add(ContentValidationIssue(choicePath, 'must not be empty'));
      }
      if (trimmed.length > 60) {
        issues.add(
          ContentValidationIssue(
            choicePath,
            'must be at most 60 characters, got ${trimmed.length}',
          ),
        );
      }
      normalized.add(trimmed);
    }

    if (normalized.toSet().length != normalized.length) {
      issues.add(
        ContentValidationIssue('$path.choices', 'must not contain duplicates'),
      );
    }
  }

  void _validateAnswerIndex(
    Object? value,
    String path,
    List<ContentValidationIssue> issues,
  ) {
    if (value is! int) {
      issues.add(ContentValidationIssue('$path.answerIndex', 'must be an int'));
      return;
    }
    if (value < 0 || value > 3) {
      issues.add(
        ContentValidationIssue(
          '$path.answerIndex',
          'expected 0..3, got $value',
        ),
      );
    }
  }

  void _validateRelationships(
    List<_QuestionRecord> questions,
    List<_CardRecord> cards,
    List<ContentValidationIssue> issues,
  ) {
    final cardsById = <String, _CardRecord>{};
    for (final card in cards) {
      final id = card.id;
      if (id != null) cardsById.putIfAbsent(id, () => card);
    }

    final referencedCardIds = <String>{};
    for (final question in questions) {
      final relatedCardId = question.relatedCardId;
      if (relatedCardId == null) continue;
      final card = cardsById[relatedCardId];
      if (card == null) {
        issues.add(
          ContentValidationIssue(
            'questions[${question.index}].relatedCardId',
            'card "$relatedCardId" does not exist',
          ),
        );
        continue;
      }

      referencedCardIds.add(relatedCardId);
      if (question.category != null &&
          card.category != null &&
          question.category != card.category) {
        issues.add(
          ContentValidationIssue(
            'questions[${question.index}].category',
            'must match cards[${card.index}].category "${card.category}"',
          ),
        );
      }
    }

    for (final card in cards) {
      final id = card.id;
      if (id != null && !referencedCardIds.contains(id)) {
        issues.add(
          ContentValidationIssue(
            'cards[${card.index}].id',
            'card "$id" is not referenced by any question',
          ),
        );
      }
    }
  }

  String? _requiredString(
    Map<String, dynamic> item,
    String field,
    String path,
    List<ContentValidationIssue> issues, {
    required int maxLength,
  }) {
    return _stringField(
      item,
      field,
      path,
      issues,
      allowEmpty: false,
      maxLength: maxLength,
    );
  }

  String? _stringField(
    Map<String, dynamic> item,
    String field,
    String path,
    List<ContentValidationIssue> issues, {
    required bool allowEmpty,
    required int maxLength,
  }) {
    if (!item.containsKey(field)) {
      issues.add(ContentValidationIssue('$path.$field', 'is required'));
      return null;
    }

    final value = item[field];
    if (value is! String) {
      issues.add(ContentValidationIssue('$path.$field', 'must be a string'));
      return null;
    }

    final trimmed = value.trim();
    if (!allowEmpty && trimmed.isEmpty) {
      issues.add(ContentValidationIssue('$path.$field', 'must not be empty'));
    }
    if (trimmed.length > maxLength) {
      issues.add(
        ContentValidationIssue(
          '$path.$field',
          'must be at most $maxLength characters, got ${trimmed.length}',
        ),
      );
    }
    return trimmed;
  }
}

class _QuestionRecord {
  final int index;
  final String? category;
  final String? relatedCardId;

  const _QuestionRecord({
    required this.index,
    required this.category,
    required this.relatedCardId,
  });
}

class _CardRecord {
  final int index;
  final String? id;
  final String? category;

  const _CardRecord({
    required this.index,
    required this.id,
    required this.category,
  });
}
