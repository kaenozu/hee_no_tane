# tests/test_comparison.py
#
# 比較ロジック (comparison.py) のテスト。
#
# 関連:
#   - comparison.py
#   - pricing.py

from decimal import Decimal

from price_compare.comparison import compare_offers, rank_offers, select_basis
from price_compare.models import (
    ComparisonBasis,
    PriceBreakdown,
)


def _make_bd(
    payable_now: str | None = None,
    effective_cost: str | None = None,
    cash_unit_cost: str | None = None,
    effective_unit_cost: str | None = None,
    normalized_quantity: str | None = None,
    quantity_unit: str | None = None,
    warnings: tuple[str, ...] | None = None,
) -> PriceBreakdown:
    return PriceBreakdown(
        display_price=Decimal(payable_now or "0"),
        tax_included=True,
        tax_rate=Decimal("0.10"),
        payable_now=Decimal(payable_now) if payable_now else None,
        effective_cost=Decimal(effective_cost) if effective_cost else None,
        cash_unit_cost=Decimal(cash_unit_cost) if cash_unit_cost else None,
        effective_unit_cost=Decimal(effective_unit_cost) if effective_unit_cost else None,
        normalized_quantity=Decimal(normalized_quantity) if normalized_quantity else None,
        quantity_unit=quantity_unit,
        cash_complete=payable_now is not None,
        reward_complete=effective_cost is not None,
        unit_complete=cash_unit_cost is not None,
        warnings=warnings or (),
    )


# ===================================================================
# 比較基準選択
# ===================================================================


class TestSelectBasis:
    def test_prefers_effective_unit_cost(self) -> None:
        basis, _ = select_basis([
            _make_bd(effective_unit_cost="0.5"),
            _make_bd(effective_unit_cost="0.6"),
        ])
        assert basis == ComparisonBasis.EFFECTIVE_UNIT_COST

    def test_falls_back_to_cash_unit_cost(self) -> None:
        basis, _ = select_basis([
            _make_bd(cash_unit_cost="0.5"),
            _make_bd(cash_unit_cost="0.6"),
        ])
        assert basis == ComparisonBasis.CASH_UNIT_COST

    def test_falls_back_to_effective_total(self) -> None:
        basis, _ = select_basis([
            _make_bd(effective_cost="500"),
            _make_bd(effective_cost="600"),
        ])
        assert basis == ComparisonBasis.EFFECTIVE_TOTAL

    def test_falls_back_to_cash_total(self) -> None:
        basis, _ = select_basis([
            _make_bd(payable_now="500"),
            _make_bd(payable_now="600"),
        ])
        assert basis == ComparisonBasis.CASH_TOTAL

    def test_no_comparison_possible(self) -> None:
        basis, _ = select_basis([_make_bd(), _make_bd()])
        assert basis is None

    def test_three_items_all_effective_unit(self) -> None:
        basis, _ = select_basis([
            _make_bd(effective_unit_cost="0.5"),
            _make_bd(effective_unit_cost="0.6"),
            _make_bd(effective_unit_cost="0.4"),
        ])
        assert basis == ComparisonBasis.EFFECTIVE_UNIT_COST

    def test_mixed_completeness_fallback(self) -> None:
        """一部のオファーに値がない場合、全件揃ってない基準は選ばれない"""
        basis, _ = select_basis([
            _make_bd(effective_unit_cost="0.5", cash_unit_cost="0.5"),
            _make_bd(cash_unit_cost="0.6"),  # effective_unit_cost なし
        ])
        assert basis == ComparisonBasis.CASH_UNIT_COST


# ===================================================================
# compare_offers（2件互換ラッパー）
# ===================================================================


