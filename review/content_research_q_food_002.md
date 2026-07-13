# `q_food_002` / `card_food_002` 調査記録

確認日: 2026-07-13
対象ブランチ: `agent/content-triage-and-correction`
調査時HEAD: `e7cad2b72e93b6c9df4265890e3ae1cb66bbebd0`
判定: `correction_required`を維持し、JSONは変更しない

## 監査対象の全主張

### 問題

- リンゴの生産量が世界一の国は中国である
- 世界のリンゴ生産量の約半分は中国である
- 日本で食べられているリンゴの多くは中国産である

### カード

- 中国は世界最大のリンゴ生産国である
- 中国は全世界のリンゴ生産量の約半分を占める
- 日本で流通するリンゴの多くは中国産である

## 確認できた事実

### FAOSTATの対象データセット

FAOSTATの公式バルクメタデータでは、データセットコード`QCL`は`Production: Crops and livestock products`であり、収穫面積、生産量、単収などを収録する。

- 公式メタデータ: https://bulks-faostat.fao.org/production/datasets_E.json
- 公式データ画面: https://www.fao.org/faostat/en/#data/QCL
- 公式正規化バルクファイル: https://bulks-faostat.fao.org/production/Production_Crops_Livestock_E_All_Data_(Normalized).zip
- 公式メタデータ上の更新日: 2025-12-31

### 2023年のリンゴ生産量

公式QCLデータをDDF形式へ変換した公開ミラーの2023年行では、次の値を確認した。

- `geo=5000`（World）: `97,339,338.76`トン
- `geo=351`（China）: `49,603,050`トン
- `geo=41`（China, mainland）: `49,601,700`トン

計算結果:

- FAOSTAT区分`China` / 世界計: `49,603,050 / 97,339,338.76 × 100 = 50.958893...%`
- `China, mainland` / 世界計: `49,601,700 / 97,339,338.76 × 100 = 50.957506...%`

したがって、2023年について「約51%」または「約半分」という表現は数値上整合する。

確認に用いた公開変換データ:

- 生産量: https://github.com/open-numbers/ddf--unfao--faostat/blob/ba0efde84cc213709596a904c2b72038affaf8a9/datapoints/QCL/ddf--datapoints--qcl_apples_production--by--geo--year.csv
- 地域定義: https://github.com/open-numbers/ddf--unfao--faostat/blob/ba0efde84cc213709596a904c2b72038affaf8a9/ddf--entities--geo.csv

地域定義では、`China`、`China, mainland`、`China, Hong Kong SAR`、`China, Macao SAR`、`China, Taiwan Province of`が別コードとして存在する。現行本文の「中国」がどの集計範囲を指すかは明記されていない。

## 確認できない情報

次は今回の実行環境では確認できなかった。

- FAOSTAT公式正規化バルクファイル内の対象3行
- 対象値のFlagとFlag Description
- 2023年値が公式値、推計値、暫定値等のどの区分か
- 2023年が現在のFAOSTATにおけるリンゴ生産量の最新利用可能年か
- 同一年・同一指標の全対象を公式原表で比較した順位
- 日本の生鮮リンゴ輸入量、加工品輸入量、国内流通量、消費量に占める中国産の割合

公式APIおよびバルクファイルへの直接取得は、実行環境の名前解決制限により完了しなかった。

## 採用しない主張

次の現行記述は、FAOSTATの世界生産統計では直接支えられないため、修正時には削除する。

- 「日本で食べられているリンゴの多くも中国産」
- 「日本で流通するリンゴの多くも中国産」

「日本で食べられている」「日本で流通する」「日本へ輸入される」は異なる母集団であり、国内生産、生鮮果実、加工品、在庫、輸出入を区別する必要がある。

## 暫定修正案

以下は公式原表の対象行とFlagを確認できた場合に限り採用候補とする。現時点ではJSONへ反映しない。

### 問題

- 問題文: `FAOSTATの2023年データで、リンゴの生産量が最も多い国・地域は？`
- 正答: `中国`
- 解説: `FAOSTATの2023年データでは、中国のリンゴ生産量は約4,960万トンで、世界計約9,734万トンの約51%を占める。`

### カード

- タイトル: `中国のリンゴ生産`
- shortText: `2023年、世界のリンゴ生産量の約51%を占めた。`
- detailText: `FAOSTATの2023年データでは、中国のリンゴ生産量は約4,960万トンで、世界計約9,734万トンの約51%にあたる。`

採用時には、`中国`がFAOSTATの`China`集計か`China, mainland`かを本文と出典条件で一致させる。

## 停止理由

公開変換データにより数値と集計範囲の候補は再現できたが、公式原表の対象行と統計Flagを直接確認できていない。プロジェクトの停止条件に従い、問題・カードの本文変更、構造化出典の設定、`approved`への変更は行わない。

## 次回の再開条件

1. FAOSTAT公式QCL原表または正規化バルクファイルを取得する
2. 品目`Apples`、要素`Production quantity`、年`2023`の中国・世界計を抽出する
3. Area、Item、Element、Year、Unit、Value、Flag、Flag Descriptionを保存する
4. 同条件の全対象から中国が最大であることを確認する
5. 中国の集計範囲を確定する
6. 修正文全文と原表を再照合する
7. 問題とカードを同一コミットで変更する
8. 監査CLIとCIを最初から再実行する
