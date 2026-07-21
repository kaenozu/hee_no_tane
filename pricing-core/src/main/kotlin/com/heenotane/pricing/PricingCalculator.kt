// src/main/kotlin/com/heenotane/pricing/PricingCalculator.kt
//
// 単一オファーの価格計算を行う純粋関数。
// Python版 price_compare/pricing.py のKotlin移植。
//
// 計算順序:
//   税抜価格 → 税込基準価格 → 商品割引 → クーポン → 送料加算
//   → 支払金額 → ポイント還元控除 → 実質価格 → 容量換算単価
//
// 関連:
//   - Models.kt (データモデル)
//   - ComparisonEngine.kt (比較関数)

package com.heenotane.pricing

import java.math.BigDecimal
import java.math.RoundingMode

// ---------------------------------------------------------------------------
// 丸めマッピング
// ---------------------------------------------------------------------------

private fun roundingMode(r: MoneyRounding): RoundingMode = when (r) {
    MoneyRounding.HALF_UP -> RoundingMode.HALF_UP
    MoneyRounding.DOWN -> RoundingMode.DOWN
    MoneyRounding.UP -> RoundingMode.UP
}

private fun round(value: BigDecimal, rounding: MoneyRounding, scale: Int = 0): BigDecimal {
    return value.setScale(scale, roundingMode(rounding))
}

// ---------------------------------------------------------------------------
// 税計算
// ---------------------------------------------------------------------------

private data class TaxResult(
    val preTaxPrice: BigDecimal,
    val taxAmount: BigDecimal,
    val basePriceInclTax: BigDecimal,
)

private fun calculateTax(
    price: BigDecimal,
    taxIncluded: Boolean,
    taxRate: BigDecimal,
    policy: CalculationPolicy,
): TaxResult {
    if (taxRate.compareTo(BigDecimal.ZERO) == 0) {
        return TaxResult(price, BigDecimal.ZERO, price)
    }
    return if (taxIncluded) {
        val gross = price
        val tax = gross.multiply(taxRate)
            .divide(BigDecimal.ONE.add(taxRate), 10, RoundingMode.HALF_UP)
            .setScale(0, roundingMode(policy.taxRounding))
        val preTax = gross.subtract(tax)
        TaxResult(preTax, tax, gross)
    } else {
        val preTax = price
        val tax = price.multiply(taxRate).setScale(0, roundingMode(policy.taxRounding))
        val gross = preTax.add(tax)
        TaxResult(preTax, tax, gross)
    }
}

// ---------------------------------------------------------------------------
// 割引・クーポン計算
// ---------------------------------------------------------------------------

private data class DiscountResult(
    val afterDiscount: BigDecimal,
    val discountTotal: BigDecimal,
    val couponActual: BigDecimal,
    val warnings: MutableList<String>,
)

private fun calculateDiscounts(
    basePrice: BigDecimal,
    percentageDiscount: BigDecimal,
    fixedDiscount: BigDecimal,
    couponDiscount: BigDecimal,
    couponMinimumSubtotal: BigDecimal?,
    policy: CalculationPolicy,
): DiscountResult {
    val warnings = mutableListOf<String>()
    var current = basePrice

    if (percentageDiscount.compareTo(BigDecimal.ZERO) > 0) {
        val amount = current.multiply(percentageDiscount)
            .setScale(0, roundingMode(policy.discountRounding))
        if (amount.compareTo(current) > 0) {
            warnings.add(WarningCode.DISCOUNT_EXCEEDS_PRICE.value)
        } else {
            current = current.subtract(amount)
        }
    }

    if (fixedDiscount.compareTo(BigDecimal.ZERO) > 0) {
        if (fixedDiscount.compareTo(current) > 0) {
            warnings.add(WarningCode.DISCOUNT_EXCEEDS_PRICE.value)
            current = BigDecimal.ZERO
        } else {
            current = current.subtract(fixedDiscount)
        }
    }

    var couponActual = BigDecimal.ZERO
    if (couponDiscount.compareTo(BigDecimal.ZERO) > 0) {
        if (couponMinimumSubtotal != null && basePrice.compareTo(couponMinimumSubtotal) < 0) {
            // クーポン不適用
        } else {
            if (couponDiscount.compareTo(current) > 0) {
                warnings.add(WarningCode.COUPON_EXCEEDS_REMAINING.value)
                couponActual = current
            } else {
                couponActual = couponDiscount
            }
            current = current.subtract(couponActual)
        }
    }

    // 割引額合計を計算
    var discountTotal = if (percentageDiscount.compareTo(BigDecimal.ZERO) > 0) {
        round(basePrice.multiply(percentageDiscount), policy.discountRounding)
    } else {
        BigDecimal.ZERO
    }
    discountTotal = discountTotal.add(fixedDiscount)
    discountTotal = discountTotal.add(couponActual)

    var afterDiscount = basePrice.subtract(discountTotal)
    if (afterDiscount.compareTo(BigDecimal.ZERO) < 0) {
        afterDiscount = BigDecimal.ZERO
    }

    return DiscountResult(afterDiscount, discountTotal, couponActual, warnings)
}

