/// lib/domain/price_comparison/comparison_engine.dart
///
/// 複数商品の計算内訳から比較基準を選び、安い順へランキングする純粋関数。
/// 容量の次元・種類が異なる商品を誤って単価比較しないために存在する。
///
/// 関連:
///   - models.dart
///   - pricing_calculator.dart
library;

import 'models.dart';

ComparisonResult rankOffers(Map<String, PriceBreakdown> breakdowns) {
  final warnings = <WarningCode>[];
  final entries = breakdowns.entries.toList(growable: false);

  final quantityCount = entries
      .where((entry) => entry.value.normalizedQuantity != null)
      .length;
  if (quantityCount > 0 && quantityCount < entries.length) {
    warnings.add(WarningCode.quantityMissing);
  }

  final unitCompatible = _unitValuesAreCompatible(entries, warnings);
  final candidates = <ComparisonBasis>[
    if (unitCompatible) ComparisonBasis.effectiveUnitCost,
    if (unitCompatible) ComparisonBasis.cashUnitCost,
    ComparisonBasis.effectiveTotal,
    ComparisonBasis.cashTotal,
  ];

  ComparisonBasis? basis;
  for (final candidate in candidates) {
    final comparableCount = entries
        .where((entry) => _valueFor(entry.value, candidate) != null)
        .length;
    if (comparableCount >= 2) {
      basis = candidate;
      break;
    }
  }

  if (basis == null) {
    return ComparisonResult(
      basis: ComparisonBasis.cashTotal,
      breakdowns: Map<String, PriceBreakdown>.unmodifiable(breakdowns),
      incomparableIds: entries.map((entry) => entry.key).toList(),
      warnings: List<WarningCode>.unmodifiable([
        ...warnings,
        WarningCode.cannotCompare,
      ]),
    );
  }

  final values = <String, double>{};
  final incomparableIds = <String>[];
  for (final entry in entries) {
    final value = _valueFor(entry.value, basis);
    if (value == null) {
      incomparableIds.add(entry.key);
    } else {
      values[entry.key] = value;
    }
  }

  final rankedIds = values.keys.toList(growable: false)
    ..sort((left, right) => values[left]!.compareTo(values[right]!));
  if (rankedIds.length < 2) {
    return ComparisonResult(
      basis: basis,
      breakdowns: Map<String, PriceBreakdown>.unmodifiable(breakdowns),
      rankedIds: rankedIds,
      values: Map<String, double>.unmodifiable(values),
      incomparableIds: incomparableIds,
      warnings: List<WarningCode>.unmodifiable([
        ...warnings,
        WarningCode.cannotCompare,
      ]),
    );
  }

  final bestValue = values[rankedIds[0]]!;
  final secondValue = values[rankedIds[1]]!;
  final difference = secondValue - bestValue;
  final average = (bestValue + secondValue) / 2;
  final percentageDifference = average > 0
      ? double.parse(((difference / average) * 100).toStringAsFixed(2))
      : null;

  return ComparisonResult(
    basis: basis,
    breakdowns: Map<String, PriceBreakdown>.unmodifiable(breakdowns),
    rankedIds: List<String>.unmodifiable(rankedIds),
    bestId: difference == 0 ? null : rankedIds.first,
    values: Map<String, double>.unmodifiable(values),
    difference: difference,
    percentageDifference: percentageDifference,
    incomparableIds: List<String>.unmodifiable(incomparableIds),
    canCompare: true,
    warnings: List<WarningCode>.unmodifiable(warnings),
  );
}

ComparisonResult compareOffers(PriceBreakdown left, PriceBreakdown right) =>
    rankOffers(<String, PriceBreakdown>{'left': left, 'right': right});

double? _valueFor(PriceBreakdown breakdown, ComparisonBasis basis) =>
    switch (basis) {
      ComparisonBasis.effectiveUnitCost => breakdown.effectiveUnitCost,
      ComparisonBasis.cashUnitCost => breakdown.cashUnitCost,
      ComparisonBasis.effectiveTotal => breakdown.effectiveCost?.toDouble(),
      ComparisonBasis.cashTotal => breakdown.payableNow.toDouble(),
    };

bool _unitValuesAreCompatible(
  List<MapEntry<String, PriceBreakdown>> entries,
  List<WarningCode> warnings,
) {
  final withQuantity = entries
      .where((entry) => entry.value.normalizedQuantity != null)
      .map((entry) => entry.value)
      .toList(growable: false);
  if (withQuantity.length < 2) return false;

  final dimensions = withQuantity
      .map((breakdown) => breakdown.quantityDimension)
      .whereType<Dimension>()
      .toSet();
  if (dimensions.length > 1) {
    warnings.add(WarningCode.dimensionMismatch);
    return false;
  }

  final measureKinds = withQuantity
      .map((breakdown) => breakdown.measureKind)
      .whereType<MeasureKind>()
      .toSet();
  if (measureKinds.length > 1) {
    warnings.add(WarningCode.measureKindMismatch);
    return false;
  }
  return true;
}
