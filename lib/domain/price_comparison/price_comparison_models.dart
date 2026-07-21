/// lib/domain/price_comparison/price_comparison_models.dart
///
/// 価格比較機能の入力・出力モデルと列挙型。
/// Flutter UI に依存せず、計算とテストから共通利用する。
library;

import 'dart:collection';

import 'decimal_value.dart';

export 'decimal_value.dart' show DecimalValue, MoneyRounding;

enum PriceUnit { milliliter, liter, gram, kilogram, piece }

enum PriceDimension { volume, mass, count }

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

enum PriceWarning {
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

extension PriceUnitProperties on PriceUnit {
  String get symbol => switch (this) {
    PriceUnit.milliliter => 'ml',
    PriceUnit.liter => 'L',
    PriceUnit.gram => 'g',
    PriceUnit.kilogram => 'kg',
    PriceUnit.piece => '個',
  };

  DecimalValue get factor => switch (this) {
    PriceUnit.milliliter || PriceUnit.gram || PriceUnit.piece =>
      DecimalValue.one,
    PriceUnit.liter || PriceUnit.kilogram => DecimalValue.fromInt(1000),
  };

  PriceDimension get dimension => switch (this) {
    PriceUnit.milliliter || PriceUnit.liter => PriceDimension.volume,
    PriceUnit.gram || PriceUnit.kilogram => PriceDimension.mass,
    PriceUnit.piece => PriceDimension.count,
  };
}

extension ComparisonBasisLabel on ComparisonBasis {
  String get label => switch (this) {
    ComparisonBasis.effectiveUnitCost => 'ポイント込みの実質単価',
    ComparisonBasis.cashUnitCost => '支払単価',
    ComparisonBasis.effectiveTotal => 'ポイント込みの実質総額',
    ComparisonBasis.cashTotal => '支払総額',
  };
}

extension PriceWarningLabel on PriceWarning {
  String get message => switch (this) {
    PriceWarning.pointsMissing => 'ポイント情報がないため、支払額を優先して比較しています。',
    PriceWarning.quantityMissing => '一部の商品に容量がないため、比較可能な基準へ切り替えました。',
    PriceWarning.shippingFullOrder => '送料は注文全体の金額です。商品単体の比較では高く見える場合があります。',
    PriceWarning.discountExceedsPrice => '値引き額が商品価格を超えたため、支払額を0円に補正しました。',
    PriceWarning.couponExceedsRemaining => 'クーポン額が残額を超えたため、残額まで適用しました。',
    PriceWarning.pointsExceedPayable => 'ポイントが支払額を超えています。',
    PriceWarning.negativeEffectiveCost => 'ポイント価値が支払額を超え、実質価格がマイナスになっています。',
    PriceWarning.dimensionMismatch => '容量の単位種別が一致しないため、単価比較できません。',
    PriceWarning.measureKindMismatch => '商品の数量種別が一致しないため、単価比較できません。',
    PriceWarning.cannotCompare => '比較可能な価格情報が2件以上ありません。',
    PriceWarning.promotionalAnomaly => '通常より大きな特典が入力されています。内容を確認してください。',
    PriceWarning.quantityZero => '容量が0のため、単価を計算できません。',
    PriceWarning.unknownField => '未対応の入力項目があります。',
    PriceWarning.unsupportedSchema => '未対応のデータ形式です。',
  };
}

final class PriceQuantity {
  final DecimalValue value;
  final PriceUnit unit;
  final int packageCount;
  final MeasureKind measureKind;

  const PriceQuantity({
    required this.value,
    required this.unit,
    this.packageCount = 1,
    this.measureKind = MeasureKind.item,
  });

  DecimalValue normalizedTotal() =>
      value * unit.factor * DecimalValue.fromInt(packageCount);
}

final class PriceOffer {
  final String id;
  final String productName;
  final String storeName;
  final DecimalValue price;
  final bool taxIncluded;
  final DecimalValue taxRate;
  final PriceQuantity? quantity;
  final DecimalValue percentageDiscount;
  final DecimalValue fixedDiscount;
  final DecimalValue couponDiscount;
  final DecimalValue? couponMinimumSubtotal;
  final DecimalValue pointRate;
  final DecimalValue fixedPoints;
  final DecimalValue? earnedPoints;
  final DecimalValue? shippingFee;

