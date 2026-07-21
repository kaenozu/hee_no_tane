import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/price_comparison/price_calculator.dart';
import 'package:hee_no_tane_app/domain/price_comparison/price_comparison_models.dart';

void main() {
  PriceOffer offer({
    String id = 'offer',
    String price = '1000',
    bool taxIncluded = true,
    String taxRate = '0.10',
    PriceQuantity? quantity,
    String percentageDiscount = '0',
    String fixedDiscount = '0',
    String couponDiscount = '0',
    String? couponMinimumSubtotal,
    String pointRate = '0',
    String fixedPoints = '0',
    String? earnedPoints,
  }) => PriceOffer(
    id: id,
    productName: '商品',
    storeName: '店舗',
    price: DecimalValue.parse(price),
    taxIncluded: taxIncluded,
    taxRate: DecimalValue.parse(taxRate),
    quantity: quantity,
    percentageDiscount: DecimalValue.parse(percentageDiscount),
    fixedDiscount: DecimalValue.parse(fixedDiscount),
    couponDiscount: DecimalValue.parse(couponDiscount),
    couponMinimumSubtotal: couponMinimumSubtotal == null
        ? null
        : DecimalValue.parse(couponMinimumSubtotal),
    pointRate: DecimalValue.parse(pointRate),
    fixedPoints: DecimalValue.parse(fixedPoints),
    earnedPoints: earnedPoints == null
        ? null
        : DecimalValue.parse(earnedPoints),
  );

  test('税抜398円に10%の税を四捨五入して加算する', () {
    final result = calculatePrice(
      offer(price: '398', taxIncluded: false),
    );

    expect(result.preTaxPrice, DecimalValue.parse('398'));
    expect(result.taxAmount, DecimalValue.parse('40'));
    expect(result.basePriceInclTax, DecimalValue.parse('438'));
  });

  test('割合値引き、固定値引き、クーポンをPython版と同じ順序で適用する', () {
    final result = calculatePrice(
      offer(
        percentageDiscount: '0.10',
        fixedDiscount: '50',
        couponDiscount: '30',
      ),
    );

    expect(result.discountAmount, DecimalValue.parse('180'));
    expect(result.payableNow, DecimalValue.parse('820'));
  });

  test('クーポン最低利用額を満たさない場合は適用しない', () {
    final result = calculatePrice(
      offer(
        price: '500',
        couponDiscount: '50',
        couponMinimumSubtotal: '1000',
      ),
    );

    expect(result.couponDiscount, DecimalValue.zero);
    expect(result.payableNow, DecimalValue.parse('500'));
  });

  test('送料、ポイント、容量単価を計算する', () {
    final result = calculatePrice(
      offer(
        price: '330',
        pointRate: '0.05',
        quantity: PriceQuantity(
          value: DecimalValue.parse('1000'),
          unit: PriceUnit.milliliter,
        ),
      ),
      context: PurchaseContext(shippingFee: DecimalValue.parse('80')),
    );

    expect(result.payableNow, DecimalValue.parse('410'));
    expect(result.earnedPoints, DecimalValue.parse('20'));
    expect(result.effectiveCost, DecimalValue.parse('390'));
    expect(result.cashUnitCost, DecimalValue.parse('0.410000'));
    expect(result.effectiveUnitCost, DecimalValue.parse('0.390000'));
  });

  test('税の丸め規則で切り捨てと切り上げを切り替えられる', () {
    final target = offer(price: '99', taxIncluded: false);

    final down = calculatePrice(
      target,
      policy: CalculationPolicy(taxRounding: MoneyRounding.down),
    );
    final up = calculatePrice(
      target,
      policy: CalculationPolicy(taxRounding: MoneyRounding.up),
    );

    expect(down.taxAmount, DecimalValue.parse('9'));
    expect(up.taxAmount, DecimalValue.parse('10'));
  });
}
