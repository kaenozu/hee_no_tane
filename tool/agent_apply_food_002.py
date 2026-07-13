from __future__ import annotations

import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERIFIED_AT = "2026-07-13"
SOURCE = {
    "title": "The genome of the domesticated apple (Malus × domestica Borkh.)",
    "publisher": "Nature Genetics (Springer Nature)",
    "url": "https://www.nature.com/articles/ng.654",
    "verifiedAt": VERIFIED_AT,
    "verificationLevel": "primary",
    "reviewStatus": "approved",
}


def update_json() -> None:
    questions_path = ROOT / "assets/data/questions.json"
    questions = json.loads(questions_path.read_text(encoding="utf-8"))
    question = next(item for item in questions if item["id"] == "q_food_002")
    if question["question"] != "リンゴの生産量が世界一の国は？":
        raise RuntimeError("q_food_002 no longer matches the reviewed source state")
    question.update(
        {
            "difficulty": "normal",
            "question": "2010年の原著論文が、栽培リンゴの祖先種として同定したのは？",
            "choices": [
                "Malus sieversii",
                "Malus sylvestris",
                "Malus baccata",
                "Malus floribunda",
            ],
            "answerIndex": 0,
            "explanation": "2010年にNature Geneticsで公表された原著論文は、バラ科の主要分類群と比較した系統再構築により、栽培リンゴの祖先種をMalus sieversiiと同定した。",
            "sourceNote": "Nature Genetics（2010）",
            "verified": True,
            "source": SOURCE,
        }
    )
    questions_path.write_text(
        json.dumps(questions, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    cards_path = ROOT / "assets/data/cards.json"
    cards = json.loads(cards_path.read_text(encoding="utf-8"))
    card = next(item for item in cards if item["id"] == "card_food_002")
    if card["title"] != "中国のリンゴ":
        raise RuntimeError("card_food_002 no longer matches the reviewed source state")
    card.update(
        {
            "title": "栽培リンゴの祖先種",
            "shortText": "2010年の系統解析ではMalus sieversiiと同定された。",
            "detailText": "2010年にNature Geneticsで公表された原著論文は、栽培リンゴの高品質ドラフトゲノム配列を報告し、バラ科の主要分類群と比較した系統再構築により、その祖先種をMalus sieversiiと同定した。",
            "sourceNote": "Nature Genetics（2010）",
            "source": SOURCE,
        }
    )
    cards_path.write_text(
        json.dumps(cards, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    if len(questions) != 103 or len(cards) != 103:
        raise RuntimeError("unexpected content record count")


def update_corrections_csv() -> None:
    path = ROOT / "review/content_corrections_batch_1.csv"
    content = path.read_text(encoding="utf-8")
    if "\nq_food_002," in content:
        raise RuntimeError("q_food_002 correction row already exists")
    content += (
        'q_food_002,card_food_002,"question,choices,answer,explanation,card",'
        '"ranking,current-statistics,unsupported-addition,scope",'
        '"世界生産順位・割合・日本流通の断定を削除し、2010年原著論文が系統再構築で栽培リンゴの祖先種をMalus sieversiiと同定した結果へ差し替え",'
        'The genome of the domesticated apple (Malus × domestica Borkh.),'
        'Nature Genetics (Springer Nature),https://www.nature.com/articles/ng.654,'
        "2026-07-13,primary,approved\n"
    )
    path.write_text(content, encoding="utf-8")


def update_research_record() -> None:
    run_head = os.environ.get("GITHUB_SHA", "unknown")
    content = f'''# `q_food_002` / `card_food_002` 調査記録

確認日: 2026-07-13
対象ブランチ: `agent/content-triage-and-correction`
調査開始時HEAD: `754475c8405c90eb01aefe837005a1147b3708ff`
実装実行時HEAD: `{run_head}`
判定: `approved`
検証レベル: `primary`

## 調査前の自己点検

- 検証対象を正答だけに限定せず、問題文、全選択肢、解説、カード本文、構造化出典まで含めた。
- 世界生産順位、割合、日本での流通という別母集団を混同しない。
- 年次更新される統計を維持する場合は、年、地域区分、Flag、順位母集団を直接確認する必要がある。
- 直接取得できない統計原表への反復調査より、全文を一次資料で直接照合できる安定した事実への置換を優先した。

## 旧本文から分解した主張

### 問題・解説

- リンゴ生産量が世界一の国は中国である。
- 世界のリンゴ生産量の約半分は中国である。
- 日本で食べられているリンゴの多くは中国産である。

### カード

- 中国は世界最大のリンゴ生産国である。
- 中国は世界生産量の約半分を占める。
- 日本で流通するリンゴの多くは中国産である。

## 旧調査経路の結論

FAOSTATのデータセット識別子と公開変換データから候補値は得られたが、公式原表の対象行、Flag、最新共通年、順位母集団、中国の集計範囲を直接確認できなかった。

世界生産統計から日本国内の消費または流通を導くこともできない。このため、旧問題の数値や順位を弱めて残すのではなく、問題全体を置換した。

## 採用した一次資料

- 論文: `The genome of the domesticated apple (Malus × domestica Borkh.)`
- 著者: Velascoほか
- 掲載誌: Nature Genetics, volume 42, pages 833–839
- 公開日: 2010-08-29
- URL: https://www.nature.com/articles/ng.654

論文の抄録は次を直接示す。

1. 栽培リンゴの高品質ドラフトゲノム配列を報告した。
2. バラ科の主要分類群と比較したPyreaeおよびMalus属の系統再構築を行った。
3. その解析により、栽培リンゴの祖先種を`M. sieversii`と同定した。

## 反証・条件差・一般化制限

- 正答は「2010年の当該論文が同定した種」に限定する。
- 栽培リンゴの遺伝的成立過程全体を単一種だけで説明する問題にはしない。
- 現在の生産量、国別順位、輸入、流通、消費については何も主張しない。
- `Malus sieversii`という綴りを選択肢と正答で一致させる。
- 論文が直接支えない品種、産地、味、栄養、栽培史をカードへ追加しない。

## 最終問題

- 問題文: `2010年の原著論文が、栽培リンゴの祖先種として同定したのは？`
- 選択肢:
  1. `Malus sieversii`
  2. `Malus sylvestris`
  3. `Malus baccata`
  4. `Malus floribunda`
- 正答: `Malus sieversii`
- 解説: `2010年にNature Geneticsで公表された原著論文は、バラ科の主要分類群と比較した系統再構築により、栽培リンゴの祖先種をMalus sieversiiと同定した。`

## 最終カード

- タイトル: `栽培リンゴの祖先種`
- shortText: `2010年の系統解析ではMalus sieversiiと同定された。`
- detailText: `2010年にNature Geneticsで公表された原著論文は、栽培リンゴの高品質ドラフトゲノム配列を報告し、バラ科の主要分類群と比較した系統再構築により、その祖先種をMalus sieversiiと同定した。`

## 承認判定

問題文、正答、選択肢、解説、カード本文の保持主張を一次論文の題名・書誌情報・抄録と照合した。旧統計と日本流通の主張はすべて削除したため、`verificationLevel: primary`、`reviewStatus: approved`とする。
'''
    (ROOT / "review/content_research_q_food_002.md").write_text(
        content,
        encoding="utf-8",
    )


def update_policy() -> None:
    path = ROOT / "docs/17_コンテンツトリアージ運用.md"
    content = path.read_text(encoding="utf-8")
    gate = '''## 資料選定ゲート

調査の長期化と取得不能な資料への固執を防ぐため、本文修正前に次を確認する。

1. 候補資料は原則3件までに絞る。
2. 候補ごとに、問題文・正答・選択肢・解説・カードのどこを直接支えるか記録する。
3. 現行値・順位・割合より、年次更新がなく条件を固定できる事実を優先する。
4. 公式原表、Flag、対象範囲を直接取得できない統計は、推測で補わない。
5. 取得不能な一次資料を同じ方法で反復せず、直接確認できる別事実への置換を検討する。
6. 確認済み、未確認、推測、反証、条件差を調査記録で分離する。

'''
    marker = "## メタ認知チェック\n"
    if marker not in content:
        raise RuntimeError("metacognitive policy marker missing")
    if "## 資料選定ゲート\n" not in content:
        content = content.replace(marker, gate + marker)

    old_flow = '''## 修正フロー

1. `review/content_triage_batch_*.csv`へ分類と理由を記録する
2. 修正対象は小規模なバッチへ分ける
3. 問題とカードを同じコミットで修正する
4. 修正後の全文を資料と再照合する
5. 承認CSVをドライランする
6. JSONへ反映する
7. コンテンツ検証、出典監査、Analyze、全テスト、Web、Androidを実行する
8. 全ゲート成功後にのみマージする
'''
    new_flow = '''## 修正フロー

1. `review/content_triage_batch_*.csv`へ分類と理由を記録する
2. 候補資料を原則3件までに絞り、直接支えられる主張を比較する
3. 取得不能または条件不足の候補を棄却し、必要なら問題全体を置換する
4. 修正対象は小規模なバッチへ分ける
5. 修正文全文と調査記録を先に完成させる
6. 問題、カード、承認CSV、調査記録を同じ変更単位で更新する
7. 修正後の全文を資料と再照合する
8. JSON構文、ID対応、構造化出典をローカル検証する
9. コンテンツ検証、出典監査、Analyze、全テスト、Web、Androidを実行する
10. CI成果物の件数を変更前の期待値と照合する
11. PRとIssueを同期し、全ゲート成功後にのみマージ可否を別途判定する
'''
    if old_flow not in content:
        raise RuntimeError("original correction flow missing")
    content = content.replace(old_flow, new_flow)

    final_marker = "### 第1次修正\n"
    if final_marker not in content:
        raise RuntimeError("batch-one summary marker missing")
    content = content[: content.index(final_marker)] + '''### 第1バッチ修正完了

8組すべてについて、保持する主張を直接資料で確認できる範囲へ限定した。数値、順位、因果、俗説、標本の一般化、国・規格・研究条件の混同が残る場合は、現行問題を部分修正せず、直接検証できる問題へ置換した。

最後に残った`q_food_002` / `card_food_002`では、取得できないFAOSTAT原表への反復調査を停止した。世界生産順位・割合・日本流通の主張をすべて削除し、2010年のNature Genetics原著論文が系統再構築で栽培リンゴの祖先種を`Malus sieversii`と同定した結果へ差し替えた。

変更後の期待監査値は次のとおり。実数はCI成果物で再確認する。

- 承認済み: 42 / 206
- 要確認: 164 / 206
- 承認済み組: 21 / 103
- メタデータ不正: 0

第1バッチの初期分類CSVは調査開始時点の判断記録として保持し、完了した修正は`review/content_corrections_batch_1.csv`と各調査記録で追跡する。
'''
    path.write_text(content, encoding="utf-8")


def main() -> None:
    update_json()
    update_corrections_csv()
    update_research_record()
    update_policy()


if __name__ == "__main__":
    main()
