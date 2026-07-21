# src/price_compare/comparison.py
#
# 1件以上の計算済みPriceBreakdownを比較・順位付けする関数。
# 比較ロジックと価格計算ロジックを分離することで、
# それぞれを独立にテスト可能にする。
#
# 関連:
#   - models.py (データモデル)
#   - pricing.py (価格計算)

from __future__ import annotations

from decimal import ROUND_HALF_UP, Decimal

from price_compare.models import (
    ComparisonBasis,
    ComparisonResult,
    PriceBreakdown,
    WarningCode,
)


def select_basis(
    breakdowns: list[PriceBreakdown],
) -> tuple[ComparisonBasis | None, list[str]]:
    """複数の内訳から最適な比較基準を選択する。"""
    warnings: list[str] = []

    # 実質単価比較（最優先）
    if all(b.effective_unit_cost is not None for b in breakdowns):
        return ComparisonBasis.EFFECTIVE_UNIT_COST, warnings

    # 支払単価比較
    if all(b.cash_unit_cost is not None for b in breakdowns):
        return ComparisonBasis.CASH_UNIT_COST, warnings

    # 実質総額比較
    if all(b.effective_cost is not None for b in breakdowns):
        return ComparisonBasis.EFFECTIVE_TOTAL, warnings

    # 支払総額比較
    if all(b.payable_now is not None for b in breakdowns):
        return ComparisonBasis.CASH_TOTAL, warnings

    return None, warnings


def _find_best_basis(
    breakdowns: list[PriceBreakdown],
) -> tuple[ComparisonBasis | None, list[str]]:
    """少なくとも2件の内訳が持つ最適な比較基準を選択する。"""
    warnings: list[str] = []

    for candidate in [
        ComparisonBasis.EFFECTIVE_UNIT_COST,
        ComparisonBasis.CASH_UNIT_COST,
        ComparisonBasis.EFFECTIVE_TOTAL,
        ComparisonBasis.CASH_TOTAL,
    ]:
        count = sum(1 for b in breakdowns if _get_value(b, candidate) is not None)
        if count >= 2:
            return candidate, warnings

    return None, warnings


def _get_value(breakdown: PriceBreakdown, basis: ComparisonBasis) -> Decimal | None:
    mapping = {
        ComparisonBasis.EFFECTIVE_UNIT_COST: breakdown.effective_unit_cost,
        ComparisonBasis.CASH_UNIT_COST: breakdown.cash_unit_cost,
        ComparisonBasis.EFFECTIVE_TOTAL: breakdown.effective_cost,
        ComparisonBasis.CASH_TOTAL: breakdown.payable_now,
    }
    return mapping.get(basis)


def rank_offers(
    breakdowns: dict[str, PriceBreakdown],
) -> ComparisonResult:
    """複数の価格内訳を比較し、安い順にランク付けする。

    Args:
        breakdowns: オファーID → PriceBreakdown のマップ

    Returns:
        ランク付けされた ComparisonResult
    """
    items = list(breakdowns.items())
    warnings: list[str] = []

    # ---- 数量の一致確認 ----
    has_qty = {iid for iid, b in items if b.normalized_quantity is not None}
    if 0 < len(has_qty) < len(items):
        warnings.append(WarningCode.QUANTITY_MISSING.value)

    # ---- 最適な比較基準を選択（少なくとも2件カバーするもの） ----
    all_breakdowns = [b for _, b in items]
    basis, basis_warnings = _find_best_basis(all_breakdowns)
    warnings.extend(basis_warnings)

    if basis is None:
        return ComparisonResult(
            basis=ComparisonBasis.CASH_TOTAL,
            breakdowns=breakdowns,
            incomparable_ids=tuple(iid for iid, _ in items),
            can_compare=False,
            warnings=tuple(warnings + [WarningCode.CANNOT_COMPARE.value]),
        )

    # ---- 各オファーの値を取得 ----
    value_map: dict[str, Decimal] = {}
    incomparable: list[str] = []
    for iid, b in items:
        val = _get_value(b, basis)
        if val is not None:
            value_map[iid] = val
        else:
            incomparable.append(iid)

    # ---- 値でソート ----
    sorted_ids = tuple(sorted(value_map.keys(), key=lambda iid: value_map[iid]))

    # ---- 差の計算（最安 vs 2位） ----
    best_val = value_map[sorted_ids[0]]
    second_val = value_map[sorted_ids[1]]
    difference = second_val - best_val  # 正なら2位が高い
    avg = (best_val + second_val) / Decimal("2")
    percentage_difference: Decimal | None = None
    if avg > 0:
        percentage_difference = (
            (difference / avg) * Decimal("100")
        ).quantize(Decimal("1.00"), rounding=ROUND_HALF_UP)

    # 同額チェック
    best_id: str | None = sorted_ids[0]
    if difference == 0:
        best_id = None

    return ComparisonResult(
        basis=basis,
        breakdowns=breakdowns,
        ranked_ids=tuple(sorted_ids),
        best_id=best_id,
        values=value_map,
        difference=difference,
        percentage_difference=percentage_difference,
        incomparable_ids=tuple(incomparable),
        can_compare=True,
        warnings=tuple(warnings),
    )


def compare_offers(
    first: PriceBreakdown,
    second: PriceBreakdown,
) -> ComparisonResult:
    """2つの価格内訳を比較する（互換ラッパー）。"""
    return rank_offers({"left": first, "right": second})
