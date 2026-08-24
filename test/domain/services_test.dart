import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/daily_question_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';

import '../helpers/release_content.dart';

void main() {
  late RewardService rewardService;

  setUp(() {
    rewardService = RewardService();
  });

  group('DailyQuestionService', () {
    test('generates 3 release-approved questions from date seed', () {
      final pairs = List.generate(10, (i) => releaseContentPair(id: '$i'));
      final result = DailyQuestionService().generateQuestions(
        '2026-07-08',
        pairs.map((pair) => pair.question).toList(),
        allCards: pairs.map((pair) => pair.card).toList(),
      );
      expect(result, hasLength(3));
    });

    test('returns release-approved question/card pairs only', () {
      final approved = releaseContentPair(id: 'approved');
      final unapprovedQuestion = Question(
        id: 'q_unapproved',
        category: 'science',
        difficulty: 'easy',
        question: '未承認問題',
        choices: const ['A', 'B', 'C', 'D'],
        answerIndex: 0,
        explanation: '未承認解説',
        relatedCardId: 'card_unapproved',
        sourceNote: '未承認',
        verified: true,
      );
      final unapprovedCard = HeeCard(
        id: 'card_unapproved',
        title: '未承認カード',
        category: 'science',
        shortText: '短文',
        detailText: '本文',
        imageAsset: '',
        rarity: 'normal',
        sourceNote: '未承認',
      );

      final result = DailyQuestionService().generateQuestions(
        '2026-07-08',
        [approved.question, unapprovedQuestion],
        allCards: [approved.card, unapprovedCard],
      );
      expect(result.map((question) => question.id), [approved.question.id]);
    });

    test('uses a stable date seed for the daily question order', () {
      final pairs = List.generate(8, (i) => releaseContentPair(id: '$i'));
      final questions = pairs.map((pair) => pair.question).toList();
      final cards = pairs.map((pair) => pair.card).toList();
      final service = DailyQuestionService();
      final first = service
          .generateQuestions('2026-07-08', questions, allCards: cards)
          .map((question) => question.id)
          .toList();
      final second = service
          .generateQuestions('2026-07-08', questions, allCards: cards)
          .map((question) => question.id)
          .toList();
      expect(second, first);
    });

    test('does not repeat questions on consecutive days', () {
      final pairs = List.generate(103, (i) => releaseContentPair(id: '$i'));
      final questions = pairs.map((pair) => pair.question).toList();
      final cards = pairs.map((pair) => pair.card).toList();
      final service = DailyQuestionService();
      final firstDay = service
          .generateQuestions('2026-01-04', questions, allCards: cards)
          .map((question) => question.id)
          .toSet();
      final nextDay = service
          .generateQuestions('2026-01-05', questions, allCards: cards)
          .map((question) => question.id)
          .toSet();
      expect(firstDay.intersection(nextDay), isEmpty);
    });

    test('uses a different question set for each play attempt', () {
      final pairs = List.generate(50, (i) => releaseContentPair(id: '$i'));
      final questions = pairs.map((pair) => pair.question).toList();
      final cards = pairs.map((pair) => pair.card).toList();
      final service = DailyQuestionService();
      final firstPlay = service
          .generateQuestions(
            '2026-07-10',
            questions,
            allCards: cards,
            rotation: 0,
            count: 3,
          )
          .map((question) => question.id)
          .toSet();
      final secondPlay = service
          .generateQuestions(
            '2026-07-10',
            questions,
            allCards: cards,
            rotation: 1,
            count: 3,
          )
          .map((question) => question.id)
          .toSet();
      expect(firstPlay, hasLength(3));
      expect(secondPlay, hasLength(3));
      expect(firstPlay.intersection(secondPlay), isEmpty);
    });
  });

  group('RewardService', () {
    test('applyReward adds card to owned list', () {
      final card = HeeCard(
        id: 'card_x',
        title: 'X',
        category: 't',
        shortText: 's',
        detailText: 'd',
        imageAsset: '',
        rarity: 'normal',
        sourceNote: 's',
      );
      final data = SaveData();
      final result = rewardService.applyReward(data, card);
      expect(result.ownedCardIds, ['card_x']);
    });

    test('daily answers and card views update separate counters', () {
      final data = SaveData();
      final answered = rewardService.recordDailyAnswer(data, '2026-07-10');
      expect(answered.totalPlayCount, 1);
      expect(answered.totalBrowseCount, 0);
      expect(answered.streakDays, 1);
      expect(answered.lastPlayedDate, '2026-07-10');

      final viewed = rewardService.recordCardView(answered);
      expect(viewed.totalPlayCount, 1);
      expect(viewed.totalBrowseCount, 1);
      expect(viewed.streakDays, 1);
    });
  });

  group('SaveData', () {
    test('serialize and deserialize', () {
      final data = SaveData(
        totalBrowseCount: 10,
        totalPlayCount: 5,
        streakDays: 3,
        lastPlayedDate: '2026-07-08',
        lastRewardDate: '2026-07-08',
        ownedCardIds: ['card_a', 'card_b'],
        settings: const GameSettings(),
      );

      final json = data.toJson();
      final restored = SaveData.fromJson(json);

      expect(restored.totalBrowseCount, 10);
      expect(restored.totalPlayCount, 5);
      expect(restored.streakDays, 3);
      expect(restored.ownedCardIds, ['card_a', 'card_b']);
    });

    test('default values for fresh data', () {
      final data = SaveData();
      expect(data.totalBrowseCount, 0);
      expect(data.ownedCardIds, isEmpty);
    });

    test('migrates from legacy totalPlayCount', () {
      final restored = SaveData.fromJson({'totalPlayCount': 3});
      expect(restored.totalBrowseCount, 3);
    });
  });
}
