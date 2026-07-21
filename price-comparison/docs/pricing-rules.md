# 価格計算仕様書

## 目的

スーパー・ドラッグストア・ネット通販で「どちらが本当に安いか」を比較するための計算ルールを定める。

本仕様は比較見積もりであり、税務上の証憑（レシート・領収書）を再現するものではない。

## 計算順序

1. 税抜価格の正規化（税込→税抜、または税抜→税込）
2. 商品割引（割引率 → 固定額値引き）
3. クーポン（最低利用額チェックあり）
4. 送料加算
5. 支払金額確定
6. ポイント還元控除（ポイント数 × 評価率）
7. 実質価格
8. 容量換算単価（支払単価 / 実質単価）

## 税計算

| 項目 | 仕様 |
|------|------|
| 税込価格からの本体抽出 | `tax = price × rate / (1 + rate)` を丸め、`preTax = price - tax` |
| 税抜価格からの税額計算 | `tax = price × rate` を丸め、`gross = price + tax` |
| 端数処理 | `CalculationPolicy.tax_rounding` に従う（デフォルト: HALF_UP） |
| 税率 | 入力値（0.10 = 10%、0.08 = 8%、0 = 非課税） |

## 割引・クーポン

適用順序:
1. 割引率（`percentageDiscount`）: 税込基準価格 × 割引率、1円単位で丸め
2. 固定額値引き（`fixedDiscount`）: 割引後価格から減算
3. クーポン（`couponDiscount`）: 最低利用額（`couponMinimumSubtotal`）を満たす場合のみ適用

クーポンが残額を超える場合、残額までに制限する。

## ポイント

| 項目 | 仕様 |
|------|------|
| 獲得ポイント | `earnedPoints` が指定されていればそれを使用。なければ `payableNow × pointRate`（切捨て）+ `fixedPoints` |
| ポイント価値 | `earnedPoints × pointValueRate`（デフォルト: 1倍） |
| 実質価格 | `payableNow - pointValue`（負の場合は警告付きで許可） |

## 送料

送料は注文属性（`PurchaseContext`）として扱う。
`ShippingAllocation` で単品帰属か注文全体かを区別する。
`FULL_ORDER` の場合は結果に警告を付ける。

## 容量換算

| 単位 | 次元 | 基準単位への換算 |
|------|------|------------------|
| ml | VOLUME | × 1 |
| L | VOLUME | × 1000 |
| g | MASS | × 1 |
| kg | MASS | × 1000 |
| piece | COUNT | × 1 |

`MeasureKind` でさらに細分化（TABLET / ROLL / SHEET / BAG 等）。
同一 `Dimension` かつ同一 `MeasureKind` の場合のみ単価比較可能。

## 比較基準

優先順位:
1. `EFFECTIVE_UNIT_COST`: 実質単価（最優先）
2. `CASH_UNIT_COST`: 支払単価
3. `EFFECTIVE_TOTAL`: 実質総額
4. `CASH_TOTAL`: 支払総額

ポイント不明時は現金比較（CASH_*）へフォールバックする。

## 入力モデル（Phase 1）

### Offer（1商品）

- id: 文字列（必須）
- productName: 文字列（必須）
- storeName: 文字列（必須）
- price: Decimal文字列（必須、正数）
- taxIncluded: 真偽値（必須）
- taxRate: Decimal文字列（0〜1）
- quantity: Quantityオブジェクト（任意）
- percentageDiscount: Decimal文字列（0〜1、デフォルト0）
- fixedDiscount: Decimal文字列（デフォルト0）
- couponDiscount: Decimal文字列（デフォルト0）
- couponMinimumSubtotal: Decimal文字列（任意）
- pointRate: Decimal文字列（0〜1、デフォルト0）
- fixedPoints: Decimal文字列（デフォルト0）
- earnedPoints: Decimal文字列（任意。未指定時は自動計算）
- shippingFee: Decimal文字列（任意。未指定時は0扱いにしない）

### Quantity（容量）

- value: Decimal文字列（正数）
- unit: ml / L / g / kg / piece
- packageCount: 整数（デフォルト1）
- measureKind: GENERIC_VOLUME / GENERIC_MASS / ITEM / TABLET / CAPSULE / SHEET / ROLL / BAG

### PurchaseContext（購入コンテキスト）

- shippingFee: Decimal（任意）
- shippingAllocation: FULL_ORDER / ALLOCATED_TO_ITEM / EXCLUDED / UNKNOWN
- checkoutTotalOverride: Decimal（任意、最終支払額の上書き）

## 警告コード一覧

| コード | 発生条件 | 計算継続 | 比較への影響 |
|--------|----------|----------|--------------|
| POINTS_MISSING | earnedPoints未指定で自動計算不可 | 継続 | 現金比較へフォールバック |
| QUANTITY_MISSING | 数量未入力 | 継続 | 総額比較のみ |
| SHIPPING_FULL_ORDER | 送料を全額帰属 | 継続 | 単価が不正確になる可能性 |
| DISCOUNT_EXCEEDS_PRICE | 割引額が価格を超過 | 継続（0円に抑止） | なし |
| COUPON_EXCEEDS_REMAINING | クーポンが残額を超過 | 継続（残額に抑止） | なし |
| POINTS_EXCEED_PAYABLE | ポイント価値が支払額超過 | 継続 | なし |
| NEGATIVE_EFFECTIVE_COST | 実質価格が負 | 継続 | PROMOTIONAL_ANOMALY扱い推奨 |
| PROMOTIONAL_ANOMALY | プロモーションにより異常値 | 継続 | 通常比較と分離推奨 |
| QUANTITY_ZERO | 数量が0 | 継続 | 単価計算不可 |
| CANNOT_COMPARE | 比較不能 | 停止 | 比較不可能 |
| UNSUPPORTED_SCHEMA | 未対応schemaVersion | 停止 | 読み込み不可 |

## 出力モデル

### PriceBreakdown

- displayPrice, taxAmount, basePriceInclTax: 税計算結果
- discountAmount: 割引額合計
- payableNow: 支払金額（割引＋送料後）
- earnedPoints: 獲得ポイント数
- pointValue: ポイント価値
- effectiveCost: 実質価格
- normalizedQuantity: 正規化後の総容量
- cashUnitCost: 支払単価
- effectiveUnitCost: 実質単価
- cashComplete / rewardComplete / unitComplete: 計算状態

## JSONスキーマ

```json
{
  "schemaVersion": 1,
  "offers": [
    {
      "id": "offer-a",
      "productName": "洗剤",
      "storeName": "店舗A",
      "price": "398",
      "taxIncluded": true,
      "taxRate": "0.10",
      "quantity": {
        "value": "500",
        "unit": "ml",
        "packageCount": 2,
        "measureKind": "GENERIC_VOLUME"
      },
      "percentageDiscount": "0",
      "fixedDiscount": "0",
      "couponDiscount": "30",
      "couponMinimumSubtotal": null,
      "pointRate": "0.01",
      "fixedPoints": "0",
      "earnedPoints": null,
      "shippingFee": null
    }
  ]
}
```
