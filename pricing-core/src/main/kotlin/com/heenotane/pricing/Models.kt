// src/main/kotlin/com/heenotane/pricing/Models.kt
//
// 価格比較アプリの入力・出力データモデル。
// Python版 price_compare/models.py のKotlin移植。
//
// 関連:
//   - PricingCalculator.kt (計算関数)
//   - ComparisonEngine.kt (比較関数)
//   - InputValidator.kt (入力検証)

package com.heenotane.pricing

import java.math.BigDecimal
import java.math.RoundingMode

// ---------------------------------------------------------------------------
// 列挙型
// ---------------------------------------------------------------------------

enum class MoneyRounding(val value: String) {
    HALF_UP("HALF_UP"),
    DOWN("DOWN"),
    UP("UP");

    companion object {
        fun fromValue(s: String): MoneyRounding = entries.first { it.value == s }
    }
}

enum class Unit(val value: String) {
    ML("ml"),
    L("L"),
    G("g"),
    KG("kg"),
    PIECE("piece");

    companion object {
        fun fromValue(s: String): Unit = entries.first { it.value == s }
    }
}

enum class Dimension {
    VOLUME, MASS, COUNT
}

enum class MeasureKind(val value: String) {
    GENERIC_VOLUME("GENERIC_VOLUME"),
    GENERIC_MASS("GENERIC_MASS"),
    ITEM("ITEM"),
    TABLET("TABLET"),
    CAPSULE("CAPSULE"),
    SHEET("SHEET"),
    ROLL("ROLL"),
    BAG("BAG");

    companion object {
        fun fromValue(s: String): MeasureKind = entries.first { it.value == s }
    }
}

enum class ComparisonBasis(val value: String) {
    EFFECTIVE_UNIT_COST("EFFECTIVE_UNIT_COST"),
    CASH_UNIT_COST("CASH_UNIT_COST"),
    EFFECTIVE_TOTAL("EFFECTIVE_TOTAL"),
    CASH_TOTAL("CASH_TOTAL");

    companion object {
        fun fromValue(s: String): ComparisonBasis = entries.first { it.value == s }
    }
}

enum class ShippingAllocation(val value: String) {
    FULL_ORDER("FULL_ORDER"),
    ALLOCATED_TO_ITEM("ALLOCATED_TO_ITEM"),
    EXCLUDED("EXCLUDED"),
    UNKNOWN("UNKNOWN");

    companion object {
        fun fromValue(s: String): ShippingAllocation = entries.first { it.value == s }
    }
}

enum class WarningCode(val value: String) {
    POINTS_MISSING("POINTS_MISSING"),
    QUANTITY_MISSING("QUANTITY_MISSING"),
    SHIPPING_FULL_ORDER("SHIPPING_FULL_ORDER"),
    DISCOUNT_EXCEEDS_PRICE("DISCOUNT_EXCEEDS_PRICE"),
    COUPON_EXCEEDS_REMAINING("COUPON_EXCEEDS_REMAINING"),
    POINTS_EXCEED_PAYABLE("POINTS_EXCEED_PAYABLE"),
    NEGATIVE_EFFECTIVE_COST("NEGATIVE_EFFECTIVE_COST"),
    DIMENSION_MISMATCH("DIMENSION_MISMATCH"),
    MEASURE_KIND_MISMATCH("MEASURE_KIND_MISMATCH"),
    CANNOT_COMPARE("CANNOT_COMPARE"),
    PROMOTIONAL_ANOMALY("PROMOTIONAL_ANOMALY"),
    QUANTITY_ZERO("QUANTITY_ZERO"),
    UNKNOWN_FIELD("UNKNOWN_FIELD"),
    UNSUPPORTED_SCHEMA("UNSUPPORTED_SCHEMA");

    companion object {
        fun fromValue(s: String): WarningCode = entries.first { it.value == s }
    }
}

// ---------------------------------------------------------------------------
// ユーティリティ
// ---------------------------------------------------------------------------

private val unitFactors: Map<Unit, BigDecimal> = mapOf(
    Unit.ML to BigDecimal("1"),
    Unit.L to BigDecimal("1000"),
    Unit.G to BigDecimal("1"),
    Unit.KG to BigDecimal("1000"),
    Unit.PIECE to BigDecimal("1"),
)

