from __future__ import annotations

import json
from pathlib import Path

STABLE_HEAD = "539b1c5ff4bf4f4f8c7a7dbf44416dc06fffe92f"
QUESTION_ID = "q_life_004"
CARD_ID = "card_life_004"
SOURCE_TITLE = "Chapter 4: Accessible Routes"
SOURCE_PUBLISHER = "U.S. Access Board"
SOURCE_URL = "https://www.access-board.gov/ada/chapter/ch04/"
VERIFIED_AT = "2026-07-13"

ROOT = Path(__file__).resolve().parents[2]
QUESTIONS_PATH = ROOT / "assets/data/questions.json"
CARDS_PATH = ROOT / "assets/data/cards.json"
CORRECTIONS_PATH = ROOT / "review/content_corrections_batch_1.csv"
RESEARCH_PATH = ROOT / "review/content_research_q_life_004.md"
SCRIPT_PATH = ROOT / ".github/scripts/apply_q_life_004.py"
WORKFLOW_PATH = ROOT / ".github/workflows/apply-q-life-004.yml"


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
    "id": "q_life_004",
    "category": "daily_life",
    "difficulty": "hard",
    "question": "「エレベーターの開閉ボタン」実はあまり効果がないと言われる理由は？",
    "choices": ["安全のため自動ドアが優先されるから", "ボタンが飾りだから", "電気代節約のため", "メーカーの仕様"],
    "answerIndex": 0,
    "explanation": "多くのエレベーターでは、安全基準により自動ドアの開閉タイミングが優先される。閉ボタンを押しても数秒間は反応しないよう設計されていることが多いんだ。",
    "relatedCardId": "card_life_004",
    "sourceNote": "日本エレベーター協会",
    "verified": True,
}
if old_question != expected_old_question:
    raise RuntimeError(f"unexpected current question record: {old_question!r}")

questions[question_index] = {
    "id": "q_life_004",
    "category": "daily_life",
    "difficulty": "hard",
    "question": "米国のADA Accessibility Standards 407.3.5で、かご呼びに応答したエレベーターの扉が完全に開いた状態を保つ最低時間は？",
    "choices": ["1秒", "3秒", "5秒", "20秒"],
    "answerIndex": 1,
    "explanation": "U.S. Access BoardのADA Accessibility Standards 407.3.5は、かご呼びに応答したエレベーターの扉を完全に開いた状態で最低3秒保つと規定している。米国の特定規定であり、すべての国・機種の閉ボタンの挙動を示すものではない。",
    "relatedCardId": "card_life_004",
    "sourceNote": "U.S. Access Board ADA 407.3.5",
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
    "id": "card_life_004",
    "title": "エレベーターの閉ボタン",
    "category": "daily_life",
    "shortText": "実はすぐには閉まらない設計。",
    "detailText": "多くのエレベーターは安全基準により、閉ボタンを押してもすぐには反応しない。自動ドアの開閉タイミングが優先されるよう設計されている。",
    "imageAsset": "assets/images/cards/card_life_004.png",
    "rarity": "normal",
    "sourceNote": "日本エレベーター協会",
}
if old_card != expected_old_card:
    raise RuntimeError(f"unexpected current card record: {old_card!r}")

cards[card_index] = {
    "id": "card_life_004",
    "title": "ADAのエレベーター扉遅延",
    "category": "daily_life",
    "shortText": "かご呼びでは完全に開いた状態を最低3秒保つ。",
    "detailText": "U.S. Access BoardのADA Accessibility Standards 407.3.5は、かご呼びに応答したエレベーターの扉を完全に開いた状態で最低3秒保つと定めている。この規定だけから、他国や全機種で閉ボタンが無効だとは判断できない。",
    "imageAsset": "assets/images/cards/card_life_004.png",
    "rarity": "normal",
    "sourceNote": "U.S. Access Board ADA 407.3.5",
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
    'q_life_004,card_life_004,"question,choices,answer,explanation,card",'
    '"scope,configuration,safety-standard,button-behavior",'
    '"閉ボタンが効かないという国・機種横断の一般化を削除し、U.S. Access BoardのADA 407.3.5が直接定める扉の完全開放3秒へ差し替え",'
    f'{SOURCE_TITLE},{SOURCE_PUBLISHER},{SOURCE_URL},{VERIFIED_AT},primary,approved\n'
)
CORRECTIONS_PATH.write_text(corrections, encoding="utf-8")

