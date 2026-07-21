/// lib/features/comparison/comparison_offer_card.dart
///
/// 価格比較画面で1候補分の入力欄と入力状態を管理する。
/// 入力文字列の検証とドメインモデルへの変換を同じ境界に閉じ込める。
library;

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/price_comparison/price_comparison_models.dart';

final class ComparisonOfferControllers {
  final TextEditingController storeName;
  final TextEditingController price;
  final TextEditingController quantity;
  final TextEditingController packageCount;
  final TextEditingController percentageDiscount;
  final TextEditingController fixedDiscount;
  final TextEditingController couponDiscount;
  final TextEditingController couponMinimumSubtotal;
  final TextEditingController shippingFee;
  final TextEditingController pointRate;
  final TextEditingController fixedPoints;

  bool taxIncluded;
  String taxRate;
  PriceUnit unit;

  ComparisonOfferControllers({
    required String defaultStoreName,
    this.taxIncluded = true,
    this.taxRate = '0.10',
    this.unit = PriceUnit.piece,
  }) : storeName = TextEditingController(text: defaultStoreName),
       price = TextEditingController(),
       quantity = TextEditingController(),
       packageCount = TextEditingController(text: '1'),
       percentageDiscount = TextEditingController(),
       fixedDiscount = TextEditingController(),
       couponDiscount = TextEditingController(),
       couponMinimumSubtotal = TextEditingController(),
       shippingFee = TextEditingController(),
       pointRate = TextEditingController(),
       fixedPoints = TextEditingController();

  PriceOffer toOffer({required String id, required String fallbackName}) {
    final quantityValue = _optionalDecimal(quantity.text);
    final store = storeName.text.trim();
    return PriceOffer(
      id: id,
      productName: '比較商品',
      storeName: store.isEmpty ? fallbackName : store,
      price: DecimalValue.parse(price.text),
      taxIncluded: taxIncluded,
      taxRate: DecimalValue.parse(taxRate),
      quantity: quantityValue == null
          ? null
          : PriceQuantity(
              value: quantityValue,
              unit: unit,
              packageCount: int.parse(packageCount.text.trim()),
            ),
      percentageDiscount: _percentAsRate(percentageDiscount.text),
      fixedDiscount: _decimalOrZero(fixedDiscount.text),
      couponDiscount: _decimalOrZero(couponDiscount.text),
      couponMinimumSubtotal: _optionalDecimal(couponMinimumSubtotal.text),
      pointRate: _percentAsRate(pointRate.text),
      fixedPoints: _decimalOrZero(fixedPoints.text),
      shippingFee: _optionalDecimal(shippingFee.text),
    );
  }

  PurchaseContext toPurchaseContext() => PurchaseContext(
    shippingFee: _optionalDecimal(shippingFee.text),
    shippingAllocation: ShippingAllocation.allocatedToItem,
  );

  void dispose() {
    storeName.dispose();
    price.dispose();
    quantity.dispose();
    packageCount.dispose();
    percentageDiscount.dispose();
    fixedDiscount.dispose();
    couponDiscount.dispose();
    couponMinimumSubtotal.dispose();
    shippingFee.dispose();
    pointRate.dispose();
    fixedPoints.dispose();
  }

  static DecimalValue _decimalOrZero(String text) =>
      _optionalDecimal(text) ?? DecimalValue.zero;

  static DecimalValue? _optionalDecimal(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : DecimalValue.parse(trimmed);
  }

  static DecimalValue _percentAsRate(String text) {
    final percent = _decimalOrZero(text);
    return percent.divide(DecimalValue.hundred, resultScale: 8);
  }
}

class ComparisonOfferCard extends StatefulWidget {
  final int index;
  final ComparisonOfferControllers controllers;

  const ComparisonOfferCard({
    super.key,
    required this.index,
    required this.controllers,
  });

  @override
  State<ComparisonOfferCard> createState() => _ComparisonOfferCardState();
}

