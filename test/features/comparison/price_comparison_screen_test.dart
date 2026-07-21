import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/features/comparison/price_comparison_screen.dart';

void main() {
  testWidgets('2つの表示価格を入力して安い候補を表示する', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: PriceComparisonScreen()),
    );

    await tester.enterText(
      find.byKey(const ValueKey('comparison-price-0')),
      '100',
    );
    await tester.enterText(
      find.byKey(const ValueKey('comparison-price-1')),
      '200',
    );
    await tester.tap(find.byKey(const ValueKey('comparison-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('comparison-result')), findsOneWidget);
    expect(find.text('候補Aがお得です'), findsOneWidget);
    expect(find.text('比較基準: 支払総額'), findsOneWidget);
  });
}
