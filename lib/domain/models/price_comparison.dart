/// lib/domain/models/price_comparison.dart
///
/// 価格比較機能の入力・出力モデル。
library;

enum MoneyRounding { halfUp, down, up }

enum PriceUnit { milliliter, liter, gram, kilogram, piece }

enum ComparisonBasis {
  effectiveUnitCost,
  cashUnitCost,
  effectiveTotal,
  cashTotal,
}

enum ShippingAllocation { fullOrder, allocatedToItem, excluded, unknown }

enum PriceWarning {
  pointsMissing,
  quantityMissing,
  shippingFullOrder,
  discountExceedsPrice,
  couponExceedsRemaining,
  negativeEffectiveCost,
  quantityZero,
  cannotCompare,
}

extension PriceUnitX on PriceUnit {
  double get factor => switch (this) {
    PriceUnit.liter || PriceUnit.kilogram => 1000,
    _ => 1,
  };

  String get symbol => switch (this) {
    PriceUnit.milliliter => 'ml',
    PriceUnit.liter => 'L',
    PriceUnit.gram => 'g',
    PriceUnit.kilogram => 'kg',
    PriceUnit.piece => '個',
  };

  String get normalizedSymbol => switch (this) {
    PriceUnit.milliliter || PriceUnit.liter => 'ml',
    PriceUnit.gram || PriceUnit.kilogram => 'g',
    PriceUnit.piece => '個',
  };
}

class PriceQuantity {
  final double value;
  final PriceUnit unit;
  final int packageCount;

  const PriceQuantity({
    required this.value,
    required this.unit,
    this.packageCount = 1,
  });

  double get normalizedTotal => value * unit.factor * packageCount;
}

class PriceOffer {
  final String id;
  final String productName;
  final String storeName;
  final double price;
  final bool taxIncluded;
  final double taxRate;
  final PriceQuantity? quantity;
  final double percentageDiscount;
  final double fixedDiscount;
  final double couponDiscount;
  final double? couponMinimumSubtotal;
  final double pointRate;
  final double fixedPoints;
  final double? earnedPoints;

  const PriceOffer({
    required this.id,
    required this.productName,
    required this.storeName,
    required this.price,
    this.taxIncluded = true,
    this.taxRate = 0.1,
    this.quantity,
    this.percentageDiscount = 0,
    this.fixedDiscount = 0,
    this.couponDiscount = 0,
    this.couponMinimumSubtotal,
    this.pointRate = 0,
    this.fixedPoints = 0,
    this.earnedPoints,
  });
}

class PurchaseContext {
  final double? shippingFee;
  final ShippingAllocation shippingAllocation;

  const PurchaseContext({
    this.shippingFee,
    this.shippingAllocation = ShippingAllocation.allocatedToItem,
  });
}

class CalculationPolicy {
  final MoneyRounding taxRounding;
  final MoneyRounding discountRounding;
  final double pointValueRate;

  const CalculationPolicy({
    this.taxRounding = MoneyRounding.halfUp,
    this.discountRounding = MoneyRounding.halfUp,
    this.pointValueRate = 1,
  });
}

class PriceBreakdown {
  final double displayPrice;
  final bool taxIncluded;
  final double taxRate;
  final double preTaxPrice;
  final double taxAmount;
  final double basePriceInclTax;
  final double percentageDiscount;
  final double fixedDiscount;
  final double couponDiscount;
  final double discountAmount;
  final double? shippingFee;
  final double payableNow;
  final double? earnedPoints;
  final double? pointValue;
  final double? effectiveCost;
  final double? normalizedQuantity;
  final String? quantityUnit;
  final double? cashUnitCost;
  final double? effectiveUnitCost;
  final List<PriceWarning> warnings;

  const PriceBreakdown({
    required this.displayPrice,
    required this.taxIncluded,
    required this.taxRate,
    required this.preTaxPrice,
    required this.taxAmount,
    required this.basePriceInclTax,
    required this.percentageDiscount,
    required this.fixedDiscount,
    required this.couponDiscount,
    required this.discountAmount,
    required this.shippingFee,
    required this.payableNow,
    required this.earnedPoints,
    required this.pointValue,
    required this.effectiveCost,
    required this.normalizedQuantity,
    required this.quantityUnit,
    required this.cashUnitCost,
    required this.effectiveUnitCost,
    this.warnings = const [],
  });
}

class PriceComparisonResult {
  final ComparisonBasis basis;
  final Map<String, PriceBreakdown> breakdowns;
  final List<String> rankedIds;
  final String? bestId;
  final Map<String, double> values;
  final double? difference;
  final double? percentageDifference;
  final List<String> incomparableIds;
  final bool canCompare;
  final List<PriceWarning> warnings;

  const PriceComparisonResult({
    required this.basis,
    required this.breakdowns,
    this.rankedIds = const [],
    this.bestId,
    this.values = const {},
    this.difference,
    this.percentageDifference,
    this.incomparableIds = const [],
    this.canCompare = false,
    this.warnings = const [],
  });
}