// ---------------------------------------------------------------------------
// メイン計算関数
// ---------------------------------------------------------------------------

fun calculatePrice(
    offer: Offer,
    context: PurchaseContext? = null,
    policy: CalculationPolicy? = null,
): PriceBreakdown {
    val ctx = context ?: PurchaseContext()
    val pol = policy ?: CalculationPolicy()

    val warnings = mutableListOf<String>()

    // ---- ステップ1: 税計算 ----
    val (preTaxPrice, taxAmount, basePriceInclTax) = calculateTax(
        offer.price, offer.taxIncluded, offer.taxRate, pol,
    )

    // ---- ステップ2: 割引・クーポン ----
    val (afterDiscount, discountTotal, couponActual, discWarnings) = calculateDiscounts(
        basePriceInclTax,
        offer.percentageDiscount,
        offer.fixedDiscount,
        offer.couponDiscount,
        offer.couponMinimumSubtotal,
        pol,
    )
    warnings.addAll(discWarnings)

    // ---- ステップ3: 送料 ----
    val shippingFee: BigDecimal? = ctx.shippingFee
    if (shippingFee != null && ctx.shippingAllocation == ShippingAllocation.FULL_ORDER) {
        warnings.add(WarningCode.SHIPPING_FULL_ORDER.value)
    }

    var payableNow: BigDecimal? = afterDiscount
    if (shippingFee != null) {
        payableNow = payableNow!!.add(shippingFee)
    }

    // ---- ステップ4: ポイント ----
    val earnedPoints: BigDecimal?
    if (offer.earnedPoints != null) {
        earnedPoints = offer.earnedPoints
    } else if (offer.pointRate.compareTo(BigDecimal.ZERO) > 0 || offer.fixedPoints.compareTo(BigDecimal.ZERO) > 0) {
        val pointsFromRate = payableNow!!.multiply(offer.pointRate)
            .setScale(0, RoundingMode.DOWN)
        earnedPoints = pointsFromRate.add(offer.fixedPoints)
    } else {
        earnedPoints = null
    }

    val pointValue: BigDecimal?
    val effectiveCost: BigDecimal?
    if (earnedPoints != null) {
        pointValue = round(earnedPoints.multiply(pol.pointValueRate), pol.discountRounding)
        effectiveCost = payableNow!!.subtract(pointValue)
        if (effectiveCost.compareTo(BigDecimal.ZERO) < 0) {
            warnings.add(WarningCode.NEGATIVE_EFFECTIVE_COST.value)
        }
    } else {
        pointValue = null
        effectiveCost = null
        warnings.add(WarningCode.POINTS_MISSING.value)
    }

    // ---- ステップ5: 容量換算 ----
    var normalizedQuantity: BigDecimal? = null
    var quantityUnit: String? = null
    var cashUnitCost: BigDecimal? = null
    var effectiveUnitCost: BigDecimal? = null

    if (offer.quantity != null && offer.quantity.value.compareTo(BigDecimal.ZERO) > 0) {
        val q = offer.quantity
        normalizedQuantity = q.normalizedTotal()
        quantityUnit = q.unit.value
        if (payableNow != null && payableNow.compareTo(BigDecimal.ZERO) > 0) {
            cashUnitCost = payableNow.divide(normalizedQuantity, 6, RoundingMode.HALF_UP)
        }
        if (effectiveCost != null && effectiveCost.compareTo(BigDecimal.ZERO) >= 0 && normalizedQuantity.compareTo(BigDecimal.ZERO) > 0) {
            effectiveUnitCost = effectiveCost.divide(normalizedQuantity, 6, RoundingMode.HALF_UP)
        }
    } else if (offer.quantity != null && offer.quantity.value.compareTo(BigDecimal.ZERO) == 0) {
        warnings.add(WarningCode.QUANTITY_ZERO.value)
    }

    // ---- 計算状態 ----
    val cashComplete = payableNow != null
    val rewardComplete = effectiveCost != null
    val unitComplete = cashUnitCost != null && normalizedQuantity != null

    return PriceBreakdown(
        displayPrice = offer.price,
        taxIncluded = offer.taxIncluded,
        taxRate = offer.taxRate,
        preTaxPrice = preTaxPrice,
        taxAmount = taxAmount,
        basePriceInclTax = basePriceInclTax,
        percentageDiscount = offer.percentageDiscount,
        fixedDiscount = offer.fixedDiscount,
        couponDiscount = couponActual,
        discountAmount = discountTotal,
        shippingFee = shippingFee,
        payableNow = payableNow,
        earnedPoints = earnedPoints,
        pointValue = pointValue,
        effectiveCost = effectiveCost,
        normalizedQuantity = normalizedQuantity,
        quantityUnit = quantityUnit,
        cashUnitCost = cashUnitCost,
        effectiveUnitCost = effectiveUnitCost,
        cashComplete = cashComplete,
        rewardComplete = rewardComplete,
        unitComplete = unitComplete,
        warnings = warnings.toList(),
    )
}
