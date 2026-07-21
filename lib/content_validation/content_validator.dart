/// Validation for bundled question/card JSON content.
library;

import 'dart:convert';

import 'package:hee_no_tane_app/content_validation/content_fingerprint.dart';
import 'package:hee_no_tane_app/domain/models/image_review_metadata.dart';
import 'package:hee_no_tane_app/domain/models/source_metadata.dart';

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
  final int playableQuestionCount;

  const ContentValidationResult({
    required this.issues,
    required this.questionCount,
    required this.cardCount,
    this.playableQuestionCount = 0,
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
    String? manifestJson,
    bool requirePlayable = true,
  }) {
    final issues = <ContentValidationIssue>[];
    final questions = _decodeObjects(questionsJson, 'questions', issues);
    final cards = _decodeObjects(cardsJson, 'cards', issues);
    final manifest = manifestJson == null
        ? null
        : _decodeManifest(manifestJson, issues);

    if (questions.isEmpty) {
      issues.add(
        const ContentValidationIssue(
          'questions',
          'must contain at least one question',
        ),
      );
    }
    if (cards.isEmpty) {
      issues.add(
        const ContentValidationIssue('cards', 'must contain at least one card'),
      );
    }

    final cardRecords = _validateCards(cards, issues, assetExists);
    final playableCount = _validateQuestions(questions, cardRecords, issues);

    if (requirePlayable && playableCount == 0) {
      issues.add(
        const ContentValidationIssue(
          'questions',
          'must contain at least one release-approved playable question',
        ),
      );
    }

    if (manifest != null) {
      _validateManifest(
        manifest,
        questions.length,
        cards.length,
        playableCount,
        issues,
      );
    }

    return ContentValidationResult(
      issues: List<ContentValidationIssue>.unmodifiable(issues),
      questionCount: questions.length,
      cardCount: cards.length,
      playableQuestionCount: playableCount,
    );
  }

  List<Map<String, dynamic>> _decodeObjects(
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
      return const <Map<String, dynamic>>[];
    }
    if (decoded is! List) {
      issues.add(ContentValidationIssue(label, 'root must be a JSON array'));
      return const <Map<String, dynamic>>[];
    }
    final result = <Map<String, dynamic>>[];
    for (var index = 0; index < decoded.length; index++) {
      final value = decoded[index];
      if (value is! Map) {
        issues.add(
          ContentValidationIssue('$label[$index]', 'must be an object'),
        );
        continue;
      }
      result.add(Map<String, dynamic>.from(value));
    }
    return result;
  }

  Map<String, dynamic>? _decodeManifest(
    String source,
    List<ContentValidationIssue> issues,
  ) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      issues.add(
        const ContentValidationIssue('manifest', 'root must be a JSON object'),
      );
    } on FormatException catch (error) {
      issues.add(
        ContentValidationIssue('manifest', 'invalid JSON: ${error.message}'),
      );
    }
    return null;
  }

  Map<String, _CardRecord> _validateCards(
    List<Map<String, dynamic>> cards,
    List<ContentValidationIssue> issues,
    AssetExists assetExists,
  ) {
    final result = <String, _CardRecord>{};
    for (var index = 0; index < cards.length; index++) {
      final card = cards[index];
      final path = 'cards[$index]';
      final id = _requiredString(card, 'id', path, issues, 80);
      final category = _requiredString(card, 'category', path, issues, 40);
      _requiredString(card, 'title', path, issues, 60);
      _requiredString(card, 'shortText', path, issues, 140);
      _requiredString(card, 'detailText', path, issues, 500);
      final imageAsset = _requiredString(card, 'imageAsset', path, issues, 240);
      final rarity = _requiredString(card, 'rarity', path, issues, 20);
      _requiredString(card, 'sourceNote', path, issues, 180);

      if (id != null && result.containsKey(id)) {
        issues.add(ContentValidationIssue('$path.id', 'duplicate id "$id"'));
      }
      if (category != null && !allowedCategories.contains(category)) {
        issues.add(
          ContentValidationIssue(
            '$path.category',
            'unknown category "$category"',
          ),
        );
      }
      if (rarity != null && !allowedRarities.contains(rarity)) {
        issues.add(
          ContentValidationIssue('$path.rarity', 'unknown rarity "$rarity"'),
        );
      }
      if (imageAsset != null && !assetExists(imageAsset)) {
        issues.add(
          ContentValidationIssue(
            '$path.imageAsset',
            'file does not exist: "$imageAsset"',
          ),
        );
      }

      final source = _parseSource(card['source'], '$path.source', issues);
      final imageReview = _parseImageReview(
        card['imageReview'],
        '$path.imageReview',
        issues,
      );
      if (source?.reviewStatus == 'approved' &&
          source?.isReleaseApproved != true) {
        issues.add(
          ContentValidationIssue(
            '$path.source',
            'approved source must include valid HTTPS metadata and contentHash',
          ),
        );
      }

      if (id != null) {
        result[id] = _CardRecord(
          json: card,
          category: category,
          source: source,
          imageReview: imageReview,
        );
      }
    }
    return result;
  }

  int _validateQuestions(
    List<Map<String, dynamic>> questions,
    Map<String, _CardRecord> cards,
    List<ContentValidationIssue> issues,
  ) {
    final seenIds = <String>{};
    final seenCardIds = <String>{};
    var playable = 0;
    for (var index = 0; index < questions.length; index++) {
      final question = questions[index];
      final path = 'questions[$index]';
      final id = _requiredString(question, 'id', path, issues, 80);
      final category = _requiredString(question, 'category', path, issues, 40);
      final difficulty = _requiredString(
        question,
        'difficulty',
        path,
        issues,
        20,
      );
      _requiredString(question, 'question', path, issues, 140);
      _requiredString(question, 'explanation', path, issues, 500);
      final relatedCardId = _requiredString(
        question,
        'relatedCardId',
        path,
        issues,
        80,
      );
      _requiredString(question, 'sourceNote', path, issues, 180);

      if (id != null && !seenIds.add(id)) {
        issues.add(ContentValidationIssue('$path.id', 'duplicate id "$id"'));
      }
      if (category != null && !allowedCategories.contains(category)) {
        issues.add(
          ContentValidationIssue(
            '$path.category',
            'unknown category "$category"',
          ),
        );
      }
      if (difficulty != null && !allowedDifficulties.contains(difficulty)) {
        issues.add(
          ContentValidationIssue(
            '$path.difficulty',
            'unknown difficulty "$difficulty"',
          ),
        );
      }

      final choices = _validateChoices(question['choices'], path, issues);
      final answerIndex = question['answerIndex'];
      if (answerIndex is! int) {
        issues.add(
          ContentValidationIssue('$path.answerIndex', 'must be an integer'),
        );
      } else if (answerIndex < 0 || answerIndex >= choices.length) {
        issues.add(
          ContentValidationIssue(
            '$path.answerIndex',
            'must point to an existing choice',
          ),
        );
      }

      final verified = question['verified'];
      if (verified is! bool) {
        issues.add(
          ContentValidationIssue('$path.verified', 'must be a boolean'),
        );
      }
      final source = _parseSource(question['source'], '$path.source', issues);
      if (source?.reviewStatus == 'approved' &&
          source?.isReleaseApproved != true) {
        issues.add(
          ContentValidationIssue(
            '$path.source',
            'approved source must include valid HTTPS metadata and contentHash',
          ),
        );
      }

      final card = relatedCardId == null ? null : cards[relatedCardId];
      if (relatedCardId != null && card == null) {
        issues.add(
          ContentValidationIssue(
            '$path.relatedCardId',
            'references missing card "$relatedCardId"',
          ),
        );
      } else if (relatedCardId != null && !seenCardIds.add(relatedCardId)) {
        issues.add(
          ContentValidationIssue(
            '$path.relatedCardId',
            'card "$relatedCardId" is paired with more than one question',
          ),
        );
      }
      if (card != null && category != null && card.category != category) {
        issues.add(
          ContentValidationIssue(
            '$path.category',
            'must match related card category "${card.category}"',
          ),
        );
      }

      if (verified == true) {
        playable++;
        if (source?.isReleaseApproved != true) {
          issues.add(
            ContentValidationIssue(
              '$path.source',
              'verified question must have release-approved source metadata',
            ),
          );
        }
        if (card?.source?.isReleaseApproved != true) {
          issues.add(
            ContentValidationIssue(
              '$path.relatedCardId',
              'verified question requires a release-approved related card',
            ),
          );
        }
        if (card?.imageReview?.isReleaseReady != true) {
          issues.add(
            ContentValidationIssue(
              'cards[$relatedCardId].imageReview',
              'playable card image must be approved or generic_placeholder',
            ),
          );
        }
        if (source != null && card?.source != null) {
          if (source.url != card!.source!.url) {
            issues.add(
              ContentValidationIssue(
                '$path.source.url',
                'must match related card source URL',
              ),
            );
          }
          if (source.contentHash != card.source!.contentHash) {
            issues.add(
              ContentValidationIssue(
                '$path.source.contentHash',
                'must match related card contentHash',
              ),
            );
          }
          final expected = ContentFingerprint.forPair(
            question: question,
            card: card.json,
          );
          if (source.contentHash != expected) {
            issues.add(
              ContentValidationIssue(
                '$path.source.contentHash',
                'does not match the current reviewed question/card content',
              ),
            );
          }
        }
      }
    }
    return playable;
  }

  List<String> _validateChoices(
    Object? value,
    String path,
    List<ContentValidationIssue> issues,
  ) {
    if (value is! List) {
      issues.add(ContentValidationIssue('$path.choices', 'must be an array'));
      return const <String>[];
    }
    if (value.length != 4) {
      issues.add(
        ContentValidationIssue(
          '$path.choices',
          'must contain exactly 4 choices, got ${value.length}',
        ),
      );
    }
    final result = <String>[];
    final normalized = <String>{};
    for (var index = 0; index < value.length; index++) {
      final choice = value[index];
      if (choice is! String || choice.trim().isEmpty) {
        issues.add(
          ContentValidationIssue(
            '$path.choices[$index]',
            'must be a non-empty string',
          ),
        );
        continue;
      }
      final trimmed = choice.trim();
      if (!normalized.add(trimmed)) {
        issues.add(
          ContentValidationIssue(
            '$path.choices[$index]',
            'must not duplicate another choice',
          ),
        );
      }
      result.add(trimmed);
    }
    return result;
  }

  SourceMetadata? _parseSource(
    Object? value,
    String path,
    List<ContentValidationIssue> issues,
  ) {
    if (value == null) return null;
    if (value is! Map) {
      issues.add(ContentValidationIssue(path, 'must be an object'));
      return null;
    }
    try {
      return SourceMetadata.fromOptionalJson(value);
    } on FormatException catch (error) {
      issues.add(ContentValidationIssue(path, error.message));
      return null;
    }
  }

  ImageReviewMetadata? _parseImageReview(
    Object? value,
    String path,
    List<ContentValidationIssue> issues,
  ) {
    if (value == null) {
      issues.add(ContentValidationIssue(path, 'must be persisted'));
      return null;
    }
    if (value is! Map) {
      issues.add(ContentValidationIssue(path, 'must be an object'));
      return null;
    }
    try {
      return ImageReviewMetadata.fromJson(Map<String, dynamic>.from(value));
    } on FormatException catch (error) {
      issues.add(ContentValidationIssue(path, error.message));
      return null;
    }
  }

  void _validateManifest(
    Map<String, dynamic> manifest,
    int questionCount,
    int cardCount,
    int playableCount,
    List<ContentValidationIssue> issues,
  ) {
    final schemaVersion = manifest['schemaVersion'];
    if (schemaVersion != 1) {
      issues.add(
        const ContentValidationIssue('manifest.schemaVersion', 'must be 1'),
      );
    }
    _expectCount(manifest, 'questionCount', questionCount, issues);
    _expectCount(manifest, 'cardCount', cardCount, issues);
    _expectCount(manifest, 'playableQuestionCount', playableCount, issues);
  }

  void _expectCount(
    Map<String, dynamic> manifest,
    String field,
    int actual,
    List<ContentValidationIssue> issues,
  ) {
    final expected = manifest[field];
    if (expected is! int) {
      issues.add(
        ContentValidationIssue('manifest.$field', 'must be an integer'),
      );
    } else if (expected != actual) {
      issues.add(
        ContentValidationIssue(
          'manifest.$field',
          'expected $expected but found $actual',
        ),
      );
    }
  }

  String? _requiredString(
    Map<String, dynamic> item,
    String field,
    String path,
    List<ContentValidationIssue> issues,
    int maxLength,
  ) {
    final value = item[field];
    if (value is! String || value.trim().isEmpty) {
      issues.add(ContentValidationIssue('$path.$field', 'must be a string'));
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.length > maxLength) {
      issues.add(
        ContentValidationIssue(
          '$path.$field',
          'must be at most $maxLength characters',
        ),
      );
    }
    return trimmed;
  }
}

class _CardRecord {
  final Map<String, dynamic> json;
  final String? category;
  final SourceMetadata? source;
  final ImageReviewMetadata? imageReview;

  const _CardRecord({
    required this.json,
    required this.category,
    required this.source,
    required this.imageReview,
  });
}
