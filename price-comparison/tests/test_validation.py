# tests/test_validation.py
#
# 入力検証 (validation.py) のテスト。
#
# 関連:
#   - validation.py
#   - models.py

from decimal import Decimal

import pytest

from price_compare.models import Offer
from price_compare.validation import (
    DecimalParseError,
    ValidationError,
    collect_errors,
    parse_decimal_string,
    validate_offer,
    validate_offers,
)

# ===================================================================
# Decimal パース
# ===================================================================


class TestParseDecimal:
    def test_valid_decimal(self):
        assert parse_decimal_string("398", field="price") == Decimal("398")

    def test_valid_decimal_with_fraction(self):
        assert parse_decimal_string("0.10", field="rate", max_fraction_digits=6) == Decimal("0.10")

    def test_invalid_format(self):
        with pytest.raises(DecimalParseError):
            parse_decimal_string("abc", field="price")

    def test_empty_string(self):
        with pytest.raises(DecimalParseError):
            parse_decimal_string("", field="price")

    def test_whitespace_only(self):
        with pytest.raises(DecimalParseError):
            parse_decimal_string("  ", field="price")

    def test_negative_number(self):
        with pytest.raises(DecimalParseError):
            parse_decimal_string("-1", field="price")

    def test_scientific_notation(self):
        with pytest.raises(DecimalParseError):
            parse_decimal_string("1e5", field="price")

    def test_nan(self):
        with pytest.raises(DecimalParseError):
            parse_decimal_string("NaN", field="price")

    def test_infinity(self):
        with pytest.raises(DecimalParseError):
            parse_decimal_string("Infinity", field="price")

    def test_too_many_integer_digits(self):
        with pytest.raises(DecimalParseError, match="too many integer digits"):
            parse_decimal_string("9999999999999", field="price", max_integer_digits=12)

    def test_too_many_fraction_digits(self):
        with pytest.raises(DecimalParseError, match="too many fraction digits"):
            parse_decimal_string("0.1234567", field="rate", max_fraction_digits=6)

    def test_not_a_string(self):
        with pytest.raises(DecimalParseError, match="must be a JSON string"):
            parse_decimal_string(123, field="price")

    def test_negative_zero(self):
        result = parse_decimal_string("-0", field="price")
        assert result == Decimal("0")


# ===================================================================
# オファー検証
# ===================================================================