class _ComparisonOfferCardState extends State<ComparisonOfferCard> {
  String get _label => '候補${String.fromCharCode(65 + widget.index)}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  foregroundColor: cs.primary,
                  child: Text(
                    String.fromCharCode(65 + widget.index),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: ValueKey('comparison-store-${widget.index}'),
              controller: widget.controllers.storeName,
              decoration: _decoration('店舗・サービス名', hintText: _label),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('comparison-price-${widget.index}'),
              controller: widget.controllers.price,
              decoration: _decoration('表示価格', suffixText: '円'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => _requiredNonNegative(value, '価格'),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('税込価格'),
              subtitle: Text(widget.controllers.taxIncluded ? '税込として計算' : '税抜として計算'),
              value: widget.controllers.taxIncluded,
              onChanged: (value) {
                setState(() => widget.controllers.taxIncluded = value);
              },
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('comparison-tax-rate-${widget.index}'),
              initialValue: widget.controllers.taxRate,
              decoration: _decoration('税率'),
              items: const [
                DropdownMenuItem(value: '0.10', child: Text('10%')),
                DropdownMenuItem(value: '0.08', child: Text('8%（軽減税率）')),
                DropdownMenuItem(value: '0', child: Text('0%（非課税）')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => widget.controllers.taxRate = value);
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    key: ValueKey('comparison-quantity-${widget.index}'),
                    controller: widget.controllers.quantity,
                    decoration: _decoration('容量・個数（任意）'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _optionalPositive,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<PriceUnit>(
                    key: ValueKey('comparison-unit-${widget.index}'),
                    initialValue: widget.controllers.unit,
                    decoration: _decoration('単位'),
                    items: PriceUnit.values
                        .map(
                          (unit) => DropdownMenuItem<PriceUnit>(
                            value: unit,
                            child: Text(unit.symbol),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => widget.controllers.unit = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('comparison-package-count-${widget.index}'),
              controller: widget.controllers.packageCount,
              decoration: _decoration('セット数', suffixText: '個'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: _positiveInteger,
            ),
            const SizedBox(height: 4),
            ExpansionTile(
              key: ValueKey('comparison-advanced-${widget.index}'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              title: const Text('値引き・送料・ポイント'),
              children: [
                _optionalField(
                  keyName: 'discount-rate',
                  controller: widget.controllers.percentageDiscount,
                  label: '割引率',
                  suffix: '%',
                  validator: _optionalPercentage,
                ),
                _optionalField(
                  keyName: 'fixed-discount',
                  controller: widget.controllers.fixedDiscount,
                  label: '固定値引き',
                  suffix: '円',
                ),
                _optionalField(
                  keyName: 'coupon',
                  controller: widget.controllers.couponDiscount,
                  label: 'クーポン値引き',
                  suffix: '円',
                ),
                _optionalField(
                  keyName: 'coupon-minimum',
                  controller: widget.controllers.couponMinimumSubtotal,
                  label: 'クーポン最低利用額',
                  suffix: '円',
                ),
                _optionalField(
                  keyName: 'shipping',
                  controller: widget.controllers.shippingFee,
                  label: '送料',
                  suffix: '円',
                ),
                _optionalField(
                  keyName: 'point-rate',
                  controller: widget.controllers.pointRate,
                  label: 'ポイント還元率',
                  suffix: '%',
                  validator: _optionalPercentage,
                ),
                _optionalField(
                  keyName: 'fixed-points',
                  controller: widget.controllers.fixedPoints,
                  label: '固定ポイント',
                  suffix: 'pt',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionalField({
    required String keyName,
    required TextEditingController controller,
    required String label,
    required String suffix,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: ValueKey('comparison-$keyName-${widget.index}'),
        controller: controller,
        decoration: _decoration(label, suffixText: suffix),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator ?? _optionalNonNegative,
      ),
    );
  }

  static InputDecoration _decoration(
    String label, {
    String? hintText,
    String? suffixText,
  }) => InputDecoration(
    labelText: label,
    hintText: hintText,
    suffixText: suffixText,
    border: const OutlineInputBorder(),
  );

  static String? _requiredNonNegative(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$labelを入力してください';
    return _validateDecimal(value, allowZero: true);
  }

  static String? _optionalNonNegative(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _validateDecimal(value, allowZero: true);
  }

  static String? _optionalPositive(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _validateDecimal(value, allowZero: false);
  }

  static String? _optionalPercentage(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      final parsed = DecimalValue.parse(value);
      if (parsed.isNegative || parsed > DecimalValue.hundred) {
        return '0〜100の範囲で入力してください';
      }
      return null;
    } on FormatException {
      return '数字で入力してください';
    }
  }

  static String? _positiveInteger(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 1) return '1以上の整数を入力してください';
    return null;
  }

  static String? _validateDecimal(String value, {required bool allowZero}) {
    try {
      final parsed = DecimalValue.parse(value);
      if (parsed.isNegative || (!allowZero && parsed.isZero)) {
        return allowZero ? '0以上で入力してください' : '0より大きい値を入力してください';
      }
      return null;
    } on FormatException {
      return '数字で入力してください';
    }
  }
}
