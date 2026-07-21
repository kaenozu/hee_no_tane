# src/price_compare/validation.py
#
# 入力検証モジュール。
# JSONから読み込んだ未検証データを、計算可能なドメインモデルへ変換する。
# 構文検証・意味検証・比較検証を分離して行う。
#
# 関連:
#   - models.py (データモデル)
#   - json_io.py (JSON入出力)

from __future__ import annotations

import re
from decimal import Decimal, InvalidOperation
from typing import Any

from price_compare.models import (
    Dimension,
    MeasureKind,
    MoneyRounding,
    Offer,
    Quantity,
    ShippingAllocation,
    Unit,
)

# ---------------------------------------------------------------------------
# 定数
# ---------------------------------------------------------------------------

PRICE_MAX_INTEGER_DIGITS = 12
RATE_MAX_INTEGER_DIGITS = 1
RATE_MAX_FRACTION_DIGITS = 6
QUANTITY_MAX_INTEGER_DIGITS = 12
QUANTITY_MAX_FRACTION_DIGITS = 6
MAX_OFFER_ARRAY_LENGTH = 100
MAX_ID_LENGTH = 64
MAX_NAME_LENGTH = 256

_DECIMAL_RE = re.compile(r"(?:0|[1-9]\d*)(?:\.\d+)?\Z")

_VALID_UNITS = frozenset(u.value for u in Unit)
_VALID_DIMENSIONS = frozenset(d.value for d in Dimension)
_VALID_MEASURE_KINDS = frozenset(m.value for m in MeasureKind)
_VALID_ROUNDINGS = frozenset(r.value for r in MoneyRounding)
_VALID_SHIPPING_ALLOCATIONS = frozenset(s.value for s in ShippingAllocation)

# ---------------------------------------------------------------------------
# カスタム例外
# ---------------------------------------------------------------------------


class ValidationError(ValueError):
    def __init__(self, message: str, code: str = "VALIDATION_ERROR") -> None:
        self.code = code
        super().__init__(message)


class DecimalParseError(ValidationError):
    def __init__(self, field: str, detail: str = "invalid decimal") -> None:
        self.field = field
        super().__init__(f"{field}: {detail}", code="DECIMAL_PARSE_ERROR")


# ---------------------------------------------------------------------------
# Decimal 安全パース
# ---------------------------------------------------------------------------


def parse_decimal_string(
    value: object,
    *,
    field: str,
    max_integer_digits: int = PRICE_MAX_INTEGER_DIGITS,
    max_fraction_digits: int = 0,
    allow_zero: bool = True,
) -> Decimal:
    if not isinstance(value, str):
        raise DecimalParseError(field, "must be a JSON string")

    # -0 は 0 として扱う
    normalized = value
    if normalized in ("-0", "-0.0", "-0.00"):
        normalized = "0"

    if not _DECIMAL_RE.fullmatch(normalized):
        raise DecimalParseError(field, "invalid decimal format")

    integer_part, dot, fraction_part = normalized.partition(".")

    if len(integer_part) > max_integer_digits:
        raise DecimalParseError(field, f"too many integer digits (max {max_integer_digits})")

    if dot and len(fraction_part) > max_fraction_digits:
        raise DecimalParseError(field, f"too many fraction digits (max {max_fraction_digits})")

    try:
        result = Decimal(normalized)
    except InvalidOperation as exc:
        raise DecimalParseError(field, "invalid decimal value") from exc

    if not result.is_finite():
        raise DecimalParseError(field, "non-finite decimal")

    if result == 0:
        result = Decimal("0")

    if not allow_zero and result == 0:
        raise DecimalParseError(field, "zero is not allowed")

    return result


# ---------------------------------------------------------------------------
# オファー検証
# ---------------------------------------------------------------------------


