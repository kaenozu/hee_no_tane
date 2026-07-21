// src/test/kotlin/com/heenotane/pricing/PricingCalculatorTest.kt
//
// PricingCalculator の基本テスト。
//
// 関連:
//   - PricingCalculator.kt
//   - Models.kt

package com.heenotane.pricing

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.Arguments
import org.junit.jupiter.params.provider.MethodSource
import java.math.BigDecimal
import java.util.stream.Stream

class PricingCalculatorTest {

    // ===================================================================
    // 税計算
    // ===================================================================

    @Test
    fun `tax excluded basic 398 yen 10pct`() {
        val offer = Offer(
            id = "a", productName = "a", storeName = "a",
            price = BigDecimal("398"), taxIncluded = false, taxRate = BigDecimal("0.10"),
        )
        val bd = calculatePrice(offer)
        assertEquals(BigDecimal("398"), bd.preTaxPrice)
        assertEquals(BigDecimal("40"), bd.taxAmount)
        assertEquals(BigDecimal("438"), bd.basePriceInclTax)
    }

    @Test
    fun `tax included basic 398 yen 10pct`() {
        val offer = Offer(
            id = "a", productName = "a", storeName = "a",
            price = BigDecimal("398"), taxIncluded = true, taxRate = BigDecimal("0.10"),
        )
        val bd = calculatePrice(offer)
        assertEquals(BigDecimal("362"), bd.preTaxPrice)
        assertEquals(BigDecimal("36"), bd.taxAmount)
        assertEquals(BigDecimal("398"), bd.basePriceInclTax)
    }

    @Test
    fun `zero tax rate`() {
        val offer = Offer(
            id = "a", productName = "a", storeName = "a",
            price = BigDecimal("100"), taxIncluded = false, taxRate = BigDecimal.ZERO,
        )
        val bd = calculatePrice(offer)
        assertEquals(BigDecimal("0"), bd.taxAmount)
        assertEquals(BigDecimal("100"), bd.basePriceInclTax)
    }

    // ===================================================================
    // 割引
    // ===================================================================

    @Test
    fun `10 percent discount`() {
        val offer = Offer(
            id = "a", productName = "a", storeName = "a",
            price = BigDecimal("1000"), taxIncluded = true, taxRate = BigDecimal("0.10"),
            percentageDiscount = BigDecimal("0.10"),
        )
        val bd = calculatePrice(offer)
        assertEquals(BigDecimal("100"), bd.discountAmount)
        assertEquals(BigDecimal("900"), bd.payableNow)
    }

    // ===================================================================
    // クーポン
    // ===================================================================

    @Test
    fun `coupon 30 yen`() {
        val offer = Offer(
            id = "a", productName = "a", storeName = "a",
            price = BigDecimal("398"), taxIncluded = true, taxRate = BigDecimal("0.10"),
            couponDiscount = BigDecimal("30"),
        )
        val bd = calculatePrice(offer)
        assertEquals(BigDecimal("30"), bd.couponDiscount)
        assertEquals(BigDecimal("368"), bd.payableNow)
    }

    // ===================================================================
    // 送料
    // ===================================================================

    @Test
    fun `shipping fee added`() {
        val offer = Offer(
            id = "a", productName = "a", storeName = "a",
            price = BigDecimal("330"), taxIncluded = true, taxRate = BigDecimal("0.10"),
        )
        val ctx = PurchaseContext(shippingFee = BigDecimal("80"))
        val bd = calculatePrice(offer, context = ctx)
        assertEquals(BigDecimal("80"), bd.shippingFee)
        assertEquals(BigDecimal("410"), bd.payableNow)
    }

    // ===================================================================
    // ポイント
    // ===================================================================

    @Test
    fun `point rate 1pct`() {
        val offer = Offer(
            id = "a", productName = "a", storeName = "a",
            price = BigDecimal("398"), taxIncluded = true, taxRate = BigDecimal("0.10"),
            couponDiscount = BigDecimal("30"), pointRate = BigDecimal("0.01"),
        )
        val bd = calculatePrice(offer)
        assertEquals(BigDecimal("3"), bd.earnedPoints)
    }

    @Test
    fun `points missing warning`() {
        val offer = Offer(
            id = "a", productName = "a", storeName = "a",
            price = BigDecimal("1000"), taxIncluded = true, taxRate = BigDecimal("0.10"),
        )
        val bd = calculatePrice(offer)
        assertTrue(bd.warnings.contains(WarningCode.POINTS_MISSING.value))
    }

    // ===================================================================
    // 容量換算
    // ===================================================================

    @Test
    fun `unit cost 500ml x2`() {
        val offer = Offer(
            id = "a", productName = "a", storeName = "a",
            price = BigDecimal("500"), taxIncluded = true, taxRate = BigDecimal("0.10"),
            quantity = Quantity(BigDecimal("500"), Unit.ML, 2),
        )
        val bd = calculatePrice(offer)
        assertEquals(BigDecimal("1000"), bd.normalizedQuantity)
        assertEquals("ml", bd.quantityUnit)
        assertEquals(BigDecimal("0.500000"), bd.cashUnitCost)
    }

    // ===================================================================
    // 複合シナリオ
    // ===================================================================

    @Test
    fun `drugstore scenario`() {
        val offer = Offer(
            id = "drugstore",
            productName = "洗剤",
            storeName = "ドラッグストア",
            price = BigDecimal("980"),
            taxIncluded = false,
            taxRate = BigDecimal("0.10"),
            quantity = Quantity(BigDecimal("500"), Unit.ML, 2),
            percentageDiscount = BigDecimal("0.10"),
            couponDiscount = BigDecimal("100"),
            pointRate = BigDecimal("0.01"),
        )
        val ctx = PurchaseContext(shippingFee = BigDecimal.ZERO)
        val bd = calculatePrice(offer, context = ctx)
        assertEquals(BigDecimal("870"), bd.payableNow)
        assertEquals(BigDecimal("8"), bd.earnedPoints)
        assertEquals(BigDecimal("862"), bd.effectiveCost)
    }

    @Test
    fun `online scenario`() {
        val offer = Offer(
            id = "online",
            productName = "洗剤",
            storeName = "通販",
            price = BigDecimal("330"),
            taxIncluded = true,
            taxRate = BigDecimal("0.10"),
            quantity = Quantity(BigDecimal("1000"), Unit.ML),
            pointRate = BigDecimal("0.05"),
        )
        val ctx = PurchaseContext(shippingFee = BigDecimal("80"))
        val bd = calculatePrice(offer, context = ctx)
        assertEquals(BigDecimal("410"), bd.payableNow)
        assertEquals(BigDecimal("20"), bd.earnedPoints)
        assertEquals(BigDecimal("390"), bd.effectiveCost)
    }
}
