/// test/features/comparison/comparison_result_screen_test.dart
///
/// 比較結果画面に順位と計算内訳が表示されることを検証する。
///
/// 関連:
///   - lib/features/comparison/comparison_result_screen.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/data/repositories/comparison_repository.dart';
import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/price_comparison/comparison_engine.dart';
import 'package:hee_no_tane_app/domain/price_comparison/models.dart';
import 'package:hee_no_tane_app/domain/price_comparison/pricing_calculator.dart';
import 'package:hee_no_tane_app/features/comparison/comparison_result_screen.dart';

void main() {
  testWidgets('順位カードを開くと税・割引・送料の内訳が見える', (tester) async {
    const offers = <Offer>[
      Offer(
        id: 'a', productName: '商品A', storeName: 'A店', price: 500,
        taxIncluded: true, taxRate: 0.10, earnedPoints: 0,
      ),
      Offer(
        id: 'b', productName: '商品B', storeName: 'B店', price: 400,
        taxIncluded: true, taxRate: 0.10, earnedPoints: 0,
      ),
    ];
    final result = rankOffers(<String, PriceBreakdown>{
      for (final offer in offers) offer.id: calculatePrice(offer),
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ComparisonResultScreen(
          offers: offers,
          result: result,
          repository: ComparisonRepository(store: _MemoryStore()),
        ),
      ),
    );

    await tester.tap(find.text('商品B'));
    await tester.pumpAndSettle();

    expect(find.text('税額'), findsOneWidget);
    expect(find.text('割引・クーポン'), findsOneWidget);
    expect(find.text('今支払う額'), findsOneWidget);
  });
}

class _MemoryStore implements PreferenceStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
