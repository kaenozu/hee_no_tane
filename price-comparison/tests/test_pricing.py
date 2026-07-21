# tests/test_pricing.py
#
# 価格計算 (pricing.py) のテスト。
# 税、割引、クーポン、ポイント、送料、容量換算の各ステップを検証する。
#
# 関連:
#   - pricing.py
#   - models.py

from decimal import Decimal

from price_compare.models import (
    CalculationPolicy,
    MoneyRounding,
    Offer,
    PurchaseContext,
    Quantity,
    ShippingAllocation,
    Unit,
    WarningCode,
)
from price_compare.pricing import calculate_price

# ===================================================================
# 税計算
# ===================================================================


class TestTaxCalculation:
    def test_tax_excluded_basic(self, offer_tax_excluded):
        """税抜398円×10%、税額40円（四捨五入）"""
        bd = calculate_price(offer_tax_excluded)
        assert bd.pre_tax_price == Decimal("398")
        assert bd.tax_amount == Decimal("40")
        assert bd.base_price_incl_tax == Decimal("438")

    def test_tax_included_basic(self, offer_tax_included):
        """税込398円×10%、本体362円、税額36円"""
        bd = calculate_price(offer_tax_included)
        assert bd.pre_tax_price == Decimal("362")
        assert bd.tax_amount == Decimal("36")
        assert bd.base_price_incl_tax == Decimal("398")

    def test_tax_excluded_99_yen_10pct(self):
        """税抜99円×10% → 税額10円（四捨五入）"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("99"), tax_included=False, tax_rate=Decimal("0.10"))
        bd = calculate_price(offer)
        assert bd.tax_amount == Decimal("10")
        assert bd.base_price_incl_tax == Decimal("109")

    def test_tax_excluded_101_yen_10pct(self):
        """税抜101円×10% → 税額10円（四捨五入）"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("101"), tax_included=False, tax_rate=Decimal("0.10"))
        bd = calculate_price(offer)
        assert bd.tax_amount == Decimal("10")
        assert bd.base_price_incl_tax == Decimal("111")

    def test_zero_tax(self, offer_zero_tax):
        """非課税（税率0%）"""
        bd = calculate_price(offer_zero_tax)
        assert bd.tax_amount == Decimal("0")
        assert bd.base_price_incl_tax == Decimal("100")

    def test_tax_rate_08(self):
        """軽減税率8%"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("1000"), tax_included=False, tax_rate=Decimal("0.08"))
        bd = calculate_price(offer)
        assert bd.tax_amount == Decimal("80")
        assert bd.base_price_incl_tax == Decimal("1080")

    def test_tax_included_99_with_10pct(self):
        """税込99円×10% → 本体90円、税額9円"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("99"), tax_included=True, tax_rate=Decimal("0.10"))
        bd = calculate_price(offer)
        assert bd.pre_tax_price == Decimal("90")
        assert bd.tax_amount == Decimal("9")

    def test_tax_rounding_down(self):
        """切捨てテスト: 税抜99円×10% → 税額9円"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("99"), tax_included=False, tax_rate=Decimal("0.10"))
        policy = CalculationPolicy(tax_rounding=MoneyRounding.DOWN)
        bd = calculate_price(offer, policy=policy)
        assert bd.tax_amount == Decimal("9")

    def test_tax_rounding_up(self):
        """切上げテスト: 税抜99円×10% → 税額10円"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("99"), tax_included=False, tax_rate=Decimal("0.10"))
        policy = CalculationPolicy(tax_rounding=MoneyRounding.UP)
        bd = calculate_price(offer, policy=policy)
        assert bd.tax_amount == Decimal("10")

    def test_price_zero_yen(self):
        """価格0円"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("0"), tax_included=True, tax_rate=Decimal("0.10"))
        bd = calculate_price(offer)
        assert bd.base_price_incl_tax == Decimal("0")
        assert bd.tax_amount == Decimal("0")


# ===================================================================
# 割引
# ===================================================================


class TestDiscount:
    def test_percentage_discount_10pct(self):
        """10%割引: 税込1000円 → 割引額100円"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("1000"), tax_included=True, tax_rate=Decimal("0.10"),
                      percentage_discount=Decimal("0.10"))
        bd = calculate_price(offer)
        assert bd.discount_amount == Decimal("100")
        assert bd.payable_now == Decimal("900")

    def test_fixed_discount_100(self):
        """固定100円値引き: 税込500円 → 400円"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("500"), tax_included=True, tax_rate=Decimal("0.10"),
                      fixed_discount=Decimal("100"))
        bd = calculate_price(offer)
        assert bd.payable_now == Decimal("400")

    def test_discount_exceeds_price(self):
        """割引が価格を超過 → 0円に抑止 + 警告"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("100"), tax_included=True, tax_rate=Decimal("0.10"),
                      fixed_discount=Decimal("200"))
        bd = calculate_price(offer)
        assert bd.payable_now == Decimal("0")
        assert WarningCode.DISCOUNT_EXCEEDS_PRICE.value in bd.warnings

    def test_percentage_100_off(self):
        """100%割引 → 0円"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("500"), tax_included=True, tax_rate=Decimal("0.10"),
                      percentage_discount=Decimal("1"))
        bd = calculate_price(offer)
        assert bd.payable_now == Decimal("0")


# ===================================================================
# クーポン
# ===================================================================


class TestCoupon:
    def test_coupon_basic(self):
        """クーポン30円: 税込398円 → 368円"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("398"), tax_included=True, tax_rate=Decimal("0.10"),
                      coupon_discount=Decimal("30"))
        bd = calculate_price(offer)
        assert bd.coupon_discount == Decimal("30")
        assert bd.payable_now == Decimal("368")

    def test_coupon_with_minimum_met(self):
        """最低利用額200円、価格500円 → クーポン適用"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("500"), tax_included=True, tax_rate=Decimal("0.10"),
                      coupon_discount=Decimal("50"),
                      coupon_minimum_subtotal=Decimal("200"))
        bd = calculate_price(offer)
        assert bd.coupon_discount == Decimal("50")

    def test_coupon_with_minimum_not_met(self):
        """最低利用額1000円、価格500円 → クーポン不適用"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("500"), tax_included=True, tax_rate=Decimal("0.10"),
                      coupon_discount=Decimal("50"),
                      coupon_minimum_subtotal=Decimal("1000"))
        bd = calculate_price(offer)
        assert bd.coupon_discount == Decimal("0")

    def test_coupon_exceeds_remaining(self):
        """クーポンが残額を超過 → 残額まで適用 + 警告"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("100"), tax_included=True, tax_rate=Decimal("0.10"),
                      coupon_discount=Decimal("200"))
        bd = calculate_price(offer)
        assert bd.coupon_discount is not None
        assert bd.base_price_incl_tax is not None
        assert bd.coupon_discount <= bd.base_price_incl_tax
        assert WarningCode.COUPON_EXCEEDS_REMAINING.value in bd.warnings


# ===================================================================
# 送料
# ===================================================================


class TestShipping:
    def test_shipping_fee_added(self):
        """送料80円を加算: 330円 + 80円 = 410円"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("330"), tax_included=True, tax_rate=Decimal("0.10"))
        ctx = PurchaseContext(shipping_fee=Decimal("80"))
        bd = calculate_price(offer, context=ctx)
        assert bd.shipping_fee == Decimal("80")
        assert bd.payable_now == Decimal("410")

    def test_shipping_full_order_warning(self):
        """送料全額帰属時に警告"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("1000"), tax_included=True, tax_rate=Decimal("0.10"))
        ctx = PurchaseContext(shipping_fee=Decimal("200"), shipping_allocation=ShippingAllocation.FULL_ORDER)
        bd = calculate_price(offer, context=ctx)
        assert bd.shipping_fee == Decimal("200")
        assert WarningCode.SHIPPING_FULL_ORDER.value in bd.warnings

    def test_no_shipping_fee(self):
        """送料未指定 → shipping_feeはNone"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("1000"), tax_included=True, tax_rate=Decimal("0.10"))
        bd = calculate_price(offer)
        assert bd.shipping_fee is None

    def test_zero_shipping_fee(self):
        """送料0円明示 → 0円として扱う"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("1000"), tax_included=True, tax_rate=Decimal("0.10"))
        ctx = PurchaseContext(shipping_fee=Decimal("0"))
        bd = calculate_price(offer, context=ctx)
        assert bd.shipping_fee == Decimal("0")


# ===================================================================
# ポイント
# ===================================================================


class TestPoints:
    def test_point_rate_1pct(self):
        """ポイント還元1%: 支払額368円 → 3pt"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("398"), tax_included=True, tax_rate=Decimal("0.10"),
                      coupon_discount=Decimal("30"), point_rate=Decimal("0.01"))
        bd = calculate_price(offer)
        assert bd.earned_points == Decimal("3")

    def test_fixed_points(self):
        """固定ポイント10pt"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("500"), tax_included=True, tax_rate=Decimal("0.10"),
                      fixed_points=Decimal("10"))
        bd = calculate_price(offer)
        assert bd.earned_points == Decimal("10")

    def test_earned_points_explicit(self):
        """獲得ポイント明示指定"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("1000"), tax_included=True, tax_rate=Decimal("0.10"),
                      earned_points=Decimal("50"))
        bd = calculate_price(offer)
        assert bd.earned_points == Decimal("50")

    def test_point_missing_fallback(self):
        """ポイント未指定で自動計算不可 → 警告あり"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("1000"), tax_included=True, tax_rate=Decimal("0.10"))
        bd = calculate_price(offer)
        assert bd.earned_points is None
        assert bd.effective_cost is None
        assert WarningCode.POINTS_MISSING.value in bd.warnings

    def test_point_value_rate_applied(self):
        """ポイント価値評価率の適用"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("1000"), tax_included=True, tax_rate=Decimal("0.10"),
                      earned_points=Decimal("100"))
        policy = CalculationPolicy(point_value_rate=Decimal("0.5"))
        bd = calculate_price(offer, policy=policy)
        assert bd.point_value == Decimal("50")
        assert bd.effective_cost == Decimal("950")

    def test_negative_effective_cost(self):
        """ポイント価値が支払額を超過 → 実質価格負 + 警告"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("100"), tax_included=True, tax_rate=Decimal("0.10"),
                      earned_points=Decimal("200"))
        bd = calculate_price(offer)
        assert bd.effective_cost is not None and bd.effective_cost < 0
        assert WarningCode.NEGATIVE_EFFECTIVE_COST.value in bd.warnings


# ===================================================================
# 容量換算
# ===================================================================


class TestQuantityConversion:
    def test_basic_unit_cost(self):
        """500ml×2本、支払額500円 → 総容量1000ml、支払単価0.500000円/ml"""
        bd = calculate_price(self._offer_with_qty("500", Unit.ML, 2, Decimal("500")))
        assert bd.normalized_quantity == Decimal("1000")
        assert bd.quantity_unit == "ml"
        assert bd.cash_unit_cost == Decimal("0.500000")

    def test_liter_conversion(self):
        """1L → 1000mlに正規化"""
        bd = calculate_price(self._offer_with_qty("1", Unit.L, 1, Decimal("1000")))
        assert bd.normalized_quantity == Decimal("1000")

    def test_kg_conversion(self):
        """1kg → 1000gに正規化"""
        bd = calculate_price(self._offer_with_qty("1", Unit.KG, 1, Decimal("1000")))
        assert bd.normalized_quantity == Decimal("1000")
        assert bd.quantity_unit == "kg"

    def test_quantity_zero(self):
        """数量0 → 警告"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("100"), tax_included=True, tax_rate=Decimal("0.10"),
                      quantity=Quantity(value=Decimal("0"), unit=Unit.PIECE))
        bd = calculate_price(offer)
        assert bd.normalized_quantity is None
        assert WarningCode.QUANTITY_ZERO.value in bd.warnings

    def test_no_quantity(self):
        """数量未指定 → 単価計算なし"""
        bd = calculate_price(self._base_offer())
        assert bd.normalized_quantity is None

    def test_piece_unit(self):
        """個数単位の単価"""
        offer = Offer(id="t", product_name="t", store_name="t", price=Decimal("300"), tax_included=True, tax_rate=Decimal("0.10"),
                      quantity=Quantity(value=Decimal("3"), unit=Unit.PIECE))
        bd = calculate_price(offer)
        assert bd.normalized_quantity == Decimal("3")
        assert bd.quantity_unit == "piece"

    @staticmethod
    def _offer_with_qty(value: str, unit: Unit, pkg: int, price: Decimal) -> Offer:
        return Offer(
            id="t", product_name="t", store_name="t",
            price=price, tax_included=True, tax_rate=Decimal("0.10"),
            quantity=Quantity(value=Decimal(value), unit=unit, package_count=pkg),
        )

    @staticmethod
    def _base_offer() -> Offer:
        return Offer(id="t", product_name="t", store_name="t",
                     price=Decimal("100"), tax_included=True, tax_rate=Decimal("0.10"))


