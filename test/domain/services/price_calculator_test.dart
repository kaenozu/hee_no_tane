/// test/domain/services/price_calculator_test.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/price_comparison.dart';
import 'package:hee_no_tane_app/domain/services/price_calculator.dart';

void main() {
  const calculator = PriceCalculator();

  group('PriceCalculator.calculate', () {
    test('adds tax to tax-exclusive prices', () {
      final result = calculator.calculate(
        const PriceOffer(
          id: 'a',
          productName: '商品A',
          storeName: '店舗A',
          price: 1000,
          taxIncluded: false,
          taxRate: 0.1,
        ),
      );

      expect(result.preTaxPrice, 1000);
      expect(result.taxAmount, 100);
      expect(result.payableNow, 1100);
    });

    test('applies percentage, fixed and coupon discounts in order', () {
      final result = calculator.calculate(
        const PriceOffer(
          id: 'a',
          productName: '商品A',
          storeName: '店舗A',
          price: 1000,
          percentageDiscount: 0.1,
          fixedDiscount: 50,
          couponDiscount: 100,
        ),
      );

      expect(result.discountAmount, 250);
      expect(result.payableNow, 750);
    });

    test('calculates points and normalized unit cost', () {
      final result = calculator.calculate(
        const PriceOffer(
          id: 'a',
          productName: '商品A',
          storeName: '店舗A',
          price: 1000,
          pointRate: 0.1,
          quantity: PriceQuantity(value: 1, unit: PriceUnit.kilogram),
        ),
      );

      expect(result.earnedPoints, 100);
      expect(result.effectiveCost, 900);
      expect(result.normalizedQuantity, 1000);
      expect(result.effectiveUnitCost, 0.9);
    });

    test('caps excessive discounts and emits a warning', () {
      final result = calculator.calculate(
        const PriceOffer(
          id: 'a',
          productName: '商品A',
          storeName: '店舗A',
          price: 100,
          fixedDiscount: 200,
        ),
      );

      expect(result.payableNow, 0);
      expect(result.warnings, contains(PriceWarning.discountExceedsPrice));
    });
  });

  group('PriceCalculator.compare', () {
    test('prefers effective unit cost and ranks cheapest first', () {
      final first = calculator.calculate(
        const PriceOffer(
          id: 'a',
          productName: '商品A',
          storeName: '店舗A',
          price: 1000,
          earnedPoints: 0,
          quantity: PriceQuantity(value: 1000, unit: PriceUnit.gram),
        ),
      );
      final second = calculator.calculate(
        const PriceOffer(
          id: 'b',
          productName: '商品B',
          storeName: '店舗B',
          price: 900,
          earnedPoints: 0,
          quantity: PriceQuantity(value: 800, unit: PriceUnit.gram),
        ),
      );

      final result = calculator.compare({'a': first, 'b': second});

      expect(result.basis, ComparisonBasis.effectiveUnitCost);
      expect(result.bestId, 'a');
      expect(result.rankedIds, ['a', 'b']);
      expect(result.canCompare, isTrue);
    });

    test('falls back to total when quantities are missing', () {
      final first = calculator.calculate(
        const PriceOffer(
          id: 'a',
          productName: '商品A',
          storeName: '店舗A',
          price: 1000,
          earnedPoints: 0,
        ),
      );
      final second = calculator.calculate(
        const PriceOffer(
          id: 'b',
          productName: '商品B',
          storeName: '店舗B',
          price: 900,
          earnedPoints: 0,
        ),
      );

      final result = calculator.compare({'a': first, 'b': second});

      expect(result.basis, ComparisonBasis.effectiveTotal);
      expect(result.bestId, 'b');
    });
  });
}
