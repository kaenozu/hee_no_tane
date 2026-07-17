/// Fail-closed validation for manually reviewed release content semantics.
library;

import 'package:hee_no_tane_app/content_validation/content_fingerprint.dart';
import 'package:hee_no_tane_app/domain/models/content_bundle.dart';

class SemanticReviewGate {
  const SemanticReviewGate._();

  static const int currentSchemaVersion = 1;
  static const List<String> requiredChecks = <String>[
    'questionChoicesAligned',
    'answerIndexCorrect',
    'explanationAligned',
    'cardAligned',
    'sourceAligned',
  ];

  static void validateOrThrow({
    required ContentBundle bundle,
    required Map<String, dynamic> reviewDocument,
  }) {
    final errors = validate(bundle: bundle, reviewDocument: reviewDocument);
    if (errors.isNotEmpty) {
      throw FormatException(
        'Semantic review validation failed:\n- ${errors.join('\n- ')}',
      );
    }
  }

  static List<String> validate({
    required ContentBundle bundle,
    required Map<String, dynamic> reviewDocument,
  }) {
    final errors = <String>[];

    if (reviewDocument['schemaVersion'] != currentSchemaVersion) {
      errors.add(
        'schemaVersion must be $currentSchemaVersion, got '
        '${reviewDocument['schemaVersion']}.',
      );
    }
    if (reviewDocument['contentVersion'] != bundle.contentVersion) {
      errors.add(
        'contentVersion does not match the generated bundle '
        '(${reviewDocument['contentVersion']} != ${bundle.contentVersion}).',
      );
    }
    if (reviewDocument['bundleHash'] != bundle.bundleHash) {
      errors.add('bundleHash does not match the generated bundle.');
    }
    if (reviewDocument['entryCount'] != bundle.entries.length) {
      errors.add(
        'entryCount does not match the generated bundle '
        '(${reviewDocument['entryCount']} != ${bundle.entries.length}).',
      );
    }

    final entriesValue = reviewDocument['entries'];
    if (entriesValue is! List) {
      errors.add('entries must be an array.');
      return errors;
    }

    final reviewsByQuestionId = <String, Map<String, dynamic>>{};
    for (final value in entriesValue) {
      if (value is! Map) {
        errors.add('Every semantic review entry must be an object.');
        continue;
      }
      final review = Map<String, dynamic>.from(value);
      final questionId = review['questionId'];
      if (questionId is! String || questionId.trim().isEmpty) {
        errors.add('A semantic review entry has an invalid questionId.');
        continue;
      }
      if (reviewsByQuestionId.containsKey(questionId)) {
        errors.add('Duplicate semantic review entry: $questionId.');
        continue;
      }
      reviewsByQuestionId[questionId] = review;
    }

    final releaseQuestionIds = <String>{};
    for (final pair in bundle.entries) {
      final question = pair.question;
      final card = pair.card;
      releaseQuestionIds.add(question.id);
      final review = reviewsByQuestionId[question.id];
      if (review == null) {
        errors.add('Missing semantic review for ${question.id}.');
        continue;
      }

      if (review['cardId'] != card.id) {
        errors.add(
          '${question.id}: reviewed cardId does not match ${card.id}.',
        );
      }
      if (review['status'] != 'approved') {
        errors.add('${question.id}: semantic review status is not approved.');
      }

      final reviewedAt = review['reviewedAt'];
      if (reviewedAt is! String ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(reviewedAt) ||
          DateTime.tryParse(reviewedAt) == null) {
        errors.add('${question.id}: reviewedAt must be an ISO calendar date.');
      }

      final currentHash = ContentFingerprint.forPair(
        question: question.toJson(),
        card: card.toJson(),
      );
      if (review['contentHash'] != currentHash) {
        errors.add('${question.id}: semantic review contentHash is stale.');
      }

      final checksValue = review['checks'];
      if (checksValue is! Map) {
        errors.add('${question.id}: checks must be an object.');
      } else {
        final checks = Map<String, dynamic>.from(checksValue);
        for (final check in requiredChecks) {
          if (checks[check] != true) {
            errors.add('${question.id}: required check $check is not true.');
          }
        }
      }
    }

    for (final questionId in reviewsByQuestionId.keys) {
      if (!releaseQuestionIds.contains(questionId)) {
        errors.add(
          'Stale semantic review for non-release question $questionId.',
        );
      }
    }

    if (entriesValue.length != bundle.entries.length) {
      errors.add(
        'Semantic review entry total does not match release entry total '
        '(${entriesValue.length} != ${bundle.entries.length}).',
      );
    }

    return errors;
  }
}