# ===================================================================
# 複合シナリオ
# ===================================================================


class TestCombinedScenarios:
    def test_drugstore_scenario(self):
        """ドラッグストア: 税抜980円、10%割引、クーポン100円、ポイント1%"""
        offer = Offer(
            id="drugstore",
            product_name="洗剤",
            store_name="ドラッグストア",
            price=Decimal("980"),
            tax_included=False,
            tax_rate=Decimal("0.10"),
            quantity=Quantity(value=Decimal("500"), unit=Unit.ML, package_count=2),
            percentage_discount=Decimal("0.10"),
            coupon_discount=Decimal("100"),
            point_rate=Decimal("0.01"),
        )
        ctx = PurchaseContext(shipping_fee=Decimal("0"))
        bd = calculate_price(offer, context=ctx)
        # 税抜980 → 税込1,078 → 10%割引108円 → 970 → クーポン100 → 870 → 送料0 → 支払870
        assert bd.payable_now == Decimal("870")
        # ポイント: 870×0.01=8pt、切捨て
        assert bd.earned_points == Decimal("8")
        assert bd.effective_cost == Decimal("862")

    def test_online_scenario(self):
        """通販: 税込330円、送料80円、ポイント5%、容量1000ml"""
        offer = Offer(
            id="online",
            product_name="洗剤",
            store_name="通販",
            price=Decimal("330"),
            tax_included=True,
            tax_rate=Decimal("0.10"),
            quantity=Quantity(value=Decimal("1000"), unit=Unit.ML),
            point_rate=Decimal("0.05"),
        )
        ctx = PurchaseContext(shipping_fee=Decimal("80"))
        bd = calculate_price(offer, context=ctx)
        assert bd.payable_now == Decimal("410")
        assert bd.earned_points == Decimal("20")
        assert bd.effective_cost == Decimal("390")

    def test_supermarket_grocery(self):
        """スーパー食料品: 税込298円、軽減税率8%"""
        offer = Offer(
            id="super",
            product_name="食材",
            store_name="スーパー",
            price=Decimal("298"),
            tax_included=True,
            tax_rate=Decimal("0.08"),
        )
        bd = calculate_price(offer)
        assert bd.tax_amount == Decimal("22")
        assert bd.base_price_incl_tax == Decimal("298")

    def test_total_discount_chain(self):
        """割引率 + 固定値引き + クーポンの適用順序"""
        offer = Offer(
            id="t", product_name="t", store_name="t",
            price=Decimal("1000"), tax_included=True, tax_rate=Decimal("0.10"),
            percentage_discount=Decimal("0.10"),  # 100円引
            fixed_discount=Decimal("50"),
            coupon_discount=Decimal("30"),
        )
        bd = calculate_price(offer)
        # 1000 → 10%OFF=900 → 固定50=850 → クーポン30=820
        assert bd.payable_now == Decimal("820")
