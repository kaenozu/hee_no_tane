import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/features/home/home_screen.dart';
import 'package:hee_no_tane_app/features/question/daily_question_screen.dart';
import 'package:hee_no_tane_app/features/collection/card_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _todayDateString() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

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

  Future<void> answerAndWait(WidgetTester tester) async {
    await tester.tap(find.text('A'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  // ── 要件1: 未所有カードへの回答でカードを獲得し、回答日が保存される ──
  testWidgets('1. unowned card answer grants card and saves date', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DailyQuestionScreen(
          question: questions[0],
          relatedCard: cards[0],
          saveRepository: saveRepository,
          rewardService: rewardService,
          saveData: SaveData(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await answerAndWait(tester);

    expect(find.text('新しい知識カードを発見'), findsOneWidget);
    expect(find.text('テストカード0'), findsOneWidget);

    final saved = await saveRepository.load();
    expect(saved.ownedCardIds, contains('card_0'));
    expect(saved.lastDailyQuestionDate, isNotEmpty);
    expect(saved.totalBrowseCount, greaterThanOrEqualTo(1));
  });

  // ── 要件2: 既所有カードへの回答でも回答日と統計が保存される ──
  testWidgets('2. already owned card still saves date and stats', (tester) async {
    final saveData = SaveData(ownedCardIds: ['card_0']);
    await tester.pumpWidget(
      MaterialApp(
        home: DailyQuestionScreen(
          question: questions[0],
          relatedCard: cards[0],
          saveRepository: saveRepository,
          rewardService: rewardService,
          saveData: saveData,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await answerAndWait(tester);

    expect(find.text('このカードは発見済みです'), findsOneWidget);

    final saved = await saveRepository.load();
    expect(saved.lastDailyQuestionDate, isNotEmpty);
    expect(saved.totalBrowseCount, greaterThanOrEqualTo(1));
    // カードは重複しない
    final cardCount = saved.ownedCardIds.where((id) => id == 'card_0').length;
    expect(cardCount, 1);
  });

  // ── 要件3: 関連カードがnullでも回答済み状態になる ──
  testWidgets('3. null relatedCard still marks as answered', (tester) async {
    final noCardQuestion = Question(
      id: 'q_nocard',
      category: 'science',
      difficulty: 'easy',
      question: 'カードなし問題',
      choices: ['A', 'B', 'C'],
      answerIndex: 0,
      explanation: '解説なし',
      relatedCardId: '',
      sourceNote: '出典なし',
      verified: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DailyQuestionScreen(
          question: noCardQuestion,
          saveRepository: saveRepository,
          rewardService: rewardService,
          saveData: SaveData(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await answerAndWait(tester);

    expect(find.text('解説'), findsOneWidget);

    final saved = await saveRepository.load();
    expect(saved.lastDailyQuestionDate, isNotEmpty);
    expect(saved.totalBrowseCount, greaterThanOrEqualTo(1));
  });

  // ── 要件4: 同日再回答できない ──
  testWidgets('4. cannot answer again on same day via home', (tester) async {
    final todayStr = _todayDateString();
    await saveRepository.save(SaveData(
      lastDailyQuestionDate: todayStr,
      ownedCardIds: ['card_0'],
    ));

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
    expect(find.text('今日の1問を始める'), findsNothing);
  });

  // ── 要件5: 「カードを読む」でCardDetailScreenが開く ──
  testWidgets('5. card to read opens CardDetailScreen', (tester) async {
    final todayStr = _todayDateString();
    await saveRepository.save(SaveData(
      lastDailyQuestionDate: todayStr,
      ownedCardIds: ['card_0'],
    ));

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

    await tester.tap(find.text('カードを読む'));
    await tester.pumpAndSettle();

    expect(find.byType(CardDetailScreen), findsOneWidget);
    expect(find.byType(DailyQuestionScreen), findsNothing);
  });

  // ── 要件6: アプリ再起動後も回答済み状態を維持する ──
  testWidgets('6. answered state persists after app restart', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DailyQuestionScreen(
          question: questions[0],
          relatedCard: cards[0],
          saveRepository: saveRepository,
          rewardService: rewardService,
          saveData: SaveData(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await answerAndWait(tester);

    final saved = await saveRepository.load();
    expect(saved.lastDailyQuestionDate, isNotEmpty);
    expect(saved.ownedCardIds, contains('card_0'));

    // アプリ再起動を再現: 新しいHomeScreenを構築
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
  });

  // ── 要件7: 未獲得カード内容の非表示テスト ──
  testWidgets('7. unowned card content stays hidden', (tester) async {
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
          saveRepository: saveRepository,
          rewardService: rewardService,
          saveData: SaveData(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 回答前: カード内容は非表示
    expect(find.text('未発見カード'), findsNothing);
    expect(find.text('隠されたテキスト'), findsNothing);
    expect(find.text('隠された詳細'), findsNothing);
    expect(find.text('出典: 隠された出典'), findsNothing);

    // 回答後: カード获得でカード名が表示される
    await answerAndWait(tester);

    expect(find.text('新しい知識カードを発見'), findsOneWidget);
    expect(find.text('未発見カード'), findsOneWidget);
    // shortText/detailTextはまだ非表示（CardDetailScreenでのみ表示）
    expect(find.text('隠されたテキスト'), findsNothing);
    expect(find.text('隠された詳細'), findsNothing);
  });
}
