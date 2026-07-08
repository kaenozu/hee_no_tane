import 'dart:ui';

import 'package:hee_no_tane_app/app.dart';
import 'package:hee_no_tane_app/domain/models/enemy.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/battle_service.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      HeeNoTaneApp(
        allQuestions: const [],
        allCards: const [],
        allEnemies: const [],
        saveData: SaveData(),
        saveRepository: SaveRepository(),
        battleService: BattleService(),
        rewardService: RewardService(),
      ),
    );
    for (var i = 0; i < 20 && find.text('へぇダンジョン').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('へぇダンジョン'), findsOneWidget);
  });

  testWidgets('App home fits a narrow mobile viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      HeeNoTaneApp(
        allQuestions: const [],
        allCards: const [],
        allEnemies: const [],
        saveData: SaveData(),
        saveRepository: SaveRepository(),
        battleService: BattleService(),
        rewardService: RewardService(),
      ),
    );
    for (var i = 0; i < 20 && find.text('今日のダンジョン').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('今日のダンジョン'), findsOneWidget);
  });

  testWidgets(
    'Starting dungeon without enemy data shows an error instead of crashing',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final questions = List.generate(
        5,
        (index) => Question(
          id: 'q$index',
          category: 'test',
          difficulty: 'easy',
          question: '問題$index',
          choices: const ['正解', 'B', 'C', 'D'],
          answerIndex: 0,
          explanation: '解説$index',
          relatedCardId: 'card$index',
          sourceNote: 'test',
          verified: true,
        ),
      );

      await tester.pumpWidget(
        HeeNoTaneApp(
          allQuestions: questions,
          allCards: const [],
          allEnemies: const [],
          saveData: SaveData(),
          saveRepository: SaveRepository(),
          battleService: BattleService(),
          rewardService: RewardService(),
        ),
      );
      await _pumpUntilFound(tester, find.text('今日のダンジョン'));

      await tester.tap(find.text('今日のダンジョン'));
      await tester.pump();

      expect(find.text('敵データが不足しています'), findsOneWidget);
    },
  );

  testWidgets(
    'User can clear a full dungeon and return home with reward saved',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final repository = SaveRepository();
      final questions = List.generate(
        5,
        (index) => Question(
          id: 'q$index',
          category: 'test',
          difficulty: 'easy',
          question: '通し問題$index',
          choices: const ['正解', 'B', 'C', 'D'],
          answerIndex: 0,
          explanation: '通し解説$index',
          relatedCardId: 'card$index',
          sourceNote: 'test',
          verified: true,
        ),
      );
      final cards = List.generate(
        5,
        (index) => HeeCard(
          id: 'card$index',
          title: '報酬カード$index',
          category: '雑学',
          shortText: '報酬説明$index',
          detailText: 'detail',
          imageAsset: '',
          rarity: 'normal',
          sourceNote: 'test',
        ),
      );
      final enemies = [
        const Enemy(
          id: 'n1',
          name: '敵1',
          type: 'normal',
          maxHp: 12,
          attack: 1,
          imageAsset: '',
        ),
        const Enemy(
          id: 'n2',
          name: '敵2',
          type: 'normal',
          maxHp: 12,
          attack: 1,
          imageAsset: '',
        ),
        const Enemy(
          id: 'n3',
          name: '敵3',
          type: 'normal',
          maxHp: 12,
          attack: 1,
          imageAsset: '',
        ),
        const Enemy(
          id: 'n4',
          name: '敵4',
          type: 'normal',
          maxHp: 12,
          attack: 1,
          imageAsset: '',
        ),
        const Enemy(
          id: 'boss',
          name: 'ボス',
          type: 'boss',
          maxHp: 12,
          attack: 1,
          imageAsset: '',
        ),
      ];

      await tester.pumpWidget(
        HeeNoTaneApp(
          allQuestions: questions,
          allCards: cards,
          allEnemies: enemies,
          saveData: SaveData(),
          saveRepository: repository,
          battleService: BattleService(),
          rewardService: RewardService(),
        ),
      );
      await _pumpUntilFound(tester, find.text('今日のダンジョン'));

      await tester.tap(find.text('今日のダンジョン'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('ダンジョンに入る'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      for (var floor = 1; floor <= 5; floor++) {
        await tester.tap(find.text('正解'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 950));
        expect(find.text('へぇ解説'), findsOneWidget);
        await tester.tap(find.text(floor == 5 ? '報酬を見る' : '次の階へ'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('ダンジョンクリア！'), findsWidgets);
      expect(find.text('へぇカードをゲット！'), findsOneWidget);

      final savedAfterClear = await repository.load();
      expect(savedAfterClear.totalPlayCount, 1);
      expect(savedAfterClear.totalClearCount, 1);
      expect(savedAfterClear.ownedCardIds.length, 1);
      expect(savedAfterClear.lastRewardDate, isNotEmpty);

      await tester.tap(find.text('ホームに戻る'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('へぇダンジョン'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
    },
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int attempts = 20,
}) async {
  for (var i = 0; i < attempts && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}
