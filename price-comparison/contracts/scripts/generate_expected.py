# contracts/scripts/generate_expected.py
#
# ゴールデンフィクスチャの expected セクションを自動生成する。
# Pythonの実際の計算結果をfixtureに反映させる。

from __future__ import annotations

import json
from decimal import Decimal
from pathlib import Path

from price_compare.comparison import rank_offers
from price_compare.models import (
    CalculationPolicy,
    MoneyRounding,
    Offer,
    PriceBreakdown,
    PurchaseContext,
    Quantity,
    ShippingAllocation,
    MeasureKind,
    Unit,
)
from price_compare.pricing import calculate_price

FIXTURE_DIR = Path(__file__).resolve().parent.parent / "fixtures"


def _load_decimal(val: str | None) -> Decimal | None:
    if val is None:
        return None
    return Decimal(val)


def _parse_quantity(data: dict | None) -> Quantity | None:
    if data is None:
        return None
    return Quantity(
        value=Decimal(data["value"]),
        unit=Unit(data["unit"]),
        package_count=data.get("package_count", 1),
        measure_kind=MeasureKind(data.get("measure_kind", "ITEM")),
    )


def _parse_offer(data: dict) -> Offer:
    return Offer(
        id=data["id"],
        product_name=data["product_name"],
        store_name=data["store_name"],
        price=Decimal(data["price"]),
        tax_included=data["tax_included"],
        tax_rate=Decimal(data["tax_rate"]),
        quantity=_parse_quantity(data.get("quantity")),
        percentage_discount=_load_decimal(data.get("percentage_discount", "0")) or Decimal("0"),
        fixed_discount=_load_decimal(data.get("fixed_discount", "0")) or Decimal("0"),
        coupon_discount=_load_decimal(data.get("coupon_discount", "0")) or Decimal("0"),
        coupon_minimum_subtotal=_load_decimal(data.get("coupon_minimum_subtotal")),
        point_rate=_load_decimal(data.get("point_rate", "0")) or Decimal("0"),
        fixed_points=_load_decimal(data.get("fixed_points", "0")) or Decimal("0"),
        earned_points=_load_decimal(data.get("earned_points")),
        shipping_fee=_load_decimal(data.get("shipping_fee")),
    )


def _parse_context(data: dict | None) -> PurchaseContext:
    if data is None:
        return PurchaseContext()
    return PurchaseContext(
        shipping_fee=_load_decimal(data.get("shipping_fee")),
        shipping_allocation=ShippingAllocation(data.get("shipping_allocation", "ALLOCATED_TO_ITEM")),
        checkout_total_override=_load_decimal(data.get("checkout_total_override")),
    )


def _bd_to_json(bd: PriceBreakdown) -> dict:
    return {
        "display_price": str(bd.display_price),
        "tax_included": bd.tax_included,
        "tax_rate": str(bd.tax_rate),
        "pre_tax_price": str(bd.pre_tax_price) if bd.pre_tax_price is not None else None,
        "tax_amount": str(bd.tax_amount) if bd.tax_amount is not None else None,
        "base_price_incl_tax": str(bd.base_price_incl_tax) if bd.base_price_incl_tax is not None else None,
        "percentage_discount": str(bd.percentage_discount) if bd.percentage_discount else "0",
        "fixed_discount": str(bd.fixed_discount) if bd.fixed_discount else "0",
        "coupon_discount": str(bd.coupon_discount) if bd.coupon_discount else "0",
        "discount_amount": str(bd.discount_amount) if bd.discount_amount else "0",
        "shipping_fee": str(bd.shipping_fee) if bd.shipping_fee is not None else None,
        "payable_now": str(bd.payable_now) if bd.payable_now is not None else None,
        "earned_points": str(bd.earned_points) if bd.earned_points is not None else None,
        "point_value": str(bd.point_value) if bd.point_value is not None else None,
        "effective_cost": str(bd.effective_cost) if bd.effective_cost is not None else None,
        "normalized_quantity": str(bd.normalized_quantity) if bd.normalized_quantity is not None else None,
        "quantity_unit": bd.quantity_unit,
        "cash_unit_cost": str(bd.cash_unit_cost) if bd.cash_unit_cost is not None else None,
        "effective_unit_cost": str(bd.effective_unit_cost) if bd.effective_unit_cost is not None else None,
        "cash_complete": bd.cash_complete,
        "reward_complete": bd.reward_complete,
        "unit_complete": bd.unit_complete,
        "warnings": list(bd.warnings),
    }


def _generate_expected(fixture: dict) -> dict:
    offers_data = fixture["offers"]
    contexts_data = fixture.get("contexts", {})

    # Calculate breakdowns
    bd_map = {}
    expected_bds = {}
    for oid, odata in offers_data.items():
        offer = _parse_offer(odata)
        ctx = _parse_context(contexts_data.get(oid))
        bd = calculate_price(offer, context=ctx)
        bd_map[oid] = bd
        expected_bds[oid] = _bd_to_json(bd)

    # Run ranking
    result = rank_offers(bd_map)

    expected_cmp = {
        "basis": result.basis.value if result.basis else None,
        "ranked_ids": list(result.ranked_ids),
        "best_id": result.best_id,
        "values": {k: str(v) for k, v in result.values.items()},
        "difference": str(result.difference) if result.difference is not None else None,
        "percentage_difference": str(result.percentage_difference) if result.percentage_difference is not None else None,
        "incomparable_ids": list(result.incomparable_ids),
        "can_compare": result.can_compare,
        "warnings": list(result.warnings),
    }

    expected = {"breakdowns": expected_bds, "comparison": expected_cmp}
    return expected


def main():
    for path in sorted(FIXTURE_DIR.glob("*.json")):
        with open(path, encoding="utf-8") as f:
            fixture = json.load(f)

        print(f"Generating expected for {path.name}...")

        expected = _generate_expected(fixture)
        fixture["expected"] = expected

        with open(path, "w", encoding="utf-8") as f:
            json.dump(fixture, f, indent=2, ensure_ascii=False)
            f.write("\n")

        print(f"  OK")


if __name__ == "__main__":
    main()
