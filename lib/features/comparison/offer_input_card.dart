/// lib/features/comparison/offer_input_card.dart
///
/// 1商品の価格条件を入力するカードと、そのTextEditingController群を提供する。
/// 2〜5件の入力画面から同じUI・変換処理を再利用するために存在する。
///
/// 関連:
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

class OfferInputCard extends StatefulWidget {
  final int index;
  final OfferFormController controller;
  final bool canRemove;
  final VoidCallback? onRemove;

  const OfferInputCard({
    super.key,
    required this.index,
    required this.controller,
    required this.canRemove,
    this.onRemove,
  });

  @override
  State<OfferInputCard> createState() => _OfferInputCardState();
}

class _OfferInputCardState extends State<OfferInputCard> {
  @override
  Widget build(BuildContext context) {
    final form = widget.controller;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('商品${widget.index + 1}', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (widget.canRemove)
                  IconButton(
                    tooltip: 'この商品を削除',
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _field(form.productName, '商品名', '例: 牛乳', keyName: 'product'),
            const SizedBox(height: 10),
            _field(form.storeName, '店舗名', '例: Aスーパー', keyName: 'store'),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    form.price,
                    '価格（円）',
                    '398',
                    keyName: 'price',
                    number: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('税込価格'),
                    value: form.taxIncluded,
                    onChanged: (value) => setState(() => form.taxIncluded = value),
                  ),
                ),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('割引・送料・ポイント・容量'),
              children: [
                Row(
                  children: [
                    Expanded(child: _field(form.taxRate, '税率（%）', '10', keyName: 'tax', number: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(form.percentageDiscount, '割引率（%）', '10', keyName: 'discount-rate', number: true)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(form.fixedDiscount, '値引額（円）', '100', keyName: 'fixed-discount', number: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(form.couponDiscount, 'クーポン（円）', '50', keyName: 'coupon', number: true)),
                  ],
                ),
                const SizedBox(height: 10),
                _field(form.shippingFee, '送料（円）', '0', keyName: 'shipping', number: true),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(form.pointRate, 'ポイント率（%）', '1', keyName: 'point-rate', number: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(form.fixedPoints, '固定ポイント', '0', keyName: 'fixed-points', number: true)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _field(form.quantity, '容量', '500', keyName: 'quantity', number: true)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 92,
                      child: DropdownButtonFormField<Unit>(
                        initialValue: form.unit,
                        decoration: const InputDecoration(labelText: '単位', border: OutlineInputBorder()),
                        items: Unit.values.map((unit) => DropdownMenuItem(value: unit, child: Text(unit.label))).toList(),
                        onChanged: (value) => setState(() => form.unit = value ?? form.unit),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(width: 82, child: _field(form.packageCount, '個数', '1', keyName: 'package-count', number: true)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    required String keyName,
    bool number = false,
  }) => TextFormField(
    key: Key('offer-${widget.controller.id}-$keyName'),
    controller: controller,
    keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
  );
}
