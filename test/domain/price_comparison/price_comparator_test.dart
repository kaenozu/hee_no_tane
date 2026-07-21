import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/price_comparison/price_comparator.dart';
import 'package:hee_no_tane_app/domain/price_comparison/price_comparison_models.dart';

void main() {
  PriceBreakdown breakdown({
    String? payableNow,
    String? effectiveCost,
    String? cashUnitCost,
    String? effectiveUnitCost,
    String? normalizedQuantity,
  }) => PriceBreakdown(
    displayPrice: DecimalValue.zero,
    taxIncluded: true,
    taxRate: DecimalValue.parse('0.10'),
    payableNow: payableNow == null ? null : DecimalValue.parse(payableNow),
    effectiveCost: effectiveCost == null
        ? null
        : DecimalValue.parse(effectiveCost),
    cashUnitCost: cashUnitCost == null
        ? null
        : DecimalValue.parse(cashUnitCost),
    effectiveUnitCost: effectiveUnitCost == null
        ? null
        : DecimalValue.parse(effectiveUnitCost),
    normalizedQuantity: normalizedQuantity == null
        ? null
        : DecimalValue.parse(normalizedQuantity),
    cashComplete: payableNow != null,
    rewardComplete: effectiveCost != null,
    unitComplete: cashUnitCost != null,
  );

  test('実質単価を優先して3件を安い順に並べる', () {
    final result = rankOffers(<String, PriceBreakdown>{
      'a': breakdown(effectiveUnitCost: '0.5'),
      'b': breakdown(effectiveUnitCost: '0.3'),
      'c': breakdown(effectiveUnitCost: '0.4'),
    });

    expect(result.basis, ComparisonBasis.effectiveUnitCost);
    expect(result.rankedIds, <String>['b', 'c', 'a']);
    expect(result.bestId, 'b');
    expect(result.difference, DecimalValue.parse('0.1'));
  });

  test('単価とポイント情報がなければ支払総額にフォールバックする', () {
    final result = rankOffers(<String, PriceBreakdown>{
      'left': breakdown(payableNow: '500'),
      'right': breakdown(payableNow: '400'),
    });

    expect(result.basis, ComparisonBasis.cashTotal);
    expect(result.bestId, 'right');
    expect(result.canCompare, isTrue);
  });

  test('最安値が同額ならbestIdを返さない', () {
    final result = rankOffers(<String, PriceBreakdown>{
      'left': breakdown(cashUnitCost: '0.5'),
      'right': breakdown(cashUnitCost: '0.5'),
    });

    expect(result.bestId, isNull);
    expect(result.difference, DecimalValue.zero);
  });

  test('2件以上だけが共通基準を持つ場合は残りを比較対象外にする', () {
    final result = rankOffers(<String, PriceBreakdown>{
      'a': breakdown(effectiveUnitCost: '0.5'),
      'b': breakdown(effectiveUnitCost: '0.3'),
      'c': breakdown(payableNow: '100'),
    });

    expect(result.rankedIds, <String>['b', 'a']);
    expect(result.incomparableIds, <String>['c']);
    expect(result.canCompare, isTrue);
  });
}
