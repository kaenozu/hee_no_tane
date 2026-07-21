/// lib/features/comparison/offer_form_controller.dart
///
/// 価格比較候補1件分の入力状態とドメインモデル変換を管理する。
library;

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/data/models/price_comparison_draft.dart';
import 'package:hee_no_tane_app/domain/models/price_comparison.dart';

final class OfferFormController {
  final String label;
  final TextEditingController name = TextEditingController();
  final TextEditingController store = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController quantity = TextEditingController();
  final TextEditingController packageCount = TextEditingController(text: '1');
  final TextEditingController percentDiscount = TextEditingController();
  final TextEditingController fixedDiscount = TextEditingController();
  final TextEditingController coupon = TextEditingController();
  final TextEditingController pointRate = TextEditingController();
  final TextEditingController shipping = TextEditingController();

  bool taxIncluded = true;
  double taxRate = 0.1;
  PriceUnit unit = PriceUnit.gram;

  OfferFormController({required this.label});

  String get displayName => name.text.trim().isEmpty ? label : name.text.trim();

  PriceOffer toOffer(String id) {
    final quantityValue = optional(quantity);
    return PriceOffer(
      id: id,
      productName: displayName,
      storeName: store.text.trim(),
      price: requiredNumber(price),
      taxIncluded: taxIncluded,
      taxRate: taxRate,
      quantity: quantityValue == null
          ? null
          : PriceQuantity(
              value: quantityValue,
              unit: unit,
              packageCount: int.tryParse(packageCount.text.trim()) ?? 1,
            ),
      percentageDiscount: (optional(percentDiscount) ?? 0) / 100,
      fixedDiscount: optional(fixedDiscount) ?? 0,
      couponDiscount: optional(coupon) ?? 0,
      pointRate: (optional(pointRate) ?? 0) / 100,
    );
  }

  PriceComparisonDraftItem toDraftItem(String id) =>
      PriceComparisonDraftItem(
        offer: toOffer(id),
        shippingFee: optional(shipping),
      );

  void applyDraft(PriceComparisonDraftItem item) {
    final offer = item.offer;
    name.text = offer.productName == label ? '' : offer.productName;
    store.text = offer.storeName;
    price.text = _format(offer.price);
    taxIncluded = offer.taxIncluded;
    taxRate = offer.taxRate;
    unit = offer.quantity?.unit ?? PriceUnit.gram;
    quantity.text = offer.quantity == null ? '' : _format(offer.quantity!.value);
    packageCount.text = offer.quantity?.packageCount.toString() ?? '1';
    percentDiscount.text = offer.percentageDiscount == 0
        ? ''
        : _format(offer.percentageDiscount * 100);
    fixedDiscount.text = offer.fixedDiscount == 0
        ? ''
        : _format(offer.fixedDiscount);
    coupon.text = offer.couponDiscount == 0
        ? ''
        : _format(offer.couponDiscount);
    pointRate.text = offer.pointRate == 0
        ? ''
        : _format(offer.pointRate * 100);
    shipping.text = item.shippingFee == null ? '' : _format(item.shippingFee!);
  }

  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    packageCount.text = '1';
    taxIncluded = true;
    taxRate = 0.1;
    unit = PriceUnit.gram;
  }

  double requiredNumber(TextEditingController controller) =>
      double.parse(controller.text.trim());

  double? optional(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
  }

  List<TextEditingController> get _controllers => <TextEditingController>[
    name,
    store,
    price,
    quantity,
    packageCount,
    percentDiscount,
    fixedDiscount,
    coupon,
    pointRate,
    shipping,
  ];

  static String _format(double value) => value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}
