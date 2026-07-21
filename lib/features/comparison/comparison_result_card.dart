/// lib/features/comparison/comparison_result_card.dart
///
/// 価格比較の順位、差額、計算内訳、注意事項を表示する。
library;

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/domain/price_comparison/price_comparison_models.dart';

class ComparisonResultCard extends StatelessWidget {
  final ComparisonResult result;
  final Map<String, PriceOffer> offers;

  const ComparisonResultCard({
    super.key,
    required this.result,
    required this.offers,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final warnings = <PriceWarning>{
      ...result.warnings,
      for (final breakdown in result.breakdowns.values) ...breakdown.warnings,
    };

    return Card(
      key: const ValueKey('comparison-result'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.leaderboard_outlined, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  '比較結果',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _summary(context),
            if (result.canCompare) ...[
              const SizedBox(height: 16),
              Text(
                '比較基準: ${result.basis.label}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 10),
              ...result.rankedIds.indexed.map(
                (entry) => _rankingRow(context, entry.$1, entry.$2),
              ),
            ],
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 14),
              Divider(color: cs.outlineVariant),
              const SizedBox(height: 6),
              ...warnings.map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 17,
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          warning.message,
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
    );
  }

  Widget _summary(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!result.canCompare) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '比較できませんでした。2つの候補に価格を入力してください。',
          style: TextStyle(color: cs.onErrorContainer),
        ),
      );
    }

    final bestId = result.bestId;
    final title = bestId == null
        ? '2つの候補は同額です'
        : '${offers[bestId]?.storeName ?? bestId}がお得です';
    final difference = result.difference;
    final subtitle = difference == null || difference.isZero
        ? result.basis.label
        : '${_formatValue(difference, result.basis)}の差'
              '${result.percentageDifference == null ? '' : '（${result.percentageDifference!.toFixed(2)}%）'}';

    return Semantics(
      liveRegion: true,
      label: '$title。$subtitle',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              key: const ValueKey('comparison-best-label'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle),
          ],
        ),
      ),
    );
  }

  Widget _rankingRow(BuildContext context, int index, String id) {
    final offer = offers[id];
    final breakdown = result.breakdowns[id];
    final value = result.values[id];
    if (offer == null || breakdown == null || value == null) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey('comparison-ranking-$id'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: index == 0
            ? cs.primary.withValues(alpha: 0.06)
            : cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: index == 0 ? cs.primary : cs.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.storeName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  _breakdownSummary(breakdown),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatValue(value, result.basis),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _breakdownSummary(PriceBreakdown breakdown) {
    final payable = breakdown.payableNow;
    final effective = breakdown.effectiveCost;
    if (payable == null) return '支払額を計算できません';
    if (effective != null) {
      return '支払 ¥${payable.toFixed(0)} / 実質 ¥${effective.toFixed(0)}';
    }
    return '支払 ¥${payable.toFixed(0)}';
  }

  String _formatValue(DecimalValue value, ComparisonBasis basis) => switch (basis) {
    ComparisonBasis.cashTotal || ComparisonBasis.effectiveTotal =>
      '¥${value.toFixed(0)}',
    ComparisonBasis.cashUnitCost || ComparisonBasis.effectiveUnitCost =>
      '¥${value.toFixed(3)}/単位',
  };
}
