// src/main/kotlin/com/heenotane/pricing/ComparisonEngine.kt
//
// 価格比較と順位付けを行う純粋関数。
// Python版 price_compare/comparison.py のKotlin移植。
//
// 関連:
//   - Models.kt (データモデル)
//   - PricingCalculator.kt (計算関数)

package com.heenotane.pricing

import java.math.BigDecimal
import java.math.RoundingMode

// ---------------------------------------------------------------------------
// 比較基準選択
// ---------------------------------------------------------------------------

data class BasisResult(
    val basis: ComparisonBasis?,
    val warnings: List<String>,
)

/**
 * 少なくとも2件の内訳が持つ最適な比較基準を選択する。
 * Python版 comparison.py の _find_best_basis に対応。
 */
fun findBestBasis(breakdowns: Collection<PriceBreakdown>): BasisResult {
    val warnings = mutableListOf<String>()

    for (candidate in listOf(
        ComparisonBasis.EFFECTIVE_UNIT_COST,
        ComparisonBasis.CASH_UNIT_COST,
        ComparisonBasis.EFFECTIVE_TOTAL,
        ComparisonBasis.CASH_TOTAL,
    )) {
        val count = breakdowns.count { bd -> getComparisonValue(bd, candidate) != null }
        if (count >= 2) {
            return BasisResult(candidate, warnings)
        }
    }

    return BasisResult(null, warnings)
}

/**
 * Python版 comparison.py の select_basis に対応（全件一致用）。
 */
fun selectBasis(breakdowns: Collection<PriceBreakdown>): BasisResult {
    val warnings = mutableListOf<String>()

    if (breakdowns.all { it.effectiveUnitCost != null }) {
        return BasisResult(ComparisonBasis.EFFECTIVE_UNIT_COST, warnings)
    }
    if (breakdowns.all { it.cashUnitCost != null }) {
        return BasisResult(ComparisonBasis.CASH_UNIT_COST, warnings)
    }
    if (breakdowns.all { it.effectiveCost != null }) {
        return BasisResult(ComparisonBasis.EFFECTIVE_TOTAL, warnings)
    }
    if (breakdowns.all { it.payableNow != null }) {
        return BasisResult(ComparisonBasis.CASH_TOTAL, warnings)
    }

    return BasisResult(null, warnings)
}

// ---------------------------------------------------------------------------
// 比較基準値の取得
// ---------------------------------------------------------------------------

private fun getComparisonValue(bd: PriceBreakdown, basis: ComparisonBasis): BigDecimal? {
    return when (basis) {
        ComparisonBasis.EFFECTIVE_UNIT_COST -> bd.effectiveUnitCost
        ComparisonBasis.CASH_UNIT_COST -> bd.cashUnitCost
        ComparisonBasis.EFFECTIVE_TOTAL -> bd.effectiveCost
        ComparisonBasis.CASH_TOTAL -> bd.payableNow
    }
}

// ---------------------------------------------------------------------------
// rank_offers（複数オファー順位付け）
// ---------------------------------------------------------------------------

/**
 * 複数のオファーを比較し、安い順にランク付けする。
 * Python版 comparison.py の rank_offers に対応。
 *
 * @param breakdowns id→PriceBreakdown のマップ
 * @return 比較結果（ComparisonResult）
 */
fun rankOffers(breakdowns: Map<String, PriceBreakdown>): ComparisonResult {
    val items = breakdowns.entries.toList()
    val warnings = mutableListOf<String>()

    // ---- 数量の一致確認 ----
    val hasQty = items.filter { (_, b) -> b.normalizedQuantity != null }.map { it.key }.toSet()
    if (hasQty.isNotEmpty() && hasQty.size < items.size) {
        warnings.add(WarningCode.QUANTITY_MISSING.value)
    }

    // ---- 最適な比較基準を選択（少なくとも2件カバーするもの） ----
    val allBreakdowns = items.map { (_, b) -> b }
    val (basis, basisWarnings) = findBestBasis(allBreakdowns)
    warnings.addAll(basisWarnings)

    if (basis == null) {
        return ComparisonResult(
            basis = ComparisonBasis.CASH_TOTAL,
            breakdowns = breakdowns,
            incomparableIds = items.map { (id, _) -> id },
            canCompare = false,
            warnings = warnings + WarningCode.CANNOT_COMPARE.value,
        )
    }

    // ---- 各オファーの値を取得 ----
    val valueMap = mutableMapOf<String, BigDecimal>()
    val incomparable = mutableListOf<String>()

    for ((id, bd) in items) {
        val value = getComparisonValue(bd, basis)
        if (value != null) {
            valueMap[id] = value
        } else {
            incomparable.add(id)
        }
    }

    // ---- 値でソート（安定ソート、同値は元の順序を維持） ----
    val sortedIds = valueMap.entries
        .sortedBy { it.value }
        .map { it.key }

    // ---- 差の計算（最安 vs 2位） ----
    val bestVal = valueMap[sortedIds[0]]!!
    val secondVal = valueMap[sortedIds[1]]!!
    val difference = secondVal.subtract(bestVal)

    var bestId: String? = sortedIds[0]
    if (difference.compareTo(BigDecimal.ZERO) == 0) {
        bestId = null
    }

    // 相対差率 (Python: avg = (best+second)/2, then (diff/avg)*100)
    val avg = bestVal.add(secondVal).divide(BigDecimal("2"), 10, RoundingMode.HALF_UP)
    val percentageDifference: BigDecimal? = if (avg.compareTo(BigDecimal.ZERO) > 0) {
        difference.divide(avg, 10, RoundingMode.HALF_UP)
            .multiply(BigDecimal("100"))
            .setScale(2, RoundingMode.HALF_UP)
    } else {
        null
    }

    return ComparisonResult(
        basis = basis,
        breakdowns = breakdowns,
        rankedIds = sortedIds,
        bestId = bestId,
        values = valueMap,
        difference = difference,
        percentageDifference = percentageDifference,
        incomparableIds = incomparable,
        canCompare = true,
        warnings = warnings,
    )
}

// ---------------------------------------------------------------------------
// compare_offers（2件互換ラッパー）
// ---------------------------------------------------------------------------

/**
 * 2件のオファーを比較する。rankOffersの互換ラッパー。
 * Python版 comparison.py の compare_offers に対応。
 */
fun compareOffers(left: PriceBreakdown, right: PriceBreakdown): ComparisonResult {
    return rankOffers(linkedMapOf("left" to left, "right" to right))
}
