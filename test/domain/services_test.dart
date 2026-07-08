import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/battle_state.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/enemy.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/battle_service.dart';
import 'package:hee_no_tane_app/domain/services/daily_dungeon_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';

void main() {
  late BattleService battleService;
  late RewardService rewardService;

  setUp(() {
    battleService = BattleService();
    rewardService = RewardService();
  });

  group('BattleService', () {
    group('正解判定', () {
      test('correct answer returns true', () {
        final q = Question(
          id: 'q_test', category: 'test', difficulty: 'easy',
          question: 'q', choices: ['A', 'B', 'C', 'D'], answerIndex: 2,
          explanation: 'e', relatedCardId: 'c', sourceNote: 's', verified: true,
        );
        expect(battleService.isCorrect(q, 2), true);
        expect(battleService.isCorrect(q, 0), false);
      });
    });

    group('ダメージ計算', () {
      test('base damage at combo 0', () {
        expect(battleService.calculateDamage(0), 12);
      });

      test('combo bonus: +2 at combo 1', () {
        expect(battleService.calculateDamage(1), 14);
      });

      test('combo bonus: +4 at combo 2', () {
        expect(battleService.calculateDamage(2), 16);
      });

      test('combo bonus capped at +6 (combo 3+)', () {
        expect(battleService.calculateDamage(3), 18);
        expect(battleService.calculateDamage(10), 18);
      });
    });

    group('被ダメージ計算', () {
      test('floor 1 damage', () {
        expect(battleService.calculateEnemyDamage(1), 8);
      });

      test('floor 3 damage', () {
        expect(battleService.calculateEnemyDamage(3), 10);
      });

      test('floor 5 damage', () {
        expect(battleService.calculateEnemyDamage(5), 12);
      });
    });

    group('answer()', () {
      BattleState makeState({int playerHp = 60, int enemyHp = 24, int combo = 0, int floor = 1}) {
        return BattleState(
          playerHp: playerHp,
          playerMaxHp: 60,
          enemyHp: enemyHp,
          enemyMaxHp: 24,
          combo: combo,
          floor: floor,
          currentQuestionIndex: 0,
          questions: [
            Question(
              id: 'q_test', category: 'test', difficulty: 'easy',
              question: 'q', choices: ['A', 'B', 'C', 'D'], answerIndex: 0,
              explanation: 'e', relatedCardId: 'c', sourceNote: 's', verified: true,
            ),
          ],
          enemy: Enemy(id: 'e', name: 'e', type: 'normal', maxHp: 24, attack: 8, imageAsset: ''),
        );
      }

      test('correct answer deals damage to enemy', () {
        final state = makeState();
        final result = battleService.answer(state: state, selectedIndex: 0);
        expect(result.isCorrect, true);
        expect(result.damageDealt, 12);
        expect(result.enemyHpAfter, 12);
        expect(result.playerHpAfter, 60);
      });

      test('wrong answer damages player', () {
        final state = makeState();
        final result = battleService.answer(state: state, selectedIndex: 1);
        expect(result.isCorrect, false);
        expect(result.damageTaken, 8);
        expect(result.playerHpAfter, 52);
        expect(result.enemyHpAfter, 24);
      });

      test('combo resets on wrong answer', () {
        final state = makeState(combo: 3);
        final result = battleService.answer(state: state, selectedIndex: 1);
        expect(result.comboAfter, 0);
      });

      test('combo increments on correct answer', () {
        final state = makeState(combo: 2);
        final result = battleService.answer(state: state, selectedIndex: 0);
        expect(result.comboAfter, 3);
      });

      test('enemy HP 0 clears floor', () {
        final state = makeState(enemyHp: 5);
        final result = battleService.answer(state: state, selectedIndex: 0);
        expect(result.isFloorCleared, true);
      });

      test('player HP 0 is game over', () {
        final state = makeState(playerHp: 5, floor: 1);
        final result = battleService.answer(state: state, selectedIndex: 1);
        expect(result.isGameOver, true);
      });

      test('floor 5 boss kill is clear', () {
        final state = BattleState(
          playerHp: 60, playerMaxHp: 60,
          enemyHp: 5, enemyMaxHp: 48, combo: 0, floor: 5,
          currentQuestionIndex: 0,
          questions: [
            Question(id: 'q1', category: 't', difficulty: 'e', question: 'q',
                choices: ['A', 'B', 'C', 'D'], answerIndex: 0,
                explanation: 'e', relatedCardId: 'c', sourceNote: 's', verified: true),
          ],
          enemy: Enemy(id: 'boss', name: 'boss', type: 'boss', maxHp: 48, attack: 10, imageAsset: ''),
        );
        final result = battleService.answer(state: state, selectedIndex: 0);
        expect(result.isFloorCleared, true);
        expect(result.isClear, true);
      });

      test('non-boss floor clear is not final clear', () {
        final state = makeState(enemyHp: 5, floor: 1);
        final result = battleService.answer(state: state, selectedIndex: 0);
        expect(result.isFloorCleared, true);
        expect(result.isClear, false);
      });
    });
  });

  group('DailyDungeonService', () {
    test('generates 5 questions from date seed', () {
      final enemies = [
        Enemy(id: 'n1', name: 'n1', type: 'normal', maxHp: 20, attack: 8, imageAsset: ''),
      ];
      final boss = Enemy(id: 'boss', name: 'boss', type: 'boss', maxHp: 48, attack: 10, imageAsset: '');
      final service = DailyDungeonService(enemies, boss);

      final questions = List.generate(10, (i) => Question(
        id: 'q_$i', category: 'test', difficulty: 'easy',
        question: 'q$i', choices: ['A', 'B', 'C', 'D'], answerIndex: 0,
        explanation: 'e', relatedCardId: 'c', sourceNote: 's', verified: true,
      ));

      final result = service.generateQuestions('2026-07-08', questions);
      expect(result.length, 5);
    });

    test('returns verified questions only', () {
      final enemies = [
        Enemy(id: 'n1', name: 'n1', type: 'normal', maxHp: 20, attack: 8, imageAsset: ''),
      ];
      final boss = Enemy(id: 'boss', name: 'boss', type: 'boss', maxHp: 48, attack: 10, imageAsset: '');
      final service = DailyDungeonService(enemies, boss);

      final questions = [
        Question(id: 'q1', category: 't', difficulty: 'e', question: 'q', choices: ['A', 'B', 'C', 'D'], answerIndex: 0, explanation: 'e', relatedCardId: 'c', sourceNote: 's', verified: false),
        Question(id: 'q2', category: 't', difficulty: 'e', question: 'q', choices: ['A', 'B', 'C', 'D'], answerIndex: 0, explanation: 'e', relatedCardId: 'c', sourceNote: 's', verified: true),
        Question(id: 'q3', category: 't', difficulty: 'e', question: 'q', choices: ['A', 'B', 'C', 'D'], answerIndex: 0, explanation: 'e', relatedCardId: 'c', sourceNote: 's', verified: true),
      ];

      final result = service.generateQuestions('2026-07-08', questions);
      expect(result.length, 2);
      expect(result.every((q) => q.verified), true);
    });

    test('assigns correct enemies per floor', () {
      final enemies = [
        Enemy(id: 'e1', name: 'Slime', type: 'normal', maxHp: 20, attack: 8, imageAsset: ''),
        Enemy(id: 'e2', name: 'Golem', type: 'normal', maxHp: 28, attack: 8, imageAsset: ''),
      ];
      final boss = Enemy(id: 'boss', name: 'Boss', type: 'boss', maxHp: 48, attack: 10, imageAsset: '');
      final service = DailyDungeonService(enemies, boss);

      expect(service.getEnemyForFloor(1).id, 'e1');
      expect(service.getEnemyForFloor(5).id, 'boss');
    });
  });

  group('RewardService', () {
    test('returns unowned card from today questions', () {
      final qs = [
        Question(id: 'q1', category: 't', difficulty: 'e', question: 'q', choices: ['A', 'B', 'C', 'D'], answerIndex: 0, explanation: 'e', relatedCardId: 'card_a', sourceNote: 's', verified: true),
        Question(id: 'q2', category: 't', difficulty: 'e', question: 'q', choices: ['A', 'B', 'C', 'D'], answerIndex: 0, explanation: 'e', relatedCardId: 'card_b', sourceNote: 's', verified: true),
      ];
      final cards = [
        HeeCard(id: 'card_a', title: 'A', category: 't', shortText: 's', detailText: 'd', imageAsset: '', rarity: 'normal', sourceNote: 's'),
        HeeCard(id: 'card_b', title: 'B', category: 't', shortText: 's', detailText: 'd', imageAsset: '', rarity: 'normal', sourceNote: 's'),
      ];
      final owned = ['card_a'];

      final result = rewardService.determineReward(todayQuestions: qs, ownedCardIds: owned, allCards: cards, today: '2024-01-01', lastRewardDate: '');
      expect(result, isNotNull);
      expect(result!.id, 'card_b');
    });

    test('returns null when reward already given today', () {
      final qs = [
        Question(id: 'q1', category: 't', difficulty: 'e', question: 'q', choices: ['A', 'B', 'C', 'D'], answerIndex: 0, explanation: 'e', relatedCardId: 'card_a', sourceNote: 's', verified: true),
      ];
      final cards = [
        HeeCard(id: 'card_a', title: 'A', category: 't', shortText: 's', detailText: 'd', imageAsset: '', rarity: 'normal', sourceNote: 's'),
      ];
      final owned = <String>[];

      final result = rewardService.determineReward(todayQuestions: qs, ownedCardIds: owned, allCards: cards, today: '2024-01-01', lastRewardDate: '2024-01-01');
      expect(result, isNull);
    });

    test('returns null when all cards owned', () {
      final qs = [
        Question(id: 'q1', category: 't', difficulty: 'e', question: 'q', choices: ['A', 'B', 'C', 'D'], answerIndex: 0, explanation: 'e', relatedCardId: 'card_a', sourceNote: 's', verified: true),
      ];
      final cards = [
        HeeCard(id: 'card_a', title: 'A', category: 't', shortText: 's', detailText: 'd', imageAsset: '', rarity: 'normal', sourceNote: 's'),
      ];
      final owned = ['card_a'];

      final result = rewardService.determineReward(todayQuestions: qs, ownedCardIds: owned, allCards: cards, today: '2024-01-01', lastRewardDate: '');
      expect(result, isNull);
    });
  });

  group('SaveData', () {
    test('serialize and deserialize', () {
      final data = SaveData(
        totalPlayCount: 5,
        totalClearCount: 3,
        streakDays: 3,
        lastPlayedDate: '2026-07-08',
        lastRewardDate: '2026-07-08',
        ownedCardIds: ['card_a', 'card_b'],
        settings: const GameSettings(soundEnabled: false),
      );

      final json = data.toJson();
      final restored = SaveData.fromJson(json);

      expect(restored.totalPlayCount, 5);
      expect(restored.totalClearCount, 3);
      expect(restored.streakDays, 3);
      expect(restored.ownedCardIds, ['card_a', 'card_b']);
      expect(restored.settings.soundEnabled, false);
    });

    test('default values for fresh data', () {
      final data = SaveData();
      expect(data.totalPlayCount, 0);
      expect(data.ownedCardIds, isEmpty);
      expect(data.settings.soundEnabled, true);
    });
  });
}
