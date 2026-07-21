/// lib/domain/price_comparison/price_comparator.dart
///
/// 計算済み価格を最適な共通基準で順位付けする純粋関数。
/// Python版 price_compare/comparison.py の優先順位と差額計算を移植する。
library;

import 'price_comparison_models.dart';

ComparisonBasis? selectComparisonBasis(List<PriceBreakdown> breakdowns) {
  if (breakdowns.every((item) => item.effectiveUnitCost != null)) {
    return ComparisonBasis.effectiveUnitCost;
  }
  if (breakdowns.every((item) => item.cashUnitCost != null)) {
    return ComparisonBasis.cashUnitCost;
  }
  if (breakdowns.every((item) => item.effectiveCost != null)) {
    return ComparisonBasis.effectiveTotal;
  }
  if (breakdowns.every((item) => item.payableNow != null)) {
    return ComparisonBasis.cashTotal;
  }
  return null;
}

ComparisonResult rankOffers(Map<String, PriceBreakdown> breakdowns) {
  final entries = breakdowns.entries.toList(growable: false);
  final warnings = <PriceWarning>[];

  final quantityCount = entries
      .where((entry) => entry.value.normalizedQuantity != null)
      .length;
  if (quantityCount > 0 && quantityCount < entries.length) {
    warnings.add(PriceWarning.quantityMissing);
  }

  final basis = _findBestBasis(
    entries.map((entry) => entry.value).toList(growable: false),
  );
  if (basis == null) {
    return ComparisonResult(
      basis: ComparisonBasis.cashTotal,
      breakdowns: breakdowns,
      incomparableIds: entries.map((entry) => entry.key).toList(),
      warnings: <PriceWarning>[...warnings, PriceWarning.cannotCompare],
    );
  }

  final values = <String, DecimalValue>{};
  final incomparableIds = <String>[];
  for (final entry in entries) {
    final value = _getValue(entry.value, basis);
    if (value == null) {
      incomparableIds.add(entry.key);
    } else {
      values[entry.key] = value;
    }
  }

  final rankedIds = values.keys.toList()
    ..sort((left, right) => values[left]!.compareTo(values[right]!));

  final bestValue = values[rankedIds[0]]!;
  final secondValue = values[rankedIds[1]]!;
  final difference = secondValue - bestValue;
  final valueSum = bestValue + secondValue;
  final percentageDifference = valueSum.isPositive
      ? (difference * DecimalValue.fromInt(200)).divide(
          valueSum,
          resultScale: 2,
          rounding: MoneyRounding.halfUp,
        )
      : null;

  return ComparisonResult(
    basis: basis,
    breakdowns: breakdowns,
    rankedIds: rankedIds,
    bestId: difference.isZero ? null : rankedIds.first,
    values: values,
    difference: difference,
    percentageDifference: percentageDifference,
    incomparableIds: incomparableIds,
    canCompare: true,
    warnings: warnings,
  );
}

ComparisonResult compareOffers(PriceBreakdown first, PriceBreakdown second) =>
    rankOffers(<String, PriceBreakdown>{'left': first, 'right': second});

ComparisonBasis? _findBestBasis(List<PriceBreakdown> breakdowns) {
  for (final candidate in ComparisonBasis.values) {
    final available = breakdowns
        .where((item) => _getValue(item, candidate) != null)
        .length;
    if (available >= 2) return candidate;
  }
  return null;
}

DecimalValue? _getValue(PriceBreakdown breakdown, ComparisonBasis basis) =>
    switch (basis) {
      ComparisonBasis.effectiveUnitCost => breakdown.effectiveUnitCost,
      ComparisonBasis.cashUnitCost => breakdown.cashUnitCost,
      ComparisonBasis.effectiveTotal => breakdown.effectiveCost,
      ComparisonBasis.cashTotal => breakdown.payableNow,
    };
