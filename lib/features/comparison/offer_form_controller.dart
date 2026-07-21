/// lib/features/comparison/offer_form_controller.dart
///
/// 1商品の入力状態と文字列からOfferへの変換を管理する。
/// 入力UIから変換・バリデーション責務を分離するために存在する。
///
/// 関連:
///   - offer_input_card.dart
///   - comparison_input_screen.dart
///   - ../../domain/price_comparison/input_validator.dart
library;

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/price_comparison/input_validator.dart';
import 'package:hee_no_tane_app/domain/price_comparison/models.dart';

class OfferFormController {
  final String id;
  final TextEditingController productName = TextEditingController();
  final TextEditingController storeName = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController taxRate = TextEditingController(text: '10');
  final TextEditingController percentageDiscount = TextEditingController();
  final TextEditingController fixedDiscount = TextEditingController();
  final TextEditingController couponDiscount = TextEditingController();
  final TextEditingController shippingFee = TextEditingController();
  final TextEditingController pointRate = TextEditingController();
  final TextEditingController fixedPoints = TextEditingController();
  final TextEditingController quantity = TextEditingController();
  final TextEditingController packageCount = TextEditingController(text: '1');

  bool taxIncluded = true;
  Unit unit = Unit.gram;

  OfferFormController(this.id);

  Offer toOffer() {
    final quantityValue = InputValidator.parseOptionalQuantity(
      quantity.text,
      fieldName: '容量',
    );
    final packageCountValue = packageCount.text.trim().isEmpty
        ? 1
        : InputValidator.parseMoney(
            packageCount.text,
            fieldName: '個数',
            allowZero: false,
          );
    final rate = InputValidator.parsePercent(
      pointRate.text,
      fieldName: 'ポイント率',
    );
    final fixed = InputValidator.parseMoney(
      fixedPoints.text,
      fieldName: '固定ポイント',
      required: false,
    );
    final offer = Offer(
      id: id,
      productName: productName.text.trim(),
      storeName: storeName.text.trim(),
      price: InputValidator.parseMoney(
        price.text,
        fieldName: '価格',
        allowZero: false,
      ),
      taxIncluded: taxIncluded,
      taxRate: InputValidator.parsePercent(
        taxRate.text,
        fieldName: '税率',
        required: true,
      ),
      quantity: quantityValue == null
          ? null
          : Quantity(
              value: quantityValue,
              unit: unit,
              packageCount: packageCountValue,
              measureKind: switch (unit.dimension) {
                Dimension.volume => MeasureKind.genericVolume,
                Dimension.mass => MeasureKind.genericMass,
                Dimension.count => MeasureKind.item,
              },
            ),
      percentageDiscount: InputValidator.parsePercent(
        percentageDiscount.text,
        fieldName: '割引率',
      ),
      fixedDiscount: InputValidator.parseMoney(
        fixedDiscount.text,
        fieldName: '値引額',
        required: false,
      ),
      couponDiscount: InputValidator.parseMoney(
        couponDiscount.text,
        fieldName: 'クーポン',
        required: false,
      ),
      pointRate: rate,
      fixedPoints: fixed,
      earnedPoints: rate == 0 && fixed == 0 ? 0 : null,
      shippingFee: InputValidator.parseOptionalMoney(
        shippingFee.text,
        fieldName: '送料',
      ),
    );
    InputValidator.validateOffer(offer);
    return offer;
  }

  void dispose() {
    productName.dispose();
    storeName.dispose();
    price.dispose();
    taxRate.dispose();
    percentageDiscount.dispose();
    fixedDiscount.dispose();
    couponDiscount.dispose();
    shippingFee.dispose();
    pointRate.dispose();
    fixedPoints.dispose();
    quantity.dispose();
    packageCount.dispose();
  }
}
