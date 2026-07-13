from __future__ import annotations

import json
from pathlib import Path

STABLE_HEAD = "269c59ceccda87a8d245e3dd6a1cd70e4482e31d"
QUESTION_ID = "q_daily_life_001"
CARD_ID = "card_daily_life_001"
SOURCE_TITLE = (
    "Does the installation of blue lights on train platforms prevent suicide? "
    "A before-and-after observational study from Japan"
)
SOURCE_PUBLISHER = "Journal of Affective Disorders (Elsevier)"
SOURCE_URL = "https://pubmed.ncbi.nlm.nih.gov/22980401/"
VERIFIED_AT = "2026-07-13"

ROOT = Path(__file__).resolve().parents[2]
QUESTIONS_PATH = ROOT / "assets/data/questions.json"
CARDS_PATH = ROOT / "assets/data/cards.json"
CORRECTIONS_PATH = ROOT / "review/content_corrections_batch_1.csv"
RESEARCH_PATH = ROOT / "review/content_research_q_daily_life_001.md"
SCRIPT_PATH = ROOT / ".github/scripts/apply_q_daily_life_001.py"
WORKFLOW_PATH = ROOT / ".github/workflows/apply-q-daily-life-001.yml"


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
    "id": "q_daily_life_001",
    "category": "daily_life",
    "difficulty": "normal",
    "question": "犯罪の抑止や心の落ち着きを目的として、駅や街頭で導入される照明の色は何色？",
    "choices": ["赤色", "緑色", "青色", "白色"],
    "answerIndex": 2,
    "explanation": "青色光には人間の副交感神経を刺激してリラックスさせる効果があると考えられ、防犯対策や駅のホームでの事故防止に採用されています。",
    "relatedCardId": "card_daily_life_001",
    "sourceNote": "警察庁 防犯環境設計指針",
    "verified": True,
}
if old_question != expected_old_question:
    raise RuntimeError(f"unexpected current question record: {old_question!r}")

questions[question_index] = {
    "id": "q_daily_life_001",
    "category": "daily_life",
    "difficulty": "normal",
    "question": "2013年に発表された日本の駅ホームの青色灯に関する観察研究で、分析対象となった駅は合計何駅？",
    "choices": ["11駅", "60駅", "71駅", "100駅"],
    "answerIndex": 2,
    "explanation": "この研究は、ある鉄道会社の2000〜2010年のデータを使い、青色灯を導入した11駅と導入していない60駅、計71駅を比較した。観察研究であり、青色灯が作用する仕組みは調べていない。",
    "relatedCardId": "card_daily_life_001",
    "sourceNote": "Matsubayashiほか（2013）Journal of Affective Disorders",
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
    "id": "card_daily_life_001",
    "title": "青色防犯灯の効果",
    "category": "daily_life",
    "shortText": "防犯のために導入された青い光",
    "detailText": "イギリスで導入された際、犯罪率が低下したという報告があり、日本でも全国の自治体で街灯や鉄道駅のホームへの導入が進みました。",
    "imageAsset": "assets/images/cards/card_daily_life_001.png",
    "rarity": "normal",
    "sourceNote": "警察庁 防犯環境設計指針",
}
if old_card != expected_old_card:
    raise RuntimeError(f"unexpected current card record: {old_card!r}")

cards[card_index] = {
    "id": "card_daily_life_001",
    "title": "駅ホームの青色灯研究",
    "category": "daily_life",
    "shortText": "2013年の観察研究は71駅を比較。",
    "detailText": "2013年の研究は、ある鉄道会社の2000〜2010年のデータを用い、青色灯を導入した11駅と導入していない60駅を比較した。論文は、単一の鉄道会社のデータに基づくことと、青色灯が作用する仕組みを検討していないことを限界としている。",
    "imageAsset": "assets/images/cards/card_daily_life_001.png",
    "rarity": "normal",
    "sourceNote": "Matsubayashiほか（2013）Journal of Affective Disorders",
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
    'q_daily_life_001,card_daily_life_001,"question,choices,answer,explanation,card",'
    '"causality,psychological-effect,crime-statistics,scope",'
    '"副交感神経・リラックス、防犯因果、英国犯罪率、日本全国導入の一般化を削除し、'
    '2013年原著が直接示す71駅の観察研究設計へ差し替え",'
    f'{SOURCE_TITLE},{SOURCE_PUBLISHER},{SOURCE_URL},{VERIFIED_AT},primary,approved\n'
)
CORRECTIONS_PATH.write_text(corrections, encoding="utf-8")