  PriceOffer({
    required this.id,
    required this.productName,
    required this.storeName,
    required this.price,
    required this.taxIncluded,
    required this.taxRate,
    this.quantity,
    DecimalValue? percentageDiscount,
    DecimalValue? fixedDiscount,
    DecimalValue? couponDiscount,
    this.couponMinimumSubtotal,
    DecimalValue? pointRate,
    DecimalValue? fixedPoints,
    this.earnedPoints,
    this.shippingFee,
  }) : percentageDiscount = percentageDiscount ?? DecimalValue.zero,
       fixedDiscount = fixedDiscount ?? DecimalValue.zero,
       couponDiscount = couponDiscount ?? DecimalValue.zero,
       pointRate = pointRate ?? DecimalValue.zero,
       fixedPoints = fixedPoints ?? DecimalValue.zero;
}

final class PurchaseContext {
  final DecimalValue? shippingFee;
  final ShippingAllocation shippingAllocation;
  final DecimalValue? checkoutTotalOverride;

  const PurchaseContext({
    this.shippingFee,
    this.shippingAllocation = ShippingAllocation.allocatedToItem,
    this.checkoutTotalOverride,
  });
}

final class CalculationPolicy {
  final MoneyRounding taxRounding;
  final MoneyRounding discountRounding;
  final DecimalValue pointValueRate;

  CalculationPolicy({
    this.taxRounding = MoneyRounding.halfUp,
    this.discountRounding = MoneyRounding.halfUp,
    DecimalValue? pointValueRate,
  }) : pointValueRate = pointValueRate ?? DecimalValue.one;
}

final class PriceBreakdown {
  final DecimalValue displayPrice;
  final bool taxIncluded;
  final DecimalValue taxRate;
  final DecimalValue? preTaxPrice;
  final DecimalValue? taxAmount;
  final DecimalValue? basePriceInclTax;
  final DecimalValue percentageDiscount;
  final DecimalValue fixedDiscount;
  final DecimalValue couponDiscount;
  final DecimalValue discountAmount;
  final DecimalValue? shippingFee;
  final DecimalValue? payableNow;
  final DecimalValue? earnedPoints;
  final DecimalValue? pointValue;
  final DecimalValue? effectiveCost;
  final DecimalValue? normalizedQuantity;
  final String? quantityUnit;
  final DecimalValue? cashUnitCost;
  final DecimalValue? effectiveUnitCost;
  final bool cashComplete;
  final bool rewardComplete;
  final bool unitComplete;
  final List<PriceWarning> warnings;

  PriceBreakdown({
    required this.displayPrice,
    required this.taxIncluded,
    required this.taxRate,
    this.preTaxPrice,
    this.taxAmount,
    this.basePriceInclTax,
    DecimalValue? percentageDiscount,
    DecimalValue? fixedDiscount,
    DecimalValue? couponDiscount,
    DecimalValue? discountAmount,
    this.shippingFee,
    this.payableNow,
    this.earnedPoints,
    this.pointValue,
    this.effectiveCost,
    this.normalizedQuantity,
    this.quantityUnit,
    this.cashUnitCost,
    this.effectiveUnitCost,
    this.cashComplete = false,
    this.rewardComplete = false,
    this.unitComplete = false,
    List<PriceWarning> warnings = const <PriceWarning>[],
  }) : percentageDiscount = percentageDiscount ?? DecimalValue.zero,
       fixedDiscount = fixedDiscount ?? DecimalValue.zero,
       couponDiscount = couponDiscount ?? DecimalValue.zero,
       discountAmount = discountAmount ?? DecimalValue.zero,
       warnings = UnmodifiableListView<PriceWarning>(warnings);

  bool get isCashComparable => cashComplete && payableNow != null;
  bool get isRewardComparable => rewardComplete && effectiveCost != null;
  bool get isUnitComparable => unitComplete && cashUnitCost != null;
}

final class ComparisonResult {
  final ComparisonBasis basis;
  final Map<String, PriceBreakdown> breakdowns;
  final List<String> rankedIds;
  final String? bestId;
  final Map<String, DecimalValue> values;
  final DecimalValue? difference;
  final DecimalValue? percentageDifference;
  final List<String> incomparableIds;
  final bool canCompare;
  final List<PriceWarning> warnings;

  ComparisonResult({
    required this.basis,
    required Map<String, PriceBreakdown> breakdowns,
    List<String> rankedIds = const <String>[],
    this.bestId,
    Map<String, DecimalValue> values = const <String, DecimalValue>{},
    this.difference,
    this.percentageDifference,
    List<String> incomparableIds = const <String>[],
    this.canCompare = false,
    List<PriceWarning> warnings = const <PriceWarning>[],
  }) : breakdowns = UnmodifiableMapView<String, PriceBreakdown>(breakdowns),
       rankedIds = UnmodifiableListView<String>(rankedIds),
       values = UnmodifiableMapView<String, DecimalValue>(values),
       incomparableIds = UnmodifiableListView<String>(incomparableIds),
       warnings = UnmodifiableListView<PriceWarning>(warnings);
}
