/// lib/domain/price_comparison/models.dart
///
/// 価格比較機能で使用する入力・計算結果のドメインモデル。
/// Python/Kotlin版の型をDartへ移植し、UI・保存層から共有するために存在する。
///
/// 関連:
///   - pricing_calculator.dart
///   - comparison_engine.dart
///   - ../../data/repositories/comparison_repository.dart
library;

enum MoneyRounding { halfUp, down, up }

enum Unit { ml, liter, gram, kilogram, piece }

enum Dimension { volume, mass, count }

enum MeasureKind {
  genericVolume,
  genericMass,
  item,
  tablet,
  capsule,
  sheet,
  roll,
  bag,
}

enum ComparisonBasis {
  effectiveUnitCost,
  cashUnitCost,
  effectiveTotal,
  cashTotal,
}

enum ShippingAllocation { fullOrder, allocatedToItem, excluded, unknown }

enum WarningCode {
  pointsMissing,
  quantityMissing,
  shippingFullOrder,
  discountExceedsPrice,
  couponExceedsRemaining,
  pointsExceedPayable,
  negativeEffectiveCost,
  dimensionMismatch,
  measureKindMismatch,
  cannotCompare,
  promotionalAnomaly,
  quantityZero,
  unknownField,
  unsupportedSchema,
}

extension UnitDefinition on Unit {
  String get jsonValue => switch (this) {
    Unit.ml => 'ml',
    Unit.liter => 'L',
    Unit.gram => 'g',
    Unit.kilogram => 'kg',
    Unit.piece => 'piece',
  };

  String get label => switch (this) {
    Unit.ml => 'ml',
    Unit.liter => 'L',
    Unit.gram => 'g',
    Unit.kilogram => 'kg',
    Unit.piece => '個',
  };

  double get factor => switch (this) {
    Unit.liter || Unit.kilogram => 1000,
    _ => 1,
  };

  Dimension get dimension => switch (this) {
    Unit.ml || Unit.liter => Dimension.volume,
    Unit.gram || Unit.kilogram => Dimension.mass,
    Unit.piece => Dimension.count,
  };

}


Unit unitFromJson(String value) => switch (value) {
  'ml' => Unit.ml,
  'L' => Unit.liter,
  'g' => Unit.gram,
  'kg' => Unit.kilogram,
  'piece' => Unit.piece,
  _ => throw FormatException('Unknown unit: $value'),
};

extension ComparisonBasisLabel on ComparisonBasis {
  String get label => switch (this) {
    ComparisonBasis.effectiveUnitCost => 'ポイント反映後の単位単価',
    ComparisonBasis.cashUnitCost => '支払額の単位単価',
    ComparisonBasis.effectiveTotal => 'ポイント反映後の実質総額',
    ComparisonBasis.cashTotal => '今支払う総額',
  };
}

class Quantity {
  final double value;
  final Unit unit;
  final int packageCount;
  final MeasureKind measureKind;

  const Quantity({
    required this.value,
    required this.unit,
    this.packageCount = 1,
    this.measureKind = MeasureKind.item,
  });

  double get normalizedTotal => value * unit.factor * packageCount;
  Dimension get dimension => unit.dimension;
}

class Offer {
  final String id;
  final String productName;
  final String storeName;
  final int price;
  final bool taxIncluded;
  final double taxRate;
  final Quantity? quantity;
  final double percentageDiscount;
  final int fixedDiscount;
  final int couponDiscount;
  final int? couponMinimumSubtotal;
  final double pointRate;
  final int fixedPoints;
  final int? earnedPoints;
  final int? shippingFee;

  const Offer({
    required this.id,
    required this.productName,
    required this.storeName,
    required this.price,
    required this.taxIncluded,
    required this.taxRate,
    this.quantity,
    this.percentageDiscount = 0,
    this.fixedDiscount = 0,
    this.couponDiscount = 0,
    this.couponMinimumSubtotal,
    this.pointRate = 0,
    this.fixedPoints = 0,
    this.earnedPoints,
    this.shippingFee,
  });
}

class PurchaseContext {
  final int? shippingFee;
  final ShippingAllocation shippingAllocation;
  final int? checkoutTotalOverride;

  const PurchaseContext({
    this.shippingFee,
    this.shippingAllocation = ShippingAllocation.allocatedToItem,
    this.checkoutTotalOverride,
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
  final int displayPrice;
  final bool taxIncluded;
  final double taxRate;
  final int preTaxPrice;
  final int taxAmount;
  final int basePriceInclTax;
  final double percentageDiscount;
  final int fixedDiscount;
  final int couponDiscount;
  final int discountAmount;
  final int? shippingFee;
  final int payableNow;
  final int? earnedPoints;
  final int? pointValue;
  final int? effectiveCost;
  final double? normalizedQuantity;
  final Unit? quantityUnit;
  final Dimension? quantityDimension;
  final MeasureKind? measureKind;
  final double? cashUnitCost;
  final double? effectiveUnitCost;
  final bool cashComplete;
  final bool rewardComplete;
  final bool unitComplete;
  final List<WarningCode> warnings;

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
    required this.quantityDimension,
    required this.measureKind,
    required this.cashUnitCost,
    required this.effectiveUnitCost,
    required this.cashComplete,
    required this.rewardComplete,
    required this.unitComplete,
    this.warnings = const <WarningCode>[],
  });

  bool get isCashComparable => cashComplete;
  bool get isRewardComparable => rewardComplete && effectiveCost != null;
  bool get isUnitComparable => unitComplete && cashUnitCost != null;
}

class ComparisonResult {
  final ComparisonBasis basis;
  final Map<String, PriceBreakdown> breakdowns;
  final List<String> rankedIds;
  final String? bestId;
  final Map<String, double> values;
  final double? difference;
  final double? percentageDifference;
  final List<String> incomparableIds;
  final bool canCompare;
  final List<WarningCode> warnings;

  const ComparisonResult({
    required this.basis,
    required this.breakdowns,
    this.rankedIds = const <String>[],
    this.bestId,
    this.values = const <String, double>{},
    this.difference,
    this.percentageDifference,
    this.incomparableIds = const <String>[],
    this.canCompare = false,
    this.warnings = const <WarningCode>[],
  });
}
