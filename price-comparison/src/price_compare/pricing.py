# src/price_compare/pricing.py
#
# 単一オファーの価格計算を行う純粋関数。
# ファイル・標準出力・グローバル状態に一切依存しない。
#
# 計算順序:
#   税抜価格 → 税込基準価格 → 商品割引 → クーポン → 送料加算
#   → 支払金額 → ポイント還元控除 → 実質価格 → 容量換算単価
#
# 関連:
#   - models.py (データモデル)
#   - comparison.py (比較関数)

from __future__ import annotations

from decimal import ROUND_DOWN, ROUND_HALF_UP, ROUND_UP, Decimal

from price_compare.models import (
    CalculationPolicy,
    MoneyRounding,
    Offer,
    PriceBreakdown,
    PurchaseContext,
    ShippingAllocation,
    WarningCode,
)

# ---------------------------------------------------------------------------
# 丸めマッピング
# ---------------------------------------------------------------------------

_ROUNDING_MAP = {
    MoneyRounding.HALF_UP: ROUND_HALF_UP,
    MoneyRounding.DOWN: ROUND_DOWN,
    MoneyRounding.UP: ROUND_UP,
}


def _round(value: Decimal, rounding: MoneyRounding, scale: int = 0) -> Decimal:
    return value.quantize(Decimal(f"1.{'0' * scale}" if scale else "1"), rounding=_ROUNDING_MAP[rounding])


# ---------------------------------------------------------------------------
# 税計算
# ---------------------------------------------------------------------------


def _calculate_tax(
    price: Decimal,
    tax_included: bool,
    tax_rate: Decimal,
    policy: CalculationPolicy,
) -> tuple[Decimal, Decimal, Decimal]:
    """税額計算を行い、(税抜価格, 税額, 税込基準価格) を返す。"""
    if tax_rate == 0:
        return price, Decimal("0"), price

    if tax_included:
        # 税込価格から本体価格を抽出
        gross = price
        tax = (
            gross * tax_rate / (Decimal("1") + tax_rate)
        ).quantize(Decimal("1"), rounding=_ROUNDING_MAP[policy.tax_rounding])
        pre_tax = gross - tax
        return pre_tax, tax, gross
    else:
        # 税抜価格に税を加算
        pre_tax = price
        tax = (price * tax_rate).quantize(Decimal("1"), rounding=_ROUNDING_MAP[policy.tax_rounding])
        gross = pre_tax + tax
        return pre_tax, tax, gross


# ---------------------------------------------------------------------------
# 割引・クーポン計算
# ---------------------------------------------------------------------------


def _calculate_discounts(
    base_price: Decimal,
    percentage_discount: Decimal,
    fixed_discount: Decimal,
    coupon_discount: Decimal,
    coupon_minimum_subtotal: Decimal | None,
    policy: CalculationPolicy,
) -> tuple[Decimal, Decimal, Decimal, list[str]]:
    """割引・クーポンを適用し、(割引後価格, 割引額合計, クーポン額, 警告) を返す。"""
    warnings: list[str] = []
    current = base_price

    if percentage_discount > 0:
        amount = (current * percentage_discount).quantize(
            Decimal("1"), rounding=_ROUNDING_MAP[policy.discount_rounding]
        )
        if amount > current:
            warnings.append(WarningCode.DISCOUNT_EXCEEDS_PRICE.value)
            amount = current
        current -= amount

    if fixed_discount > 0:
        if fixed_discount > current:
            warnings.append(WarningCode.DISCOUNT_EXCEEDS_PRICE.value)
            current = Decimal("0")
        else:
            current -= fixed_discount

    coupon_actual = Decimal("0")
    if coupon_discount > 0:
        if coupon_minimum_subtotal is not None and base_price < coupon_minimum_subtotal:
            # クーポン不適用
            pass
        else:
            if coupon_discount > current:
                warnings.append(WarningCode.COUPON_EXCEEDS_REMAINING.value)
                coupon_actual = current
            else:
                coupon_actual = coupon_discount
            current -= coupon_actual

    discount_total = (base_price - current) - coupon_actual + fixed_discount  # simplified
    # Recalculate properly
    discount_total = (percentage_discount * base_price if percentage_discount > 0 else Decimal("0"))
    discount_total = _round(discount_total, policy.discount_rounding)
    discount_total += fixed_discount
    discount_total += coupon_actual

    after_discount = base_price - discount_total
    if after_discount < 0:
        after_discount = Decimal("0")

    return after_discount, discount_total, coupon_actual, warnings


