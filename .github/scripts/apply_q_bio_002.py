from __future__ import annotations

import json
from pathlib import Path

STABLE_HEAD = "9814561f48b55dfcfdc73da33e99aa208a3c7347"
QUESTION_ID = "q_bio_002"
CARD_ID = "card_bio_002"
SOURCE_TITLE = "Blue Whale Heart Arrives at the ROM"
SOURCE_PUBLISHER = "Royal Ontario Museum"
SOURCE_URL = "https://www.rom.on.ca/en/about-us/newsroom/press-releases/blue-whale-heart-arrives-at-the-rom"
VERIFIED_AT = "2026-07-13"

ROOT = Path(__file__).resolve().parents[2]
QUESTIONS_PATH = ROOT / "assets/data/questions.json"
CARDS_PATH = ROOT / "assets/data/cards.json"
CORRECTIONS_PATH = ROOT / "review/content_corrections_batch_1.csv"
RESEARCH_PATH = ROOT / "review/content_research_q_bio_002.md"
SCRIPT_PATH = ROOT / ".github/scripts/apply_q_bio_002.py"
WORKFLOW_PATH = ROOT / ".github/workflows/apply-q-bio-002.yml"


def load_json(path: Path) -> list[dict[str, object]]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, list):
        raise RuntimeError(f"{path} must contain a JSON array")
    return value


def find_unique(records: list[dict[str, object]], record_id: str) -> tuple[int, dict[str, object]]:
    matches = [(index, record) for index, record in enumerate(records) if record.get("id") == record_id]
    if len(matches) != 1:
        raise RuntimeError(f"expected exactly one {record_id}, found {len(matches)}")
    return matches[0]


questions = load_json(QUESTIONS_PATH)
question_index, old_question = find_unique(questions, QUESTION_ID)
expected_old_question = {
    "id": "q_bio_002",
    "category": "living_things",
    "difficulty": "normal",
    "question": "シロナガスクジラの心臓の重さは約どれくらい？",
    "choices": ["約10kg", "約180kg", "約500kg", "約1t"],
    "answerIndex": 1,
    "explanation": "シロナガスクジラの心臓は約180kgもある。小型車1台分くらいの重さなんだ。",
    "relatedCardId": "card_bio_002",
    "sourceNote": "National Geographic",
    "verified": True,
}
if old_question != expected_old_question:
    raise RuntimeError(f"unexpected current question record: {old_question!r}")

