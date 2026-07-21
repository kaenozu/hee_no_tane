/// lib/domain/services/price_calculator.dart
///
/// 単一商品の価格計算と複数商品の順位付けを行う純粋関数群。
library;

import 'dart:math' as math;

import 'package:hee_no_tane_app/domain/models/price_comparison.dart';

class PriceCalculator {
  const PriceCalculator();

  PriceBreakdown calculate(
    PriceOffer offer, {
    PurchaseContext context = const PurchaseContext(),
    CalculationPolicy policy = const CalculationPolicy(),
  }) {
    _validateOffer(offer);
    _validateContext(context);

    final warnings = <PriceWarning>[];
    final tax = _calculateTax(offer, policy);
    final discounts = _calculateDiscounts(
      basePrice: tax.gross,
      offer: offer,
      policy: policy,
    );
    warnings.addAll(discounts.warnings);

    final shippingFee = context.shippingAllocation == ShippingAllocation.excluded
        ? null
        : context.shippingFee;
    if (shippingFee != null &&
        context.shippingAllocation == ShippingAllocation.fullOrder) {
      warnings.add(PriceWarning.shippingFullOrder);
    }

    final payableNow = discounts.afterDiscount + (shippingFee ?? 0);
    final earnedPoints = offer.earnedPoints ??
        ((offer.pointRate > 0 || offer.fixedPoints > 0)
            ? _roundDown(payableNow * offer.pointRate) + offer.fixedPoints
            : null);

    double? pointValue;
    double? effectiveCost;
    if (earnedPoints == null) {
      warnings.add(PriceWarning.pointsMissing);
    } else {
      pointValue = _round(
        earnedPoints * policy.pointValueRate,
        policy.discountRounding,
      );
      effectiveCost = payableNow - pointValue;
      if (effectiveCost < 0) warnings.add(PriceWarning.negativeEffectiveCost);
    }

    double? normalizedQuantity;
    String? quantityUnit;
    double? cashUnitCost;
    double? effectiveUnitCost;
    final quantity = offer.quantity;
    if (quantity != null) {
      if (quantity.value == 0) {
        warnings.add(PriceWarning.quantityZero);
      } else {
        normalizedQuantity = quantity.normalizedTotal;
        quantityUnit = quantity.unit.normalizedSymbol;
        if (payableNow > 0) {
          cashUnitCost = _roundTo(payableNow / normalizedQuantity, 6);
        }
        if (effectiveCost != null && effectiveCost >= 0) {
          effectiveUnitCost = _roundTo(effectiveCost / normalizedQuantity, 6);
        }
      }
    }

    return PriceBreakdown(
      displayPrice: offer.price,
      taxIncluded: offer.taxIncluded,
      taxRate: offer.taxRate,
      preTaxPrice: tax.preTax,
      taxAmount: tax.tax,
      basePriceInclTax: tax.gross,
      percentageDiscount: offer.percentageDiscount,
      fixedDiscount: offer.fixedDiscount,
      couponDiscount: discounts.couponActual,
      discountAmount: discounts.discountTotal,
      shippingFee: shippingFee,
      payableNow: payableNow,
      earnedPoints: earnedPoints,
      pointValue: pointValue,
      effectiveCost: effectiveCost,
      normalizedQuantity: normalizedQuantity,
      quantityUnit: quantityUnit,
      cashUnitCost: cashUnitCost,
      effectiveUnitCost: effectiveUnitCost,
      warnings: List.unmodifiable(warnings),
    );
  }

  PriceComparisonResult compare(Map<String, PriceBreakdown> breakdowns) {
    if (breakdowns.length < 2) {
      return PriceComparisonResult(
        basis: ComparisonBasis.cashTotal,
        breakdowns: breakdowns,
        incomparableIds: breakdowns.keys.toList(growable: false),
        warnings: const [PriceWarning.cannotCompare],
      );
    }

    final warnings = <PriceWarning>[];
    final withQuantity = breakdowns.values
        .where((breakdown) => breakdown.normalizedQuantity != null)
        .length;
    if (withQuantity > 0 && withQuantity < breakdowns.length) {
      warnings.add(PriceWarning.quantityMissing);
    }

    final basis = _bestBasis(breakdowns.values);
    if (basis == null) {
      return PriceComparisonResult(
        basis: ComparisonBasis.cashTotal,
        breakdowns: breakdowns,
        incomparableIds: breakdowns.keys.toList(growable: false),
        warnings: [...warnings, PriceWarning.cannotCompare],
      );
    }

    final values = <String, double>{};
    final incomparable = <String>[];
    for (final entry in breakdowns.entries) {
      final value = _valueFor(entry.value, basis);
      if (value == null) {
        incomparable.add(entry.key);
      } else {
        values[entry.key] = value;
      }
    }

    final rankedIds = values.keys.toList()
      ..sort((left, right) => values[left]!.compareTo(values[right]!));
    final best = values[rankedIds[0]]!;
    final second = values[rankedIds[1]]!;
    final difference = second - best;
    final average = (best + second) / 2;

    return PriceComparisonResult(
      basis: basis,
      breakdowns: breakdowns,
      rankedIds: List.unmodifiable(rankedIds),
      bestId: difference == 0 ? null : rankedIds.first,
      values: Map.unmodifiable(values),
      difference: difference,
      percentageDifference: average > 0
          ? _roundTo((difference / average) * 100, 2)
          : null,
      incomparableIds: List.unmodifiable(incomparable),
      canCompare: true,
      warnings: List.unmodifiable(warnings),
    );
  }

