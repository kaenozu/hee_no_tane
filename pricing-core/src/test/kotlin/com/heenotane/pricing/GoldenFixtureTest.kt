// src/test/kotlin/com/heenotane/pricing/GoldenFixtureTest.kt
//
// ゴールデンフィクスチャテスト。
// contracts/fixtures/*.json を読み込み、Kotlin 実装の結果と比較する。
//
// 関連:
//   - contracts/fixtures/ (JSON fixtures)
//   - PricingCalculator.kt
//   - ComparisonEngine.kt

package com.heenotane.pricing

import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.TestFactory
import java.io.File
import java.math.BigDecimal
import java.util.stream.Stream

class GoldenFixtureTest {

    private val fixtureDir: File = File("../price-comparison/contracts/fixtures").normalize()

    @TestFactory
    fun `validate golden fixtures`(): Stream<DynamicTest> {
        val fixtureFiles = fixtureDir.listFiles { f -> f.name.endsWith(".json") }
            ?.sortedBy { it.name }
            ?: emptyList()

        Assertions.assertTrue(fixtureFiles.isNotEmpty(), "No fixture files found at ${fixtureDir.absolutePath}")

        return fixtureFiles.map { file ->
            val name = file.nameWithoutExtension
            DynamicTest.dynamicTest("golden $name") {
                val json = JsonParser.parseString(file.readText()).asJsonObject
                val desc = json.get("description")?.asString ?: name
                val offersData = json.getAsJsonObject("offers")
                val contextsData = json.getAsJsonObject("contexts") ?: JsonObject()
                val expected = json.getAsJsonObject("expected")

                // Parse and calculate each offer
                val breakdowns = mutableMapOf<String, PriceBreakdown>()

                for ((oid, offerEl) in offersData.entrySet()) {
                    val offerObj = offerEl.asJsonObject
                    val offer = parseOffer(offerObj)
                    val ctx = parseContext(contextsData.get(oid)?.asJsonObject)
                    breakdowns[oid] = calculatePrice(offer, ctx)
                }

                // Check breakdowns
                val expectedBds = expected.getAsJsonObject("breakdowns")
                for ((oid, expectedBdEl) in expectedBds.entrySet()) {
                    val actualBd = breakdowns[oid]
                        ?: throw AssertionError("[$name] Missing breakdown for $oid")
                    val expectedBd = expectedBdEl.asJsonObject
                    val errors = findBreakdownErrors(actualBd, expectedBd, "$name.breakdowns.$oid")
                    if (errors.isNotEmpty()) {
                        throw AssertionError("[$name] Breakdown mismatches:\n${errors.joinToString("\n")}")
                    }
                }

                // Run ranking
                val result = rankOffers(breakdowns)

                // Check comparison
                val expectedCmp = expected.getAsJsonObject("comparison")
                val cmpErrors = findComparisonErrors(result, expectedCmp, "$name.comparison")
                if (cmpErrors.isNotEmpty()) {
                    throw AssertionError("[$name] Comparison mismatches:\n${cmpErrors.joinToString("\n")}")
                }
            }
        }.stream()
    }

    // ------------------------------------------------------------------
    // Parsing helpers
    // ------------------------------------------------------------------

    private fun dec(el: JsonElement?): BigDecimal? {
        if (el == null || el.isJsonNull) return null
        return BigDecimal(el.asString)
    }

    private fun str(el: JsonElement?): String? {
        if (el == null || el.isJsonNull) return null
        return el.asString
    }

    private fun bool(el: JsonElement?, default: Boolean = false): Boolean {
        if (el == null || el.isJsonNull) return default
        return el.asBoolean
    }

    private fun intVal(el: JsonElement?, default: Int = 1): Int {
        if (el == null || el.isJsonNull) return default
        return el.asInt
    }

