import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/features/result/result_screen.dart';

void main() {
  testWidgets('system back does not return from result to completed battle', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Text('Home'),
        routes: {
          '/result': (_) => const ResultScreen(
            isClear: true,
            correctCount: 5,
            finalFloor: 5,
            remainingHp: 40,
          ),
        },
      ),
    );

    Navigator.of(tester.element(find.text('Home'))).pushNamed('/result');
    await tester.pumpAndSettle();
    expect(find.text('ダンジョンクリア！'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('ダンジョンクリア！'), findsOneWidget);

    await tester.tap(find.text('ホームに戻る'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('clear result with reward fits a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ResultScreen(
          isClear: true,
          correctCount: 5,
          finalFloor: 5,
          remainingHp: 40,
          obtainedCard: HeeCard(
            id: 'card',
            title: 'とても長い名前のへぇカード',
            category: '雑学',
            shortText: '短い画面でも報酬カードの説明が読めます。',
            detailText: 'detail',
            imageAsset: '',
            rarity: 'normal',
            sourceNote: 'test',
          ),
        ),
      ),
    );

    expect(find.text('へぇカードをゲット！'), findsOneWidget);
    expect(find.text('ホームに戻る'), findsOneWidget);
  });
}
