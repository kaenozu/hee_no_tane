/// Runtime release eligibility checks for question/card pairs.
library;

import 'package:hee_no_tane_app/content_validation/content_fingerprint.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';

class ContentReleasePolicy {
  const ContentReleasePolicy._();

  static bool isPlayablePair(Question question, HeeCard card) {
    if (!question.verified || question.relatedCardId != card.id) return false;
    if (question.category != card.category) return false;
    if (!question.isSourceReleaseApproved || !card.isSourceReleaseApproved) {
      return false;
    }
    if (!card.imageReview.isReleaseReady) return false;

    final questionSource = question.sourceMetadata;
    final cardSource = card.sourceMetadata;
    if (questionSource == null || cardSource == null) return false;
    if (questionSource.url != cardSource.url ||
        questionSource.contentHash != cardSource.contentHash) {
      return false;
    }

    final currentHash = ContentFingerprint.forPair(
      question: question.toJson(),
      card: card.toJson(),
    );
    return currentHash == questionSource.contentHash;
  }
}