  _TaxResult _calculateTax(PriceOffer offer, CalculationPolicy policy) {
    if (offer.taxRate == 0) {
      return _TaxResult(offer.price, 0, offer.price);
    }
    if (offer.taxIncluded) {
      final tax = _round(
        offer.price * offer.taxRate / (1 + offer.taxRate),
        policy.taxRounding,
      );
      return _TaxResult(offer.price - tax, tax, offer.price);
    }
    final tax = _round(offer.price * offer.taxRate, policy.taxRounding);
    return _TaxResult(offer.price, tax, offer.price + tax);
  }

  _DiscountResult _calculateDiscounts({
    required double basePrice,
    required PriceOffer offer,
    required CalculationPolicy policy,
  }) {
    final warnings = <PriceWarning>[];
    var current = basePrice;
    var percentageAmount = 0.0;
    var fixedAmount = 0.0;

    if (offer.percentageDiscount > 0) {
      percentageAmount = _round(
        current * offer.percentageDiscount,
        policy.discountRounding,
      );
      if (percentageAmount > current) {
        warnings.add(PriceWarning.discountExceedsPrice);
        percentageAmount = current;
      }
      current -= percentageAmount;
    }

    if (offer.fixedDiscount > 0) {
      fixedAmount = math.min(offer.fixedDiscount, current);
      if (offer.fixedDiscount > current) {
        warnings.add(PriceWarning.discountExceedsPrice);
      }
      current -= fixedAmount;
    }

    var couponActual = 0.0;
    final couponEligible = offer.couponMinimumSubtotal == null ||
        basePrice >= offer.couponMinimumSubtotal!;
    if (offer.couponDiscount > 0 && couponEligible) {
      couponActual = math.min(offer.couponDiscount, current);
      if (offer.couponDiscount > current) {
        warnings.add(PriceWarning.couponExceedsRemaining);
      }
      current -= couponActual;
    }

    return _DiscountResult(
      afterDiscount: current,
      discountTotal: percentageAmount + fixedAmount + couponActual,
      couponActual: couponActual,
      warnings: warnings,
    );
  }

  ComparisonBasis? _bestBasis(Iterable<PriceBreakdown> breakdowns) {
    for (final basis in ComparisonBasis.values) {
      if (breakdowns.where((item) => _valueFor(item, basis) != null).length >= 2) {
        return basis;
      }
    }
    return null;
  }

  double? _valueFor(PriceBreakdown breakdown, ComparisonBasis basis) =>
      switch (basis) {
        ComparisonBasis.effectiveUnitCost => breakdown.effectiveUnitCost,
        ComparisonBasis.cashUnitCost => breakdown.cashUnitCost,
        ComparisonBasis.effectiveTotal => breakdown.effectiveCost,
        ComparisonBasis.cashTotal => breakdown.payableNow,
      };

  void _validateOffer(PriceOffer offer) {
    if (!offer.price.isFinite || offer.price < 0) {
      throw const FormatException('価格は0以上で入力してください。');
    }
    if (!offer.taxRate.isFinite || offer.taxRate < 0 || offer.taxRate > 1) {
      throw const FormatException('税率が不正です。');
    }
    if (offer.percentageDiscount < 0 || offer.percentageDiscount > 1) {
      throw const FormatException('割引率は0〜100%で入力してください。');
    }
    if (offer.pointRate < 0 || offer.pointRate > 1) {
      throw const FormatException('ポイント率は0〜100%で入力してください。');
    }
    final quantity = offer.quantity;
    if (quantity != null &&
        (!quantity.value.isFinite ||
            quantity.value < 0 ||
            quantity.packageCount <= 0)) {
      throw const FormatException('数量が不正です。');
    }
  }

  void _validateContext(PurchaseContext context) {
    final shipping = context.shippingFee;
    if (shipping != null && (!shipping.isFinite || shipping < 0)) {
      throw const FormatException('送料は0以上で入力してください。');
    }
  }

  double _round(double value, MoneyRounding rounding) => switch (rounding) {
    MoneyRounding.halfUp => value >= 0
        ? (value + 0.5).floorToDouble()
        : (value - 0.5).ceilToDouble(),
    MoneyRounding.down => value.truncateToDouble(),
    MoneyRounding.up => value == value.truncateToDouble()
        ? value
        : value > 0
            ? value.ceilToDouble()
            : value.floorToDouble(),
  };

  double _roundDown(double value) => value.floorToDouble();

  double _roundTo(double value, int scale) {
    final factor = math.pow(10, scale).toDouble();
    return ((value * factor) + 0.5).floorToDouble() / factor;
  }
}

class _TaxResult {
  final double preTax;
  final double tax;
  final double gross;

  const _TaxResult(this.preTax, this.tax, this.gross);
}

class _DiscountResult {
  final double afterDiscount;
  final double discountTotal;
  final double couponActual;
  final List<PriceWarning> warnings;

  const _DiscountResult({
    required this.afterDiscount,
    required this.discountTotal,
    required this.couponActual,
    required this.warnings,
  });
}
