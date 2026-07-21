/// lib/features/comparison/price_comparison_screen.dart
///
/// 2つの商品候補を入力し、税込・値引き・送料・ポイント・容量を含めて比較する画面。
/// 入力UIのみを担当し、計算は domain/price_comparison の純粋関数へ委譲する。
library;

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/price_comparison/price_calculator.dart';
import 'package:hee_no_tane_app/domain/price_comparison/price_comparator.dart';
import 'package:hee_no_tane_app/domain/price_comparison/price_comparison_models.dart';
import 'package:hee_no_tane_app/features/comparison/comparison_offer_card.dart';
import 'package:hee_no_tane_app/features/comparison/comparison_result_card.dart';

class PriceComparisonScreen extends StatefulWidget {
  const PriceComparisonScreen({super.key});

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen> {
  final _formKey = GlobalKey<FormState>();
  late List<ComparisonOfferControllers> _controllers;
  ComparisonResult? _result;
  int _formGeneration = 0;
  Map<String, PriceOffer> _offers = const <String, PriceOffer>{};

  @override
  void initState() {
    super.initState();
    _controllers = _newControllers();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<ComparisonOfferControllers> _newControllers() => [
    ComparisonOfferControllers(defaultStoreName: '候補A'),
    ComparisonOfferControllers(defaultStoreName: '候補B'),
  ];

  void _compare() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() != true) return;

    final quantities = _controllers
        .where((controller) => controller.quantity.text.trim().isNotEmpty)
        .toList(growable: false);
    if (quantities.length == _controllers.length &&
        quantities[0].unit.dimension != quantities[1].unit.dimension) {
      _showMessage('容量単価を比べる場合は、mlとL、gとkgなど同じ種類の単位を選んでください。');
      return;
    }

    try {
      final offers = <String, PriceOffer>{};
      final breakdowns = <String, PriceBreakdown>{};
      for (var index = 0; index < _controllers.length; index++) {
        final id = 'offer_$index';
        final fallback = '候補${String.fromCharCode(65 + index)}';
        final controller = _controllers[index];
        final offer = controller.toOffer(id: id, fallbackName: fallback);
        offers[id] = offer;
        breakdowns[id] = calculatePrice(
          offer,
          context: controller.toPurchaseContext(),
        );
      }

      setState(() {
        _offers = Map<String, PriceOffer>.unmodifiable(offers);
        _result = rankOffers(breakdowns);
      });
    } on FormatException {
      _showMessage('入力内容を確認してください。');
    }
  }

  void _reset() {
    final previousControllers = _controllers;
    setState(() {
      _controllers = _newControllers();
      _formGeneration++;
      _offers = const <String, PriceOffer>{};
      _result = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in previousControllers) {
        controller.dispose();
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('価格比較'),
        actions: [
          IconButton(
            tooltip: '入力をリセット',
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.compare_arrows),
                  SizedBox(width: 10),
                  Expanded(child: Text('価格だけでなく、税・値引き・送料・ポイント・容量をまとめて比較します。')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < _controllers.length; index++) ...[
              ComparisonOfferCard(
                key: ValueKey('comparison-offer-card-$_formGeneration-$index'),
                index: index,
                controllers: _controllers[index],
              ),
              if (index < _controllers.length - 1) const SizedBox(height: 14),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('comparison-submit'),
              onPressed: _compare,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('比較する'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (result != null) ...[
              const SizedBox(height: 18),
              ComparisonResultCard(result: result, offers: _offers),
            ],
          ],
        ),
      ),
    );
  }
}
