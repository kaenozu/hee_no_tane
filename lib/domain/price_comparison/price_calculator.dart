/// lib/domain/price_comparison/price_calculator.dart
///
/// Python版 price_compare の計算順序と丸め規則を固定小数で再現する。
/// 公開モデルは既存APIとの互換性を保つため double のまま維持する。
library;

import 'package:hee_no_tane_app/domain/models/price_comparison.dart';

import 'decimal_value.dart';

class PriceCalculator {
  const PriceCalculator();

  PriceBreakdown calculate(
    PriceOffer offer, {
    PurchaseContext context = const PurchaseContext(),
    CalculationPolicy policy = const CalculationPolicy(),
  }) {
    _validateOffer(offer);
    _validateContext(context);
    _validatePolicy(policy);

    final warnings = <PriceWarning>[];
    final tax = _calculateTax(offer, policy);
    final discounts = _calculateDiscounts(
      basePrice: tax.gross,
      offer: offer,
      policy: policy,
    );
    warnings.addAll(discounts.warnings);

    final shippingFee =
        context.shippingAllocation == ShippingAllocation.excluded
        ? null
        : context.shippingFee == null
        ? null
        : _decimal(context.shippingFee!);
    if (shippingFee != null &&
        context.shippingAllocation == ShippingAllocation.fullOrder) {
      warnings.add(PriceWarning.shippingFullOrder);
    }

    final payableNow =
        discounts.afterDiscount + (shippingFee ?? DecimalValue.zero);
    final earnedPoints = _calculatePoints(offer, payableNow);

    DecimalValue? pointValue;
    DecimalValue? effectiveCost;
    if (earnedPoints == null) {
      warnings.add(PriceWarning.pointsMissing);
    } else {
      pointValue = (earnedPoints * _decimal(policy.pointValueRate)).quantize(
        0,
        rounding: _rounding(policy.discountRounding),
      );
      effectiveCost = payableNow - pointValue;
      if (effectiveCost.isNegative) {
        warnings.add(PriceWarning.negativeEffectiveCost);
      }
    }

    DecimalValue? normalizedQuantity;
    String? quantityUnit;
    DecimalValue? cashUnitCost;
    DecimalValue? effectiveUnitCost;
    final quantity = offer.quantity;
    if (quantity != null) {
      final quantityValue = _decimal(quantity.value);
      if (quantityValue.isZero) {
        warnings.add(PriceWarning.quantityZero);
      } else {
        normalizedQuantity =
            quantityValue *
            DecimalValue.fromInt(_unitFactor(quantity.unit)) *
            DecimalValue.fromInt(quantity.packageCount);
        quantityUnit = quantity.unit.normalizedSymbol;
        if (payableNow.isPositive) {
          cashUnitCost = payableNow.divide(
            normalizedQuantity,
            resultScale: 6,
            rounding: DecimalRounding.halfUp,
          );
        }
        if (effectiveCost != null && !effectiveCost.isNegative) {
          effectiveUnitCost = effectiveCost.divide(
            normalizedQuantity,
            resultScale: 6,
            rounding: DecimalRounding.halfUp,
          );
        }
      }
    }

    return PriceBreakdown(
      displayPrice: offer.price,
      taxIncluded: offer.taxIncluded,
      taxRate: offer.taxRate,
      preTaxPrice: tax.preTax.toDouble(),
      taxAmount: tax.tax.toDouble(),
      basePriceInclTax: tax.gross.toDouble(),
      percentageDiscount: offer.percentageDiscount,
      fixedDiscount: offer.fixedDiscount,
      couponDiscount: discounts.couponActual.toDouble(),
      discountAmount: discounts.discountTotal.toDouble(),
      shippingFee: shippingFee?.toDouble(),
      payableNow: payableNow.toDouble(),
      earnedPoints: earnedPoints?.toDouble(),
      pointValue: pointValue?.toDouble(),
      effectiveCost: effectiveCost?.toDouble(),
      normalizedQuantity: normalizedQuantity?.toDouble(),
      quantityUnit: quantityUnit,
      cashUnitCost: cashUnitCost?.toDouble(),
      effectiveUnitCost: effectiveUnitCost?.toDouble(),
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

    final basisSelection = _bestBasis(breakdowns);
    if (basisSelection.dimensionMismatch) {
      warnings.add(PriceWarning.dimensionMismatch);
    }
    final basis = basisSelection.basis;
    if (basis == null) {
      return PriceComparisonResult(
        basis: ComparisonBasis.cashTotal,
        breakdowns: breakdowns,
        incomparableIds: breakdowns.keys.toList(growable: false),
        warnings: [...warnings, PriceWarning.cannotCompare],
      );
    }

    final values = <String, DecimalValue>{};
    final incomparable = <String>[];
    for (final entry in breakdowns.entries) {
      final value = _valueFor(entry.value, basis);
      if (value == null) {
        incomparable.add(entry.key);
      } else {
        values[entry.key] = _decimal(value);
      }
    }

    final rankedIds = values.keys.toList()
      ..sort((left, right) => values[left]!.compareTo(values[right]!));
    final best = values[rankedIds[0]]!;
    final second = values[rankedIds[1]]!;
    final difference = second - best;
    final sum = best + second;
    final percentageDifference = sum.isPositive
        ? (difference * DecimalValue.fromInt(200)).divide(
            sum,
            resultScale: 2,
            rounding: DecimalRounding.halfUp,
          )
        : null;

    return PriceComparisonResult(
      basis: basis,
      breakdowns: breakdowns,
      rankedIds: List.unmodifiable(rankedIds),
      bestId: difference.isZero ? null : rankedIds.first,
      values: Map.unmodifiable(
        values.map((key, value) => MapEntry(key, value.toDouble())),
      ),
      difference: difference.toDouble(),
      percentageDifference: percentageDifference?.toDouble(),
      incomparableIds: List.unmodifiable(incomparable),
      canCompare: true,
      warnings: List.unmodifiable(warnings),
    );
  }

  ({DecimalValue preTax, DecimalValue tax, DecimalValue gross}) _calculateTax(
    PriceOffer offer,
    CalculationPolicy policy,
  ) {
    final price = _decimal(offer.price);
    final taxRate = _decimal(offer.taxRate);
    if (taxRate.isZero) {
      return (preTax: price, tax: DecimalValue.zero, gross: price);
    }
    if (offer.taxIncluded) {
      final tax = (price * taxRate).divide(
        DecimalValue.one + taxRate,
        resultScale: 0,
        rounding: _rounding(policy.taxRounding),
      );
      return (preTax: price - tax, tax: tax, gross: price);
    }
    final tax = (price * taxRate).quantize(
      0,
      rounding: _rounding(policy.taxRounding),
    );
    return (preTax: price, tax: tax, gross: price + tax);
  }

  ({
    DecimalValue afterDiscount,
    DecimalValue discountTotal,
    DecimalValue couponActual,
    List<PriceWarning> warnings,
  })
  _calculateDiscounts({
    required DecimalValue basePrice,
    required PriceOffer offer,
    required CalculationPolicy policy,
  }) {
    final warnings = <PriceWarning>[];
    final percentageDiscount = _decimal(offer.percentageDiscount);
    final fixedDiscount = _decimal(offer.fixedDiscount);
    final couponDiscount = _decimal(offer.couponDiscount);
    var current = basePrice;
    var percentageActual = DecimalValue.zero;

    if (percentageDiscount.isPositive) {
      var amount = (current * percentageDiscount).quantize(
        0,
        rounding: _rounding(policy.discountRounding),
      );
      if (amount > current) {
        warnings.add(PriceWarning.discountExceedsPrice);
        amount = current;
      }
      percentageActual = amount;
      current -= percentageActual;
    }

    var fixedActual = DecimalValue.zero;
    if (fixedDiscount.isPositive) {
      if (fixedDiscount > current) {
        warnings.add(PriceWarning.discountExceedsPrice);
        fixedActual = current;
      } else {
        fixedActual = fixedDiscount;
      }
      current -= fixedActual;
    }

    var couponActual = DecimalValue.zero;
    if (couponDiscount.isPositive) {
      final minimumSubtotal = offer.couponMinimumSubtotal == null
          ? null
          : _decimal(offer.couponMinimumSubtotal!);
      final eligible = minimumSubtotal == null || basePrice >= minimumSubtotal;
      if (eligible) {
        if (couponDiscount > current) {
          warnings.add(PriceWarning.couponExceedsRemaining);
          couponActual = current;
        } else {
          couponActual = couponDiscount;
        }
        current -= couponActual;
      }
    }

    final discountTotal = percentageActual + fixedActual + couponActual;
    final afterDiscount = current;

    return (
      afterDiscount: afterDiscount,
      discountTotal: discountTotal,
      couponActual: couponActual,
      warnings: warnings,
    );
  }

  DecimalValue? _calculatePoints(PriceOffer offer, DecimalValue payableNow) {
    if (offer.earnedPoints != null) return _decimal(offer.earnedPoints!);
    final pointRate = _decimal(offer.pointRate);
    final fixedPoints = _decimal(offer.fixedPoints);
    if (!pointRate.isPositive && !fixedPoints.isPositive) return null;
    return (payableNow * pointRate).quantize(
          0,
          rounding: DecimalRounding.down,
        ) +
        fixedPoints;
  }

  ({ComparisonBasis? basis, bool dimensionMismatch}) _bestBasis(
    Map<String, PriceBreakdown> breakdowns,
  ) {
    var dimensionMismatch = false;
    for (final basis in ComparisonBasis.values) {
      final available = breakdowns.entries
          .where((entry) => _valueFor(entry.value, basis) != null)
          .toList(growable: false);
      if (available.length < 2) continue;
      if (basis == ComparisonBasis.effectiveUnitCost ||
          basis == ComparisonBasis.cashUnitCost) {
        final units = available
            .map((entry) => entry.value.quantityUnit)
            .whereType<String>()
            .toSet();
        if (units.length != 1) {
          dimensionMismatch = true;
          continue;
        }
      }
      return (basis: basis, dimensionMismatch: dimensionMismatch);
    }
    return (basis: null, dimensionMismatch: dimensionMismatch);
  }

  double? _valueFor(PriceBreakdown breakdown, ComparisonBasis basis) =>
      switch (basis) {
        ComparisonBasis.effectiveUnitCost => breakdown.effectiveUnitCost,
        ComparisonBasis.cashUnitCost => breakdown.cashUnitCost,
        ComparisonBasis.effectiveTotal => breakdown.effectiveCost,
        ComparisonBasis.cashTotal => breakdown.payableNow,
      };

  void _validateOffer(PriceOffer offer) {
    _validateNonNegative(offer.price, '価格');
    _validateRate(offer.taxRate, '税率');
    _validateRate(offer.percentageDiscount, '割引率');
    _validateNonNegative(offer.fixedDiscount, '固定値引き');
    _validateNonNegative(offer.couponDiscount, 'クーポン');
    if (offer.couponMinimumSubtotal != null) {
      _validateNonNegative(offer.couponMinimumSubtotal!, 'クーポン最低利用額');
    }
    _validateRate(offer.pointRate, 'ポイント率');
    _validateNonNegative(offer.fixedPoints, '固定ポイント');
    if (offer.earnedPoints != null) {
      _validateNonNegative(offer.earnedPoints!, '獲得ポイント');
    }
    final quantity = offer.quantity;
    if (quantity != null) {
      _validateNonNegative(quantity.value, '数量');
      if (quantity.packageCount <= 0) {
        throw const FormatException('個数は1以上で入力してください。');
      }
    }
  }

  void _validateContext(PurchaseContext context) {
    if (context.shippingFee != null) {
      _validateNonNegative(context.shippingFee!, '送料');
    }
  }

  void _validatePolicy(CalculationPolicy policy) {
    _validateNonNegative(policy.pointValueRate, 'ポイント価値');
  }

  void _validateRate(double value, String label) {
    if (!value.isFinite || value < 0 || value > 1) {
      throw FormatException('$labelは0〜100%で入力してください。');
    }
  }

  void _validateNonNegative(double value, String label) {
    if (!value.isFinite || value < 0) {
      throw FormatException('$labelは0以上で入力してください。');
    }
  }

  int _unitFactor(PriceUnit unit) => switch (unit) {
    PriceUnit.liter || PriceUnit.kilogram => 1000,
    _ => 1,
  };

  DecimalRounding _rounding(MoneyRounding rounding) => switch (rounding) {
    MoneyRounding.halfUp => DecimalRounding.halfUp,
    MoneyRounding.down => DecimalRounding.down,
    MoneyRounding.up => DecimalRounding.up,
  };

  DecimalValue _decimal(double value) => DecimalValue.fromDouble(value);
}
