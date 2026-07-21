/// test/domain/price_comparison/comparison_engine_test.dart
///
/// 比較基準の選択、順位、同額、容量次元不一致時のフォールバックを検証する。
///
/// 関連:
///   - lib/domain/price_comparison/comparison_engine.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/price_comparison/comparison_engine.dart';
import 'package:hee_no_tane_app/domain/price_comparison/models.dart';
import 'package:hee_no_tane_app/domain/price_comparison/pricing_calculator.dart';

void main() {
  test('同じ容量次元なら実質単価で順位付けする', () {
    final first = calculatePrice(const Offer(
      id: 'a',
      productName: 'A',
      storeName: '店',
      price: 500,
      taxIncluded: true,
      taxRate: 0.10,
      earnedPoints: 0,
      quantity: Quantity(value: 500, unit: Unit.gram, measureKind: MeasureKind.genericMass),
    ));
    final second = calculatePrice(const Offer(
      id: 'b',
      productName: 'B',
      storeName: '店',
      price: 800,
      taxIncluded: true,
      taxRate: 0.10,
      earnedPoints: 0,
      quantity: Quantity(value: 1000, unit: Unit.gram, measureKind: MeasureKind.genericMass),
    ));

    final result = rankOffers(<String, PriceBreakdown>{'a': first, 'b': second});

    expect(result.basis, ComparisonBasis.effectiveUnitCost);
    expect(result.bestId, 'b');
    expect(result.rankedIds, <String>['b', 'a']);
  });

  test('質量と体積は単価比較せず実質総額へフォールバックする', () {
    final mass = calculatePrice(const Offer(
      id: 'mass', productName: '粉', storeName: '店', price: 500,
      taxIncluded: true, taxRate: 0.10, earnedPoints: 0,
      quantity: Quantity(value: 500, unit: Unit.gram, measureKind: MeasureKind.genericMass),
    ));
    final volume = calculatePrice(const Offer(
      id: 'volume', productName: '液体', storeName: '店', price: 400,
      taxIncluded: true, taxRate: 0.10, earnedPoints: 0,
      quantity: Quantity(value: 500, unit: Unit.ml, measureKind: MeasureKind.genericVolume),
    ));

    final result = rankOffers(<String, PriceBreakdown>{'mass': mass, 'volume': volume});

    expect(result.basis, ComparisonBasis.effectiveTotal);
    expect(result.bestId, 'volume');
    expect(result.warnings, contains(WarningCode.dimensionMismatch));
  });
}
