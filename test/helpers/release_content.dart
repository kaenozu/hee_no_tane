import 'package:hee_no_tane_app/content_validation/content_fingerprint.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/image_review_metadata.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/source_metadata.dart';

class TestContentPair {
  final Question question;
  final HeeCard card;

  const TestContentPair({required this.question, required this.card});
}

TestContentPair releaseContentPair({
  required String id,
  String category = 'science',
  String difficulty = 'easy',
  String? questionText,
  List<String> choices = const <String>['A', 'B', 'C', 'D'],
  int answerIndex = 0,
  String? explanation,
  String? title,
  String? shortText,
  String? detailText,
  String imageAsset = '',
  String rarity = 'normal',
  String? sourceUrl,
}) {
  final questionId = 'q_$id';
  final cardId = 'card_$id';
  final note = 'テスト出典$id';
  final draftQuestion = Question(
    id: questionId,
    category: category,
    difficulty: difficulty,
    question: questionText ?? 'テスト問題$id',
    choices: choices,
    answerIndex: answerIndex,
    explanation: explanation ?? '解説$id',
    relatedCardId: cardId,
    sourceNote: note,
    verified: true,
  );
  const imageReview = ImageReviewMetadata(
    status: 'generic_placeholder',
    reviewedAt: '2026-07-14',
    note: 'テスト用プレースホルダー',
  );
  final draftCard = HeeCard(
    id: cardId,
    title: title ?? 'テストカード$id',
    category: category,
    shortText: shortText ?? '短いテキスト$id',
    detailText: detailText ?? '詳細テキスト$id',
    imageAsset: imageAsset,
    rarity: rarity,
    sourceNote: note,
    imageReview: imageReview,
  );
  final hash = ContentFingerprint.forPair(
    question: draftQuestion.toJson(),
    card: draftCard.toJson(),
  );
  final source = SourceMetadata(
    title: 'テスト資料$id',
    publisher: 'テスト発行元',
    url: sourceUrl ?? 'https://example.com/source/$id',
    verifiedAt: '2026-07-14',
    verificationLevel: 'primary',
    reviewStatus: 'approved',
    contentHash: hash,
  );
  return TestContentPair(
    question: Question(
      id: draftQuestion.id,
      category: draftQuestion.category,
      difficulty: draftQuestion.difficulty,
      question: draftQuestion.question,
      choices: draftQuestion.choices,
      answerIndex: draftQuestion.answerIndex,
      explanation: draftQuestion.explanation,
      relatedCardId: draftQuestion.relatedCardId,
      sourceNote: note,
      verified: true,
      sourceMetadata: source,
    ),
    card: HeeCard(
      id: draftCard.id,
      title: draftCard.title,
      category: draftCard.category,
      shortText: draftCard.shortText,
      detailText: draftCard.detailText,
      imageAsset: draftCard.imageAsset,
      rarity: draftCard.rarity,
      sourceNote: note,
      sourceMetadata: source,
      imageReview: imageReview,
    ),
  );
}
