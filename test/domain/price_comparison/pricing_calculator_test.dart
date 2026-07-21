/// test/domain/price_comparison/pricing_calculator_test.dart
///
/// 税・割引・送料・ポイント・容量換算の計算順序を検証する。
///
/// 関連:
///   - lib/domain/price_comparison/pricing_calculator.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/price_comparison/models.dart';
import 'package:hee_no_tane_app/domain/price_comparison/pricing_calculator.dart';

void main() {
  test('税から単位単価まで指定順で計算する', () {
    const offer = Offer(
      id: 'a',
      productName: '洗剤',
      storeName: 'A店',
      price: 1000,
      taxIncluded: false,
      taxRate: 0.10,
      percentageDiscount: 0.10,
      fixedDiscount: 50,
      couponDiscount: 40,
      pointRate: 0.01,
      shippingFee: 100,
      quantity: Quantity(
        value: 500,
        unit: Unit.gram,
        packageCount: 2,
        measureKind: MeasureKind.genericMass,
      ),
    );

    final result = calculatePrice(
      offer,
      context: const PurchaseContext(shippingFee: 100),
    );

    expect(result.taxAmount, 100);
    expect(result.basePriceInclTax, 1100);
    expect(result.discountAmount, 200);
    expect(result.payableNow, 1000);
    expect(result.earnedPoints, 10);
    expect(result.effectiveCost, 990);
    expect(result.normalizedQuantity, 1000);
    expect(result.cashUnitCost, 1);
    expect(result.effectiveUnitCost, closeTo(0.99, 0.000001));
  });

  test('税込398円の税額を36円として抽出する', () {
    const offer = Offer(
      id: 'a',
      productName: '食品',
      storeName: 'A店',
      price: 398,
      taxIncluded: true,
      taxRate: 0.10,
      earnedPoints: 0,
    );

    final result = calculatePrice(offer);

    expect(result.preTaxPrice, 362);
    expect(result.taxAmount, 36);
    expect(result.payableNow, 398);
    expect(result.effectiveCost, 398);
  });

  test('0.5円の境界をHALF_UPで1円に丸める', () {
    const offer = Offer(
      id: 'a',
      productName: '端数商品',
      storeName: 'A店',
      price: 5,
      taxIncluded: false,
      taxRate: 0.10,
      earnedPoints: 0,
    );

    final result = calculatePrice(offer);

    expect(result.taxAmount, 1);
    expect(result.payableNow, 6);
  });
}
