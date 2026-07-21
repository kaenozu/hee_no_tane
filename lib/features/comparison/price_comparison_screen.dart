/// lib/features/comparison/price_comparison_screen.dart
///
/// 2商品の価格・容量・割引・ポイント・送料を入力して比較する画面。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hee_no_tane_app/domain/models/price_comparison.dart';
import 'package:hee_no_tane_app/domain/services/price_calculator.dart';
import 'package:intl/intl.dart';

class PriceComparisonScreen extends StatefulWidget {
  const PriceComparisonScreen({super.key});

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _calculator = const PriceCalculator();
  final _left = _OfferFormData(label: '商品A');
  final _right = _OfferFormData(label: '商品B');
  PriceComparisonResult? _result;
  String? _error;

  @override
  void dispose() {
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  void _compare() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final leftOffer = _left.toOffer('left');
      final rightOffer = _right.toOffer('right');
      final left = _calculator.calculate(
        leftOffer,
        context: PurchaseContext(shippingFee: _left.optional(_left.shipping)),
      );
      final right = _calculator.calculate(
        rightOffer,
        context: PurchaseContext(shippingFee: _right.optional(_right.shipping)),
      );
      setState(() {
        _result = _calculator.compare({'left': left, 'right': right});
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _result = null;
        _error = error.message.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('価格比較')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '容量・割引・ポイント・送料を含めて、本当に安い方を比較します。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _OfferCard(data: _left),
            const SizedBox(height: 12),
            _OfferCard(data: _right),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('price-comparison-submit'),
              onPressed: _compare,
              icon: const Icon(Icons.compare_arrows),
              label: const Text('比較する'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              _ResultCard(result: _result!, left: _left, right: _right),
            ],
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatefulWidget {
  final _OfferFormData data;

  const _OfferCard({required this.data});

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: data.name,
              decoration: const InputDecoration(labelText: '商品名（任意）'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: data.store,
              decoration: const InputDecoration(labelText: '店舗名（任意）'),
            ),
            const SizedBox(height: 8),
            _NumberField(
              controller: data.price,
              label: '表示価格（円）',
              required: true,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('税込価格'),
              value: data.taxIncluded,
              onChanged: (value) => setState(() => data.taxIncluded = value),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _NumberField(controller: data.quantity, label: '内容量'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<PriceUnit>(
                    initialValue: data.unit,
                    decoration: const InputDecoration(labelText: '単位'),
                    items: PriceUnit.values
                        .map(
                          (unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit.symbol),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => data.unit = value ?? data.unit),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    controller: data.packageCount,
                    label: '個数',
                    integer: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: data.percentDiscount,
                    label: '割引率（%）',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    controller: data.fixedDiscount,
                    label: '値引き（円）',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: data.coupon,
                    label: 'クーポン（円）',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    controller: data.pointRate,
                    label: 'ポイント率（%）',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _NumberField(controller: data.shipping, label: '送料（円）'),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final bool integer;

  const _NumberField({
    required this.controller,
    required this.label,
    this.required = false,
    this.integer = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(integer ? r'[0-9]' : r'[0-9.]'),
        ),
      ],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return required ? '$labelを入力してください' : null;
        final number = double.tryParse(text);
        if (number == null || !number.isFinite || number < 0) {
          return '0以上の数値を入力してください';
        }
        return null;
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  final PriceComparisonResult result;
  final _OfferFormData left;
  final _OfferFormData right;

  const _ResultCard({
    required this.result,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    final best = result.bestId;
    final tie = result.canCompare && best == null;
    final title = !result.canCompare
        ? '比較できませんでした'
        : tie
        ? '同じ価格です'
        : '${best == 'left' ? left.displayName : right.displayName}がお得です';
    return Card(
      key: const ValueKey('price-comparison-result'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (result.difference != null && result.difference! > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${_formatMoney(result.difference!)}円安い（約${result.percentageDifference?.toStringAsFixed(2)}%差）',
              ),
            ],
            const Divider(height: 24),
            _breakdownRow(left.displayName, result.breakdowns['left']!),
            const SizedBox(height: 12),
            _breakdownRow(right.displayName, result.breakdowns['right']!),
            const SizedBox(height: 12),
            Text(
              '比較基準: ${_basisLabel(result.basis)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow(String name, PriceBreakdown breakdown) {
    final unit = breakdown.effectiveUnitCost ?? breakdown.cashUnitCost;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text('支払額: ${_formatMoney(breakdown.payableNow)}円'),
        if (breakdown.effectiveCost != null)
          Text('実質価格: ${_formatMoney(breakdown.effectiveCost!)}円'),
        if (unit != null)
          Text('単価: ${unit.toStringAsFixed(3)}円/${breakdown.quantityUnit}'),
      ],
    );
  }

  String _basisLabel(ComparisonBasis basis) => switch (basis) {
    ComparisonBasis.effectiveUnitCost => 'ポイント込み単価',
    ComparisonBasis.cashUnitCost => '支払単価',
    ComparisonBasis.effectiveTotal => 'ポイント込み総額',
    ComparisonBasis.cashTotal => '支払総額',
  };

  static String _formatMoney(double value) =>
      NumberFormat('#,##0').format(value);
}

class _OfferFormData {
  final String label;
  final name = TextEditingController();
  final store = TextEditingController();
  final price = TextEditingController();
  final quantity = TextEditingController();
  final packageCount = TextEditingController(text: '1');
  final percentDiscount = TextEditingController();
  final fixedDiscount = TextEditingController();
  final coupon = TextEditingController();
  final pointRate = TextEditingController();
  final shipping = TextEditingController();
  bool taxIncluded = true;
  PriceUnit unit = PriceUnit.gram;

  _OfferFormData({required this.label});

  String get displayName => name.text.trim().isEmpty ? label : name.text.trim();

  double optional(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  PriceOffer toOffer(String id) {
    final quantityValue = quantity.text.trim().isEmpty
        ? null
        : optional(quantity);
    return PriceOffer(
      id: id,
      productName: displayName,
      storeName: store.text.trim(),
      price: optional(price),
      taxIncluded: taxIncluded,
      quantity: quantityValue == null
          ? null
          : PriceQuantity(
              value: quantityValue,
              unit: unit,
              packageCount: int.tryParse(packageCount.text.trim()) ?? 1,
            ),
      percentageDiscount: optional(percentDiscount) / 100,
      fixedDiscount: optional(fixedDiscount),
      couponDiscount: optional(coupon),
      pointRate: optional(pointRate) / 100,
    );
  }

  void dispose() {
    for (final controller in [
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
    ]) {
      controller.dispose();
    }
  }
}