questions[question_index] = {
    "id": "q_bio_002",
    "category": "living_things",
    "difficulty": "normal",
    "question": "2017年、Royal Ontario Museumの実物シロナガスクジラ心臓標本がドイツで受けた保存処理は？",
    "choices": ["プラスティネーション", "凍結乾燥", "液浸保存", "樹脂製レプリカの作製"],
    "answerIndex": 0,
    "explanation": "Royal Ontario Museumの公式発表によると、この実物標本はドイツのグーベンでプラスティネーション処理を受け、2017年5月15日にトロントへ到着した。",
    "relatedCardId": "card_bio_002",
    "sourceNote": "Royal Ontario Museum（2017）",
    "verified": True,
    "source": {
        "title": SOURCE_TITLE,
        "publisher": SOURCE_PUBLISHER,
        "url": SOURCE_URL,
        "verifiedAt": VERIFIED_AT,
        "verificationLevel": "primary",
        "reviewStatus": "approved",
    },
}
QUESTIONS_PATH.write_text(
    json.dumps(questions, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

cards = load_json(CARDS_PATH)
card_index, old_card = find_unique(cards, CARD_ID)
expected_old_card = {
    "id": "card_bio_002",
    "title": "シロナガスクジラの心臓",
    "category": "living_things",
    "shortText": "地球上で最も大きな心臓。",
    "detailText": "シロナガスクジラの心臓は約180kg。小型車1台分の重さで、1回の拍動で約80リットルの血液を送り出す。",
    "imageAsset": "assets/images/cards/card_bio_002.png",
    "rarity": "rare",
    "sourceNote": "National Geographic",
}
if old_card != expected_old_card:
    raise RuntimeError(f"unexpected current card record: {old_card!r}")

cards[card_index] = {
    "id": "card_bio_002",
    "title": "保存されたシロナガスクジラの心臓",
    "category": "living_things",
    "shortText": "実物標本はプラスティネーションで保存された。",
    "detailText": "Royal Ontario Museumの2017年公式発表によると、実物の心臓標本はドイツのグーベンでプラスティネーション処理を受けた。2017年5月15日にトロントへ到着し、5月18日に展示へ設置された。",
    "imageAsset": "assets/images/cards/card_bio_002.png",
    "rarity": "rare",
    "sourceNote": "Royal Ontario Museum（2017）",
    "source": {
        "title": SOURCE_TITLE,
        "publisher": SOURCE_PUBLISHER,
        "url": SOURCE_URL,
        "verifiedAt": VERIFIED_AT,
        "verificationLevel": "primary",
        "reviewStatus": "approved",
    },
}
CARDS_PATH.write_text(
    json.dumps(cards, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

corrections = CORRECTIONS_PATH.read_text(encoding="utf-8")
if QUESTION_ID in corrections or CARD_ID in corrections:
    raise RuntimeError("correction CSV already contains the target pair")
if not corrections.endswith("\n"):
    corrections += "\n"
corrections += (
    'q_bio_002,card_bio_002,"question,choices,answer,explanation,card",'
    '"numeric,analogy,physiology,specimen-generalization",'
    '"約180kg、小型車1台分、1拍動80L、種全体への固定値一般化を削除し、ROM公式資料が直接示す特定実物標本のプラスティネーション処理へ差し替え",'
    f'{SOURCE_TITLE},{SOURCE_PUBLISHER},{SOURCE_URL},{VERIFIED_AT},primary,approved\n'
)
CORRECTIONS_PATH.write_text(corrections, encoding="utf-8")

research = f"""# `q_bio_002` / `card_bio_002` 調査・修正記録

確認日: {VERIFIED_AT}
対象ブランチ: `agent/content-triage-and-correction`
判定: 心臓重量、車との比喩、拍出量、種全体への一般化を削除し、Royal Ontario Museumの公式資料が直接支える特定標本の保存工程へ差し替えて承認

## 監査対象だった主張

### 問題

- シロナガスクジラの心臓は約180kgである
- その値を種全体の代表値として四択問題にできる
- 約180kgは小型車1台分に相当する

### カード

- シロナガスクジラの心臓は地球上で最も大きい
- シロナガスクジラの心臓は約180kgである
- 約180kgは小型車1台分に相当する
- 1回の拍動で約80リットルの血液を送り出す

## メタ認知による問題点

- 心臓重量は個体、体格、標本状態、摘出・保存工程、計測時点、付着組織の範囲で変わり得る。
- 特定個体または標本の測定値を、シロナガスクジラ全体の固定値として提示していた。
- `小型車1台分`は比較対象となる車種、車両重量、積載条件が示されず、180kgとの対応も不明確だった。
- `1拍動80リットル`は、対象個体、測定方法、安静・運動条件、推定か実測かが示されていなかった。
- `地球上で最も大きい`は、比較対象、組織の定義、測定条件を揃えた資料が必要になる。
- 出典欄の`National Geographic`だけでは、記事名、URL、対象標本、測定条件を特定できなかった。

## 採用した公式資料

- Title: `{SOURCE_TITLE}`
- Publisher: `{SOURCE_PUBLISHER}`
- Published: 2017-05-18
- Category: Press Release
- Record: {SOURCE_URL}

## 直接確認できた事実

Royal Ontario Museumの公式発表から、次を確認した。

1. 同館は実物の保存されたシロナガスクジラ心臓標本を展示した。
2. 標本はドイツのブランデンブルク州グーベンを経由した。
3. グーベンでプラスティネーション処理を受けた。
4. 2017年5月15日にトロント・ピアソン国際空港へ到着した。
5. 2017年5月18日に展示へ設置された。

修正後の問題とカードには、特定標本の保存処理、場所、到着日、設置日だけを採用した。

## 資料に存在するが採用しない主張

ROMの2017年発表は、この標本を当時の`first and only real preserved blue whale heart in the world`と表現し、シロナガスクジラの心臓を動物で最大とも説明している。

これらは2017年時点の展示広報上の表現または広い比較主張であり、今回の設問に不要である。現在も唯一か、比較条件を統一した解剖学的ランキングかを別資料で再検証していないため、問題・カードには採用しない。

## 直接確認できなかった情報

- この標本の処理前または処理後の正確な重量
- 重量を測定した日時、機器、付着組織の範囲
- この標本の個体の体長、年齢、性別と心臓重量の関係
- `約180kg`がどの個体・標本・測定段階を指すか
- `小型車1台分`の比較対象車種と重量
- 1回の拍動で約80リットルという値の実測条件
- 2017年以後も世界で唯一の実物保存標本か
- 統一条件で比較した全動物の心臓重量ランキング

## 採用しない主張

- `シロナガスクジラの心臓は約180kg`
- `約180kgが種全体の固定的な正答`
- `小型車1台分`
- `1拍動で約80リットル`
- `地球上で最も大きな心臓`
- `現在も世界で唯一の実物保存標本`

これらをすべて反対の意味で否定したのではない。対象個体、標本状態、測定方法、比較条件、時点を現行文のとおり直接支える資料が揃わないため削除した。

## 修正後の問題

- 問題文: `2017年、Royal Ontario Museumの実物シロナガスクジラ心臓標本がドイツで受けた保存処理は？`
- 選択肢: `プラスティネーション`、`凍結乾燥`、`液浸保存`、`樹脂製レプリカの作製`
- 正答: `プラスティネーション`
- 解説: ROM公式発表が直接示す実物標本、グーベン、保存処理、到着日だけに限定

設問をROMの当該実物標本と2017年公式発表に限定することで正答を一意にした。他のシロナガスクジラ標本が同じ処理を受けたとは主張しない。

## 修正後のカード

- タイトル: `保存されたシロナガスクジラの心臓`
- shortText: `実物標本はプラスティネーションで保存された。`
- detailText: 特定標本、グーベンでの処理、2017年5月15日の到着、5月18日の設置だけに限定

## 証拠レベル

`primary`

理由: 標本を所蔵・展示したRoyal Ontario Museum自身の公式発表から、その標本の保存工程と展示日程を直接確認したため。この証拠レベルは特定標本の取り扱いに対するもので、種全体の心臓重量や生理値に対する一次証拠ではない。

## 承認条件の自己点検

- 問題前提: ROM公式発表が直接支える
- 正答の一意性: 当該標本が受けた処理としてプラスティネーションを明記
- 数値: 重量と拍出量を採用していない
- 母集団: 種全体ではなくROMの特定標本に限定
- 比喩: 小型車との比較を削除
- ランキング: 最大・唯一という主張を問題とカードから削除
- 時点: 2017年の公式発表に限定
- 問題とカードの出典URL: 同一
- 未確認主張の残存: なし

## 再検証条件

- 心臓重量または拍出量を再追加する場合
- 特定標本の情報を種全体へ広げる場合
- 最大、唯一、世界初などの比較・時点依存表現を追加する場合
- プラスティネーションの具体的工程や材料を説明する場合
"""
RESEARCH_PATH.write_text(research, encoding="utf-8")

SCRIPT_PATH.unlink()
WORKFLOW_PATH.unlink()

print(f"prepared correction from stable head {STABLE_HEAD}")
