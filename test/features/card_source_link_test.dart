import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/collection/card_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/release_content.dart';

void main() {
  testWidgets('approved owned card shows and opens source link', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    Uri? openedUri;

    await tester.pumpWidget(
      MaterialApp(
        home: CardDetailScreen(
          card: _approvedCard,
          isOwned: true,
          rewardService: RewardService(),
          saveRepository: SaveRepository(),
          sourceLauncher: (uri) async {
            openedUri = uri;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('出典を開く'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('card-source-open-action')));
    await tester.pump();

    expect(openedUri, Uri.parse('https://www.jma.go.jp/example'));
  });

  testWidgets('legacy source does not show source link', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        home: CardDetailScreen(
          card: _legacyCard,
          isOwned: true,
          rewardService: RewardService(),
          saveRepository: SaveRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('出典を開く'), findsNothing);
  });

  testWidgets('source launch failure keeps card readable', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        home: CardDetailScreen(
          card: _approvedCard,
          isOwned: true,
          rewardService: RewardService(),
          saveRepository: SaveRepository(),
          sourceLauncher: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('card-source-open-action')));
    await tester.pump();

    expect(find.text('詳しい本文'), findsOneWidget);
    expect(find.text('出典ページを開けませんでした。カードはそのまま閲覧できます。'), findsOneWidget);
  });
}

final _approvedCard = releaseContentPair(
  id: 'source_link',
  title: 'テストカード',
  shortText: '短い知識',
  detailText: '詳しい本文',
  sourceUrl: 'https://www.jma.go.jp/example',
).card;

const _legacyCard = HeeCard(
  id: 'card',
  title: 'テストカード',
  category: 'science',
  shortText: '短い知識',
  detailText: '詳しい本文',
  imageAsset: '',
  rarity: 'normal',
  sourceNote: 'test source',
);
