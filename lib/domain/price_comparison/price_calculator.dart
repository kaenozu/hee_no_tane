/// lib/domain/price_comparison/price_calculator.dart
///
/// 単一商品の税・値引き・送料・ポイント・容量単価を計算する純粋関数。
/// Python版 price_compare/pricing.py の計算順序と丸め規則を移植する。
library;

import 'price_comparison_models.dart';

PriceBreakdown calculatePrice(
  PriceOffer offer, {
  PurchaseContext? context,
  CalculationPolicy? policy,
}) {
  final actualContext = context ?? const PurchaseContext();
  final actualPolicy = policy ?? CalculationPolicy();
  final warnings = <PriceWarning>[];

  final tax = _calculateTax(
    price: offer.price,
    taxIncluded: offer.taxIncluded,
    taxRate: offer.taxRate,
    policy: actualPolicy,
  );

  final discounts = _calculateDiscounts(
    basePrice: tax.basePriceInclTax,
    percentageDiscount: offer.percentageDiscount,
    fixedDiscount: offer.fixedDiscount,
    couponDiscount: offer.couponDiscount,
    couponMinimumSubtotal: offer.couponMinimumSubtotal,
    policy: actualPolicy,
  );
  warnings.addAll(discounts.warnings);

  DecimalValue? shippingFee;
  if (actualContext.shippingFee != null) {
    shippingFee = actualContext.shippingFee;
    if (actualContext.shippingAllocation == ShippingAllocation.fullOrder) {
      warnings.add(PriceWarning.shippingFullOrder);
    }
  }

  var payableNow = discounts.afterDiscount;
  if (shippingFee != null) payableNow += shippingFee;

  DecimalValue? earnedPoints;
  if (offer.earnedPoints != null) {
    earnedPoints = offer.earnedPoints;
  } else if (offer.pointRate.isPositive || offer.fixedPoints.isPositive) {
    final pointsFromRate = (payableNow * offer.pointRate).quantize(
      0,
      rounding: MoneyRounding.down,
    );
    earnedPoints = pointsFromRate + offer.fixedPoints;
  }

  DecimalValue? pointValue;
  DecimalValue? effectiveCost;
  if (earnedPoints != null) {
    pointValue = (earnedPoints * actualPolicy.pointValueRate).quantize(
      0,
      rounding: actualPolicy.discountRounding,
    );
    effectiveCost = payableNow - pointValue;
    if (effectiveCost.isNegative) {
      warnings.add(PriceWarning.negativeEffectiveCost);
    }
  } else {
    warnings.add(PriceWarning.pointsMissing);
  }

  DecimalValue? normalizedQuantity;
  String? quantityUnit;
  DecimalValue? cashUnitCost;
  DecimalValue? effectiveUnitCost;
  final quantity = offer.quantity;
  if (quantity != null && quantity.value.isPositive) {
    normalizedQuantity = quantity.normalizedTotal();
    quantityUnit = quantity.unit.symbol;
    if (payableNow.isPositive) {
      cashUnitCost = payableNow.divide(
        normalizedQuantity,
        resultScale: 6,
        rounding: MoneyRounding.halfUp,
      );
    }
    if (effectiveCost != null &&
        !effectiveCost.isNegative &&
        normalizedQuantity.isPositive) {
      effectiveUnitCost = effectiveCost.divide(
        normalizedQuantity,
        resultScale: 6,
        rounding: MoneyRounding.halfUp,
      );
    }
  } else if (quantity != null && quantity.value.isZero) {
    warnings.add(PriceWarning.quantityZero);
  }

  return PriceBreakdown(
    displayPrice: offer.price,
    taxIncluded: offer.taxIncluded,
    taxRate: offer.taxRate,
    preTaxPrice: tax.preTaxPrice,
    taxAmount: tax.taxAmount,
    basePriceInclTax: tax.basePriceInclTax,
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
    cashComplete: true,
    rewardComplete: effectiveCost != null,
    unitComplete: cashUnitCost != null && normalizedQuantity != null,
    warnings: warnings,
  );
}

({
  DecimalValue preTaxPrice,
  DecimalValue taxAmount,
  DecimalValue basePriceInclTax,
})
_calculateTax({
  required DecimalValue price,
  required bool taxIncluded,
  required DecimalValue taxRate,
  required CalculationPolicy policy,
}) {
  if (taxRate.isZero) {
    return (
      preTaxPrice: price,
      taxAmount: DecimalValue.zero,
      basePriceInclTax: price,
    );
  }

  if (taxIncluded) {
    final gross = price;
    final tax = (gross * taxRate).divide(
      DecimalValue.one + taxRate,
      resultScale: 0,
      rounding: policy.taxRounding,
    );
    return (preTaxPrice: gross - tax, taxAmount: tax, basePriceInclTax: gross);
  }

  final tax = (price * taxRate).quantize(0, rounding: policy.taxRounding);
  return (preTaxPrice: price, taxAmount: tax, basePriceInclTax: price + tax);
}

({
  DecimalValue afterDiscount,
  DecimalValue discountTotal,
  DecimalValue couponActual,
  List<PriceWarning> warnings,
})
_calculateDiscounts({
  required DecimalValue basePrice,
  required DecimalValue percentageDiscount,
  required DecimalValue fixedDiscount,
  required DecimalValue couponDiscount,
  required DecimalValue? couponMinimumSubtotal,
  required CalculationPolicy policy,
}) {
  final warnings = <PriceWarning>[];
  var current = basePrice;

  if (percentageDiscount.isPositive) {
    var amount = (current * percentageDiscount).quantize(
      0,
      rounding: policy.discountRounding,
    );
    if (amount > current) {
      warnings.add(PriceWarning.discountExceedsPrice);
      amount = current;
    }
    current -= amount;
  }

  if (fixedDiscount.isPositive) {
    if (fixedDiscount > current) {
      warnings.add(PriceWarning.discountExceedsPrice);
      current = DecimalValue.zero;
    } else {
      current -= fixedDiscount;
    }
  }

  var couponActual = DecimalValue.zero;
  if (couponDiscount.isPositive) {
    final meetsMinimum =
        couponMinimumSubtotal == null || basePrice >= couponMinimumSubtotal;
    if (meetsMinimum) {
      if (couponDiscount > current) {
        warnings.add(PriceWarning.couponExceedsRemaining);
        couponActual = current;
      } else {
        couponActual = couponDiscount;
      }
      current -= couponActual;
    }
  }

  var discountTotal = percentageDiscount.isPositive
      ? (percentageDiscount * basePrice).quantize(
          0,
          rounding: policy.discountRounding,
        )
      : DecimalValue.zero;
  discountTotal += fixedDiscount;
  discountTotal += couponActual;

  var afterDiscount = basePrice - discountTotal;
  if (afterDiscount.isNegative) afterDiscount = DecimalValue.zero;

  return (
    afterDiscount: afterDiscount,
    discountTotal: discountTotal,
    couponActual: couponActual,
    warnings: warnings,
  );
}