research = f"""# `q_daily_life_001` / `card_daily_life_001` 調査・修正記録

確認日: {VERIFIED_AT}
対象ブランチ: `agent/content-triage-and-correction`
判定: 心理・生理効果と防犯・事故防止の因果を削除し、原著論文の研究設計が直接支える内容へ差し替えて承認

## 監査対象だった主張

### 問題

- 青色光は人間の副交感神経を刺激する
- 青色光には人をリラックスさせる効果がある
- その効果を理由に防犯対策へ採用されている
- その効果を理由に駅ホームの事故防止へ採用されている

### カード

- イギリスで青色照明を導入した際に犯罪率が低下した
- 日本全国の自治体で街灯への導入が進んだ
- 日本の鉄道駅ホームへの導入が進んだ
- 防犯灯と駅ホーム照明に共通する因果的な効果がある

## メタ認知による問題点

- 導入目的と実際の効果を区別していなかった。
- 防犯灯、踏切、駅ホーム照明を、用途・場所・評価指標の違いを無視して一括していた。
- 観察研究の結果から、生理的な作用機序と因果関係を断定していた。
- 地域、鉄道会社、期間、時間帯、設置位置、比較群を示さず、全国一般へ拡張していた。
- `犯罪率が低下した`というカード主張には、対象地域、犯罪分類、期間、比較方法を直接示す出典が付いていなかった。
- 出典欄の`警察庁 防犯環境設計指針`から、現行文の心理・生理効果、英国の犯罪率、鉄道ホームの効果を直接確認できなかった。

## 採用した一次資料

- Title: `{SOURCE_TITLE}`
- Authors: Tetsuya Matsubayashi, Yasuyuki Sawada, Michiko Ueda
- Journal: `Journal of Affective Disorders`
- Publication: 2013 May; 147(1-3): 385–388
- DOI: `10.1016/j.jad.2012.08.018`
- PMID: `22980401`
- Record: {SOURCE_URL}
- Publication type: Observational Study

## 直接確認できた事実

原著論文の抄録から、次を確認した。

1. 研究は、日本の駅ホームに設置された青色LED灯と自殺件数を扱う観察研究である。
2. ある鉄道会社の2000年から2010年までのパネルデータを使用した。
3. 分析対象は合計71駅だった。
4. 青色灯を導入した11駅を介入群、導入していない60駅を対照群として比較した。
5. 回帰分析では導入後の減少が報告されたが、95%信頼区間は広い。
6. 論文自身が、単一の鉄道会社のデータに依存することと、青色灯による作用機序を調べていないことを限界としている。

修正後の問題とカードには、1から4および限界のうち原著抄録が直接支える研究設計だけを採用した。効果量はクイズ本文へ採用していない。

## 反証・条件差として確認した原著

- Title: `Reconsidering the effects of blue-light installation for prevention of railway suicides`
- Authors: Masao Ichikawa, Haruhiko Inada, Minae Kumeji
- Journal: `Journal of Affective Disorders`
- Publication: 2014 Jan; 152-154: 183–185
- DOI: `10.1016/j.jad.2013.09.006`
- PMID: `24074716`
- Record: https://pubmed.ncbi.nlm.nih.gov/24074716/

この再検討は、2002年4月から2012年3月までの政府統計を使い、青色灯が点灯し得る場所・時間帯へ対象範囲を分解した。抄録では、全5,841件のうち駅構内かつ夜間だったものは14%であり、仮に夜間の駅ホームで何らかの効果があっても、全体への影響は先行推定より小さいと結論づけている。

これは、先行研究が存在しないことや効果が必ずゼロであることを示す資料ではない。一方で、先行研究の推定を全国、全時間帯、犯罪防止、心理・生理作用へ一般化できないことを示す条件差・反証として扱う。

## 直接確認できなかった情報

- 青色光が副交感神経を刺激するという、この文脈に対応した実験結果
- 青色光が人をリラックスさせ、その結果として犯罪や事故を減らすという作用機序
- イギリスのどの地域で、どの犯罪分類が、どの期間・比較条件で低下したか
- 日本全国の自治体における導入件数または導入率
- 日本全国の鉄道駅における導入件数または導入率
- 防犯灯と駅ホーム照明で同じ効果が成立すること
- 青色灯以外の同時対策、駅固有要因、時間変化などの交絡を完全に除去した因果効果

## 採用しない主張

- `青色光は副交感神経を刺激する`
- `青色光は人をリラックスさせる`
- `リラックス効果によって犯罪が減る`
- `リラックス効果によって駅ホームの事故が減る`
- `イギリスで導入後に犯罪率が低下した`
- `日本全国で導入が進んだ`
- `青色防犯灯には防犯効果がある`

これらをすべて反対の意味で否定したのではない。現行の問題・カードに必要な地域、期間、母集団、測定方法、作用機序、交絡調整を直接支える資料が揃わないため削除した。

## 修正後の問題

- 問題文: `2013年に発表された日本の駅ホームの青色灯に関する観察研究で、分析対象となった駅は合計何駅？`
- 選択肢: `11駅`、`60駅`、`71駅`、`100駅`
- 正答: `71駅`
- 解説: 2000〜2010年、導入11駅、非導入60駅、合計71駅という研究設計と、作用機序未検討という限界だけに限定

設問を当該2013年原著の分析対象数に限定することで、正答を一意にした。青色灯の効果が全国・全時間帯・他用途でも成立するとは主張しない。

## 修正後のカード

- タイトル: `駅ホームの青色灯研究`
- shortText: `2013年の観察研究は71駅を比較。`
- detailText: 単一鉄道会社、2000〜2010年、導入11駅、非導入60駅、作用機序未検討という原著抄録の範囲だけに限定

## 証拠レベル

`primary`

理由: 査読済み原著論文の抄録から研究対象、期間、駅数、比較群、研究上の限界を直接確認し、修正文にはそれらだけを残したため。

## 承認条件の自己点検

- 問題前提: 2013年原著の抄録が直接支える
- 正答の一意性: 合計71駅と明記され、11駅と60駅の内訳とも整合する
- 数値: 対象駅数と期間を原著抄録で直接確認
- 母集団: ある一鉄道会社の駅に限定
- 地域: 日本の大都市圏という原著の条件を全国一般へ拡張していない
- 因果: 効果量・生理機序・犯罪抑止の因果を問題とカードから削除
- 条件差・反証: 2014年の再検討を記録し、一般化を避けた
- 問題とカードの出典URL: 同一
- 未確認主張の残存: なし

## 再検証条件

- 効果量や信頼区間をクイズ本文へ追加する場合
- 犯罪抑止、事故防止、心理・生理作用を追加する場合
- 特定鉄道会社の観察結果を全国または海外へ広げる場合
- 防犯灯、踏切灯、駅ホーム灯を同一の介入として扱う場合
- 導入数、導入率、最新の運用状況を追加する場合
"""
RESEARCH_PATH.write_text(research, encoding="utf-8")

# Remove the temporary application path so the final comparison against STABLE_HEAD
# contains only the four intended project files.
SCRIPT_PATH.unlink()
WORKFLOW_PATH.unlink()

print(f"prepared correction from stable head {STABLE_HEAD}")
