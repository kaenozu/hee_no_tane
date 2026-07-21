# src/price_compare/models.py
#
# 価格比較アプリの入力・出力データモデル。
# すべての計算はこのモデルを基に行われる。
#
# 関連:
#   - pricing.py (計算関数)
#   - comparison.py (比較関数)
#   - validation.py (入力検証)

from __future__ import annotations

from dataclasses import dataclass, field
from decimal import Decimal
from enum import StrEnum

# ---------------------------------------------------------------------------
# 列挙型
# ---------------------------------------------------------------------------


class MoneyRounding(StrEnum):
    HALF_UP = "HALF_UP"
    DOWN = "DOWN"
    UP = "UP"


class Unit(StrEnum):
    ML = "ml"
    L = "L"
    G = "g"
    KG = "kg"
    PIECE = "piece"


class Dimension(StrEnum):
    VOLUME = "VOLUME"
    MASS = "MASS"
    COUNT = "COUNT"


class MeasureKind(StrEnum):
    GENERIC_VOLUME = "GENERIC_VOLUME"
    GENERIC_MASS = "GENERIC_MASS"
    ITEM = "ITEM"
    TABLET = "TABLET"
    CAPSULE = "CAPSULE"
    SHEET = "SHEET"
    ROLL = "ROLL"
    BAG = "BAG"


class ComparisonBasis(StrEnum):
    EFFECTIVE_UNIT_COST = "EFFECTIVE_UNIT_COST"
    CASH_UNIT_COST = "CASH_UNIT_COST"
    EFFECTIVE_TOTAL = "EFFECTIVE_TOTAL"
    CASH_TOTAL = "CASH_TOTAL"


class ShippingAllocation(StrEnum):
    FULL_ORDER = "FULL_ORDER"
    ALLOCATED_TO_ITEM = "ALLOCATED_TO_ITEM"
    EXCLUDED = "EXCLUDED"
    UNKNOWN = "UNKNOWN"


class WarningCode(StrEnum):
    POINTS_MISSING = "POINTS_MISSING"
    QUANTITY_MISSING = "QUANTITY_MISSING"
    SHIPPING_FULL_ORDER = "SHIPPING_FULL_ORDER"
    DISCOUNT_EXCEEDS_PRICE = "DISCOUNT_EXCEEDS_PRICE"
    COUPON_EXCEEDS_REMAINING = "COUPON_EXCEEDS_REMAINING"
    POINTS_EXCEED_PAYABLE = "POINTS_EXCEED_PAYABLE"
    NEGATIVE_EFFECTIVE_COST = "NEGATIVE_EFFECTIVE_COST"
    DIMENSION_MISMATCH = "DIMENSION_MISMATCH"
    MEASURE_KIND_MISMATCH = "MEASURE_KIND_MISMATCH"
    CANNOT_COMPARE = "CANNOT_COMPARE"
    PROMOTIONAL_ANOMALY = "PROMOTIONAL_ANOMALY"
    QUANTITY_ZERO = "QUANTITY_ZERO"
    UNKNOWN_FIELD = "UNKNOWN_FIELD"
    UNSUPPORTED_SCHEMA = "UNSUPPORTED_SCHEMA"


# ---------------------------------------------------------------------------
# ユーティリティ
# ---------------------------------------------------------------------------


_UNIT_FACTORS: dict[Unit, Decimal] = {
    Unit.ML: Decimal("1"),
    Unit.L: Decimal("1000"),
    Unit.G: Decimal("1"),
    Unit.KG: Decimal("1000"),
    Unit.PIECE: Decimal("1"),
}

_UNIT_DIMENSIONS: dict[Unit, Dimension] = {
    Unit.ML: Dimension.VOLUME,
    Unit.L: Dimension.VOLUME,
    Unit.G: Dimension.MASS,
    Unit.KG: Dimension.MASS,
    Unit.PIECE: Dimension.COUNT,
}


def unit_to_factor(unit: Unit) -> Decimal:
    return _UNIT_FACTORS[unit]


def unit_to_dimension(unit: Unit) -> Dimension:
    return _UNIT_DIMENSIONS[unit]