class TestCompareOffers:
    def test_left_is_cheaper_by_unit_cost(self) -> None:
        left = _make_bd(effective_unit_cost="0.5", payable_now="500")
        right = _make_bd(effective_unit_cost="0.6", payable_now="600")
        result = compare_offers(left, right)
        assert result.can_compare is True
        assert result.best_id == "left"
        assert result.basis == ComparisonBasis.EFFECTIVE_UNIT_COST

    def test_right_is_cheaper(self) -> None:
        left = _make_bd(effective_unit_cost="0.7", payable_now="700")
        right = _make_bd(effective_unit_cost="0.5", payable_now="500")
        result = compare_offers(left, right)
        assert result.can_compare is True
        assert result.best_id == "right"

    def test_equal_values(self) -> None:
        left = _make_bd(effective_unit_cost="0.5", payable_now="500")
        right = _make_bd(effective_unit_cost="0.5", payable_now="500")
        result = compare_offers(left, right)
        assert result.can_compare is True
        assert result.best_id is None

    def test_payment_cheaper_but_unit_expensive(self) -> None:
        left = _make_bd(payable_now="400", effective_unit_cost="0.8", cash_unit_cost="0.8")
        right = _make_bd(payable_now="500", effective_unit_cost="0.4", cash_unit_cost="0.4")
        result = compare_offers(left, right)
        assert result.basis == ComparisonBasis.EFFECTIVE_UNIT_COST
        assert result.best_id == "right"

    def test_cannot_compare_insufficient_data(self) -> None:
        left = _make_bd()
        right = _make_bd()
        result = compare_offers(left, right)
        assert result.can_compare is False

    def test_points_missing_fallback(self) -> None:
        left = _make_bd(payable_now="500", cash_unit_cost="0.5")
        right = _make_bd(payable_now="400", cash_unit_cost="0.4")
        result = compare_offers(left, right)
        assert result.can_compare is True
        assert result.basis == ComparisonBasis.CASH_UNIT_COST

    def test_difference_calculation(self) -> None:
        left = _make_bd(effective_unit_cost="0.5", payable_now="500")
        right = _make_bd(effective_unit_cost="0.6", payable_now="600")
        result = compare_offers(left, right)
        assert result.difference == Decimal("0.1")
        assert result.percentage_difference is not None


# ===================================================================
# rank_offers（複数オファー）
# ===================================================================


class TestRankOffers:
    def test_three_offers_ranked(self) -> None:
        bds = {
            "a": _make_bd(effective_unit_cost="0.5"),
            "b": _make_bd(effective_unit_cost="0.3"),
            "c": _make_bd(effective_unit_cost="0.4"),
        }
        result = rank_offers(bds)
        assert result.can_compare is True
        assert result.ranked_ids == ("b", "c", "a")
        assert result.best_id == "b"

    def test_best_id_none_on_tie(self) -> None:
        bds = {
            "a": _make_bd(effective_unit_cost="0.5"),
            "b": _make_bd(effective_unit_cost="0.5"),
        }
        result = rank_offers(bds)
        assert result.can_compare is True
        assert result.best_id is None

    def test_incomparable_excluded(self) -> None:
        # "b" は cash_unit_cost のみ持ち、"a" は effective_unit_cost のみ
        # 共通基準がない → 両方 incomparable
        bds = {
            "a": _make_bd(effective_unit_cost="0.5"),
            "b": _make_bd(cash_unit_cost="0.3"),
        }
        result = rank_offers(bds)
        assert result.can_compare is False
        assert len(result.incomparable_ids) == 2

    def test_partial_comparable(self) -> None:
        """一部のオファーだけが共通基準を持つケース"""
        bds = {
            "a": _make_bd(effective_unit_cost="0.5"),
            "b": _make_bd(effective_unit_cost="0.3"),
            "c": _make_bd(payable_now="100"),
        }
        result = rank_offers(bds)
        # a,b は effective_unit_cost で比較可能、c は incomparable
        assert result.ranked_ids == ("b", "a")
        assert result.incomparable_ids == ("c",)
        assert result.can_compare is True

    def test_all_incomparable(self) -> None:
        bds = {
            "a": _make_bd(payable_now="100"),
            "b": _make_bd(),
        }
        result = rank_offers(bds)
        assert result.can_compare is False
        assert len(result.incomparable_ids) == 2

    def test_difference_between_best_and_second(self) -> None:
        bds = {
            "a": _make_bd(effective_unit_cost="0.5"),
            "b": _make_bd(effective_unit_cost="0.3"),
            "c": _make_bd(effective_unit_cost="0.4"),
        }
        result = rank_offers(bds)
        # b(0.3) < c(0.4): difference = 0.1
        assert result.difference == Decimal("0.1")
        assert result.percentage_difference is not None
