# 03. データ設計書 v0.1

## 1. 方針

へぇダンジョンのMVPでは、すべての初期データをJSONで管理する。

対象:

- questions.json
- cards.json
- enemies.json

アプリ内でAI生成は行わない。AIは開発時に問題候補を作るためだけに使い、アプリに入れる前に検証済みフラグを付ける。

## 2. Question

### 2.1 フィールド

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| id | string | Yes | 問題ID |
| category | string | Yes | カテゴリ |
| difficulty | string | Yes | easy/normal/hard |
| question | string | Yes | 問題文 |
| choices | string[] | Yes | 4択選択肢 |
| answerIndex | number | Yes | 正解index。0始まり |
| explanation | string | Yes | へぇ解説 |
| relatedCardId | string | Yes | 関連カードID |
| sourceNote | string | Yes | 出典メモ、URL、確認メモ |
| verified | boolean | Yes | 検証済みならtrue |

### 2.2 例

```json
{
  "id": "q_geo_001",
  "category": "nature_geography",
  "difficulty": "easy",
  "question": "世界でいちばん深い湖は？",
  "choices": ["バイカル湖", "琵琶湖", "カスピ海", "スペリオル湖"],
  "answerIndex": 0,
  "explanation": "バイカル湖の最大深度は約1,642m。湖の中でいちばん深い湖として知られているよ。",
  "relatedCardId": "card_geo_001",
  "sourceNote": "Lake Baikal reference: https://en.wikipedia.org/wiki/Lake_Baikal",
  "verified": true
}
```

## 3. HeeCard

### 3.1 フィールド

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| id | string | Yes | カードID |
| title | string | Yes | カード名 |
| category | string | Yes | カテゴリ |
| shortText | string | Yes | 一覧用短文 |
| detailText | string | Yes | 詳細説明 |
| imageAsset | string | No | 画像パス |
| rarity | string | Yes | normal/rare/super_rare |
| sourceNote | string | Yes | 出典メモ |

### 3.2 例

```json
{
  "id": "card_geo_001",
  "title": "バイカル湖",
  "category": "nature_geography",
  "shortText": "世界で最も深い湖として知られるロシアの湖。",
  "detailText": "バイカル湖はロシアにある湖で、最大深度は約1,642m。深さだけでなく、透明度や固有種の多さでも知られている。",
  "imageAsset": "assets/images/cards/card_geo_001.png",
  "rarity": "normal",
  "sourceNote": "Lake Baikal reference: https://en.wikipedia.org/wiki/Lake_Baikal"
}
```

## 4. Enemy

### 4.1 フィールド

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| id | string | Yes | 敵ID |
| name | string | Yes | 敵名 |
| type | string | Yes | normal/boss |
| maxHp | number | Yes | 最大HP |
| attack | number | Yes | 基本攻撃力 |
| imageAsset | string | No | 画像パス |

## 5. SaveData

### 5.1 フィールド

| フィールド | 型 | 説明 |
|---|---|---|
| version | number | セーブデータバージョン |
| totalPlayCount | number | 累計プレイ回数 |
| totalClearCount | number | 累計クリア回数 |
| streakDays | number | 連続プレイ日数 |
| lastPlayedDate | string | 最終プレイ日 |
| lastRewardDate | string | 最終報酬獲得日 |
| ownedCardIds | string[] | 獲得済みカードID |
| settings | object | 設定 |

### 5.2 例

```json
{
  "version": 1,
  "totalPlayCount": 3,
  "totalClearCount": 2,
  "streakDays": 2,
  "lastPlayedDate": "2026-07-08",
  "lastRewardDate": "2026-07-08",
  "ownedCardIds": ["card_geo_001"],
  "settings": {
    "soundEnabled": true,
    "bgmEnabled": true
  }
}
```

## 6. ID命名規則

### 6.1 Question

```text
q_<category_short>_<number>
```

例:

```text
q_geo_001
q_sci_001
q_bio_001
```

### 6.2 Card

```text
card_<category_short>_<number>
```

例:

```text
card_geo_001
card_sci_001
```

### 6.3 Enemy

```text
enemy_<type>_<number>
```

例:

```text
enemy_slime_001
enemy_boss_001
```

## 7. 問題作成ルール

### 7.1 採用条件

- 答えが一意に決まる
- 選択肢が自然
- 解説が短く面白い
- 出典メモがある
- `verified: true` にできる

### 7.2 不採用条件

- 諸説ある
- 数値が年により変わりやすい
- 政治、医療、金融、法律など慎重な分野
- 子ども向けに不適切な内容
- 文化・国籍・属性を揶揄する内容

### 7.3 変更されやすい情報

世界一、最大、最新、現役、人口、ランキングなどは更新される可能性がある。v0.1ではなるべく避けるか、出典と確認日を必ず残す。

## 8. サンプルデータの扱い

このZIPに含めた `data/*.sample.json` は実装初期の雛形。

AIエージェントはこれを `assets/data/` にコピーし、アプリから読み込めるようにする。
