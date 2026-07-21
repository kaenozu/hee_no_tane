/// lib/features/comparison/comparison_result_screen.dart
///
/// 価格比較の順位・差額・各計算ステップを表示し、結果を履歴へ保存する画面。
/// 最安値だけでなく税・割引・送料・ポイント・単価の根拠を確認できるようにする。
///
/// 関連:
///   - comparison_input_screen.dart
///   - ../../data/repositories/comparison_repository.dart
///   - ../../domain/price_comparison/models.dart
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hee_no_tane_app/data/repositories/comparison_repository.dart';
import 'package:hee_no_tane_app/domain/price_comparison/models.dart';

class ComparisonResultScreen extends StatefulWidget {
  final List<Offer> offers;
  final ComparisonResult result;
  final ComparisonRepository repository;
  final DateTime? savedAt;

  const ComparisonResultScreen({
    super.key,
    required this.offers,
    required this.result,
    required this.repository,
    this.savedAt,
  });

  @override
  State<ComparisonResultScreen> createState() => _ComparisonResultScreenState();
}

class _ComparisonResultScreenState extends State<ComparisonResultScreen> {
  bool _saving = false;
  bool _saved = false;

  final NumberFormat _yen = NumberFormat.decimalPattern('ja_JP');

  @override
  void initState() {
    super.initState();
    _saved = widget.savedAt != null;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repository.save(widget.offers);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('比較結果を保存しました。')),
      );
    } on ComparisonSaveException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return Scaffold(
      appBar: AppBar(title: const Text('比較結果')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _summaryCard(result),
          const SizedBox(height: 12),
          ...result.rankedIds.asMap().entries.map(
            (entry) => _breakdownCard(entry.key + 1, entry.value),
          ),
          if (result.incomparableIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '比較対象外: ${result.incomparableIds.map(_offerName).join('、')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _saving || _saved ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_saved ? Icons.check : Icons.save_outlined),
          label: Text(_saved ? '保存済み' : '比較結果を保存'),
        ),
      ),
    );
  }

  Widget _summaryCard(ComparisonResult result) {
    final best = result.bestId == null ? null : _offer(result.bestId!);
    final difference = result.difference;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('比較基準', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(result.basis.label, style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 28),
            if (!result.canCompare)
              const Text('比較可能な商品が2件ありません。')
            else if (best == null)
              const Text('最安値は同額です。')
            else ...[
              Text('最安: ${best.productName}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(best.storeName),
              if (difference != null) ...[
                const SizedBox(height: 8),
                Text(
                  '2位との差: ${_formatBasisValue(difference, result.basis)}'
                  '${result.percentageDifference == null ? '' : '（${result.percentageDifference!.toStringAsFixed(2)}%）'}',
                ),
              ],
            ],
            if (widget.savedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                '保存日時: ${DateFormat('yyyy/MM/dd HH:mm').format(widget.savedAt!.toLocal())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _breakdownCard(int rank, String id) {
    final offer = _offer(id);
    final breakdown = widget.result.breakdowns[id]!;
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(child: Text('$rank')),
        title: Text(offer.productName),
        subtitle: Text(
          '${offer.storeName}・${_formatBasisValue(widget.result.values[id]!, widget.result.basis)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _row('表示価格', '${_yen.format(breakdown.displayPrice)}円'),
          _row('税額', '${_yen.format(breakdown.taxAmount)}円'),
          _row('税込基準価格', '${_yen.format(breakdown.basePriceInclTax)}円'),
          _row('割引・クーポン', '-${_yen.format(breakdown.discountAmount)}円'),
          _row('送料', breakdown.shippingFee == null ? 'なし' : '${_yen.format(breakdown.shippingFee)}円'),
          _row('今支払う額', '${_yen.format(breakdown.payableNow)}円', emphasized: true),
          _row('獲得ポイント', breakdown.earnedPoints == null ? '未入力' : '${_yen.format(breakdown.earnedPoints)}pt'),
          _row('実質価格', breakdown.effectiveCost == null ? '算出不可' : '${_yen.format(breakdown.effectiveCost)}円'),
          if (breakdown.normalizedQuantity != null)
            _row(
              '容量換算',
              '${breakdown.normalizedQuantity!.toStringAsFixed(_fractionDigits(breakdown.normalizedQuantity!))} ${_baseUnitLabel(breakdown.quantityDimension)}',
            ),
          if (breakdown.cashUnitCost != null)
            _row('支払単価', '${breakdown.cashUnitCost!.toStringAsFixed(3)}円/${_baseUnitLabel(breakdown.quantityDimension)}'),
          if (breakdown.effectiveUnitCost != null)
            _row('実質単価', '${breakdown.effectiveUnitCost!.toStringAsFixed(3)}円/${_baseUnitLabel(breakdown.quantityDimension)}'),
          if (breakdown.warnings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                breakdown.warnings.map(_warningLabel).join('、'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasized = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: emphasized ? const TextStyle(fontWeight: FontWeight.bold) : null),
      ],
    ),
  );

  Offer _offer(String id) => widget.offers.firstWhere((offer) => offer.id == id);
  String _offerName(String id) => _offer(id).productName;

  String _formatBasisValue(double value, ComparisonBasis basis) {
    if (basis == ComparisonBasis.cashTotal || basis == ComparisonBasis.effectiveTotal) {
      return '${_yen.format(value.round())}円';
    }
    return '${value.toStringAsFixed(3)}円/単位';
  }

  String _baseUnitLabel(Dimension? dimension) => switch (dimension) {
    Dimension.volume => 'ml',
    Dimension.mass => 'g',
    Dimension.count => '個',
    null => '単位',
  };

  int _fractionDigits(double value) => value == value.roundToDouble() ? 0 : 3;

  String _warningLabel(WarningCode warning) => switch (warning) {
    WarningCode.pointsMissing => 'ポイント未入力',
    WarningCode.shippingFullOrder => '送料は注文全体分',
    WarningCode.discountExceedsPrice => '値引額が価格を超過',
    WarningCode.couponExceedsRemaining => 'クーポン額を上限調整',
    WarningCode.pointsExceedPayable => 'ポイントが支払額を超過',
    WarningCode.negativeEffectiveCost => '実質価格がマイナス',
    WarningCode.quantityZero => '容量が0',
    _ => warning.name,
  };
}
