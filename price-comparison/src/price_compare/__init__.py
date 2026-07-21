# src/price_compare/__init__.py
#
# 価格比較アプリ Phase 1 のエントリポイント。
# 外部向けに主要な型と関数を公開する。
#
# 関連:
#   - models.py (データモデル)
#   - pricing.py (計算関数)
#   - comparison.py (比較関数)

from price_compare.comparison import compare_offers, rank_offers
from price_compare.models import (
    CalculationPolicy,
    ComparisonBasis,
    ComparisonResult,
    Dimension,
    MeasureKind,
    MoneyRounding,
    Offer,
    PriceBreakdown,
    PurchaseContext,
    Quantity,
    ShippingAllocation,
    Unit,
    WarningCode,
)
from price_compare.pricing import calculate_price

__all__ = [
    "Offer",
    "Quantity",
    "Unit",
    "Dimension",
    "MeasureKind",
    "PriceBreakdown",
    "ComparisonResult",
    "ComparisonBasis",
    "CalculationPolicy",
    "MoneyRounding",
    "ShippingAllocation",
    "PurchaseContext",
    "WarningCode",
    "calculate_price",
    "compare_offers",
    "rank_offers",
]
