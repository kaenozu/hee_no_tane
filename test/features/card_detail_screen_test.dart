import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/features/collection/card_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('owned card detail reveals knowledge text', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        home: CardDetailScreen(
          card: _card,
          isOwned: true,
          rewardService: RewardService(),
          saveRepository: SaveRepository(),
          saveData: SaveData(ownedCardIds: [_card.id]),
        ),
      ),
    );

    expect(find.text('へぇポイント'), findsOneWidget);
    expect(find.text('短い知識'), findsOneWidget);
    expect(find.text('くわしい知識'), findsOneWidget);
    expect(find.text('詳しい本文'), findsOneWidget);
    expect(find.text('出典: test source'), findsOneWidget);
  });

  testWidgets('locked card detail reveals knowledge after viewing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        home: CardDetailScreen(
          card: _card,
          isOwned: false,
          rewardService: RewardService(),
          saveRepository: SaveRepository(),
          saveData: SaveData(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('新しい知識を収集しました'), findsOneWidget);
    expect(find.text('へぇポイント'), findsOneWidget);
    expect(find.text('短い知識'), findsOneWidget);
    expect(find.text('くわしい知識'), findsOneWidget);
    expect(find.text('詳しい本文'), findsOneWidget);
  });
}

const _card = HeeCard(
  id: 'card',
  title: 'テストカード',
  category: 'science',
  shortText: '短い知識',
  detailText: '詳しい本文',
  imageAsset: '',
  rarity: 'rare',
  sourceNote: 'test source',
);
