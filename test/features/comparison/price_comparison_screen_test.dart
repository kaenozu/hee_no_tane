/// test/features/comparison/price_comparison_screen_test.dart
///
/// 価格比較画面の基本入力から結果表示までを検証する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/features/comparison/price_comparison_screen.dart';

void main() {
  testWidgets('2つの表示価格を入力して安い商品を表示する', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PriceComparisonScreen()));

    await tester.enterText(
      find.byKey(const ValueKey('price-comparison-left-price')),
      '100',
    );
    await tester.enterText(
      find.byKey(const ValueKey('price-comparison-right-price')),
      '200',
    );
    final submit = find.byKey(const ValueKey('price-comparison-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('price-comparison-result')),
      findsOneWidget,
    );
    expect(find.text('商品Aがお得です'), findsOneWidget);
    expect(find.text('比較基準: 支払総額'), findsOneWidget);
  });
}
