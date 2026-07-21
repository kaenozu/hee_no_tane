/// lib/features/comparison/price_comparison_screen.dart
///
/// 2商品の価格・容量・割引・ポイント・送料を入力して比較する画面。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hee_no_tane_app/domain/price_comparison/price_comparison.dart';
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
        context: PurchaseContext(
          shippingFee: _left.optionalNullable(_left.shipping),
        ),
      );
      final right = _calculator.calculate(
        rightOffer,
        context: PurchaseContext(
          shippingFee: _right.optionalNullable(_right.shipping),
        ),
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
            _OfferCard(side: 'left', data: _left),
            const SizedBox(height: 12),
            _OfferCard(side: 'right', data: _right),
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
                key: const ValueKey('price-comparison-error'),
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
  final String side;
  final _OfferFormData data;

  const _OfferCard({required this.side, required this.data});

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
              key: ValueKey('price-comparison-${widget.side}-price'),
              controller: data.price,
              label: '表示価格（円）',
              required: true,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('税込価格'),
              value: data.taxIncluded,
              onChanged: (value) => setState(() => data.taxIncluded = value),
            ),
            DropdownButtonFormField<double>(
              key: ValueKey('price-comparison-${widget.side}-tax-rate'),
              initialValue: data.taxRate,
              decoration: const InputDecoration(labelText: '税率'),
              items: const [
                DropdownMenuItem(value: 0.1, child: Text('10%')),
                DropdownMenuItem(value: 0.08, child: Text('8%（軽減税率）')),
                DropdownMenuItem(value: 0, child: Text('0%（非課税）')),
              ],
              onChanged: (value) => setState(() => data.taxRate = value ?? 0.1),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _NumberField(
                    controller: data.quantity,
                    label: '内容量',
                  ),
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
                    percentage: true,
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
                    controller: data.couponMinimum,
                    label: '最低利用額（円）',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: data.pointRate,
                    label: 'ポイント率（%）',
                    percentage: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    controller: data.fixedPoints,
                    label: '固定ポイント',
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
  final bool percentage;

  const _NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.required = false,
    this.integer = false,
    this.percentage = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
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
        if (integer && number < 1) return '1以上の整数を入力してください';
        if (percentage && number > 100) return '100以下で入力してください';
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
    final warnings = <PriceWarning>{
      ...result.warnings,
      for (final breakdown in result.breakdowns.values) ...breakdown.warnings,
    };

    return Semantics(
      liveRegion: true,
      label: title,
      child: Card(
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
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...warnings.map(
                  (warning) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _warningLabel(warning),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
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

  String _warningLabel(PriceWarning warning) => switch (warning) {
    PriceWarning.pointsMissing => 'ポイント情報がないため、支払額を優先して比較しています。',
    PriceWarning.quantityMissing => '一部の商品に内容量がないため、総額で比較しています。',
    PriceWarning.shippingFullOrder => '送料は注文全体の金額です。',
    PriceWarning.discountExceedsPrice => '値引き額が価格を超えたため、支払額を0円に補正しました。',
    PriceWarning.couponExceedsRemaining => 'クーポン額を値引き後の残額までに補正しました。',
    PriceWarning.negativeEffectiveCost => 'ポイント価値が支払額を超えています。',
    PriceWarning.quantityZero => '内容量が0のため、単価を計算できません。',
    PriceWarning.dimensionMismatch => '容量・重量・個数が混在しているため、総額で比較しています。',
    PriceWarning.cannotCompare => '比較可能な価格情報が2件以上ありません。',
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
  final couponMinimum = TextEditingController();
  final pointRate = TextEditingController();
  final fixedPoints = TextEditingController();
  final shipping = TextEditingController();
  bool taxIncluded = true;
  double taxRate = 0.1;
  PriceUnit unit = PriceUnit.gram;

  _OfferFormData({required this.label});

  String get displayName => name.text.trim().isEmpty ? label : name.text.trim();

  double optional(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  double? optionalNullable(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : double.tryParse(text);
  }

  PriceOffer toOffer(String id) {
    final quantityValue = optionalNullable(quantity);
    return PriceOffer(
      id: id,
      productName: displayName,
      storeName: store.text.trim(),
      price: optional(price),
      taxIncluded: taxIncluded,
      taxRate: taxRate,
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
      couponMinimumSubtotal: optionalNullable(couponMinimum),
      pointRate: optional(pointRate) / 100,
      fixedPoints: optional(fixedPoints),
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
      couponMinimum,
      pointRate,
      fixedPoints,
      shipping,
    ]) {
      controller.dispose();
    }
  }
}
