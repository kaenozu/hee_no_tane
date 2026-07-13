# `q_daily_life_008` / `card_daily_life_008` 調査記録

確認日: 2026-07-13
対象バッチ: 高リスク修正バッチ2
判定: `approved`
検証レベル: `primary`
画像判定: `generic_placeholder`

## 調査前の自己点検

- 問題文、全選択肢、正答、解説、カード本文、構造化出典、画像を対象にした。
- 旧問題の一部だけが妥当でも、周辺の数値・因果・逸話が支えられない場合は部分承認しない。
- 取得できる直接資料が全文を支える、条件を固定した別事実への全面置換を許容した。

## 旧本文から分解した主張

- 非常口が緑なのは赤い炎の補色で最も目立つから
- 科学的根拠で緑が選ばれた
- 日本のデザインが国際標準になったという一連の因果

## 採用資料

- 資料名: `Safety signs and signals: Guidance on Regulations L64`
- 発行元: `UK Health and Safety Executive (HSE)`
- URL: https://www.hse.gov.uk/pubns/priced/l64.pdf

## 直接確認できた事実

- HSE L64はHealth and Safety (Safety Signs and Signals) Regulations 1996の公式ガイダンスである。
- L64表1は緑をEmergency escape、First-aid sign、No dangerに割り当てる。
- 情報対象としてdoors、exits、escape routes、equipment and facilitiesを示す。

## 採用しない主張・条件差

- 補色だけを採用理由とする因果、日本発祥からISO化までの一般化を扱わない。
- 資料が直接示さない追加の年代、順位、因果、心理効果、発明起源をカードへ足さない。

## 最終問題

- 問題文: `英国HSEの安全標識ガイダンスL64で、緑色が示す用途は？`
- 選択肢:
  1. `非常口・避難経路や応急手当`
  2. `消火設備`
  3. `禁止行為`
  4. `注意・警告`
- 正答: `非常口・避難経路や応急手当`
- 解説: `HSEのL64表1は、緑を非常脱出・応急手当の標識に割り当て、扉、出口、避難経路、設備、施設を示すとしている。`

## 最終カード

- タイトル: `安全標識の緑色`
- shortText: `非常口・避難経路と応急手当を示す色。`
- detailText: `英国HSEの安全標識ガイダンスL64表1では、緑色は非常脱出・応急手当の標識に使われ、扉、出口、避難経路、設備、施設を示す。`

## 画像確認

`assets/images/cards/card_daily_life_008.png`は対象6枚で同一SHA-256 `bae58e7195f3630abb908bbd373d6d98eaa9d3b009fa9cd19aaa2c1d556d3b1e`の宝箱プレースホルダーだった。旧主張や新主張を具体的に図示しておらず矛盾はしないが、内容固有の画像でもないため`generic_placeholder`とする。

## 承認判定

保持する全文を上記資料と照合し、旧主張をすべて削除した。問題とカードの出典URL、確認日、証拠レベル、承認状態を一致させたため承認する。
