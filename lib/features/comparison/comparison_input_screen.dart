/// lib/features/comparison/comparison_input_screen.dart
///
/// 2〜5件の商品条件を入力し、価格計算とランキングを開始する画面。
/// 保存済み比較履歴も同じ入口から再表示できるようにするために存在する。
///
/// 関連:
///   - offer_input_card.dart
///   - comparison_result_screen.dart
///   - ../../data/repositories/comparison_repository.dart
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hee_no_tane_app/data/repositories/comparison_repository.dart';
import 'package:hee_no_tane_app/domain/price_comparison/comparison_engine.dart';
import 'package:hee_no_tane_app/domain/price_comparison/input_validator.dart';
import 'package:hee_no_tane_app/domain/price_comparison/models.dart';
import 'package:hee_no_tane_app/domain/price_comparison/pricing_calculator.dart';
import 'package:hee_no_tane_app/features/comparison/comparison_result_screen.dart';
import 'package:hee_no_tane_app/features/comparison/offer_input_card.dart';

class ComparisonInputScreen extends StatefulWidget {
  final ComparisonRepository repository;

  const ComparisonInputScreen({super.key, required this.repository});

  @override
  State<ComparisonInputScreen> createState() => _ComparisonInputScreenState();
}

class _ComparisonInputScreenState extends State<ComparisonInputScreen> {
  final List<OfferFormController> _forms = <OfferFormController>[];
  List<SavedComparison> _history = const <SavedComparison>[];
  bool _loadingHistory = true;
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _forms.add(OfferFormController('offer-${_nextId++}'));
    _forms.add(OfferFormController('offer-${_nextId++}'));
    _loadHistory();
  }

  @override
  void dispose() {
    for (final form in _forms) {
      form.dispose();
    }
    super.dispose();
  }

  void _addOffer() {
    if (_forms.length >= 5) return;
    setState(() {
      _forms.add(OfferFormController('offer-${_nextId++}'));
    });
  }

  void _removeOffer(int index) {
    if (_forms.length <= 2) return;
    final removed = _forms.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _loadHistory() async {
    try {
      final history = await widget.repository.loadAll();
      if (!mounted) return;
      setState(() {
        _history = history;
        _loadingHistory = false;
      });
    } on ComparisonLoadException catch (error) {
      if (!mounted) return;
      setState(() => _loadingHistory = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _compare() async {
    try {
      final offers = _forms.map((form) => form.toOffer()).toList(growable: false);
      final breakdowns = <String, PriceBreakdown>{
        for (final offer in offers)
          offer.id: calculatePrice(
            offer,
            context: PurchaseContext(shippingFee: offer.shippingFee),
          ),
      };
      final result = rankOffers(breakdowns);
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => ComparisonResultScreen(
            offers: offers,
            result: result,
            repository: widget.repository,
          ),
        ),
      );
      if (mounted) await _loadHistory();
    } on InputValidationException catch (error) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('入力内容を確認してください'),
          content: Text(error.messages.join('\n')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openSaved(SavedComparison saved) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ComparisonResultScreen(
          offers: saved.offers,
          result: saved.result,
          repository: widget.repository,
          savedAt: saved.savedAt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('価格を比較')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        children: [
          Text(
            '税込・割引・送料・ポイント・容量をまとめて比較します。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ..._forms.asMap().entries.map(
            (entry) => OfferInputCard(
              key: ValueKey<String>(entry.value.id),
              index: entry.key,
              controller: entry.value,
              canRemove: _forms.length > 2,
              onRemove: () => _removeOffer(entry.key),
            ),
          ),
          if (_forms.length < 5)
            OutlinedButton.icon(
              key: const Key('add-offer-button'),
              onPressed: _addOffer,
              icon: const Icon(Icons.add),
              label: const Text('商品を追加（最大5件）'),
            ),
          const SizedBox(height: 24),
          _historySection(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          key: const Key('compare-button'),
          onPressed: _compare,
          icon: const Icon(Icons.compare_arrows),
          label: const Text('計算して比較する'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _historySection() {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_history.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '保存した比較結果はここに表示されます。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('保存した比較', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ..._history.take(5).map(
          (saved) => Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text(saved.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                DateFormat('yyyy/MM/dd HH:mm').format(saved.savedAt.toLocal()),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openSaved(saved),
            ),
          ),
        ),
      ],
    );
  }

}
