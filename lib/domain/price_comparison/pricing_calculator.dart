/// lib/domain/price_comparison/pricing_calculator.dart
///
/// 単一商品の税・割引・送料・ポイント・容量単価を順番に計算する純粋関数。
/// UIや保存処理に依存せず、同じ入力から常に同じ内訳を得るために存在する。
///
/// 関連:
///   - models.dart
///   - comparison_engine.dart
library;

import 'models.dart';

const int _rateScale = 1000000;

int _scaledRate(double rate) => (rate * _rateScale).round();

int _roundRatio(
  int value,
  int numerator,
  int denominator,
  MoneyRounding rounding,
) {
  final dividend = BigInt.from(value) * BigInt.from(numerator);
  final divisor = BigInt.from(denominator);
  final quotient = dividend ~/ divisor;
  final remainder = dividend.remainder(divisor);
  final increment = switch (rounding) {
    MoneyRounding.halfUp => remainder * BigInt.two >= divisor,
    MoneyRounding.down => false,
    MoneyRounding.up => remainder > BigInt.zero,
  };
  return (increment ? quotient + BigInt.one : quotient).toInt();
}

PriceBreakdown calculatePrice(
  Offer offer, {
  PurchaseContext context = const PurchaseContext(),
  CalculationPolicy policy = const CalculationPolicy(),
}) {
  final warnings = <WarningCode>[];
  final taxRate = _scaledRate(offer.taxRate);

  final int preTaxPrice;
  final int taxAmount;
  final int basePriceInclTax;
  if (taxRate == 0) {
    preTaxPrice = offer.price;
    taxAmount = 0;
    basePriceInclTax = offer.price;
  } else if (offer.taxIncluded) {
    taxAmount = _roundRatio(
      offer.price,
      taxRate,
      _rateScale + taxRate,
      policy.taxRounding,
    );
    preTaxPrice = offer.price - taxAmount;
    basePriceInclTax = offer.price;
  } else {
    preTaxPrice = offer.price;
    taxAmount = _roundRatio(
      offer.price,
      taxRate,
      _rateScale,
      policy.taxRounding,
    );
    basePriceInclTax = offer.price + taxAmount;
  }

  var current = basePriceInclTax;
  var discountAmount = 0;
  final percentageRate = _scaledRate(offer.percentageDiscount);
  if (percentageRate > 0) {
    var percentageAmount = _roundRatio(
      current,
      percentageRate,
      _rateScale,
      policy.discountRounding,
    );
    if (percentageAmount > current) {
      percentageAmount = current;
      warnings.add(WarningCode.discountExceedsPrice);
    }
    current -= percentageAmount;
    discountAmount += percentageAmount;
  }

  if (offer.fixedDiscount > 0) {
    final fixedActual = offer.fixedDiscount > current
        ? current
        : offer.fixedDiscount;
    if (offer.fixedDiscount > current) {
      warnings.add(WarningCode.discountExceedsPrice);
    }
    current -= fixedActual;
    discountAmount += fixedActual;
  }

  var couponActual = 0;
  final couponEligible = offer.couponMinimumSubtotal == null ||
      basePriceInclTax >= offer.couponMinimumSubtotal!;
  if (couponEligible && offer.couponDiscount > 0) {
    couponActual = offer.couponDiscount > current
        ? current
        : offer.couponDiscount;
    if (offer.couponDiscount > current) {
      warnings.add(WarningCode.couponExceedsRemaining);
    }
    current -= couponActual;
    discountAmount += couponActual;
  }

  final configuredShipping = context.shippingFee ?? offer.shippingFee;
  final shippingFee = context.shippingAllocation == ShippingAllocation.excluded
      ? null
      : configuredShipping;
  if (shippingFee != null &&
      context.shippingAllocation == ShippingAllocation.fullOrder) {
    warnings.add(WarningCode.shippingFullOrder);
  }

  final payableNow = context.checkoutTotalOverride ??
      current + (shippingFee ?? 0);

  int? earnedPoints;
  if (offer.earnedPoints != null) {
    earnedPoints = offer.earnedPoints;
  } else {
    final pointRate = _scaledRate(offer.pointRate);
    if (pointRate > 0 || offer.fixedPoints > 0) {
      earnedPoints = _roundRatio(
            payableNow,
            pointRate,
            _rateScale,
            MoneyRounding.down,
          ) +
          offer.fixedPoints;
    }
  }

  int? pointValue;
  int? effectiveCost;
  if (earnedPoints == null) {
    warnings.add(WarningCode.pointsMissing);
  } else {
    pointValue = _roundRatio(
      earnedPoints,
      _scaledRate(policy.pointValueRate),
      _rateScale,
      policy.discountRounding,
    );
    effectiveCost = payableNow - pointValue;
    if (pointValue > payableNow) {
      warnings.add(WarningCode.pointsExceedPayable);
    }
    if (effectiveCost < 0) {
      warnings.add(WarningCode.negativeEffectiveCost);
    }
  }

  double? normalizedQuantity;
  Unit? quantityUnit;
  Dimension? quantityDimension;
  MeasureKind? measureKind;
  double? cashUnitCost;
  double? effectiveUnitCost;
  final quantity = offer.quantity;
  if (quantity != null) {
    if (quantity.value <= 0 || quantity.normalizedTotal <= 0) {
      warnings.add(WarningCode.quantityZero);
    } else {
      normalizedQuantity = quantity.normalizedTotal;
      quantityUnit = quantity.unit;
      quantityDimension = quantity.dimension;
      measureKind = quantity.measureKind;
      cashUnitCost = payableNow / normalizedQuantity;
      if (effectiveCost != null && effectiveCost >= 0) {
        effectiveUnitCost = effectiveCost / normalizedQuantity;
      }
    }
  }

  return PriceBreakdown(
    displayPrice: offer.price,
    taxIncluded: offer.taxIncluded,
    taxRate: offer.taxRate,
    preTaxPrice: preTaxPrice,
    taxAmount: taxAmount,
    basePriceInclTax: basePriceInclTax,
    percentageDiscount: offer.percentageDiscount,
    fixedDiscount: offer.fixedDiscount,
    couponDiscount: couponActual,
    discountAmount: discountAmount,
    shippingFee: shippingFee,
    payableNow: payableNow,
    earnedPoints: earnedPoints,
    pointValue: pointValue,
    effectiveCost: effectiveCost,
    normalizedQuantity: normalizedQuantity,
    quantityUnit: quantityUnit,
    quantityDimension: quantityDimension,
    measureKind: measureKind,
    cashUnitCost: cashUnitCost,
    effectiveUnitCost: effectiveUnitCost,
    cashComplete: true,
    rewardComplete: effectiveCost != null,
    unitComplete: cashUnitCost != null,
    warnings: List<WarningCode>.unmodifiable(warnings),
  );
}