private val unitDimensions: Map<Unit, Dimension> = mapOf(
    Unit.ML to Dimension.VOLUME,
    Unit.L to Dimension.VOLUME,
    Unit.G to Dimension.MASS,
    Unit.KG to Dimension.MASS,
    Unit.PIECE to Dimension.COUNT,
)

fun unitToFactor(unit: Unit): BigDecimal = unitFactors[unit]!!

fun unitToDimension(unit: Unit): Dimension = unitDimensions[unit]!!

// ---------------------------------------------------------------------------
// 入力モデル
// ---------------------------------------------------------------------------

data class Quantity(
    val value: BigDecimal,
    val unit: Unit,
    val packageCount: Int = 1,
    val measureKind: MeasureKind = MeasureKind.ITEM,
) {
    fun normalizedTotal(): BigDecimal =
        value.multiply(unitToFactor(unit)).multiply(BigDecimal(packageCount))
}

data class Offer(
    val id: String,
    val productName: String,
    val storeName: String,
    val price: BigDecimal,
    val taxIncluded: Boolean,
    val taxRate: BigDecimal,
    val quantity: Quantity? = null,
    val percentageDiscount: BigDecimal = BigDecimal.ZERO,
    val fixedDiscount: BigDecimal = BigDecimal.ZERO,
    val couponDiscount: BigDecimal = BigDecimal.ZERO,
    val couponMinimumSubtotal: BigDecimal? = null,
    val pointRate: BigDecimal = BigDecimal.ZERO,
    val fixedPoints: BigDecimal = BigDecimal.ZERO,
    val earnedPoints: BigDecimal? = null,
    val shippingFee: BigDecimal? = null,
)

data class PurchaseContext(
    val shippingFee: BigDecimal? = null,
    val shippingAllocation: ShippingAllocation = ShippingAllocation.ALLOCATED_TO_ITEM,
    val checkoutTotalOverride: BigDecimal? = null,
)

data class CalculationPolicy(
    val taxRounding: MoneyRounding = MoneyRounding.HALF_UP,
    val discountRounding: MoneyRounding = MoneyRounding.HALF_UP,
    val pointValueRate: BigDecimal = BigDecimal.ONE,
)

// ---------------------------------------------------------------------------
// 出力モデル
// ---------------------------------------------------------------------------

data class PriceBreakdown(
    val displayPrice: BigDecimal,
    val taxIncluded: Boolean,
    val taxRate: BigDecimal,

    val preTaxPrice: BigDecimal? = null,
    val taxAmount: BigDecimal? = null,
    val basePriceInclTax: BigDecimal? = null,

    val percentageDiscount: BigDecimal = BigDecimal.ZERO,
    val fixedDiscount: BigDecimal = BigDecimal.ZERO,
    val couponDiscount: BigDecimal = BigDecimal.ZERO,
    val discountAmount: BigDecimal = BigDecimal.ZERO,

    val shippingFee: BigDecimal? = null,

    val payableNow: BigDecimal? = null,

    val earnedPoints: BigDecimal? = null,
    val pointValue: BigDecimal? = null,
    val effectiveCost: BigDecimal? = null,

    val normalizedQuantity: BigDecimal? = null,
    val quantityUnit: String? = null,
    val cashUnitCost: BigDecimal? = null,
    val effectiveUnitCost: BigDecimal? = null,

    val cashComplete: Boolean = false,
    val rewardComplete: Boolean = false,
    val unitComplete: Boolean = false,

    val warnings: List<String> = emptyList(),
) {
    fun isCashComparable(): Boolean = cashComplete && payableNow != null

    fun isRewardComparable(): Boolean = rewardComplete && effectiveCost != null

    fun isUnitComparable(): Boolean = unitComplete && cashUnitCost != null
}

data class ComparisonResult(
    val basis: ComparisonBasis?,
    val breakdowns: Map<String, PriceBreakdown>,
    val rankedIds: List<String> = emptyList(),
    val bestId: String? = null,
    val values: Map<String, BigDecimal> = emptyMap(),
    val difference: BigDecimal? = null,
    val percentageDifference: BigDecimal? = null,
    val incomparableIds: List<String> = emptyList(),
    val canCompare: Boolean = false,
    val warnings: List<String> = emptyList(),
)