research = f"""# `q_life_004` / `card_life_004` 調査・修正記録

確認日: {VERIFIED_AT}
対象ブランチ: `agent/content-triage-and-correction`
判定: 閉ボタンの有効性に関する国・機種・設定横断の一般化を削除し、U.S. Access BoardのADA Accessibility Standardsが直接規定する扉の完全開放時間へ差し替えて承認

## 監査対象だった主張

### 問題

- エレベーターの開閉ボタンはあまり効果がない
- その理由は安全のため自動ドアが優先されるからである
- `開ボタン`と`閉ボタン`を同じ挙動として扱える

### カード

- 多くのエレベーターは閉ボタンを押してもすぐには反応しない
- その挙動は安全基準による
- 自動ドアの開閉タイミングが常に閉ボタンより優先される

## メタ認知による問題点

- 国、適用規格、設置年代、メーカー、機種、制御設定、運転モードを特定していなかった。
- `あまり効果がない`は、反応時間、閉扉開始、戸開保持、再開扉など異なる挙動を混在させる曖昧な評価だった。
- 開ボタンと閉ボタンの機能を一括していた。
- 通常運転、独立運転、消防運転、点検運転などの条件差を分離していなかった。
- `安全基準`の名称、条項、対象範囲を示していなかった。
- 出典欄の`日本エレベーター協会`だけでは、資料名、URL、該当箇所、対象規格を特定できなかった。

## 採用した一次資料

- Title: `{SOURCE_TITLE}`
- Publisher: `{SOURCE_PUBLISHER}`
- Standard: ADA Accessibility Standards, Chapter 4
- Record: {SOURCE_URL}

U.S. Access Boardは米国連邦政府の独立機関であり、このページはADA Accessibility Standardsの公式本文である。

## 直接確認できた事実

公式本文から、次を確認した。

1. 407.3.2は、エレベーターの昇降路扉とかご扉が自動的に開閉することを定める。
2. 407.3.3は、物または人が扉を遮った場合に自動的に停止・再開扉する装置を要求する。
3. 407.3.3.3は、再開扉装置が最低20秒有効であることを定める。
4. 407.3.4は、かごが呼びに応答する通知から扉が閉まり始めるまでの最低時間を距離式で定め、最低値を5秒とする。ただし例外がある。
5. 407.3.5は、かご呼びに応答したエレベーターの扉を完全に開いた状態で最低3秒保つことを定める。
6. 407.4.7.1.3は、戸開ボタンと戸閉ボタンを含む操作ボタンの触覚記号を定める。

修正後の問題とカードには、407.3.5の最低3秒という単一の規定だけを採用した。

## 条件差・反証

- 同じ公式規格内でも、完全開放時間、呼び通知から閉扉開始までの時間、再開扉装置の有効時間は別々の条項と数値で定められている。
- したがって、`数秒反応しない`という表現だけでは、どの時間を指すか特定できない。
- 407.4.7.1.3は戸閉ボタンの記号を明示しているが、これは通常運転時に押せば常に即時閉扉することを保証する資料ではない。一方、ボタンを単なる飾りとみなす根拠にもならない。
- ADA Accessibility Standardsは米国のアクセシビリティ規定であり、日本や他国の全機種・全設定へ一般化できない。

## 直接確認できなかった情報

- 日本の一般的なエレベーターで閉ボタンが反応するまでの時間
- 日本のどの安全基準が、閉ボタンより自動閉扉タイミングを優先すると定めるか
- メーカー・機種・設定別の閉ボタン挙動
- 通常運転以外の各運転モードにおける閉ボタン挙動
- `多くのエレベーター`という母集団と割合
- 閉ボタンが無効または装飾だけである機種の範囲

## 採用しない主張

- `エレベーターの開閉ボタンはあまり効果がない`
- `閉ボタンは飾りである`
- `多くのエレベーターは閉ボタンを押しても数秒反応しない`
- `安全基準により自動ドアのタイミングが閉ボタンより常に優先される`
- `米国ADAの規定が日本を含む全エレベーターに当てはまる`

これらをすべて反対の意味で否定したのではない。対象国、規格、機種、設定、運転モード、時間の定義を現行文のとおり直接支える資料が揃わないため削除した。

## 修正後の問題

- 問題文: `米国のADA Accessibility Standards 407.3.5で、かご呼びに応答したエレベーターの扉が完全に開いた状態を保つ最低時間は？`
- 選択肢: `1秒`、`3秒`、`5秒`、`20秒`
- 正答: `3秒`
- 解説: U.S. Access Board公式本文の407.3.5と、米国の特定規定であるという適用範囲だけに限定

5秒と20秒は同じ規格内の別要件であり、正答ではない。設問で407.3.5と`完全に開いた状態`を明示して数値の混同を避けた。

## 修正後のカード

- タイトル: `ADAのエレベーター扉遅延`
- shortText: `かご呼びでは完全に開いた状態を最低3秒保つ。`
- detailText: 米国ADA 407.3.5の要件と、他国・全機種の閉ボタン挙動を示さないという条件だけに限定

## 証拠レベル

`primary`

理由: 規定を策定・公開するU.S. Access BoardのADA Accessibility Standards公式本文から、条項番号、対象動作、最低時間を直接確認したため。この証拠レベルは米国ADA 407.3.5の内容に対するもので、日本のエレベーター仕様や閉ボタン一般に対する証拠ではない。

## 承認条件の自己点検

- 問題前提: U.S. Access Board公式本文が直接支える
- 正答の一意性: 407.3.5に最低3秒と明記
- 数値: 対象動作を`完全に開いた状態`に限定
- 地域・制度: 米国ADAに限定
- 機種・設定: 全機種への一般化を避けた
- 因果: 安全性を理由とする因果説明を削除
- ボタン挙動: 有効・無効を断定していない
- 問題とカードの出典URL: 同一
- 未確認主張の残存: なし

## 再検証条件

- 日本の規格またはメーカー仕様を追加する場合
- 閉ボタンの反応時間や有効性を説明する場合
- 5秒の扉・信号タイミングまたは20秒の再開扉装置を追加する場合
- 消防運転、独立運転、点検運転などのモード別挙動を追加する場合
"""
RESEARCH_PATH.write_text(research, encoding="utf-8")

SCRIPT_PATH.unlink()
WORKFLOW_PATH.unlink()

print(f"prepared correction from stable head {STABLE_HEAD}")
