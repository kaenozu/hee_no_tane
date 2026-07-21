/// test/domain/price_comparison/price_calculator_python_parity_test.dart
///
/// Python版 price_compare と同じ計算境界・丸め規則を検証する。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/price_comparison/price_comparison.dart';

void main() {
  const calculator = PriceCalculator();

  PriceOffer offer({
    String id = 'offer',
    double price = 1000,
    bool taxIncluded = true,
    double taxRate = 0.1,
    PriceQuantity? quantity,
    double percentageDiscount = 0,
    double fixedDiscount = 0,
    double couponDiscount = 0,
    double? couponMinimumSubtotal,
    double pointRate = 0,
    double fixedPoints = 0,
    double? earnedPoints,
  }) => PriceOffer(
    id: id,
    productName: '商品',
    storeName: '店舗',
    price: price,
    taxIncluded: taxIncluded,
    taxRate: taxRate,
    quantity: quantity,
    percentageDiscount: percentageDiscount,
    fixedDiscount: fixedDiscount,
    couponDiscount: couponDiscount,
    couponMinimumSubtotal: couponMinimumSubtotal,
    pointRate: pointRate,
    fixedPoints: fixedPoints,
    earnedPoints: earnedPoints,
  );

  test('税抜398円に10%の税を四捨五入して加算する', () {
    final result = calculator.calculate(offer(price: 398, taxIncluded: false));

    expect(result.preTaxPrice, 398);
    expect(result.taxAmount, 40);
    expect(result.payableNow, 438);
  });

  test('税の丸め規則で切り捨てと切り上げを切り替えられる', () {
    final target = offer(price: 99, taxIncluded: false);

    final down = calculator.calculate(
      target,
      policy: const CalculationPolicy(taxRounding: MoneyRounding.down),
    );
    final up = calculator.calculate(
      target,
      policy: const CalculationPolicy(taxRounding: MoneyRounding.up),
    );

    expect(down.taxAmount, 9);
    expect(up.taxAmount, 10);
  });

  test('割合値引き、固定値引き、クーポンを順番に適用する', () {
    final result = calculator.calculate(
      offer(percentageDiscount: 0.1, fixedDiscount: 50, couponDiscount: 30),
    );

    expect(result.discountAmount, 180);
    expect(result.payableNow, 820);
  });

  test('クーポン最低利用額を満たさない場合は適用しない', () {
    final result = calculator.calculate(
      offer(price: 500, couponDiscount: 50, couponMinimumSubtotal: 1000),
    );

    expect(result.couponDiscount, 0);
    expect(result.payableNow, 500);
  });

  test('送料、ポイント、容量単価を同じ計算境界で処理する', () {
    final result = calculator.calculate(
      offer(
        price: 330,
        pointRate: 0.05,
        quantity: const PriceQuantity(value: 1000, unit: PriceUnit.milliliter),
      ),
      context: const PurchaseContext(shippingFee: 80),
    );

    expect(result.payableNow, 410);
    expect(result.earnedPoints, 20);
    expect(result.effectiveCost, 390);
    expect(result.cashUnitCost, 0.41);
    expect(result.effectiveUnitCost, 0.39);
  });

  test('値引きが価格を超えた場合もPython版と同じ内訳を返す', () {
    final result = calculator.calculate(offer(price: 100, fixedDiscount: 200));

    expect(result.discountAmount, 200);
    expect(result.payableNow, 0);
    expect(result.warnings, contains(PriceWarning.discountExceedsPrice));
  });

  test('容量と重量は単価比較せず総額へフォールバックする', () {
    final volume = calculator.calculate(
      offer(
        id: 'volume',
        price: 100,
        earnedPoints: 0,
        quantity: const PriceQuantity(value: 1, unit: PriceUnit.liter),
      ),
    );
    final mass = calculator.calculate(
      offer(
        id: 'mass',
        price: 90,
        earnedPoints: 0,
        quantity: const PriceQuantity(value: 1, unit: PriceUnit.kilogram),
      ),
    );

    final result = calculator.compare({'volume': volume, 'mass': mass});

    expect(result.canCompare, isTrue);
    expect(result.basis, ComparisonBasis.effectiveTotal);
    expect(result.bestId, 'mass');
    expect(result.warnings, contains(PriceWarning.dimensionMismatch));
  });

  test('負の固定値引きをドメイン境界で拒否する', () {
    expect(
      () => calculator.calculate(offer(fixedDiscount: -1)),
      throwsFormatException,
    );
  });
}
