# src/price_compare/cli.py
#
# 価格比較CLIのエントリポイント。
# 引数解析、ファイル入力、計算処理の呼び出し、人間向け表示を行う。
# 計算ロジックそのものは pricing.py / comparison.py に委譲する。
#
# 終了コード:
#   0: 正常終了
#   1: 入力値エラー
#   2: JSON形式エラー
#   3: 比較不能
#   4: 未対応スキーマ
#
# 関連:
#   - json_io.py (JSON入出力)
#   - pricing.py (価格計算)
#   - comparison.py (比較)

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import NoReturn

from price_compare.comparison import rank_offers
from price_compare.json_io import (
    JsonInputError,
    UnsupportedSchemaError,
    load_and_validate,
    price_breakdown_to_dict,
)
from price_compare.models import (
    CalculationPolicy,
    ComparisonResult,
    Offer,
    PriceBreakdown,
    PurchaseContext,
)
from price_compare.pricing import calculate_price

EXIT_SUCCESS = 0
EXIT_INPUT_ERROR = 1
EXIT_JSON_FORMAT_ERROR = 2
EXIT_CANNOT_COMPARE = 3
EXIT_UNSUPPORTED_SCHEMA = 4


def _exit(message: str, code: int) -> NoReturn:
    print(f"Error: {message}", file=sys.stderr)
    sys.exit(code)


# ---------------------------------------------------------------------------
# 表示
# ---------------------------------------------------------------------------


def _render_price(v: str | None) -> str:
    if v is None:
        return "---"
    return v


def _render_warnings(warnings: tuple[str, ...]) -> list[str]:
    if not warnings:
        return []
    return [f"  [!] {w}" for w in warnings]


def format_store_section(
    label: str,
    bd: PriceBreakdown,
) -> list[str]:
    lines: list[str] = []
    lines.append(f"  [{label}]")
    label_tag = '（税抜）' if not bd.tax_included else '（税込）'
    lines.append(f"    表示価格:         {_render_price(str(bd.display_price))}円{label_tag}")
    if bd.tax_amount is not None:
        lines.append(f"    税額:             {_render_price(str(bd.tax_amount))}円")
    lines.append(f"    税込基準価格:     {_render_price(str(bd.base_price_incl_tax))}円")

    if bd.percentage_discount > 0:
        pct = bd.percentage_discount * 100
        lines.append(f"    商品割引 ({pct}%):    -{_render_price(str(bd.discount_amount))}円")
    if bd.fixed_discount > 0:
        lines.append(f"    固定値引き:       -{_render_price(str(bd.fixed_discount))}円")
    if bd.coupon_discount > 0:
        lines.append(f"    クーポン:         -{_render_price(str(bd.coupon_discount))}円")
    if bd.shipping_fee is not None and bd.shipping_fee > 0:
        lines.append(f"    送料:            +{_render_price(str(bd.shipping_fee))}円")

    lines.append(f"    支払金額:         {_render_price(str(bd.payable_now))}円")
    if bd.earned_points is not None:
        lines.append(f"    獲得ポイント:     {_render_price(str(bd.earned_points))}pt")
    if bd.point_value is not None:
        lines.append(f"    ポイント価値:     {_render_price(str(bd.point_value))}円")
    if bd.effective_cost is not None:
        lines.append(f"    実質価格:         {_render_price(str(bd.effective_cost))}円")

    if bd.normalized_quantity is not None and bd.quantity_unit is not None:
        lines.append(f"    総容量:           {_render_price(str(bd.normalized_quantity))}{bd.quantity_unit}")
        if bd.cash_unit_cost is not None:
            lines.append(f"    支払単価:         {_render_price(str(bd.cash_unit_cost))}円/{bd.quantity_unit}")
        if bd.effective_unit_cost is not None:
            lines.append(f"    実質単価:         {_render_price(str(bd.effective_unit_cost))}円/{bd.quantity_unit}")

    for w in _render_warnings(bd.warnings):
        lines.append(w)

    return lines


