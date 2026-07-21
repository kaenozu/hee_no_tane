# tests/test_cli.py
#
# CLI表示・出力モジュール (cli.py) のテスト。
#
# 関連:
#   - cli.py
#   - json_io.py
#   - pricing.py

from decimal import Decimal
from json import loads

import pytest

from price_compare.cli import (
    _exit,
    format_comparison_result,
    format_store_section,
    output_json,
)
from price_compare.models import (
    ComparisonBasis,
    ComparisonResult,
    PriceBreakdown,
)


def _bd(display: str = "200") -> PriceBreakdown:
    return PriceBreakdown(
        display_price=Decimal(display),
        tax_included=True,
        tax_rate=Decimal("0.10"),
        cash_complete=True,
        reward_complete=True,
        unit_complete=False,
    )


class TestFormatStoreSection:
    def test_basic_display(self) -> None:
        bd = _bd("398")
        lines = format_store_section("スーパーA", bd)
        assert len(lines) >= 1
        assert "スーパーA" in lines[0]
        display_line = [line for line in lines if "表示価格" in line][0]
        assert "398" in display_line
        assert "税込" in display_line

    def test_tax_excluded_label(self) -> None:
        bd = PriceBreakdown(
            display_price=Decimal("398"),
            tax_included=False,
            tax_rate=Decimal("0.10"),
            cash_complete=True,
            reward_complete=True,
            unit_complete=False,
        )
        lines = format_store_section("店B", bd)
        display_line = [line for line in lines if "表示価格" in line][0]
        assert "税抜" in display_line

    def test_with_tax_amount(self) -> None:
        bd = PriceBreakdown(
            display_price=Decimal("398"),
            tax_included=False,
            tax_rate=Decimal("0.10"),
            tax_amount=Decimal("40"),
            cash_complete=True,
            reward_complete=True,
            unit_complete=False,
        )
        lines = format_store_section("店C", bd)
        tax_line = [line for line in lines if "税額" in line]
        assert len(tax_line) == 1


class TestFormatComparisonResult:
    def test_winner_displayed(self) -> None:
        result = ComparisonResult(
            basis=ComparisonBasis.EFFECTIVE_TOTAL,
            breakdowns={"a": _bd("200"), "b": _bd("300")},
            ranked_ids=("a", "b"),
            best_id="a",
            values={"a": Decimal("200"), "b": Decimal("300")},
            difference=Decimal("100"),
            percentage_difference=Decimal("33.33"),
            can_compare=True,
            warnings=(),
        )
        lines = format_comparison_result(result)
        text = "\n".join(lines)
        assert "a" in text
        assert "最安" in text

    def test_cannot_compare(self) -> None:
        result = ComparisonResult(
            basis=ComparisonBasis.EFFECTIVE_TOTAL,
            breakdowns={"a": _bd("200"), "b": _bd("300")},
            incomparable_ids=("a", "b"),
            can_compare=False,
            warnings=("比較基準が異なる",),
        )
        lines = format_comparison_result(result)
        text = "\n".join(lines)
        assert "比較" in text

    def test_multiple_offers(self) -> None:
        result = ComparisonResult(
            basis=ComparisonBasis.EFFECTIVE_TOTAL,
            breakdowns={
                "a": _bd("200"),
                "b": _bd("300"),
                "c": _bd("250"),
            },
            ranked_ids=("a", "c", "b"),
            best_id="a",
            values={
                "a": Decimal("200"),
                "b": Decimal("300"),
                "c": Decimal("250"),
            },
            difference=Decimal("50"),
            can_compare=True,
            warnings=(),
        )
        lines = format_comparison_result(result)
        text = "\n".join(lines)
        assert "a" in text
        assert "c" in text
        assert "最安" in text


class TestOutputJson:
    def test_basic_output(self) -> None:
        result = ComparisonResult(
            basis=ComparisonBasis.EFFECTIVE_TOTAL,
            breakdowns={"a": _bd("200"), "b": _bd("300")},
            ranked_ids=("a", "b"),
            best_id="a",
            values={"a": Decimal("200"), "b": Decimal("300")},
            difference=Decimal("100"),
            percentage_difference=Decimal("33.33"),
            can_compare=True,
            warnings=(),
        )
        json_str = output_json(result)
        data = loads(json_str)
        assert data["winnerId"] == "a"
        assert data["difference"] == "100"
        assert data["percentageDifference"] == "33.33"
        assert data["rankedIds"] == ["a", "b"]

    def test_null_difference(self) -> None:
        result = ComparisonResult(
            basis=ComparisonBasis.EFFECTIVE_TOTAL,
            breakdowns={"a": _bd("200"), "b": _bd("200")},
            ranked_ids=("a", "b"),
            best_id=None,
            values={"a": Decimal("200"), "b": Decimal("200")},
            difference=Decimal("0"),
            can_compare=True,
            warnings=(),
        )
        json_str = output_json(result)
        data = loads(json_str)
        assert data["difference"] == "0"
        assert data["winnerId"] is None


class TestExit:
    def test_exit_with_message(self) -> None:
        with pytest.raises(SystemExit) as exc_info:
            _exit("test error", 42)
        assert exc_info.value.code == 42
