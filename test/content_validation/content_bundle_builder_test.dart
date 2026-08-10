import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/content_validation/content_bundle_builder.dart';
import 'package:hee_no_tane_app/content_validation/content_fingerprint.dart';
import 'package:hee_no_tane_app/domain/models/content_bundle.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';

void main() {
  test('build includes only release-approved pairs in stable id order', () {
    final approvedB = _approvedPair('q_b', 'c_b');
    final approvedA = _approvedPair('q_a', 'c_a');
    final blocked = _approvedPair('q_blocked', 'c_blocked');
    final blockedQuestion = Question(
      id: blocked.question.id,
      category: blocked.question.category,
      difficulty: blocked.question.difficulty,
      question: blocked.question.question,
      choices: blocked.question.choices,
      answerIndex: blocked.question.answerIndex,
      explanation: blocked.question.explanation,
      relatedCardId: blocked.question.relatedCardId,
      sourceNote: blocked.question.legacySourceNote,
      verified: false,
      sourceMetadata: blocked.question.sourceMetadata,
    );

    final bundle = ContentBundleBuilder.build(
      questions: <Question>[
        approvedB.question,
        blockedQuestion,
        approvedA.question,
      ],
      cards: <HeeCard>[approvedB.card, blocked.card, approvedA.card],
      contentVersion: '1.0.0+1',
    );

    expect(bundle.entries.map((entry) => entry.question.id), <String>[
      'q_a',
      'q_b',
    ]);
    expect(bundle.bundleHash, hasLength(64));
    expect(
      ContentBundle.fromJson(bundle.toJson()).bundleHash,
      bundle.bundleHash,
    );
  });

  test('pending image review stays bundled for review-stage runtime', () {
    final pair = _approvedPair('q_pending', 'c_pending');
    final pendingCardJson = pair.card.toJson();
    pendingCardJson['imageReview'] = <String, dynamic>{
      'status': 'pending',
      'reviewedAt': '2026-08-10',
      'note': 'visual review pending',
    };
    final pendingCard = HeeCard.fromJson(pendingCardJson);

    expect(pendingCard.isSourceReleaseApproved, isTrue);
    expect(pendingCard.imageReview.isReleaseReady, isTrue);
    expect(pendingCard.imageReview.isFinalImageApproved, isFalse);

    final bundle = ContentBundleBuilder.build(
      questions: <Question>[pair.question],
      cards: <HeeCard>[pendingCard],
      contentVersion: '1.0.0+1',
    );

    expect(bundle.entries, hasLength(1));
    expect(bundle.entries.single.card.imageReview.status, 'pending');
  });

  test('bundle parser rejects payload changes without a new hash', () {
    final pair = _approvedPair('q_a', 'c_a');
    final bundle = ContentBundleBuilder.build(
      questions: <Question>[pair.question],
      cards: <HeeCard>[pair.card],
      contentVersion: '1.0.0+1',
    );
    final json = bundle.toJson();
    final entries = json['entries'] as List<dynamic>;
    final entry = entries.single as Map<String, dynamic>;
    final question = entry['question'] as Map<String, dynamic>;
    question['question'] = '改ざんされた質問';

    expect(() => ContentBundle.fromJson(json), throwsA(isA<FormatException>()));
  });
}

({Question question, HeeCard card}) _approvedPair(
  String questionId,
  String cardId,
) {
  final questionJson = <String, dynamic>{
    'id': questionId,
    'category': 'science',
    'difficulty': 'easy',
    'question': 'テスト質問 $questionId',
    'choices': <String>['A', 'B', 'C', 'D'],
    'answerIndex': 0,
    'explanation': 'テスト解説',
    'relatedCardId': cardId,
    'sourceNote': 'テスト出典',
    'verified': true,
  };
  final cardJson = <String, dynamic>{
    'id': cardId,
    'title': 'テストカード $cardId',
    'category': 'science',
    'shortText': '短文',
    'detailText': '詳細文',
    'imageAsset': 'assets/images/cards/$cardId.webp',
    'rarity': 'common',
    'sourceNote': 'テスト出典',
    'imageReview': <String, dynamic>{
      'status': 'approved',
      'reviewedAt': '2026-07-16',
    },
  };
  final hash = ContentFingerprint.forPair(
    question: questionJson,
    card: cardJson,
  );
  final source = <String, dynamic>{
    'title': 'テスト資料',
    'publisher': 'テスト出版社',
    'url': 'https://example.com/source/$questionId',
    'verifiedAt': '2026-07-16',
    'verificationLevel': 'primary',
    'reviewStatus': 'approved',
    'contentHash': hash,
  };
  questionJson['source'] = source;
  cardJson['source'] = Map<String, dynamic>.from(source);

  return (
    question: Question.fromJson(questionJson),
    card: HeeCard.fromJson(cardJson),
  );
}
