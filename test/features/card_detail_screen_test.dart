import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/features/collection/card_detail_screen.dart';

void main() {
  testWidgets('owned card detail reveals knowledge text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CardDetailScreen(card: _card, isOwned: true),
      ),
    );

    expect(find.text('へぇポイント'), findsOneWidget);
    expect(find.text('短い知識'), findsOneWidget);
    expect(find.text('くわしい知識'), findsOneWidget);
    expect(find.text('詳しい本文'), findsOneWidget);
    expect(find.text('出典: test source'), findsOneWidget);
  });

  testWidgets('locked card detail hides knowledge text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CardDetailScreen(card: _card, isOwned: false),
      ),
    );

    expect(find.text('未発見のカード'), findsOneWidget);
    expect(find.text('まだ読めません'), findsOneWidget);
    expect(find.text('短い知識'), findsNothing);
    expect(find.text('詳しい本文'), findsNothing);
    expect(find.text('出典: test source'), findsNothing);
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
