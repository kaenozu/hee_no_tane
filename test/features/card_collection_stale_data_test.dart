import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/app.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/collection/card_detail_screen.dart';
import 'package:hee_no_tane_app/features/collection/card_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_save_repository.dart';

String _today() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

HeeCard _card(String id, String title) {
  return HeeCard(
    id: id,
    title: title,
    category: 'science',
    shortText: '$titleの短い説明',
    detailText: '$titleの詳細説明',
    imageAsset: '',
    rarity: 'normal',
    sourceNote: 'テスト出典',
  );
}

Widget _detailApp({
  required HeeCard card,
  required bool isOwned,
  required FakeSaveRepository repository,
  required RewardService rewardService,
}) {
  return MaterialApp(
    home: CardDetailScreen(
      card: card,
      isOwned: isOwned,
      saveRepository: repository,
      rewardService: rewardService,
    ),
  );
}

Widget _listApp({
  required List<HeeCard> cards,
  required FakeSaveRepository repository,
  required RewardService rewardService,
}) {
  return MaterialApp(
    home: CardListScreen(
      allCards: cards,
      saveRepository: repository,
      rewardService: rewardService,
    ),
  );
}

void main() {
  late FakeSaveRepository repository;
  late RewardService rewardService;
  late HeeCard cardA;
  late HeeCard cardB;

  setUp(() {
    repository = FakeSaveRepository();
    rewardService = RewardService();
    cardA = _card('card_a', 'カードA');
    cardB = _card('card_b', 'カードB');
  });

  group('A. CardDetail protects current save data', () {
    testWidgets('A1. card view updates the latest repository data only', (
      tester,
    ) async {
      final today = _today();
      final latest = SaveData(
        totalBrowseCount: 7,
        streakDays: 4,
        lastPlayedDate: today,
        lastDailyQuestionDate: today,
        ownedCardIds: [cardA.id, cardB.id],
        settings: const GameSettings(themeMode: ThemeMode.dark),
      );
      repository.setLoadedData(latest);

      await tester.pumpWidget(
        _detailApp(
          card: cardA,
          isOwned: true,
          repository: repository,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.loadCallCount, 1);
      expect(repository.saveCallCount, 1);
      final saved = repository.lastSavedData!;
      expect(saved.totalBrowseCount, 8);
      expect(saved.ownedCardIds, latest.ownedCardIds);
      expect(saved.lastDailyQuestionDate, today);
      expect(saved.streakDays, 4);
      expect(saved.lastPlayedDate, today);
      expect(saved.settings.themeMode, ThemeMode.dark);
    });

    testWidgets('A2. load failure never saves an empty replacement', (
      tester,
    ) async {
      final original = SaveData(
        totalBrowseCount: 7,
        streakDays: 4,
        lastPlayedDate: _today(),
        lastDailyQuestionDate: _today(),
        ownedCardIds: [cardA.id, cardB.id],
        settings: const GameSettings(themeMode: ThemeMode.dark),
      );
      repository.setLoadedData(original);
      repository.failLoads();

      await tester.pumpWidget(
        _detailApp(
          card: cardA,
          isOwned: true,
          repository: repository,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(repository.loadCallCount, 1);
      expect(repository.saveCallCount, 0);
      expect(find.text(cardA.title), findsOneWidget);
      expect(find.text(cardA.detailText), findsOneWidget);

      repository.clearLoadFailure();
      final loaded = await repository.loadOrThrow();
      expect(loaded.ownedCardIds, original.ownedCardIds);
      expect(loaded.lastDailyQuestionDate, original.lastDailyQuestionDate);
      expect(loaded.totalBrowseCount, original.totalBrowseCount);
      expect(loaded.settings.themeMode, ThemeMode.dark);
    });

    testWidgets('A3. save failure leaves the repository data unchanged', (
      tester,
    ) async {
      final original = SaveData(
        totalBrowseCount: 7,
        streakDays: 4,
        lastPlayedDate: _today(),
        lastDailyQuestionDate: _today(),
        ownedCardIds: [cardA.id, cardB.id],
      );
      repository.setLoadedData(original);
      repository.holdNextSave();

      await tester.pumpWidget(
        _detailApp(
          card: cardA,
          isOwned: true,
          repository: repository,
          rewardService: rewardService,
        ),
      );
      await tester.pump();
      repository.failSave();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(repository.saveCallCount, 1);
      expect(find.text(cardA.title), findsOneWidget);
      final loaded = await repository.loadOrThrow();
      expect(loaded.totalBrowseCount, original.totalBrowseCount);
      expect(loaded.ownedCardIds, original.ownedCardIds);
      expect(loaded.lastDailyQuestionDate, original.lastDailyQuestionDate);
    });
  });

  group('B. CardList uses injected current data', () {
    testWidgets('B1. initial display uses repository ownership state', (
      tester,
    ) async {
      repository.setLoadedData(SaveData(ownedCardIds: [cardB.id]));

      await tester.pumpWidget(
        _listApp(
          cards: [cardA, cardB],
          repository: repository,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.loadCallCount, 1);
      expect(find.text('へぇ図鑑 (1/2)'), findsOneWidget);
      expect(find.text(cardB.title), findsOneWidget);
      expect(find.text(cardA.title), findsNothing);
      expect(find.text('???'), findsOneWidget);
      final ownedPosition = tester.getTopLeft(
        find.byKey(ValueKey('card-tile-${cardB.id}')),
      );
      final lockedPosition = tester.getTopLeft(
        find.byKey(ValueKey('card-tile-${cardA.id}')),
      );
      expect(ownedPosition.dx, lessThan(lockedPosition.dx));
    });

    testWidgets('B2. returning from detail reloads ownership and ordering', (
      tester,
    ) async {
      final cardC = _card('card_c', 'カードC');
      repository.setLoadedData(SaveData(ownedCardIds: [cardC.id]));

      await tester.pumpWidget(
        _listApp(
          cards: [cardA, cardB, cardC],
          repository: repository,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('へぇ図鑑 (1/3)'), findsOneWidget);
      await tester.tap(find.text(cardC.title));
      await tester.pumpAndSettle();
      expect(find.byType(CardDetailScreen), findsOneWidget);

      repository.setLoadedData(
        SaveData(
          totalBrowseCount: 1,
          lastPlayedDate: _today(),
          ownedCardIds: [cardB.id, cardC.id],
        ),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(CardListScreen), findsOneWidget);
      expect(find.text('へぇ図鑑 (2/3)'), findsOneWidget);
      expect(find.text(cardB.title), findsOneWidget);
      expect(find.text(cardC.title), findsOneWidget);
      expect(find.text(cardA.title), findsNothing);
      expect(find.text('???'), findsOneWidget);

      final cardBPosition = tester.getTopLeft(
        find.byKey(ValueKey('card-tile-${cardB.id}')),
      );
      final cardCPosition = tester.getTopLeft(
        find.byKey(ValueKey('card-tile-${cardC.id}')),
      );
      final cardAPosition = tester.getTopLeft(
        find.byKey(ValueKey('card-tile-${cardA.id}')),
      );
      expect(cardBPosition.dx, lessThan(cardCPosition.dx));
      expect(cardCPosition.dx, lessThan(cardAPosition.dx));
    });

    testWidgets('B3. detail uses the repository injected into CardList', (
      tester,
    ) async {
      repository.setLoadedData(SaveData(ownedCardIds: [cardA.id]));

      await tester.pumpWidget(
        _listApp(
          cards: [cardA],
          repository: repository,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(cardA.title));
      await tester.pumpAndSettle();

      expect(find.byType(CardDetailScreen), findsOneWidget);
      expect(repository.saveCallCount, 1);
      expect(repository.loadCallCount, greaterThanOrEqualTo(2));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(repository.loadCallCount, greaterThanOrEqualTo(3));
    });

    testWidgets('B4. Home injects the app repository into CardList', (
      tester,
    ) async {
      repository.setLoadedData(SaveData(ownedCardIds: [cardA.id]));

      await tester.pumpWidget(
        HeeNoTaneApp(
          allQuestions: const [],
          allCards: [cardA, cardB],
          saveData: SaveData(),
          saveRepository: repository,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      final collectionButton = find.text('図鑑 (1/2)');
      await tester.ensureVisible(collectionButton);
      await tester.tap(collectionButton);
      await tester.pumpAndSettle();

      expect(find.byType(CardListScreen), findsOneWidget);
      expect(find.text('へぇ図鑑 (1/2)'), findsOneWidget);
      expect(repository.loadCallCount, greaterThanOrEqualTo(2));
    });

    testWidgets('B5. load error shows retry and recovers', (tester) async {
      repository.setLoadedData(SaveData(ownedCardIds: [cardA.id]));
      repository.failLoads();

      await tester.pumpWidget(
        _listApp(
          cards: [cardA, cardB],
          repository: repository,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('図鑑データを読み込めませんでした'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
      expect(repository.saveCallCount, 0);

      repository.clearLoadFailure();
      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();

      expect(find.text('へぇ図鑑 (1/2)'), findsOneWidget);
      expect(find.text(cardA.title), findsOneWidget);
    });
  });

  group('C. regressions', () {
    testWidgets('C1. unowned card remains hidden and does not write stats', (
      tester,
    ) async {
      repository.setLoadedData(SaveData());

      await tester.pumpWidget(
        _detailApp(
          card: cardA,
          isOwned: false,
          repository: repository,
          rewardService: rewardService,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('???'), findsOneWidget);
      expect(find.text(cardA.title), findsNothing);
      expect(find.text(cardA.shortText), findsNothing);
      expect(find.text(cardA.detailText), findsNothing);
      expect(repository.loadCallCount, 0);
      expect(repository.saveCallCount, 0);
    });
  });

  group('D. SaveRepository strict load contract', () {
    test('D1. missing data is a valid empty save', () async {
      SharedPreferences.setMockInitialValues({});
      final realRepository = SaveRepository();
      final loaded = await realRepository.loadOrThrow();
      expect(loaded.ownedCardIds, isEmpty);
      expect(loaded.totalBrowseCount, 0);
    });

    test('D2. malformed data throws from strict load', () async {
      SharedPreferences.setMockInitialValues({
        'hee_no_tane_save_data': '{not valid json',
      });
      final realRepository = SaveRepository();

      await expectLater(
        realRepository.loadOrThrow(),
        throwsA(isA<SaveLoadException>()),
      );
    });

    test('D3. best-effort load retains the legacy empty fallback', () async {
      SharedPreferences.setMockInitialValues({
        'hee_no_tane_save_data': '{not valid json',
      });
      final realRepository = SaveRepository();
      final loaded = await realRepository.load();
      expect(loaded.ownedCardIds, isEmpty);
      expect(loaded.totalBrowseCount, 0);
    });
  });
}