# ---------------------------------------------------------------------------
# 入力モデル
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class Quantity:
    value: Decimal
    unit: Unit
    package_count: int = 1
    measure_kind: MeasureKind = MeasureKind.ITEM

    def normalized_total(self) -> Decimal:
        return self.value * unit_to_factor(self.unit) * Decimal(self.package_count)


@dataclass(frozen=True)
class Offer:
    id: str
    product_name: str
    store_name: str
    price: Decimal
    tax_included: bool
    tax_rate: Decimal
    quantity: Quantity | None = None
    percentage_discount: Decimal = Decimal("0")
    fixed_discount: Decimal = Decimal("0")
    coupon_discount: Decimal = Decimal("0")
    coupon_minimum_subtotal: Decimal | None = None
    point_rate: Decimal = Decimal("0")
    fixed_points: Decimal = Decimal("0")
    earned_points: Decimal | None = None
    shipping_fee: Decimal | None = None


@dataclass(frozen=True)
class PurchaseContext:
    shipping_fee: Decimal | None = None
    shipping_allocation: ShippingAllocation = ShippingAllocation.ALLOCATED_TO_ITEM
    checkout_total_override: Decimal | None = None


@dataclass(frozen=True)
class CalculationPolicy:
    tax_rounding: MoneyRounding = MoneyRounding.HALF_UP
    discount_rounding: MoneyRounding = MoneyRounding.HALF_UP
    point_value_rate: Decimal = Decimal("1")


# ---------------------------------------------------------------------------
# 出力モデル
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class PriceBreakdown:
    display_price: Decimal
    tax_included: bool
    tax_rate: Decimal

    # 税計算
    pre_tax_price: Decimal | None = None
    tax_amount: Decimal | None = None
    base_price_incl_tax: Decimal | None = None

    # 割引・クーポン
    percentage_discount: Decimal = Decimal("0")
    fixed_discount: Decimal = Decimal("0")
    coupon_discount: Decimal = Decimal("0")
    discount_amount: Decimal = Decimal("0")

    # 送料
    shipping_fee: Decimal | None = None

    # 支払
    payable_now: Decimal | None = None

    # ポイント
    earned_points: Decimal | None = None
    point_value: Decimal | None = None
    effective_cost: Decimal | None = None

    # 容量
    normalized_quantity: Decimal | None = None
    quantity_unit: str | None = None
    cash_unit_cost: Decimal | None = None
    effective_unit_cost: Decimal | None = None

    # 計算状態
    cash_complete: bool = False
    reward_complete: bool = False
    unit_complete: bool = False

    # 警告
    warnings: tuple[str, ...] = field(default_factory=tuple)

    def is_cash_comparable(self) -> bool:
        return self.cash_complete and self.payable_now is not None

    def is_reward_comparable(self) -> bool:
        return self.reward_complete and self.effective_cost is not None

    def is_unit_comparable(self) -> bool:
        return self.unit_complete and self.cash_unit_cost is not None


@dataclass(frozen=True)
class ComparisonResult:
    """複数オファーの比較結果。

    breakdowns: id→PriceBreakdown のマップ
    ranked_ids: 安い順のidリスト（比較可能なもののみ）
    best_id: 最安のid（同額時または比較不能時はNone）
    values: id→比較基準値のマップ
    difference: 最安と2位の差額（None=同額/比較不能）
    percentage_difference: 相対差率（%）
    incomparable_ids: 比較不能だったidリスト
    can_compare: 少なくとも2件比較可能か
    warnings: グローバル警告
    """

    basis: ComparisonBasis
    breakdowns: dict[str, PriceBreakdown]
    ranked_ids: tuple[str, ...] = field(default_factory=tuple)
    best_id: str | None = None
    values: dict[str, Decimal] = field(default_factory=dict)
    difference: Decimal | None = None
    percentage_difference: Decimal | None = None
    incomparable_ids: tuple[str, ...] = field(default_factory=tuple)
    can_compare: bool = False
    warnings: tuple[str, ...] = field(default_factory=tuple)
