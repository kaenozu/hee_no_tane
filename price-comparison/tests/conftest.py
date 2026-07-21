# tests/conftest.py
#
# pytest フィクスチャ定義。
#
# 関連:
#   - test_pricing.py
#   - test_comparison.py

from decimal import Decimal

import pytest

from price_compare.models import (
    CalculationPolicy,
    MeasureKind,
    Offer,
    PurchaseContext,
    Quantity,
    Unit,
)


@pytest.fixture
def default_policy() -> CalculationPolicy:
    return CalculationPolicy()


@pytest.fixture
def default_context() -> PurchaseContext:
    return PurchaseContext()


# ---------------------------------------------------------------------------
# ベースオファー
# ---------------------------------------------------------------------------


@pytest.fixture
def offer_tax_included() -> Offer:
    return Offer(
        id="base-tax-incl",
        product_name="テスト商品",
        store_name="テスト店舗",
        price=Decimal("398"),
        tax_included=True,
        tax_rate=Decimal("0.10"),
    )


@pytest.fixture
def offer_tax_excluded() -> Offer:
    return Offer(
        id="base-tax-excl",
        product_name="テスト商品",
        store_name="テスト店舗",
        price=Decimal("398"),
        tax_included=False,
        tax_rate=Decimal("0.10"),
    )


@pytest.fixture
def offer_with_quantity() -> Offer:
    return Offer(
        id="with-qty",
        product_name="テスト商品",
        store_name="テスト店舗",
        price=Decimal("500"),
        tax_included=True,
        tax_rate=Decimal("0.10"),
        quantity=Quantity(
            value=Decimal("500"),
            unit=Unit.ML,
            package_count=2,
            measure_kind=MeasureKind.GENERIC_VOLUME,
        ),
    )


@pytest.fixture
def offer_zero_tax() -> Offer:
    return Offer(
        id="zero-tax",
        product_name="非課税商品",
        store_name="テスト店舗",
        price=Decimal("100"),
        tax_included=True,
        tax_rate=Decimal("0"),
    )