    private fun parseQuantity(obj: JsonElement?): Quantity? {
        if (obj == null || obj.isJsonNull) return null
        val o = obj.asJsonObject
        return Quantity(
            value = BigDecimal(o.get("value").asString),
            unit = Unit.fromValue(o.get("unit").asString),
            packageCount = intVal(o.get("package_count")),
            measureKind = MeasureKind.fromValue(str(o.get("measure_kind")) ?: "ITEM"),
        )
    }

    private fun parseOffer(obj: JsonObject): Offer {
        return Offer(
            id = obj.get("id").asString,
            productName = obj.get("product_name").asString,
            storeName = obj.get("store_name").asString,
            price = BigDecimal(obj.get("price").asString),
            taxIncluded = obj.get("tax_included").asBoolean,
            taxRate = BigDecimal(obj.get("tax_rate").asString),
            quantity = parseQuantity(obj.get("quantity")),
            percentageDiscount = dec(obj.get("percentage_discount")) ?: BigDecimal.ZERO,
            fixedDiscount = dec(obj.get("fixed_discount")) ?: BigDecimal.ZERO,
            couponDiscount = dec(obj.get("coupon_discount")) ?: BigDecimal.ZERO,
            couponMinimumSubtotal = dec(obj.get("coupon_minimum_subtotal")),
            pointRate = dec(obj.get("point_rate")) ?: BigDecimal.ZERO,
            fixedPoints = dec(obj.get("fixed_points")) ?: BigDecimal.ZERO,
            earnedPoints = dec(obj.get("earned_points")),
            shippingFee = dec(obj.get("shipping_fee")),
        )
    }

    private fun parseContext(obj: JsonObject?): PurchaseContext {
        if (obj == null) return PurchaseContext()
        return PurchaseContext(
            shippingFee = dec(obj.get("shipping_fee")),
            shippingAllocation = ShippingAllocation.fromValue(
                str(obj.get("shipping_allocation")) ?: "ALLOCATED_TO_ITEM"
            ),
            checkoutTotalOverride = dec(obj.get("checkout_total_override")),
        )
    }

    // ------------------------------------------------------------------
    // Error comparison helpers
    // ------------------------------------------------------------------

    private fun findBreakdownErrors(
        actual: PriceBreakdown,
        expected: JsonObject,
        path: String,
    ): List<String> {
        val errors = mutableListOf<String>()

        fun check(field: String, expectedVal: JsonElement?, actualVal: Any?) {
            val p = "$path.$field"
            if (expectedVal == null || expectedVal.isJsonNull) {
                if (actualVal != null) {
                    val aStr = actualVal.toString()
                    if (aStr != "0" && aStr != "0.0") { // skip zero defaults
                        errors.add("$p: expected=null actual=$aStr")
                    }
                }
            } else {
                val eStr = expectedVal.asString
                val aStr = when (actualVal) {
                    is BigDecimal -> actualVal.toPlainString()
                    is Boolean -> actualVal.toString()
                    is String -> actualVal
                    is List<*> -> actualVal.joinToString(",")
                    null -> "null"
                    else -> actualVal.toString()
                }
                if (eStr != aStr) {
                    errors.add("$p: expected=$eStr actual=$aStr")
                }
            }
        }

        check("display_price", expected.get("display_price"), actual.displayPrice)
        check("tax_included", expected.get("tax_included"), actual.taxIncluded)
        check("tax_rate", expected.get("tax_rate"), actual.taxRate)
        check("pre_tax_price", expected.get("pre_tax_price"), actual.preTaxPrice)
        check("tax_amount", expected.get("tax_amount"), actual.taxAmount)
        check("base_price_incl_tax", expected.get("base_price_incl_tax"), actual.basePriceInclTax)
        check("percentage_discount", expected.get("percentage_discount"), actual.percentageDiscount)
        check("fixed_discount", expected.get("fixed_discount"), actual.fixedDiscount)
        check("coupon_discount", expected.get("coupon_discount"), actual.couponDiscount)
        check("discount_amount", expected.get("discount_amount"), actual.discountAmount)
        check("shipping_fee", expected.get("shipping_fee"), actual.shippingFee)
        check("payable_now", expected.get("payable_now"), actual.payableNow)
        check("earned_points", expected.get("earned_points"), actual.earnedPoints)
        check("point_value", expected.get("point_value"), actual.pointValue)
        check("effective_cost", expected.get("effective_cost"), actual.effectiveCost)
        check("normalized_quantity", expected.get("normalized_quantity"), actual.normalizedQuantity)
        check("quantity_unit", expected.get("quantity_unit"), actual.quantityUnit)
        check("cash_unit_cost", expected.get("cash_unit_cost"), actual.cashUnitCost)
        check("effective_unit_cost", expected.get("effective_unit_cost"), actual.effectiveUnitCost)
        check("cash_complete", expected.get("cash_complete"), actual.cashComplete)
        check("reward_complete", expected.get("reward_complete"), actual.rewardComplete)
        check("unit_complete", expected.get("unit_complete"), actual.unitComplete)

        // Warnings as list of strings
        val expectedWarnings = expected.getAsJsonArray("warnings")
        if (expectedWarnings != null) {
            val eWarn = expectedWarnings.map { it.asString }
            val aWarn = actual.warnings
            if (eWarn != aWarn) {
                errors.add("$path.warnings: expected=$eWarn actual=$aWarn")
            }
        }

        return errors
    }

