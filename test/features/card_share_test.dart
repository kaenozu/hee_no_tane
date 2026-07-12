import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/save_data.dart';
import 'package:hee_no_tane_app/domain/services/reward_service.dart';
import 'package:hee_no_tane_app/features/collection/card_detail_screen.dart';
import 'package:hee_no_tane_app/features/collection/card_share_preview.dart';
import 'package:hee_no_tane_app/features/collection/card_share_service.dart';

import '../helpers/fake_save_repository.dart';

const _card = HeeCard(
  id: 'card_01',
  title: 'ハチミツは腐りにくい',
  category: 'food',
  shortText: '水分が少なく酸性のため、適切に保存されたハチミツはとても腐りにくい。',
  detailText: 'ハチミツは高い糖度、低い水分活性、酸性という条件が重なり、微生物が増殖しにくい食品です。',
  imageAsset: '',
  rarity: 'rare',
  sourceNote: '農林水産省・食品保存資料',
);

class _FakeCardShareGateway implements CardShareGateway {
  int callCount = 0;
  Uint8List? receivedBytes;
  String? receivedFileName;
  Rect? receivedOrigin;
  Object? error;
  Completer<void>? completer;

  void hold() {
    completer = Completer<void>();
  }

  void complete() {
    completer?.complete();
    completer = null;
  }

  @override
  Future<void> sharePng({
    required Uint8List bytes,
    required String fileName,
    required Rect sharePositionOrigin,
  }) async {
    callCount++;
    receivedBytes = bytes;
    receivedFileName = fileName;
    receivedOrigin = sharePositionOrigin;

    final currentError = error;
    if (currentError != null) throw currentError;
    final pending = completer;
    if (pending != null) await pending.future;
  }
}

class _FakeCardShareImageRenderer implements CardShareImageRenderer {
  int callCount = 0;
  Object? error;
  Uint8List bytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);

  @override
  Future<Uint8List> render(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    callCount++;
    expect(boundaryKey.currentContext, isNotNull);
    expect(pixelRatio, 3.0);
    final currentError = error;
    if (currentError != null) throw currentError;
    return bytes;
  }
}

Future<void> _pumpCardDetail(
  WidgetTester tester, {
  required bool isOwned,
  HeeCard card = _card,
}) async {
  final repository = FakeSaveRepository();
  repository.setLoadedData(
    SaveData(ownedCardIds: isOwned ? [card.id] : const []),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: CardDetailScreen(
        card: card,
        isOwned: isOwned,
        rewardService: RewardService(),
        saveRepository: repository,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpShareDialog(
  WidgetTester tester, {
  required HeeCard card,
  required CardShareGateway gateway,
  required CardShareImageRenderer renderer,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              key: const ValueKey('open-share-dialog'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => CardShareDialog(
                  card: card,
                  shareGateway: gateway,
                  imageRenderer: renderer,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-share-dialog')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('S1. owned card shows the image share action', (tester) async {
    await _pumpCardDetail(tester, isOwned: true);

    expect(find.byKey(const ValueKey('card-share-action')), findsOneWidget);
    expect(find.byTooltip('画像で共有'), findsOneWidget);
  });

  testWidgets('S2. unowned card does not expose the share action', (
    tester,
  ) async {
    await _pumpCardDetail(tester, isOwned: false);

    expect(find.byKey(const ValueKey('card-share-action')), findsNothing);
    expect(find.text(_card.title), findsNothing);
  });

  testWidgets('S3. share action opens a safe card preview', (tester) async {
    await _pumpCardDetail(tester, isOwned: true);

    await tester.tap(find.byKey(const ValueKey('card-share-action')));
    await tester.pumpAndSettle();

    final preview = find.byKey(const ValueKey('card-share-preview'));
    expect(find.text('共有画像を確認'), findsOneWidget);
    expect(preview, findsOneWidget);
    expect(
      find.descendant(of: preview, matching: find.text(_card.title)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: preview, matching: find.text(_card.shortText)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: preview, matching: find.text('食べ物')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: preview,
        matching: find.text('出典: ${_card.sourceNote}'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: preview, matching: find.text('へぇの種')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: preview, matching: find.text(_card.detailText)),
      findsNothing,
    );
  });

  testWidgets('S4. share sends PNG bytes, file name, and iPad origin', (
    tester,
  ) async {
    final gateway = _FakeCardShareGateway();
    final renderer = _FakeCardShareImageRenderer();
    await _pumpShareDialog(
      tester,
      card: _card,
      gateway: gateway,
      renderer: renderer,
    );

    await tester.tap(find.widgetWithText(FilledButton, '共有する'));
    await tester.pumpAndSettle();

    expect(renderer.callCount, 1);
    expect(gateway.callCount, 1);
    expect(gateway.receivedBytes, renderer.bytes);
    expect(gateway.receivedBytes, isNotEmpty);
    expect(gateway.receivedFileName, 'hee_card_card_01.png');
    expect(gateway.receivedOrigin, isNotNull);
    expect(gateway.receivedOrigin!.isEmpty, isFalse);
  });

  testWidgets('S5. long share content does not overflow', (tester) async {
    final longCard = HeeCard(
      id: 'long',
      title: List.filled(8, 'とても長いカードタイトル').join(),
      category: 'science',
      shortText: List.filled(12, '長い説明でも共有画像の枠内に安全に収まります。').join(),
      detailText: 'detail',
      imageAsset: '',
      rarity: 'normal',
      sourceNote: List.filled(8, '非常に長い出典情報').join(),
    );

    await _pumpShareDialog(
      tester,
      card: longCard,
      gateway: _FakeCardShareGateway(),
      renderer: _FakeCardShareImageRenderer(),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('card-share-preview')), findsOneWidget);
  });

  testWidgets('S6. rendering failure is handled and shown to the user', (
    tester,
  ) async {
    final renderer = _FakeCardShareImageRenderer()
      ..error = const CardShareException('render failed');
    final gateway = _FakeCardShareGateway();
    await _pumpShareDialog(
      tester,
      card: _card,
      gateway: gateway,
      renderer: renderer,
    );

    await tester.tap(find.widgetWithText(FilledButton, '共有する'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(gateway.callCount, 0);
    expect(
      find.text('共有画像を作成できませんでした。もう一度お試しください。'),
      findsOneWidget,
    );
    expect(find.text('共有する'), findsOneWidget);
  });

  testWidgets('S7. sharing in progress prevents duplicate submissions', (
    tester,
  ) async {
    final gateway = _FakeCardShareGateway()..hold();
    final renderer = _FakeCardShareImageRenderer();
    await _pumpShareDialog(
      tester,
      card: _card,
      gateway: gateway,
      renderer: renderer,
    );

    await tester.tap(find.widgetWithText(FilledButton, '共有する'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();

    expect(gateway.callCount, 1);
    expect(find.text('作成中...'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);

    gateway.complete();
    await tester.pumpAndSettle();
    expect(gateway.callCount, 1);
  });

  testWidgets('S8. repaint renderer produces PNG data', (tester) async {
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: const CardSharePreview(card: _card),
          ),
        ),
      ),
    );
    await tester.pump();

    final bytes = await tester.runAsync(
      () => const RepaintBoundaryCardShareImageRenderer().render(
        boundaryKey,
        pixelRatio: 1.0,
      ),
    );

    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(8));
    expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
  });
}