class TestValidateOffer:
    def test_valid_offer(self):
        offer = validate_offer({
            "id": "test",
            "productName": "商品名",
            "storeName": "店舗名",
            "price": "500",
            "taxIncluded": True,
            "taxRate": "0.10",
        })
        assert isinstance(offer, Offer)
        assert offer.price == Decimal("500")

    def test_missing_id(self):
        with pytest.raises(ValidationError, match="id is required"):
            validate_offer({
                "productName": "商品名",
                "storeName": "店舗名",
                "price": "500",
                "taxIncluded": True,
                "taxRate": "0.10",
            })

    def test_invalid_price_format(self):
        with pytest.raises(ValidationError, match="price"):
            validate_offer({
                "id": "t", "productName": "t", "storeName": "t",
                "price": "abc", "taxIncluded": True, "taxRate": "0.10",
            })

    def test_price_zero(self):
        with pytest.raises(ValidationError, match="price"):
            validate_offer({
                "id": "t", "productName": "t", "storeName": "t",
                "price": "0", "taxIncluded": True, "taxRate": "0.10",
            })

    def test_tax_rate_too_high(self):
        with pytest.raises(ValidationError, match="taxRate must be between 0 and 1"):
            validate_offer({
                "id": "t", "productName": "t", "storeName": "t",
                "price": "500", "taxIncluded": True, "taxRate": "1.5",
            })

    def test_percentage_discount_out_of_range(self):
        with pytest.raises(ValidationError, match="percentageDiscount"):
            validate_offer({
                "id": "t", "productName": "t", "storeName": "t",
                "price": "500", "taxIncluded": True, "taxRate": "0.10",
                "percentageDiscount": "1.5",
            })

    def test_with_quantity(self):
        offer = validate_offer({
            "id": "t", "productName": "t", "storeName": "t",
            "price": "500", "taxIncluded": True, "taxRate": "0.10",
            "quantity": {"value": "500", "unit": "ml", "packageCount": 2, "measureKind": "GENERIC_VOLUME"},
        })
        assert offer.quantity is not None
        assert offer.quantity.value == Decimal("500")
        assert offer.quantity.package_count == 2

    def test_unknown_unit(self):
        with pytest.raises(ValidationError):
            validate_offer({
                "id": "t", "productName": "t", "storeName": "t",
                "price": "500", "taxIncluded": True, "taxRate": "0.10",
                "quantity": {"value": "1", "unit": "unknown"},
            })

    def test_empty_product_name(self):
        with pytest.raises(ValidationError, match="productName"):
            validate_offer({
                "id": "t", "productName": "", "storeName": "t",
                "price": "500", "taxIncluded": True, "taxRate": "0.10",
            })

    def test_explicit_earned_points(self):
        offer = validate_offer({
            "id": "t", "productName": "t", "storeName": "t",
            "price": "500", "taxIncluded": True, "taxRate": "0.10",
            "earnedPoints": "100",
        })
        assert offer.earned_points == Decimal("100")

    def test_all_fields(self):
        """全フィールド指定"""
        offer = validate_offer({
            "id": "full-test",
            "productName": "テスト商品名",
            "storeName": "テスト店舗名",
            "price": "1000",
            "taxIncluded": False,
            "taxRate": "0.08",
            "quantity": {"value": "1", "unit": "L", "packageCount": 1, "measureKind": "GENERIC_VOLUME"},
            "percentageDiscount": "0.10",
            "fixedDiscount": "50",
            "couponDiscount": "30",
            "couponMinimumSubtotal": "500",
            "pointRate": "0.01",
            "fixedPoints": "10",
            "earnedPoints": "20",
            "shippingFee": "200",
        })
        assert offer.id == "full-test"
        assert offer.percentage_discount == Decimal("0.10")
        assert offer.fixed_discount == Decimal("50")
        assert offer.coupon_discount == Decimal("30")
        assert offer.coupon_minimum_subtotal == Decimal("500")
        assert offer.point_rate == Decimal("0.01")
        assert offer.fixed_points == Decimal("10")
        assert offer.earned_points == Decimal("20")
        assert offer.shipping_fee == Decimal("200")


# ===================================================================
# 複数オファー検証
# ===================================================================


class TestValidateOffers:
    def test_empty_list(self):
        result = validate_offers([])
        assert result == []

    def test_multiple_offers(self):
        result = validate_offers([
            {"id": "a", "productName": "A", "storeName": "S", "price": "100", "taxIncluded": True, "taxRate": "0.10"},
            {"id": "b", "productName": "B", "storeName": "S", "price": "200", "taxIncluded": True, "taxRate": "0.10"},
        ])
        assert len(result) == 2

    def test_too_many_offers(self):
        with pytest.raises(ValidationError, match="too many offers"):
            validate_offers([{}] * 101)


# ===================================================================
# 全エラー収集
# ===================================================================


class TestCollectErrors:
    def test_valid_input(self):
        errors = collect_errors({
            "schemaVersion": 1,
            "offers": [
                {"id": "a", "productName": "A", "storeName": "S", "price": "100", "taxIncluded": True, "taxRate": "0.10"},
            ],
        })
        assert errors == []

    def test_missing_schema_version(self):
        errors = collect_errors({"offers": []})
        assert any("schemaVersion" in e for e in errors)

    def test_missing_offers(self):
        errors = collect_errors({"schemaVersion": 1})
        assert any("offers" in e for e in errors)

    def test_invalid_offer(self):
        errors = collect_errors({
            "schemaVersion": 1,
            "offers": [{"id": "a"}],
        })
        assert len(errors) > 0