    private fun findComparisonErrors(
        actual: ComparisonResult,
        expected: JsonObject,
        path: String,
    ): List<String> {
        val errors = mutableListOf<String>()

        if (expected.has("basis")) {
            val expBasis = if (expected.get("basis").isJsonNull) null else expected.get("basis").asString
            val actBasis = actual.basis?.value
            if (expBasis != actBasis) errors.add("$path.basis: expected=$expBasis actual=$actBasis")
        }
        if (expected.has("ranked_ids")) {
            val expRanked = expected.getAsJsonArray("ranked_ids").map { it.asString }
            if (expRanked != actual.rankedIds) errors.add("$path.ranked_ids: expected=$expRanked actual=${actual.rankedIds}")
        }
        if (expected.has("best_id")) {
            val expBest = if (expected.get("best_id").isJsonNull) null else expected.get("best_id").asString
            if (expBest != actual.bestId) errors.add("$path.best_id: expected=$expBest actual=${actual.bestId}")
        }
        if (expected.has("difference")) {
            val expDiff = if (expected.get("difference").isJsonNull) null else expected.get("difference").asString
            val actDiff = actual.difference?.toPlainString()
            if (expDiff != actDiff) errors.add("$path.difference: expected=$expDiff actual=$actDiff")
        }
        if (expected.has("percentage_difference")) {
            val expPct = if (expected.get("percentage_difference").isJsonNull) null else expected.get("percentage_difference").asString
            val actPct = actual.percentageDifference?.toPlainString()
            if (expPct != actPct) errors.add("$path.percentage_difference: expected=$expPct actual=$actPct")
        }
        if (expected.has("incomparable_ids")) {
            val expInc = expected.getAsJsonArray("incomparable_ids").map { it.asString }
            if (expInc != actual.incomparableIds) errors.add("$path.incomparable_ids: expected=$expInc actual=${actual.incomparableIds}")
        }
        if (expected.has("can_compare")) {
            val expCmp = expected.get("can_compare").asBoolean
            if (expCmp != actual.canCompare) errors.add("$path.can_compare: expected=$expCmp actual=${actual.canCompare}")
        }
        if (expected.has("values")) {
            val expVals = expected.getAsJsonObject("values")
            for ((k, v) in expVals.entrySet()) {
                val expVal = if (v.isJsonNull) null else v.asString
                val actVal = actual.values[k]?.toPlainString()
                if (expVal != actVal) errors.add("$path.values.$k: expected=$expVal actual=$actVal")
            }
        }
        if (expected.has("warnings")) {
            val expWarn = expected.getAsJsonArray("warnings").map { it.asString }
            if (expWarn != actual.warnings) errors.add("$path.warnings: expected=$expWarn actual=${actual.warnings}")
        }

        return errors
    }
}