def format_comparison_result(result: ComparisonResult) -> list[str]:
    lines: list[str] = []

    lines.append(f"比較基準: {result.basis.value}")

    for iid in result.ranked_ids:
        lines.append("")
        lines.extend(format_store_section(iid, result.breakdowns[iid]))

    for iid in result.incomparable_ids:
        lines.append("")
        lines.extend(format_store_section(f"{iid} (比較不能)", result.breakdowns[iid]))

    if not result.can_compare:
        lines.append("")
        lines.append("判定: 比較できません")
        for w in _render_warnings(result.warnings):
            lines.append(w)
        return lines

    lines.append("")
    lines.append("判定:")
    if result.best_id is not None:
        lines.append(f"  {result.best_id}: 最安 ({result.basis.value})")
    else:
        lines.append("  同額です")

    if result.difference is not None:
        lines.append(f"  差額: {abs(result.difference)}円")
    if result.percentage_difference is not None:
        lines.append(f"  差率: {result.percentage_difference}%")

    for w in _render_warnings(result.warnings):
        lines.append(w)

    return lines


def output_json(result: ComparisonResult) -> str:
    import json as json_lib

    data = {
        "basis": result.basis.value,
        "canCompare": result.can_compare,
        "winnerId": result.best_id,
        "difference": str(result.difference) if result.difference is not None else None,
        "percentageDifference": str(result.percentage_difference) if result.percentage_difference is not None else None,
        "rankedIds": list(result.ranked_ids),
        "incomparableIds": list(result.incomparable_ids),
        "breakdowns": {
            iid: price_breakdown_to_dict(bd)
            for iid, bd in result.breakdowns.items()
        },
        "warnings": list(result.warnings),
    }
    return json_lib.dumps(data, indent=2, ensure_ascii=False)


# ---------------------------------------------------------------------------
# メイン
# ---------------------------------------------------------------------------


def compare_command(args: argparse.Namespace) -> None:
    try:
        offers = load_and_validates(args.file)
    except JsonInputError as e:
        _exit(str(e), EXIT_JSON_FORMAT_ERROR)
    except UnsupportedSchemaError as e:
        _exit(str(e), EXIT_UNSUPPORTED_SCHEMA)
    except ValueError as e:
        _exit(str(e), EXIT_INPUT_ERROR)

    if len(offers) < 2:
        _exit("need at least 2 offers to compare", EXIT_INPUT_ERROR)

    policy = CalculationPolicy()
    context = PurchaseContext()

    breakdowns: dict[str, PriceBreakdown] = {}
    for o in offers:
        breakdowns[o.id] = calculate_price(o, context, policy)

    result = rank_offers(breakdowns)

    if args.format == "json":
        print(output_json(result))
    else:
        print(f"商品: {offers[0].product_name}")
        print("")
        for line in format_comparison_result(result):
            print(line)

    if not result.can_compare:
        sys.exit(EXIT_CANNOT_COMPARE)
    sys.exit(EXIT_SUCCESS)


def load_and_validates(path: Path) -> list[Offer]:
    """JSONファイルを読み込み、検証し、Offerリストを返す。"""
    return load_and_validate(path)


def main() -> None:
    parser = argparse.ArgumentParser(description="価格比較CLI")
    subparsers = parser.add_subparsers(dest="command")

    compare_parser = subparsers.add_parser("compare", help="複数オファーを比較する")
    compare_parser.add_argument("file", type=Path, help="オファーJSONファイルへのパス")
    compare_parser.add_argument(
        "--format",
        choices=["text", "json"],
        default="text",
        help="出力形式（デフォルト: text）",
    )
    compare_parser.set_defaults(func=compare_command)

    args = parser.parse_args()
    if args.command is None:
        parser.print_help()
        sys.exit(EXIT_SUCCESS)

    args.func(args)


if __name__ == "__main__":
    main()