def validate_offer(raw: dict[str, Any]) -> Offer:
    """1件のオファーを検証し、ドメインモデルを返す。"""
    errors: list[str] = []

    # ID
    offer_id = _validate_string(raw, "id", errors, max_length=MAX_ID_LENGTH)
    product_name = _validate_string(raw, "productName", errors, max_length=MAX_NAME_LENGTH)
    store_name = _validate_string(raw, "storeName", errors, max_length=MAX_NAME_LENGTH)

    # 価格
    price = _validate_decimal(raw, "price", errors, allow_zero=False)
    tax_included = _validate_bool(raw, "taxIncluded", errors)
    tax_rate = _validate_rate(raw, "taxRate", errors)

    # 数量
    quantity = _validate_quantity(raw.get("quantity"), errors)

    # 割引
    percentage_discount = _validate_decimal(raw, "percentageDiscount", errors, default="0")
    fixed_discount = _validate_decimal(raw, "fixedDiscount", errors, default="0")
    coupon_discount = _validate_decimal(raw, "couponDiscount", errors, default="0")
    coupon_minimum = _validate_decimal_opt(raw, "couponMinimumSubtotal", errors)

    # ポイント
    point_rate = _validate_rate(raw, "pointRate", errors, default="0")
    fixed_points = _validate_decimal(raw, "fixedPoints", errors, default="0")
    earned_points = _validate_decimal_opt(raw, "earnedPoints", errors)

    # 送料
    shipping_fee = _validate_decimal_opt(raw, "shippingFee", errors)

    # 割引率の範囲チェック
    if percentage_discount is not None and (percentage_discount < 0 or percentage_discount > Decimal("1")):
        errors.append("percentageDiscount must be between 0 and 1")

    if point_rate is not None and (point_rate < 0 or point_rate > Decimal("1")):
        errors.append("pointRate must be between 0 and 1")

    # 税率の範囲
    if tax_rate is not None and (tax_rate < 0 or tax_rate > Decimal("1")):
        errors.append("taxRate must be between 0 and 1")

    if errors:
        raise ValidationError("; ".join(errors))

    return Offer(
        id=offer_id or "",
        product_name=product_name or "",
        store_name=store_name or "",
        price=price or Decimal("0"),
        tax_included=tax_included or False,
        tax_rate=tax_rate or Decimal("0"),
        quantity=quantity,
        percentage_discount=percentage_discount or Decimal("0"),
        fixed_discount=fixed_discount or Decimal("0"),
        coupon_discount=coupon_discount or Decimal("0"),
        coupon_minimum_subtotal=coupon_minimum,
        point_rate=point_rate or Decimal("0"),
        fixed_points=fixed_points or Decimal("0"),
        earned_points=earned_points,
        shipping_fee=shipping_fee,
    )


def validate_offers(raw_list: list[dict[str, Any]]) -> list[Offer]:
    """複数オファーを検証する。"""
    if len(raw_list) > MAX_OFFER_ARRAY_LENGTH:
        raise ValidationError(f"too many offers (max {MAX_OFFER_ARRAY_LENGTH})")

    return [validate_offer(item) for item in raw_list]


# ---------------------------------------------------------------------------
# ヘルパー
# ---------------------------------------------------------------------------


def _validate_string(
    raw: dict[str, Any],
    key: str,
    errors: list[str],
    max_length: int = 256,
) -> str | None:
    value = raw.get(key)
    if value is None:
        errors.append(f"{key} is required")
        return None
    if not isinstance(value, str):
        errors.append(f"{key} must be a string")
        return None
    trimmed = value.strip()
    if not trimmed:
        errors.append(f"{key} must not be empty")
        return None
    if len(trimmed) > max_length:
        errors.append(f"{key} must not exceed {max_length} characters")
        return None
    return trimmed


def _validate_bool(
    raw: dict[str, Any],
    key: str,
    errors: list[str],
) -> bool | None:
    value = raw.get(key)
    if value is None:
        errors.append(f"{key} is required")
        return None
    if not isinstance(value, bool):
        errors.append(f"{key} must be a boolean")
        return None
    return value


