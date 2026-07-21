# tests/test_json_io.py
#
# JSON入出力 (json_io.py) のテスト。
#
# 関連:
#   - json_io.py
#   - validation.py

import json
from decimal import Decimal
from pathlib import Path

import pytest

from price_compare.json_io import (
    JsonInputError,
    UnsupportedSchemaError,
    load_and_validate,
    load_json_file,
    price_breakdown_to_dict,
)
from price_compare.models import PriceBreakdown

# ===================================================================
# JSON読み込み
# ===================================================================


class TestLoadJsonFile:
    def test_file_not_found(self) -> None:
        with pytest.raises(JsonInputError, match="file not found"):
            load_json_file(Path("/nonexistent/file.json"))

    def test_invalid_json(self, tmp_path: Path) -> None:
        f = tmp_path / "invalid.json"
        f.write_text("{invalid}", encoding="utf-8")
        with pytest.raises(JsonInputError, match="invalid JSON"):
            load_json_file(f)

    def test_empty_object(self, tmp_path: Path) -> None:
        f = tmp_path / "empty.json"
        f.write_text("{}", encoding="utf-8")
        result = load_json_file(f)
        assert result == {}

    def test_duplicate_keys_rejected(self, tmp_path: Path) -> None:
        f = tmp_path / "duplicate.json"
        f.write_text('{"a":1,"a":2}', encoding="utf-8")
        with pytest.raises(JsonInputError, match="duplicate JSON key"):
            load_json_file(f)

    def test_file_too_large(self, tmp_path: Path) -> None:
        f = tmp_path / "large.json"
        # Write just under limit, then test
        f.write_text(" " * 1_000_001, encoding="utf-8")
        with pytest.raises(JsonInputError, match="JSON file is too large"):
            load_json_file(f)


# ===================================================================
# 読み込み＋検証
# ===================================================================


class TestLoadAndValidate:
    def test_valid_file(self, tmp_path: Path) -> None:
        f = tmp_path / "valid.json"
        f.write_text(json.dumps({
            "schemaVersion": 1,
            "offers": [
                {"id": "a", "productName": "A", "storeName": "S",
                 "price": "100", "taxIncluded": True, "taxRate": "0.10"},
            ],
        }), encoding="utf-8")
        offers = load_and_validate(f)
        assert len(offers) == 1

    def test_unsupported_schema_version(self, tmp_path: Path) -> None:
        f = tmp_path / "bad_schema.json"
        f.write_text(json.dumps({
            "schemaVersion": 999,
            "offers": [],
        }), encoding="utf-8")
        with pytest.raises(UnsupportedSchemaError, match="unsupported schemaVersion"):
            load_and_validate(f)

    def test_no_schema_version(self, tmp_path: Path) -> None:
        f = tmp_path / "no_schema.json"
        f.write_text(json.dumps({
            "offers": [],
        }), encoding="utf-8")
        with pytest.raises(JsonInputError, match="schemaVersion must be an integer"):
            load_and_validate(f)

    def test_offers_not_array(self, tmp_path: Path) -> None:
        f = tmp_path / "bad_offers.json"
        f.write_text(json.dumps({
            "schemaVersion": 1,
            "offers": "not an array",
        }), encoding="utf-8")
        with pytest.raises(JsonInputError, match="offers must be an array"):
            load_and_validate(f)

    def test_root_not_object(self, tmp_path: Path) -> None:
        f = tmp_path / "root_array.json"
        f.write_text("[]", encoding="utf-8")
        with pytest.raises(JsonInputError, match="root must be a JSON object"):
            load_and_validate(f)

    def test_decimal_precision_preserved(self, tmp_path: Path) -> None:
        """JSONの小数がDecimalとして保持される"""
        f = tmp_path / "decimal_test.json"
        f.write_text(json.dumps({
            "schemaVersion": 1,
            "offers": [
                {"id": "a", "productName": "A", "storeName": "S",
                 "price": "0.1", "taxIncluded": True, "taxRate": "0.10"},
            ],
        }), encoding="utf-8")
        offers = load_and_validate(f)
        assert offers[0].price == Decimal("0.1")


# ===================================================================
# 出力
# ===================================================================


class TestPriceBreakdownToDict:
    def test_full_breakdown(self) -> None:
        bd = PriceBreakdown(
            display_price=Decimal("398"),
            tax_included=True,
            tax_rate=Decimal("0.10"),
            payable_now=Decimal("368"),
            effective_cost=Decimal("365"),
            cash_complete=True,
            reward_complete=True,
            unit_complete=False,
        )
        d = price_breakdown_to_dict(bd)
        assert d["displayPrice"] == "398"
        assert d["payableNow"] == "368"
        assert d["effectiveCost"] == "365"
        assert d["cashComplete"] is True

    def test_partial_breakdown(self) -> None:
        bd = PriceBreakdown(
            display_price=Decimal("100"),
            tax_included=True,
            tax_rate=Decimal("0.10"),
            cash_complete=False,
            reward_complete=False,
            unit_complete=False,
        )
        d = price_breakdown_to_dict(bd)
        assert d["payableNow"] is None
        assert d["warnings"] == []
