import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/collection/card_detail_screen.dart';
import 'package:hee_no_tane_app/features/collection/card_list_screen.dart';

import '../helpers/fake_save_repository.dart';

void main() {
  final cards = [
    HeeCard(
      id: 'card_a',
      title: '山の名前',
      category: 'nature_geography',
      shortText: 'short',
      detailText: 'detail',
      imageAsset: '',
      rarity: 'normal',
      sourceNote: 'test',
    ),
    HeeCard(
      id: 'card_b',
      title: '星の話',
      category: 'science',
      shortText: 'short',
      detailText: 'detail',
      imageAsset: '',
      rarity: 'rare',
      sourceNote: 'test',
    ),
    HeeCard(
      id: 'card_c',
      title: '忍者',
      category: 'history',
      shortText: 'short',
      detailText: 'detail',
      imageAsset: '',
      rarity: 'normal',
      sourceNote: 'test',
    ),
  ];

  late FakeSaveRepository repository;
  late RewardService rewardService;

  Widget buildScreen({
    required SaveData saveData,
    List<HeeCard>? allCards,
  }) {
    repository.setLoadedData(saveData);
    return MaterialApp(
      home: CardListScreen(
        allCards: allCards ?? cards,
        saveRepository: repository,
        rewardService: rewardService,
      ),
    );
  }

  setUp(() {
    repository = FakeSaveRepository();
    rewardService = RewardService();
  });

  group('CardListScreen', () {
    testWidgets('shows owned card title and unowned as ???', (tester) async {
      await tester.pumpWidget(
        buildScreen(saveData: SaveData(ownedCardIds: ['card_b'])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CardListScreen), findsOneWidget);
      expect(find.text('星の話'), findsOneWidget);
      expect(find.text('???'), findsNWidgets(2));
    });

    testWidgets('category filter shows matching cards', (tester) async {
      await tester.pumpWidget(
        buildScreen(
          saveData: SaveData(ownedCardIds: ['card_a', 'card_b', 'card_c']),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('山の名前'), findsOneWidget);
      expect(find.text('星の話'), findsOneWidget);
      expect(find.text('忍者'), findsOneWidget);

      await tester.tap(find.text('科学'));
      await tester.pumpAndSettle();

      expect(find.text('星の話'), findsOneWidget);
      expect(find.text('山の名前'), findsNothing);
      expect(find.text('忍者'), findsNothing);
    });

    testWidgets('selecting all brings back all cards', (tester) async {
      await tester.pumpWidget(
        buildScreen(
          saveData: SaveData(ownedCardIds: ['card_a', 'card_b', 'card_c']),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('科学'));
      await tester.pumpAndSettle();
      expect(find.text('星の話'), findsOneWidget);

      await tester.tap(find.text('すべて'));
      await tester.pumpAndSettle();

      expect(find.text('星の話'), findsOneWidget);
      expect(find.text('山の名前'), findsOneWidget);
      expect(find.text('忍者'), findsOneWidget);
    });

    testWidgets('shows empty message when no cards', (tester) async {
      await tester.pumpWidget(
        buildScreen(saveData: SaveData(), allCards: const []),
      );
      await tester.pumpAndSettle();

      expect(find.text('カードがありません'), findsOneWidget);
    });

    testWidgets('app bar shows owned count', (tester) async {
      await tester.pumpWidget(
        buildScreen(saveData: SaveData(ownedCardIds: ['card_a'])),
      );
      await tester.pumpAndSettle();

      expect(find.text('へぇ図鑑 (1/3)'), findsOneWidget);
    });

    testWidgets('tapping card navigates to detail screen', (tester) async {
      await tester.pumpWidget(
        buildScreen(saveData: SaveData(ownedCardIds: ['card_a'])),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('山の名前'));
      await tester.pumpAndSettle();

      expect(find.byType(CardDetailScreen), findsOneWidget);
      expect(repository.loadCallCount, greaterThanOrEqualTo(2));
      expect(repository.saveCallCount, 1);
    });
  });
}
