import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/daily_question_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';

void main() {
  late RewardService rewardService;

  setUp(() {
    rewardService = RewardService();
  });

  group('DailyQuestionService', () {
    test('generates 3 questions from date seed', () {
      final service = DailyQuestionService();

      final questions = List.generate(
        10,
        (i) => Question(
          id: 'q_$i',
          category: 'test',
          difficulty: 'easy',
          question: 'q$i',
          choices: ['A', 'B', 'C', 'D'],
          answerIndex: 0,
          explanation: 'e',
          relatedCardId: 'c',
          sourceNote: 's',
          verified: true,
        ),
      );

      final result = service.generateQuestions('2026-07-08', questions);
      expect(result.length, 3);
    });

    test('returns verified questions only', () {
      final service = DailyQuestionService();

      final questions = [
        Question(
          id: 'q1',
          category: 't',
          difficulty: 'e',
          question: 'q',
          choices: ['A', 'B', 'C', 'D'],
          answerIndex: 0,
          explanation: 'e',
          relatedCardId: 'c',
          sourceNote: 's',
          verified: false,
        ),
        Question(
          id: 'q2',
          category: 't',
          difficulty: 'e',
          question: 'q',
          choices: ['A', 'B', 'C', 'D'],
          answerIndex: 0,
          explanation: 'e',
          relatedCardId: 'c',
          sourceNote: 's',
          verified: true,
        ),
        Question(
          id: 'q3',
          category: 't',
          difficulty: 'e',
          question: 'q',
          choices: ['A', 'B', 'C', 'D'],
          answerIndex: 0,
          explanation: 'e',
          relatedCardId: 'c',
          sourceNote: 's',
          verified: true,
        ),
      ];

      final result = service.generateQuestions('2026-07-08', questions);
      expect(result.length, 2);
      expect(result.every((q) => q.verified), true);
    });

    test('uses a stable date seed for the daily question order', () {
      final service = DailyQuestionService();

      final questions = List.generate(
        8,
        (i) => Question(
          id: 'q_$i',
          category: 'test',
          difficulty: 'easy',
          question: 'q$i',
          choices: ['A', 'B', 'C', 'D'],
          answerIndex: 0,
          explanation: 'e',
          relatedCardId: 'c',
          sourceNote: 's',
          verified: true,
        ),
      );

      final first = service
          .generateQuestions('2026-07-08', questions)
          .map((q) => q.id)
          .toList();
      final second = service
          .generateQuestions('2026-07-08', questions)
          .map((q) => q.id)
          .toList();
      expect(second, first);
    });

    test('does not repeat questions on consecutive days', () {
      final service = DailyQuestionService();
      final questions = List.generate(
        103,
        (i) => Question(
          id: 'q_$i',
          category: 'test',
          difficulty: 'easy',
          question: 'q$i',
          choices: const ['A', 'B', 'C', 'D'],
          answerIndex: 0,
          explanation: 'e',
          relatedCardId: 'c_$i',
          sourceNote: 's',
          verified: true,
        ),
      );

      final firstDay = service
          .generateQuestions('2026-01-04', questions)
          .map((q) => q.id)
          .toSet();
      final nextDay = service
          .generateQuestions('2026-01-05', questions)
          .map((q) => q.id)
          .toSet();

      expect(firstDay.intersection(nextDay), isEmpty);
    });

    test('uses a different question set for each play attempt', () {
      final service = DailyQuestionService();
      final questions = List.generate(
        50,
        (i) => Question(
          id: 'q_$i',
          category: 'test',
          difficulty: 'easy',
          question: 'q$i',
          choices: const ['A', 'B', 'C', 'D'],
          answerIndex: 0,
          explanation: 'e',
          relatedCardId: 'c_$i',
          sourceNote: 's',
          verified: true,
        ),
      );

      final firstPlay = service
          .generateQuestions('2026-07-10', questions, rotation: 0, count: 3)
          .map((q) => q.id)
          .toSet();
      final secondPlay = service
          .generateQuestions('2026-07-10', questions, rotation: 1, count: 3)
          .map((q) => q.id)
          .toSet();

      expect(firstPlay, hasLength(3));
      expect(secondPlay, hasLength(3));
      expect(firstPlay.intersection(secondPlay), isEmpty);
    });
  });

  group('RewardService', () {
    test('returns unowned card from today questions', () {
      final qs = [
        Question(
          id: 'q1',
          category: 't',
          difficulty: 'e',
          question: 'q',
          choices: ['A', 'B', 'C', 'D'],
          answerIndex: 0,
          explanation: 'e',
          relatedCardId: 'card_a',
          sourceNote: 's',
          verified: true,
        ),
        Question(
          id: 'q2',
          category: 't',
          difficulty: 'e',
          question: 'q',
          choices: ['A', 'B', 'C', 'D'],
          answerIndex: 0,
          explanation: 'e',
          relatedCardId: 'card_b',
          sourceNote: 's',
          verified: true,
        ),
      ];
      final cards = [
        HeeCard(
          id: 'card_a',
          title: 'A',
          category: 't',
          shortText: 's',
          detailText: 'd',
          imageAsset: '',
          rarity: 'normal',
          sourceNote: 's',
        ),
        HeeCard(
          id: 'card_b',
          title: 'B',
          category: 't',
          shortText: 's',
          detailText: 'd',
          imageAsset: '',
          rarity: 'normal',
          sourceNote: 's',
        ),
      ];
      final owned = ['card_a'];

      final result = rewardService.determineReward(
        todayQuestions: qs,
        ownedCardIds: owned,
        allCards: cards,
        today: '2024-01-01',
        lastRewardDate: '',
      );
      expect(result, isNotNull);
      expect(result!.id, 'card_b');
    });

    test('returns null when reward already given today', () {
      final qs = [
        Question(
          id: 'q1',
          category: 't',
          difficulty: 'e',
          question: 'q',
          choices: ['A', 'B', 'C', 'D'],
          answerIndex: 0,
          explanation: 'e',
          relatedCardId: 'card_a',
          sourceNote: 's',
          verified: true,
        ),
      ];
      final cards = [
        HeeCard(
          id: 'card_a',
          title: 'A',
          category: 't',
          shortText: 's',
          detailText: 'd',
          imageAsset: '',
          rarity: 'normal',
          sourceNote: 's',
        ),
      ];
      final owned = <String>[];

      final result = rewardService.determineReward(
        todayQuestions: qs,
        ownedCardIds: owned,
        allCards: cards,
        today: '2024-01-01',
        lastRewardDate: '2024-01-01',
      );
      expect(result, isNull);
    });

    test('returns null when all cards owned', () {
      final qs = [
        Question(
          id: 'q1',
          category: 't',
          difficulty: 'e',
          question: 'q',
          choices: ['A', 'B', 'C', 'D'],
          answerIndex: 0,
          explanation: 'e',
          relatedCardId: 'card_a',
          sourceNote: 's',
          verified: true,
        ),
      ];
      final cards = [
        HeeCard(
          id: 'card_a',
          title: 'A',
          category: 't',
          shortText: 's',
          detailText: 'd',
          imageAsset: '',
          rarity: 'normal',
          sourceNote: 's',
        ),
      ];
      final owned = ['card_a'];

      final result = rewardService.determineReward(
        todayQuestions: qs,
        ownedCardIds: owned,
        allCards: cards,
        today: '2024-01-01',
        lastRewardDate: '',
      );
      expect(result, isNull);
    });

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

    test('updatePlayStats increments browse count and manages streak', () {
      final data = SaveData(totalBrowseCount: 0, streakDays: 0);
      final result = rewardService.updatePlayStats(data, '2026-07-10');
      expect(result.totalBrowseCount, 1);
      expect(result.streakDays, 1);
      expect(result.lastPlayedDate, '2026-07-10');
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
