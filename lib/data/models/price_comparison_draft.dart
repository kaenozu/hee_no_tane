/// lib/data/models/price_comparison_draft.dart
///
/// 価格比較画面の保存用DTO。ドメインモデルとJSONの変換境界を担う。
library;

import 'package:hee_no_tane_app/domain/models/price_comparison.dart';

class PriceComparisonDraftItem {
  final PriceOffer offer;
  final double? shippingFee;

  const PriceComparisonDraftItem({
    required this.offer,
    this.shippingFee,
  });

  factory PriceComparisonDraftItem.fromJson(Map<String, dynamic> json) {
    final quantityJson = json['quantity'];
    return PriceComparisonDraftItem(
      offer: PriceOffer(
        id: json['id'] as String? ?? '',
        productName: json['productName'] as String? ?? '',
        storeName: json['storeName'] as String? ?? '',
        price: _readDouble(json['price']),
        taxIncluded: json['taxIncluded'] as bool? ?? true,
        taxRate: _readDouble(json['taxRate'], fallback: 0.1),
        quantity: quantityJson is Map
            ? PriceQuantity(
                value: _readDouble(quantityJson['value']),
                unit: PriceUnit.values.firstWhere(
                  (unit) => unit.name == quantityJson['unit'],
                  orElse: () => PriceUnit.gram,
                ),
                packageCount: _readInt(
                  quantityJson['packageCount'],
                  fallback: 1,
                ),
              )
            : null,
        percentageDiscount: _readDouble(json['percentageDiscount']),
        fixedDiscount: _readDouble(json['fixedDiscount']),
        couponDiscount: _readDouble(json['couponDiscount']),
        couponMinimumSubtotal: _readNullableDouble(
          json['couponMinimumSubtotal'],
        ),
        pointRate: _readDouble(json['pointRate']),
        fixedPoints: _readDouble(json['fixedPoints']),
        earnedPoints: _readNullableDouble(json['earnedPoints']),
      ),
      shippingFee: _readNullableDouble(json['shippingFee']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': offer.id,
    'productName': offer.productName,
    'storeName': offer.storeName,
    'price': offer.price,
    'taxIncluded': offer.taxIncluded,
    'taxRate': offer.taxRate,
    'quantity': offer.quantity == null
        ? null
        : <String, dynamic>{
            'value': offer.quantity!.value,
            'unit': offer.quantity!.unit.name,
            'packageCount': offer.quantity!.packageCount,
          },
    'percentageDiscount': offer.percentageDiscount,
    'fixedDiscount': offer.fixedDiscount,
    'couponDiscount': offer.couponDiscount,
    'couponMinimumSubtotal': offer.couponMinimumSubtotal,
    'pointRate': offer.pointRate,
    'fixedPoints': offer.fixedPoints,
    'earnedPoints': offer.earnedPoints,
    'shippingFee': shippingFee,
  };
}

class PriceComparisonDraft {
  final PriceComparisonDraftItem left;
  final PriceComparisonDraftItem right;

  const PriceComparisonDraft({
    required this.left,
    required this.right,
  });

  factory PriceComparisonDraft.fromJson(Map<String, dynamic> json) =>
      PriceComparisonDraft(
        left: PriceComparisonDraftItem.fromJson(
          Map<String, dynamic>.from(json['left'] as Map),
        ),
        right: PriceComparisonDraftItem.fromJson(
          Map<String, dynamic>.from(json['right'] as Map),
        ),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'left': left.toJson(),
    'right': right.toJson(),
  };
}

double _readDouble(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double? _readNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