# ---------------------------------------------------------------------------
# メイン計算関数
# ---------------------------------------------------------------------------


def calculate_price(
    offer: Offer,
    context: PurchaseContext | None = None,
    policy: CalculationPolicy | None = None,
) -> PriceBreakdown:
    """単一オファーの価格内訳を計算する。"""
    if policy is None:
        policy = CalculationPolicy()
    if context is None:
        context = PurchaseContext()

    warnings: list[str] = []

    # ---- ステップ1: 税計算 ----
    pre_tax_price, tax_amount, base_price_incl_tax = _calculate_tax(
        offer.price, offer.tax_included, offer.tax_rate, policy
    )

    # ---- ステップ2: 割引・クーポン ----
    after_discount, discount_total, coupon_actual, disc_warnings = _calculate_discounts(
        base_price_incl_tax,
        offer.percentage_discount,
        offer.fixed_discount,
        offer.coupon_discount,
        offer.coupon_minimum_subtotal,
        policy,
    )
    warnings.extend(disc_warnings)

    # ---- ステップ3: 送料 ----
    shipping_fee: Decimal | None = None
    if context.shipping_fee is not None:
        shipping_fee = context.shipping_fee
        if context.shipping_allocation == ShippingAllocation.FULL_ORDER:
            warnings.append(WarningCode.SHIPPING_FULL_ORDER.value)

    payable_now = after_discount
    if shipping_fee is not None:
        payable_now += shipping_fee

    # ---- ステップ4: ポイント ----
    earned_points: Decimal | None = None
    if offer.earned_points is not None:
        earned_points = offer.earned_points
    elif offer.point_rate > 0 or offer.fixed_points > 0:
        # 付与率から計算
        points_from_rate = (payable_now * offer.point_rate).quantize(
            Decimal("1"), rounding=ROUND_DOWN
        )
        earned_points = points_from_rate + offer.fixed_points

    point_value: Decimal | None = None
    effective_cost: Decimal | None = None
    if earned_points is not None:
        point_value = _round(earned_points * policy.point_value_rate, policy.discount_rounding)
        effective_cost = payable_now - point_value
        if effective_cost < 0:
            warnings.append(WarningCode.NEGATIVE_EFFECTIVE_COST.value)
    else:
        warnings.append(WarningCode.POINTS_MISSING.value)

    # ---- ステップ5: 容量換算 ----
    normalized_quantity: Decimal | None = None
    quantity_unit: str | None = None
    cash_unit_cost: Decimal | None = None
    effective_unit_cost: Decimal | None = None

    if offer.quantity is not None and offer.quantity.value > 0:
        q = offer.quantity
        normalized_quantity = q.normalized_total()
        quantity_unit = q.unit.value
        if payable_now > 0:
            scale = 6
            cash_unit_cost = (
                payable_now / normalized_quantity
            ).quantize(Decimal(f"1.{'0' * scale}"), rounding=ROUND_HALF_UP)
        if effective_cost is not None and effective_cost >= 0 and normalized_quantity > 0:
            scale = 6
            effective_unit_cost = (
                effective_cost / normalized_quantity
            ).quantize(Decimal(f"1.{'0' * scale}"), rounding=ROUND_HALF_UP)
    elif offer.quantity is not None and offer.quantity.value == 0:
        warnings.append(WarningCode.QUANTITY_ZERO.value)

    # ---- 計算状態 ----
    cash_complete = payable_now is not None
    reward_complete = effective_cost is not None
    unit_complete = cash_unit_cost is not None and normalized_quantity is not None

    return PriceBreakdown(
        display_price=offer.price,
        tax_included=offer.tax_included,
        tax_rate=offer.tax_rate,
        pre_tax_price=pre_tax_price,
        tax_amount=tax_amount,
        base_price_incl_tax=base_price_incl_tax,
        percentage_discount=offer.percentage_discount,
        fixed_discount=offer.fixed_discount,
        coupon_discount=coupon_actual,
        discount_amount=discount_total,
        shipping_fee=shipping_fee,
        payable_now=payable_now,
        earned_points=earned_points,
        point_value=point_value,
        effective_cost=effective_cost,
        normalized_quantity=normalized_quantity,
        quantity_unit=quantity_unit,
        cash_unit_cost=cash_unit_cost,
        effective_unit_cost=effective_unit_cost,
        cash_complete=cash_complete,
        reward_complete=reward_complete,
        unit_complete=unit_complete,
        warnings=tuple(warnings),
    )
