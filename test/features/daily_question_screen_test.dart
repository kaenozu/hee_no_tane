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
import '../helpers/fake_save_repository.dart';

String _todayDateString() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

Widget buildDailyQuestionScreen({
  required Question question,
  HeeCard? relatedCard,
  required SaveRepository saveRepository,
  required RewardService rewardService,
  SaveData? saveData,
}) {
  if (saveRepository is FakeSaveRepository && saveData != null) {
    saveRepository.setLoadedData(saveData);
  }
  return MaterialApp(
    home: DailyQuestionScreen(
      question: question,
      relatedCard: relatedCard,
      saveRepository: saveRepository,
      rewardService: rewardService,
    ),
  );
}

Widget buildHomeScreen({
  required List<Question> allQuestions,
  required List<HeeCard> allCards,
  required SaveRepository saveRepository,
  required RewardService rewardService,
}) {
  return MaterialApp(
    home: HomeScreen(
      allQuestions: allQuestions,
      allCards: allCards,
      saveRepository: saveRepository,
      rewardService: rewardService,
    ),
  );
}

/// DailyQuestionScreen を push した状態でテストするためのラッパー。
/// root に DummyHome、その上に DailyQuestionScreen が push される。
/// handlePopRoute() で DailyQuestionScreen を pop できる。
Future<void> pushDailyQuestionScreen(
  WidgetTester tester, {
  required Question question,
  HeeCard? relatedCard,
  required SaveRepository saveRepository,
  required RewardService rewardService,
  SaveData? saveData,
}) async {
  if (saveRepository is FakeSaveRepository && saveData != null) {
    saveRepository.setLoadedData(saveData);
  }
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          Future.microtask(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DailyQuestionScreen(
                  question: question,
                  relatedCard: relatedCard,
                  saveRepository: saveRepository,
                  rewardService: rewardService,
                ),
              ),
            );
          });
          return const Scaffold(body: Center(child: Text('DummyHome')));
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late List<Question> questions;
  late List<HeeCard> cards;
  late RewardService rewardService;
  late FakeSaveRepository fakeRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    rewardService = RewardService();
    fakeRepo = FakeSaveRepository();
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

  // ──────────────────────────────────────────────
  // 回帰テスト（既存の7テストから固定wait除去）
  // ──────────────────────────────────────────────

  testWidgets('R1. unowned card answer grants card and saves date', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildDailyQuestionScreen(
        question: questions[0],
        relatedCard: cards[0],
        saveRepository: fakeRepo,
        rewardService: rewardService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    // Fake は即時完了するので1pumpでsettle
    await tester.pumpAndSettle();

    expect(find.text('新しい知識カードを発見'), findsOneWidget);
    expect(find.text('テストカード0'), findsOneWidget);
    expect(fakeRepo.saveCallCount, 1);
    final saved = fakeRepo.lastSavedData!;
    expect(saved.ownedCardIds, contains('card_0'));
    expect(saved.lastDailyQuestionDate, isNotEmpty);
    expect(saved.totalBrowseCount, greaterThanOrEqualTo(1));
  });

  testWidgets('R2. already owned card still saves date and stats', (
    tester,
  ) async {
    final saveData = SaveData(ownedCardIds: ['card_0']);
    await tester.pumpWidget(
      buildDailyQuestionScreen(
        question: questions[0],
        relatedCard: cards[0],
        saveRepository: fakeRepo,
        rewardService: rewardService,
        saveData: saveData,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();

    expect(find.text('このカードは発見済みです'), findsOneWidget);
    expect(fakeRepo.saveCallCount, 1);
    final saved = fakeRepo.lastSavedData!;
    expect(saved.lastDailyQuestionDate, isNotEmpty);
    expect(saved.totalBrowseCount, greaterThanOrEqualTo(1));
    final cardCount = saved.ownedCardIds.where((id) => id == 'card_0').length;
    expect(cardCount, 1);
  });

  testWidgets('R3. null relatedCard still marks as answered', (tester) async {
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
      buildDailyQuestionScreen(
        question: noCardQuestion,
        saveRepository: fakeRepo,
        rewardService: rewardService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();

    expect(find.text('解説'), findsOneWidget);
    expect(fakeRepo.saveCallCount, 1);
    final saved = fakeRepo.lastSavedData!;
    expect(saved.lastDailyQuestionDate, isNotEmpty);
    expect(saved.totalBrowseCount, greaterThanOrEqualTo(1));
  });

  testWidgets('R4. cannot answer again on same day via home', (tester) async {
    final todayStr = _todayDateString();
    fakeRepo.setLoadedData(
      SaveData(lastDailyQuestionDate: todayStr, ownedCardIds: ['card_0']),
    );

    await tester.pumpWidget(
      buildHomeScreen(
        allQuestions: questions,
        allCards: cards,
        saveRepository: fakeRepo,
        rewardService: rewardService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('今日の1問は完了しました'), findsOneWidget);
    expect(find.text('今日の1問を始める'), findsNothing);
  });

  testWidgets('R5. card to read opens CardDetailScreen', (tester) async {
    final todayStr = _todayDateString();
    fakeRepo.setLoadedData(
      SaveData(lastDailyQuestionDate: todayStr, ownedCardIds: ['card_0']),
    );

    await tester.pumpWidget(
      buildHomeScreen(
        allQuestions: questions,
        allCards: cards,
        saveRepository: fakeRepo,
        rewardService: rewardService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('カードを読む'));
    await tester.pumpAndSettle();

    expect(find.byType(CardDetailScreen), findsOneWidget);
  });

  testWidgets(
    'R6. answer persists through SaveRepository and survives app restart',
    (tester) async {
      // 実SaveRepository + SharedPreferences mockで永続化を検証する。
      final realRepo = SaveRepository();

      await tester.pumpWidget(
        buildDailyQuestionScreen(
          question: questions[0],
          relatedCard: cards[0],
          saveRepository: realRepo,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      // 新しいSaveRepositoryインスタンスで保存データを読み込む
      final freshRepo = SaveRepository();
      final saved = await freshRepo.load();
      final todayStr = _todayDateString();
      expect(saved.lastDailyQuestionDate, todayStr);
      expect(saved.ownedCardIds, contains('card_0'));
      expect(saved.totalBrowseCount, greaterThanOrEqualTo(1));

      // 新しいHomeScreenを構築して再起動後の状態を確認
      await tester.pumpWidget(
        buildHomeScreen(
          allQuestions: questions,
          allCards: cards,
          saveRepository: freshRepo,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('今日の1問を始める'), findsNothing);
      expect(find.text('今日の1問は完了しました'), findsOneWidget);
      expect(find.text('カードを読む'), findsOneWidget);
    },
  );

  testWidgets('R7. unowned card content stays hidden', (tester) async {
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
      buildDailyQuestionScreen(
        question: questions[0],
        relatedCard: unownedCard,
        saveRepository: fakeRepo,
        rewardService: rewardService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('未発見カード'), findsNothing);
    expect(find.text('隠されたテキスト'), findsNothing);
    expect(find.text('隠された詳細'), findsNothing);

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();

    expect(find.text('新しい知識カードを発見'), findsOneWidget);
    expect(find.text('未発見カード'), findsOneWidget);
    expect(find.text('隠されたテキスト'), findsNothing);
    expect(find.text('隠された詳細'), findsNothing);
  });

  // ──────────────────────────────────────────────
  // A. 保存中の制御
  // ──────────────────────────────────────────────

  group('A. save-in-progress', () {
    testWidgets('A1. double answer prevented during save', (tester) async {
      fakeRepo.holdNextSave();
      await tester.pumpWidget(
        buildDailyQuestionScreen(
          question: questions[0],
          relatedCard: cards[0],
          saveRepository: fakeRepo,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      // 1回目の回答
      await tester.tap(find.text('A'));
      await tester.pump();

      expect(fakeRepo.saveCallCount, 1);

      // 2回目の回答を試行
      await tester.tap(find.text('B'));
      await tester.pump();

      // save() は2回呼ばれていないこと
      expect(fakeRepo.saveCallCount, 1);

      // 選択結果が変更されていないこと
      fakeRepo.completeSave();
      await tester.pumpAndSettle();

      // 解説が表示されている（Aが選ばれた証拠）
      expect(find.text('解説0'), findsOneWidget);
    });

    testWidgets('A2. home navigation blocked during save', (tester) async {
      fakeRepo.holdNextSave();
      await tester.pumpWidget(
        buildDailyQuestionScreen(
          question: questions[0],
          relatedCard: cards[0],
          saveRepository: fakeRepo,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pump();

      // ホームボタンが無効（onPressed: null）であること
      final homeButton = find.widgetWithText(FilledButton, 'ホームへ戻る');
      expect(homeButton, findsNothing);
    });

    testWidgets('A3. system back prevented during save', (tester) async {
      fakeRepo.holdNextSave();
      await pushDailyQuestionScreen(
        tester,
        question: questions[0],
        relatedCard: cards[0],
        saveRepository: fakeRepo,
        rewardService: rewardService,
      );

      await tester.tap(find.text('A'));
      await tester.pump();

      // AppBarの戻るボタンが非表示（root routeではIcons.arrow_backが出ないので、代わりに
      // handlePopRouteでpop拒否を確認する）
      await tester.binding.handlePopRoute();
      await tester.pump();

      // 画面がpopしていない（DailyQuestionScreenがまだ表示されている）
      expect(find.byType(DailyQuestionScreen), findsOneWidget);
    });

    testWidgets('A4. card detail navigation blocked during save', (
      tester,
    ) async {
      fakeRepo.holdNextSave();
      await tester.pumpWidget(
        buildDailyQuestionScreen(
          question: questions[0],
          relatedCard: cards[0],
          saveRepository: fakeRepo,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pump();

      // 保存中はカード獲得ブロックが表示されない（_saveSucceeded == false）
      expect(find.text('図鑑で見る'), findsNothing);
      expect(find.text('カードを読む'), findsNothing);

      // Direct navigation attempt should also fail
      expect(find.byType(CardDetailScreen), findsNothing);
    });

    testWidgets('A5. navigation enabled after save succeeds', (tester) async {
      fakeRepo.holdNextSave();
      await tester.pumpWidget(
        buildDailyQuestionScreen(
          question: questions[0],
          relatedCard: cards[0],
          saveRepository: fakeRepo,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pump();

      // 保存完了
      fakeRepo.completeSave();
      await tester.pumpAndSettle();

      // カードブロックが表示され、"ホームへ戻る"FilledButtonが表示されている
      expect(find.text('新しい知識カードを発見'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'ホームへ戻る'), findsOneWidget);

      // ホームへ戻れる（画面下部までスクロールしてタップ）
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'ホームへ戻る'));
      await tester.pumpAndSettle();
      expect(find.byType(DailyQuestionScreen), findsNothing);
    });
  });

  // ──────────────────────────────────────────────
  // B. 保存失敗
  // ──────────────────────────────────────────────

  group('B. save failure', () {
    testWidgets('B1. save failure detected - not marked as succeeded', (
      tester,
    ) async {
      fakeRepo.holdNextSave();
      await tester.pumpWidget(
        buildDailyQuestionScreen(
          question: questions[0],
          relatedCard: cards[0],
          saveRepository: fakeRepo,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pump();

      // 保存失敗
      fakeRepo.failSave();
      await tester.pumpAndSettle();

      // 保存中表示が消えている
      expect(find.text('回答を保存しています...'), findsNothing);

      // エラーメッセージが表示されている
      expect(find.text('保存エラー'), findsOneWidget);
      expect(find.text('保存に失敗しました'), findsOneWidget);

      // 保存成功状態になっていない（カードブロックなし）
      expect(find.text('新しい知識カードを発見'), findsNothing);

      // ホームへ戻れない（ボタンがnull）
      expect(find.widgetWithText(FilledButton, 'ホームへ戻る'), findsNothing);

      // カード詳細へ移動できない
      expect(find.text('図鑑で見る'), findsNothing);
    });

    testWidgets('B2. retry succeeds after failure', (tester) async {
      fakeRepo.holdNextSave();
      await tester.pumpWidget(
        buildDailyQuestionScreen(
          question: questions[0],
          relatedCard: cards[0],
          saveRepository: fakeRepo,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pump();

      // 1回目失敗
      fakeRepo.failSave();
      await tester.pumpAndSettle();

      expect(fakeRepo.saveCallCount, 1);
      expect(find.text('再試行'), findsOneWidget);

      // 再試行（画面下部までスクロール）
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      fakeRepo.holdNextSave();
      await tester.tap(find.text('再試行'));
      await tester.pump();

      // 再試行成功
      fakeRepo.completeSave();
      await tester.pumpAndSettle();

      // save() が合計2回呼ばれる
      expect(fakeRepo.saveCallCount, 2);

      // エラー表示が消えている
      expect(find.text('保存エラー'), findsNothing);

      // カードブロックが表示されている
      expect(find.text('新しい知識カードを発見'), findsOneWidget);
    });

    testWidgets('B3. retry data is idempotent - no double counting', (
      tester,
    ) async {
      fakeRepo.holdNextSave();
      await tester.pumpWidget(
        buildDailyQuestionScreen(
          question: questions[0],
          relatedCard: cards[0],
          saveRepository: fakeRepo,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pump();

      // 1回目のsave()で渡されたデータを記録
      fakeRepo.failSave();
      await tester.pumpAndSettle();

      final firstCallData = fakeRepo.savedDataHistory[0];

      // 再試行（画面下部までスクロール）
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      fakeRepo.holdNextSave();
      await tester.tap(find.text('再試行'));
      await tester.pump();

      fakeRepo.completeSave();
      await tester.pumpAndSettle();

      // 1回目と2回目で渡されたSaveDataが同値（二重加算なし）かつ独立したインスタンス
      expect(fakeRepo.saveCallCount, 2);
      final secondCallData = fakeRepo.savedDataHistory[1];
      expect(identical(firstCallData, secondCallData), isFalse);
      expect(
        identical(firstCallData.ownedCardIds, secondCallData.ownedCardIds),
        isFalse,
      );
      expect(secondCallData.ownedCardIds, firstCallData.ownedCardIds);
      expect(secondCallData.totalBrowseCount, firstCallData.totalBrowseCount);
      expect(secondCallData.streakDays, firstCallData.streakDays);
      expect(
        secondCallData.lastDailyQuestionDate,
        firstCallData.lastDailyQuestionDate,
      );

      // 所有カードIDに重複がない
      for (final id in secondCallData.ownedCardIds) {
        expect(secondCallData.ownedCardIds.where((x) => x == id).length, 1);
      }
    });
  });

  // ──────────────────────────────────────────────
  // D. 回答前のシステム戻る
  // ──────────────────────────────────────────────

  group('D. system back before answering', () {
    testWidgets('D1. system back allowed before selecting an answer', (
      tester,
    ) async {
      await pushDailyQuestionScreen(
        tester,
        question: questions[0],
        relatedCard: cards[0],
        saveRepository: fakeRepo,
        rewardService: rewardService,
      );

      // AppBarの戻るボタンが表示されている
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // システム戻る
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // DailyQuestionScreen が pop された
      expect(find.byType(DailyQuestionScreen), findsNothing);
      // DummyHome が表示されている
      expect(find.text('DummyHome'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // C. HomeScreen カード欠損
  // ──────────────────────────────────────────────

  group('C. card missing on home', () {
    testWidgets(
      'C1. answered without card - completed display, no start button',
      (tester) async {
        final todayStr = _todayDateString();
        // 回答済みだが、今日の問題のrelatedCardIdに一致するカードがない
        fakeRepo.setLoadedData(
          SaveData(
            lastDailyQuestionDate: todayStr,
            ownedCardIds: ['card_0'],
            totalBrowseCount: 1,
            streakDays: 1,
            lastPlayedDate: todayStr,
          ),
        );

        // cardMap に今日の問題のカードがない
        // questions[0].relatedCardId = 'card_0' は cards[0] に存在するので、
        // カードが存在しない状態を作るには cards から card_0 を除外
        // さらに問題は questions[0] だけを使う（DailyQuestionServiceが他の問題を選ばないように）
        final cardsWithoutFirst = cards.sublist(1);

        await tester.pumpWidget(
          buildHomeScreen(
            allQuestions: [questions[0]],
            allCards: cardsWithoutFirst,
            saveRepository: fakeRepo,
            rewardService: rewardService,
          ),
        );
        await tester.pumpAndSettle();

        // 開始ボタンがない
        expect(find.text('今日の1問を始める'), findsNothing);

        // 完了表示
        expect(find.text('今日の1問は完了しました'), findsOneWidget);

        // カード読込エラー表示
        expect(find.text('カード情報を読み込めませんでした'), findsOneWidget);

        // カードを読むボタンがない
        expect(find.text('カードを読む'), findsNothing);

        // save() が呼ばれていない（HomeScreen表示だけで保存しない）
        expect(fakeRepo.saveCallCount, 0);

        // lastDailyQuestionDate が変更されていない
        final loaded = await fakeRepo.load();
        expect(loaded.lastDailyQuestionDate, todayStr);
      },
    );

    testWidgets('C2. system back during save error - no pop', (tester) async {
      fakeRepo.holdNextSave();
      await pushDailyQuestionScreen(
        tester,
        question: questions[0],
        relatedCard: cards[0],
        saveRepository: fakeRepo,
        rewardService: rewardService,
      );

      await tester.tap(find.text('A'));
      await tester.pump();

      fakeRepo.failSave();
      await tester.pumpAndSettle();

      // 保存失敗状態でシステム戻る
      await tester.binding.handlePopRoute();
      await tester.pump();

      // 画面がpopしていない
      expect(find.byType(DailyQuestionScreen), findsOneWidget);
    });

    testWidgets('C3. system back after save success - pop allowed', (
      tester,
    ) async {
      fakeRepo.holdNextSave();
      await pushDailyQuestionScreen(
        tester,
        question: questions[0],
        relatedCard: cards[0],
        saveRepository: fakeRepo,
        rewardService: rewardService,
      );

      await tester.tap(find.text('A'));
      await tester.pump();

      fakeRepo.completeSave();
      await tester.pumpAndSettle();

      // 保存成功後はシステム戻るでpopできる
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // DailyQuestionScreen が pop された
      expect(find.byType(DailyQuestionScreen), findsNothing);
      // DummyHome が表示されている
      expect(find.text('DummyHome'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // E. ホーム画面の再読込
  // ──────────────────────────────────────────────

  group('E. home refresh after quiz', () {
    /// DailyQuestionScreen を push する前の HomeScreen を表示する。
    Widget buildHomePushingToQuiz() {
      return MaterialApp(
        home: HomeScreen(
          allQuestions: questions,
          allCards: cards,
          saveRepository: fakeRepo,
          rewardService: rewardService,
        ),
      );
    }

    testWidgets('E1. system back after save success refreshes home', (
      tester,
    ) async {
      fakeRepo.setLoadedData(SaveData());

      await tester.pumpWidget(buildHomePushingToQuiz());
      await tester.pumpAndSettle();

      // 今日の1問を開始
      await tester.tap(find.text('今日の1問を始める'));
      await tester.pumpAndSettle();

      fakeRepo.holdNextSave();
      await tester.tap(find.text('A'));
      await tester.pump();

      fakeRepo.completeSave();
      await tester.pumpAndSettle();

      // システム戻る
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // ホームが再読込され、回答済み状態が表示される
      expect(find.text('今日の1問を始める'), findsNothing);
      expect(find.text('今日の1問は完了しました'), findsOneWidget);
    });

    testWidgets('E2. AppBar back after save success refreshes home', (
      tester,
    ) async {
      fakeRepo.setLoadedData(SaveData());

      await tester.pumpWidget(buildHomePushingToQuiz());
      await tester.pumpAndSettle();

      await tester.tap(find.text('今日の1問を始める'));
      await tester.pumpAndSettle();

      fakeRepo.holdNextSave();
      await tester.tap(find.text('A'));
      await tester.pump();

      fakeRepo.completeSave();
      await tester.pumpAndSettle();

      // AppBarの戻るボタンをタップ（保存成功後は _canLeave == true で表示される）
      final backButton = find.byIcon(Icons.arrow_back);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // ホームが再読込され、回答済み状態が表示される
      expect(find.byType(DailyQuestionScreen), findsNothing);
      expect(find.text('今日の1問を始める'), findsNothing);
      expect(find.text('今日の1問は完了しました'), findsOneWidget);
    });

    testWidgets('E3. back before answering keeps unanswered state', (
      tester,
    ) async {
      fakeRepo.setLoadedData(SaveData());

      await tester.pumpWidget(buildHomePushingToQuiz());
      await tester.pumpAndSettle();

      expect(find.text('今日の1問を始める'), findsOneWidget);

      // 今日の1問を開始
      await tester.tap(find.text('今日の1問を始める'));
      await tester.pumpAndSettle();

      // 回答せずに戻る
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // ホームが再読込され、未回答状態が維持される
      expect(find.text('今日の1問を始める'), findsOneWidget);
      expect(find.text('今日の1問は完了しました'), findsNothing);
    });

    testWidgets('E4. home button after save success refreshes home', (
      tester,
    ) async {
      fakeRepo.setLoadedData(SaveData());

      await tester.pumpWidget(buildHomePushingToQuiz());
      await tester.pumpAndSettle();

      await tester.tap(find.text('今日の1問を始める'));
      await tester.pumpAndSettle();

      fakeRepo.holdNextSave();
      await tester.tap(find.text('A'));
      await tester.pump();

      fakeRepo.completeSave();
      await tester.pumpAndSettle();

      // 画面下部の「ホームへ戻る」ボタンをタップ
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'ホームへ戻る'));
      await tester.pumpAndSettle();

      // ホームが再読込され、回答済み状態が表示される
      expect(find.text('今日の1問を始める'), findsNothing);
      expect(find.text('今日の1問は完了しました'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // F. カード詳細の保存失敗
  // ──────────────────────────────────────────────

  group('F. card detail save failure', () {
    late FakeSaveRepository failingRepo;
    late HeeCard ownedCard;

    setUp(() {
      failingRepo = FakeSaveRepository();
      ownedCard = HeeCard(
        id: 'card_viewed',
        title: '閲覧テストカード',
        category: 'science',
        shortText: '短い説明',
        detailText: '詳細な説明文',
        imageAsset: '',
        rarity: 'normal',
        sourceNote: 'テスト出典',
      );
    });

    testWidgets('F1. save failure does not crash card detail', (tester) async {
      failingRepo.holdNextSave();

      await tester.pumpWidget(
        MaterialApp(
          home: CardDetailScreen(
            card: ownedCard,
            isOwned: true,
            rewardService: rewardService,
            saveRepository: failingRepo,
          ),
        ),
      );
      await tester.pump();

      failingRepo.failSave();
      await tester.pumpAndSettle();

      // 未処理例外がない
      expect(tester.takeException(), isNull);

      // 画面が表示されている
      expect(find.byType(CardDetailScreen), findsOneWidget);
      expect(find.text(ownedCard.title), findsOneWidget);
      expect(find.text(ownedCard.detailText), findsOneWidget);
      expect(failingRepo.saveCallCount, 1);
    });

    testWidgets('F2. save success on card detail works normally', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CardDetailScreen(
            card: ownedCard,
            isOwned: true,
            rewardService: rewardService,
            saveRepository: failingRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 保存が1回呼ばれている
      expect(failingRepo.saveCallCount, 1);

      // 更新されたSaveDataが渡されている（totalBrowseCount >= 1）
      final saved = failingRepo.lastSavedData!;
      expect(saved.totalBrowseCount, greaterThanOrEqualTo(1));

      // 画面が正常に表示されている
      expect(find.text(ownedCard.title), findsOneWidget);
      expect(find.text(ownedCard.detailText), findsOneWidget);
    });
  });
}
