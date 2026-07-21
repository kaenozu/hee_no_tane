# src/price_compare/json_io.py
#
# JSONファイルの読み書きを担当するモジュール。
# JSON DTOとドメインモデルの変換、バージョンチェックを行う。
# pricing.pyやcomparison.pyを直接呼び出さない。
#
# 関連:
#   - models.py (データモデル)
#   - validation.py (入力検証)

from __future__ import annotations

import json
from decimal import Decimal
from pathlib import Path
from typing import Any

from price_compare.models import Offer, PriceBreakdown
from price_compare.validation import validate_offers

# ---------------------------------------------------------------------------
# 定数
# ---------------------------------------------------------------------------

SUPPORTED_SCHEMA_VERSIONS = frozenset({1})
MAX_JSON_BYTES = 1_000_000

EXIT_SUCCESS = 0
EXIT_INPUT_ERROR = 1
EXIT_JSON_FORMAT_ERROR = 2
EXIT_CANNOT_COMPARE = 3
EXIT_UNSUPPORTED_SCHEMA = 4


# ---------------------------------------------------------------------------
# カスタム例外
# ---------------------------------------------------------------------------


class JsonInputError(ValueError):
    pass


class UnsupportedSchemaError(ValueError):
    pass


# ---------------------------------------------------------------------------
# 重複キー検出
# ---------------------------------------------------------------------------


def _reject_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise JsonInputError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


# ---------------------------------------------------------------------------
# 読み込み
# ---------------------------------------------------------------------------


def _parse_float_safe(value: str) -> Decimal:
    """JSONの小数値をDecimalとしてパースする。"""
    return Decimal(value)


def load_json_file(path: Path) -> Any:
    """JSONファイルを安全に読み込む。"""
    if not path.exists():
        raise JsonInputError(f"file not found: {path}")

    size = path.stat().st_size
    if size > MAX_JSON_BYTES:
        raise JsonInputError(f"JSON file is too large: {size} bytes (max {MAX_JSON_BYTES})")

    raw = path.read_text(encoding="utf-8")

    try:
        return json.loads(
            raw,
            parse_float=_parse_float_safe,
            object_pairs_hook=_reject_duplicate_keys,
        )
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        raise JsonInputError(f"invalid JSON: {exc}") from exc


def load_and_validate(path: Path) -> list[Offer]:
    """JSONファイルを読み込み、検証し、Offerリストを返す。"""
    raw_data = load_json_file(path)

    if not isinstance(raw_data, dict):
        raise JsonInputError("root must be a JSON object")

    # schemaVersion チェック
    schema_version = raw_data.get("schemaVersion")
    if not isinstance(schema_version, int):
        raise JsonInputError("schemaVersion must be an integer")
    if schema_version not in SUPPORTED_SCHEMA_VERSIONS:
        msg = f"unsupported schemaVersion: {schema_version} (supported: {sorted(SUPPORTED_SCHEMA_VERSIONS)})"
        raise UnsupportedSchemaError(msg)

    offers_raw = raw_data.get("offers")
    if not isinstance(offers_raw, list):
        raise JsonInputError("offers must be an array")

    return validate_offers(offers_raw)


# ---------------------------------------------------------------------------
# 出力
# ---------------------------------------------------------------------------


def _decimal_to_str(value: Decimal | None) -> str | None:
    if value is None:
        return None
    return str(value)


def price_breakdown_to_dict(bd: PriceBreakdown) -> dict[str, Any]:
    """PriceBreakdownをJSON互換dictに変換する。"""
    return {
        "displayPrice": str(bd.display_price),
        "taxIncluded": bd.tax_included,
        "taxRate": str(bd.tax_rate),
        "preTaxPrice": _decimal_to_str(bd.pre_tax_price),
        "taxAmount": _decimal_to_str(bd.tax_amount),
        "basePriceInclTax": _decimal_to_str(bd.base_price_incl_tax),
        "percentageDiscount": str(bd.percentage_discount),
        "fixedDiscount": str(bd.fixed_discount),
        "couponDiscount": str(bd.coupon_discount),
        "discountAmount": str(bd.discount_amount),
        "shippingFee": _decimal_to_str(bd.shipping_fee),
        "payableNow": _decimal_to_str(bd.payable_now),
        "earnedPoints": _decimal_to_str(bd.earned_points),
        "pointValue": _decimal_to_str(bd.point_value),
        "effectiveCost": _decimal_to_str(bd.effective_cost),
        "normalizedQuantity": _decimal_to_str(bd.normalized_quantity),
        "quantityUnit": bd.quantity_unit,
        "cashUnitCost": _decimal_to_str(bd.cash_unit_cost),
        "effectiveUnitCost": _decimal_to_str(bd.effective_unit_cost),
        "cashComplete": bd.cash_complete,
        "rewardComplete": bd.reward_complete,
        "unitComplete": bd.unit_complete,
        "warnings": list(bd.warnings),
    }