def _validate_decimal(
    raw: dict[str, Any],
    key: str,
    errors: list[str],
    default: str | None = None,
    allow_zero: bool = True,
    max_fraction_digits: int = 6,
) -> Decimal | None:
    value = raw.get(key)
    if value is None:
        if default is not None:
            return Decimal(default)
        errors.append(f"{key} is required")
        return None
    try:
        return parse_decimal_string(
            value, field=key, allow_zero=allow_zero,
            max_fraction_digits=max_fraction_digits,
        )
    except DecimalParseError as e:
        errors.append(str(e))
        return None


def _validate_decimal_opt(
    raw: dict[str, Any],
    key: str,
    errors: list[str],
    max_fraction_digits: int = 6,
) -> Decimal | None:
    value = raw.get(key)
    if value is None:
        return None
    try:
        return parse_decimal_string(
            value, field=key, max_fraction_digits=max_fraction_digits,
        )
    except DecimalParseError as e:
        errors.append(str(e))
        return None


def _validate_rate(
    raw: dict[str, Any],
    key: str,
    errors: list[str],
    default: str | None = None,
) -> Decimal | None:
    value = raw.get(key)
    if value is None:
        if default is not None:
            return Decimal(default)
        errors.append(f"{key} is required")
        return None
    try:
        return parse_decimal_string(
            value,
            field=key,
            max_integer_digits=RATE_MAX_INTEGER_DIGITS,
            max_fraction_digits=RATE_MAX_FRACTION_DIGITS,
        )
    except DecimalParseError as e:
        errors.append(str(e))
        return None


def _validate_quantity(
    value: Any,
    errors: list[str],
) -> Quantity | None:
    if value is None:
        return None
    if not isinstance(value, dict):
        errors.append("quantity must be an object")
        return None

    q_value = _validate_decimal(value, "value", errors, allow_zero=False)
    unit_str = _validate_string(value, "unit", errors, max_length=16)
    unit = None
    if unit_str:
        if unit_str not in _VALID_UNITS:
            errors.append(f"unknown unit: {unit_str}")
        else:
            unit = Unit(unit_str)

    package_count = value.get("packageCount", 1)
    if not isinstance(package_count, int) or package_count < 1:
        errors.append("packageCount must be a positive integer")

    measure_kind_str = value.get("measureKind", MeasureKind.ITEM.value)
    if not isinstance(measure_kind_str, str) or measure_kind_str not in _VALID_MEASURE_KINDS:
        errors.append(f"unknown measureKind: {measure_kind_str}")

    if errors:
        return None

    return Quantity(
        value=q_value or Decimal("0"),
        unit=unit or Unit.PIECE,
        package_count=package_count if isinstance(package_count, int) else 1,
        measure_kind=MeasureKind(measure_kind_str) if isinstance(measure_kind_str, str) else MeasureKind.ITEM,
    )


# ---------------------------------------------------------------------------
# バッチ検証（全エラー収集）
# ---------------------------------------------------------------------------


def collect_errors(raw_data: Any) -> list[str]:
    """可能な限り全エラーを収集する。"""
    all_errors: list[str] = []

    if not isinstance(raw_data, dict):
        return ["root must be a JSON object"]

    schema_version = raw_data.get("schemaVersion")
    if not isinstance(schema_version, int):
        all_errors.append("schemaVersion must be an integer")

    offers_raw = raw_data.get("offers")
    if not isinstance(offers_raw, list):
        return all_errors + ["offers must be an array"]

    for i, item in enumerate(offers_raw):
        if not isinstance(item, dict):
            all_errors.append(f"offers[{i}] must be an object")
            continue
        try:
            validate_offer(item)
        except ValidationError as e:
            all_errors.append(f"offers[{i}]: {e}")

    return all_errors
