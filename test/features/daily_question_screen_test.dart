import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/features/home/home_screen.dart';
import 'package:hee_no_tane_app/features/question/daily_question_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late List<Question> questions;
  late List<HeeCard> cards;
  late RewardService rewardService;
  late SaveRepository saveRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    rewardService = RewardService();
    saveRepository = SaveRepository();
    questions = List.generate(
      10,
      (i) => Question(
        id: 'q_$i',
        category: 'science',
        difficulty: 'easy',
        question: 'テスト問題$i',
        choices: ['A', 'B', 'C', 'D'],
        answerIndex: 0,
        explanation: '解説$i',
        relatedCardId: 'card_$i',
        sourceNote: '出典$i',
        verified: true,
      ),
    );
    cards = List.generate(
      10,
      (i) => HeeCard(
        id: 'card_$i',
        title: 'テストカード$i',
        category: 'science',
        shortText: '短いテキスト$i',
        detailText: '詳細テキスト$i',
        imageAsset: '',
        rarity: 'normal',
        sourceNote: '出典$i',
      ),
    );
  });

  /// 回答操作後に非同期なカード獲得処理が完了するまで待機する。
  Future<void> answerAndWait(WidgetTester tester) async {
    await tester.tap(find.text('A'));
    // 非同期な _applyCardReward が完了するまで複数回 pump する
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  group('1. ホームの未回答状態で、問題文とカード内容が漏れない', () {
    testWidgets('home hides question text and card content when unanswered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            allQuestions: questions,
            allCards: cards,
            saveRepository: saveRepository,
            rewardService: rewardService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('テスト問題0'), findsNothing);
      expect(find.text('短いテキスト0'), findsNothing);
      expect(find.text('詳細テキスト0'), findsNothing);
      expect(find.text('今日の1問'), findsOneWidget);
      expect(find.text('今日の1問を始める'), findsOneWidget);
    });
  });

  group('2. 今日の1問を開始できる', () {
    testWidgets('tapping start button navigates to question screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            allQuestions: questions,
            allCards: cards,
            saveRepository: saveRepository,
            rewardService: rewardService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('今日の1問を始める'));
      await tester.pumpAndSettle();

      expect(find.byType(DailyQuestionScreen), findsOneWidget);
      expect(find.text('今日の1問'), findsOneWidget);
    });
  });

  group('3. 正解後に解説と出典が表示される', () {
    testWidgets('correct answer shows explanation and source', (tester) async {
      final saveData = SaveData();
      await tester.pumpWidget(
        MaterialApp(
          home: DailyQuestionScreen(
            question: questions[0],
            relatedCard: cards[0],
            allCards: cards,
            saveRepository: saveRepository,
            rewardService: rewardService,
            saveData: saveData,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await answerAndWait(tester);

      expect(find.text('解説'), findsOneWidget);
      expect(find.text('解説0'), findsOneWidget);
      expect(find.text('出典: 出典0'), findsOneWidget);
      expect(find.textContaining('✓ 正解'), findsOneWidget);
    });
  });

  group('4. 不正解後にも解説と出典が表示される', () {
    testWidgets('wrong answer still shows explanation and source', (tester) async {
      final saveData = SaveData();
      await tester.pumpWidget(
        MaterialApp(
          home: DailyQuestionScreen(
            question: questions[0],
            relatedCard: cards[0],
            allCards: cards,
            saveRepository: saveRepository,
            rewardService: rewardService,
            saveData: saveData,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 不正解（B）をタップ
      await tester.tap(find.text('B'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      expect(find.text('解説'), findsOneWidget);
      expect(find.text('解説0'), findsOneWidget);
      expect(find.text('出典: 出典0'), findsOneWidget);
      expect(find.textContaining('✗'), findsOneWidget);
    });
  });

  group('5. 回答後に関連カードが所有状態になる', () {
    testWidgets('answering question adds card to owned list', (tester) async {
      final saveData = SaveData();
      await tester.pumpWidget(
        MaterialApp(
          home: DailyQuestionScreen(
            question: questions[0],
            relatedCard: cards[0],
            allCards: cards,
            saveRepository: saveRepository,
            rewardService: rewardService,
            saveData: saveData,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await answerAndWait(tester);

      expect(find.text('新しい知識カードを発見'), findsOneWidget);
      expect(find.text('テストカード0'), findsOneWidget);

      final savedData = await saveRepository.load();
      expect(savedData.ownedCardIds, contains('card_0'));
    });
  });

  group('6. 既所有カードを回答しても重複追加されない', () {
    testWidgets('answering question for already owned card does not duplicate', (tester) async {
      final saveData = SaveData(ownedCardIds: ['card_0']);
      await tester.pumpWidget(
        MaterialApp(
          home: DailyQuestionScreen(
            question: questions[0],
            relatedCard: cards[0],
            allCards: cards,
            saveRepository: saveRepository,
            rewardService: rewardService,
            saveData: saveData,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await answerAndWait(tester);

      expect(find.text('このカードは発見済みです'), findsOneWidget);

      final savedData = await saveRepository.load();
      final cardCount = savedData.ownedCardIds.where((id) => id == 'card_0').length;
      expect(cardCount, 1);
    });
  });

  group('7. 同日の再表示で「今日の1問は完了しました」になる', () {
    testWidgets('home shows completed state when already answered today', (tester) async {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final saveData = SaveData(
        lastDailyQuestionDate: dateStr,
        ownedCardIds: ['card_0'],
      );
      await saveRepository.save(saveData);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            allQuestions: questions,
            allCards: cards,
            saveRepository: saveRepository,
            rewardService: rewardService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('今日の1問は完了しました'), findsOneWidget);
      expect(find.text('カードを読む'), findsOneWidget);
      expect(find.text('今日の1問を始める'), findsNothing);
    });
  });

  group('8. アプリ再起動後も回答済み状態が維持される', () {
    testWidgets('answered state persists after app restart', (tester) async {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await tester.pumpWidget(
        MaterialApp(
          home: DailyQuestionScreen(
            question: questions[0],
            relatedCard: cards[0],
            allCards: cards,
            saveRepository: saveRepository,
            rewardService: rewardService,
            saveData: SaveData(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await answerAndWait(tester);

      final savedData = await saveRepository.load();
      expect(savedData.lastDailyQuestionDate, dateStr);
      expect(savedData.ownedCardIds, contains('card_0'));

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            allQuestions: questions,
            allCards: cards,
            saveRepository: saveRepository,
            rewardService: rewardService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('今日の1問は完了しました'), findsOneWidget);
    });
  });

  group('9. 翌日には別の日付として回答可能になる', () {
    testWidgets('different date allows new answer', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final saveData = SaveData(
        lastDailyQuestionDate: yesterdayStr,
        ownedCardIds: ['card_0'],
      );
      await saveRepository.save(saveData);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            allQuestions: questions,
            allCards: cards,
            saveRepository: saveRepository,
            rewardService: rewardService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('今日の1問を始める'), findsOneWidget);
      expect(find.text('今日の1問は完了しました'), findsNothing);
    });
  });

  group('10. 未獲得カード詳細の恒久非表示テストが引き続き通る', () {
    testWidgets('unowned card detail hides all content permanently', (tester) async {
      final unownedCard = HeeCard(
        id: 'card_unowned',
        title: '未発見カード',
        category: 'science',
        shortText: '隠されたテキスト',
        detailText: '隠された詳細',
        imageAsset: '',
        rarity: 'normal',
        sourceNote: '隠された出典',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DailyQuestionScreen(
            question: questions[0],
            relatedCard: unownedCard,
            allCards: cards,
            saveRepository: saveRepository,
            rewardService: rewardService,
            saveData: SaveData(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('未発見カード'), findsNothing);
      expect(find.text('隠されたテキスト'), findsNothing);
      expect(find.text('隠された詳細'), findsNothing);
      expect(find.text('出典: 隠された出典'), findsNothing);
    });
  });
}
