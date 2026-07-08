"""
scripts/generate_content.py -- assets/data/questions.json と cards.json を生成・編集

使い方:
  # API自動生成
  python scripts/generate_content.py --api-key YOUR_KEY
  python scripts/generate_content.py --api-key YOUR_KEY --count 120

  # WebのGemini/ChatGPTの回答をファイルから取り込み
  python scripts/generate_content.py --import responses.json

  # 現状確認
  python scripts/generate_content.py --dry-run

環境変数 GEMINI_API_KEY でも可。
既存の問題は保持し、差分だけ追加する。
"""

import argparse, json, os, re, sys
from pathlib import Path

from google import genai
from google.genai import types

ASSETS_DIR = Path(__file__).resolve().parent.parent / "assets" / "data"
QUESTIONS_FILE = ASSETS_DIR / "questions.json"
CARDS_FILE = ASSETS_DIR / "cards.json"

# 旧データのIDに使われていた略称→カテゴリ名マッピング
CATEGORY_ABBR = {
    "nature_geography": "geo",
    "living_things": "bio",
    "history": "his",
    "science": "sci",
    "food": "food",
    "language": "lang",
    "daily_life": "life",
}

# アプリで使われている7カテゴリ
CATEGORIES = [
    "nature_geography",  # 自然・地理
    "living_things",     # 生き物
    "history",           # 歴史
    "science",           # 科学
    "food",              # 食べ物
    "language",          # ことば
    "daily_life",        # 生活
]

DIFFICULTIES = ["easy", "normal", "hard"]
RARITIES = ["normal", "rare"]

# questions.json 用スキーマ
QUESTION_SCHEMA = {
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "question": {"type": "string", "description": "クイズ問題文（20〜50字）"},
            "choices": {
                "type": "array",
                "items": {"type": "string"},
                "minItems": 4, "maxItems": 4,
                "description": "4択の選択肢",
            },
            "answerIndex": {
                "type": "integer",
                "description": "正解のインデックス（0〜3）",
            },
            "explanation": {"type": "string", "description": "解説（50〜150字）"},
            "category": {
                "type": "string",
                "enum": CATEGORIES,
            },
            "difficulty": {
                "type": "string",
                "enum": DIFFICULTIES,
            },
            "sourceNote": {"type": "string", "description": "出典メモ（15〜40字）"},
            "title": {"type": "string", "description": "対応カードのタイトル"},
            "shortText": {"type": "string", "description": "カードの短い説明（15〜35字）"},
            "detailText": {"type": "string", "description": "カードの詳細（50〜120字）"},
            "rarity": {"type": "string", "enum": RARITIES},
        },
        "required": [
            "question", "choices", "answerIndex", "explanation",
            "category", "difficulty", "sourceNote",
            "title", "shortText", "detailText", "rarity",
        ],
    },
}


def load_existing() -> tuple[list[dict], list[dict]]:
    questions = []
    cards = []
    if QUESTIONS_FILE.exists():
        with open(QUESTIONS_FILE, encoding="utf-8") as f:
            questions = json.load(f)
    if CARDS_FILE.exists():
        with open(CARDS_FILE, encoding="utf-8") as f:
            cards = json.load(f)
    return questions, cards


def existing_question_ids(questions: list[dict]) -> set[str]:
    return {q["id"] for q in questions if "id" in q}


def existing_card_ids(cards: list[dict]) -> set[str]:
    return {c["id"] for c in cards if "id" in c}


def build_prompt(existing_questions: list[dict], target_count: int) -> str:
    categories_detail = "\n".join(
        f"  {c}: " + {
            "nature_geography": "自然・地理",
            "living_things": "生き物",
            "history": "歴史",
            "science": "科学",
            "food": "食べ物",
            "language": "ことば",
            "daily_life": "生活",
        }[c]
        for c in CATEGORIES
    )

    existing_titles = [q.get("title", "") for q in existing_questions if q.get("title")]
    existing_block = ""
    if existing_titles:
        existing_block = (
            "\n\n以下は既存カードのタイトルです。テーマが重複しないようにしてください:\n"
            + "\n".join(f"  - {t}" for t in existing_titles)
        )

    return f"""あなたは「へぇの種」という雑学クイズアプリの編集者です。

7カテゴリから均等に選んで {target_count}問の新しい雑学クイズ問題と対応するカードデータをJSON配列で生成してください。
カテゴリ:
{categories_detail}{existing_block}

要件:
- 1問につき4択。正解は1つ。他の選択肢ももっともらしく。
- 解説は簡潔でわかりやすく。
- 出典メモは「Wikipedia」「国立天文台」など短く。
- カードの rarity は全体の約20%を "rare"、残りを "normal" に。
- 問題の difficulty は easy:normal:hard = 3:4:3 くらいの割合で。
- difficulty "easy" は常識レベルの簡単な問題、"hard" はマニアックな知識問題。
- 事実に基づくこと。推測や不確かな情報は含めない。
- 既存タイトルとテーマが重複しないように。

出力は必ずJSON配列。各要素は指定されたスキーマに従うこと。"""


def generate_batch(client: genai.Client, existing_questions: list[dict], batch_size: int) -> list[dict]:
    prompt = build_prompt(existing_questions, target_count=batch_size)

    try:
        response = client.models.generate_content(
            model="gemini-3-flash-preview",
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=QUESTION_SCHEMA,
                temperature=1.3,
                top_p=0.95,
            ),
        )

        if not response.candidates or not response.candidates[0].content.parts:
            print("  [SKIP] Empty response", file=sys.stderr)
            return []

        raw = response.text
        if raw.startswith("```"):
            raw = re.sub(r"^```(?:json)?\s*", "", raw)
            raw = re.sub(r"\s*```$", "", raw)

        items: list[dict] = json.loads(raw)
        return items

    except Exception as e:
        print(f"  [ERROR] API call failed: {e}", file=sys.stderr)
        return []


def validate_item(item: dict) -> str | None:
    if not isinstance(item.get("choices"), list) or len(item["choices"]) != 4:
        return "choices must be exactly 4"
    idx = item.get("answerIndex", -1)
    if not isinstance(idx, int) or idx < 0 or idx > 3:
        return "answerIndex out of range (0-3)"
    if item.get("category") not in CATEGORIES:
        return f"invalid category: {item.get('category')}"
    if item.get("difficulty") not in DIFFICULTIES:
        return f"invalid difficulty: {item.get('difficulty')}"
    if item.get("rarity") not in RARITIES:
        return f"invalid rarity: {item.get('rarity')}"
    if not item.get("question") or len(item["question"]) < 8:
        return "question too short"
    if not item.get("explanation") or len(item["explanation"]) < 20:
        return "explanation too short"
    return None


def merge_into_existing(
    new_items: list[dict],
    existing_questions: list[dict],
    existing_cards: list[dict],
) -> tuple[list[dict], list[dict]]:
    q_ids = existing_question_ids(existing_questions)
    c_ids = existing_card_ids(existing_cards)

    # カテゴリごとの最大連番を計算（新旧両方のID形式に対応）
    def max_seq(entries, id_pattern: str) -> dict[str, int]:
        counters: dict[str, int] = {}
        for entry in entries:
            cat = entry.get("category", "unknown")
            eid = entry.get("id", "")
            # フル名パターン: q_nature_geography_001 / card_nature_geography_001
            m = re.search(id_pattern.replace("{cat}", re.escape(cat)), eid)
            if m:
                counters[cat] = max(counters.get(cat, 0), int(m.group(1)))
            # 略称パターン: q_geo_001 / card_geo_001
            abbr = CATEGORY_ABBR.get(cat)
            if abbr:
                m = re.search(id_pattern.replace("{cat}", re.escape(abbr)), eid)
                if m:
                    counters[cat] = max(counters.get(cat, 0), int(m.group(1)))
        return counters

    q_counters = max_seq(existing_questions, r"q_{cat}_(\d+)")
    c_counters = max_seq(existing_cards, r"card_{cat}_(\d+)")

    qs = list(existing_questions)
    cs = list(existing_cards)

    for item in new_items:
        err = validate_item(item)
        if err:
            print(f"  [SKIP] validation: {err}")
            continue

        cat = item["category"]

        # question ID
        qn = q_counters.get(cat, 0) + 1
        q_counters[cat] = qn
        q_id = f"q_{cat}_{qn:03d}"
        while q_id in q_ids:
            qn += 1
            q_counters[cat] = qn
            q_id = f"q_{cat}_{qn:03d}"
        q_ids.add(q_id)

        # card ID
        cn = c_counters.get(cat, 0) + 1
        c_counters[cat] = cn
        c_id = f"card_{cat}_{cn:03d}"
        while c_id in c_ids:
            cn += 1
            c_counters[cat] = cn
            c_id = f"card_{cat}_{cn:03d}"
        c_ids.add(c_id)

        # タイトルが既存カードと重複しないか簡易チェック
        title = item["title"]
        if any(c.get("title") == title for c in cs):
            print(f"  [SKIP] duplicate title: {title}")
            continue

        q_entry = {
            "id": q_id,
            "category": cat,
            "difficulty": item["difficulty"],
            "question": item["question"],
            "choices": item["choices"],
            "answerIndex": item["answerIndex"],
            "explanation": item["explanation"],
            "relatedCardId": c_id,
            "sourceNote": item["sourceNote"],
            "verified": True,
        }
        c_entry = {
            "id": c_id,
            "title": title,
            "category": cat,
            "shortText": item["shortText"],
            "detailText": item["detailText"],
            "imageAsset": f"assets/images/cards/{c_id}.png",
            "rarity": item["rarity"],
            "sourceNote": item["sourceNote"],
        }

        qs.append(q_entry)
        cs.append(c_entry)
        print(f"  [OK] {q_id} / {c_id}: {title}")

    return qs, cs


def print_summary(qs: list[dict], cs: list[dict]) -> None:
    print(f"\n合計: {len(qs)} questions, {len(cs)} cards")
    cats = {}
    for q in qs:
        c = q.get("category", "?")
        cats[c] = cats.get(c, 0) + 1
    print("カテゴリ分布:")
    for k, v in sorted(cats.items()):
        print(f"  {k}: {v}")


def save(qs: list[dict], cs: list[dict]) -> None:
    with open(QUESTIONS_FILE, "w", encoding="utf-8") as f:
        json.dump(qs, f, ensure_ascii=False, indent=2)
    with open(CARDS_FILE, "w", encoding="utf-8") as f:
        json.dump(cs, f, ensure_ascii=False, indent=2)


def main():
    parser = argparse.ArgumentParser(description="問題＋カードデータの生成・編集")
    parser.add_argument("--api-key", help="Gemini API キー（API生成モード）")
    parser.add_argument("--count", type=int, default=100, help="生成する問題数（デフォルト: 100）")
    parser.add_argument("--batch-size", type=int, default=15, help="1回のAPI呼び出しで生成する数")
    parser.add_argument("--import", dest="import_file", metavar="FILE",
                        help="JSONファイルから問題を取り込んで既存データにマージ")
    parser.add_argument("--dry-run", action="store_true", help="生成せずに既存データだけ表示")
    args = parser.parse_args()

    existing_qs, existing_cs = load_existing()
    print(f"既存: {len(existing_qs)} questions, {len(existing_cs)} cards")

    # ── dry-run ──
    if args.dry_run:
        print_summary(existing_qs, existing_cs)
        return

    # ── import mode ──
    if args.import_file:
        import_path = Path(args.import_file)
        if not import_path.exists():
            print(f"Error: ファイルが見つかりません: {import_path}", file=sys.stderr)
            sys.exit(1)
        with open(import_path, encoding="utf-8") as f:
            raw = f.read()
        raw = raw.strip()
        if raw.startswith("```"):
            raw = re.sub(r"^```(?:json)?\s*", "", raw)
            raw = re.sub(r"\s*```$", "", raw)
        try:
            items = json.loads(raw)
        except json.JSONDecodeError as e:
            print(f"Error: JSONパース失敗: {e}", file=sys.stderr)
            sys.exit(1)
        if not isinstance(items, list):
            items = [items]
        print(f"読み込み: {len(items)}件")

        # 既存にマージ
        qs, cs = merge_into_existing(items, existing_qs, existing_cs)
        save(qs, cs)
        added = len(qs) - len(existing_qs)
        print(f"\nマージ完了: +{added}件（合計 {len(qs)}問）")
        print_summary(qs, cs)
        return

    # ── API generation mode ──
    api_key = args.api_key or os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("Error: GEMINI_API_KEY, --api-key, または --import が必要です", file=sys.stderr)
        sys.exit(1)

    client = genai.Client(api_key=api_key)

    # 既存データをベースに、増分生成する
    qs = list(existing_qs)
    cs = list(existing_cs)
    total_start = len(qs)
    total_new = 0

    while len(qs) - total_start < args.count:
        batch = min(args.batch_size, args.count - total_new)
        print(f"\n生成中... (残り {args.count - total_new} 問 / batch={batch})")
        items = generate_batch(client, qs, batch)
        if not items:
            print("  [RETRY] 空レスポンス。リトライ...")
            continue

        validated = [it for it in items if validate_item(it) is None]
        print(f"  API応答: {len(items)}件、有効: {len(validated)}件")

        if validated:
            qs, cs = merge_into_existing(validated, qs, cs)
            total_new = len(qs) - total_start
            save(qs, cs)
            print(f"  中間保存: {len(qs)} questions, {len(cs)} cards (+{total_new} new)")

        if len(qs) - total_start >= args.count:
            break

    total_new = len(qs) - total_start
    if total_new == 0:
        print("新規データが生成されませんでした", file=sys.stderr)
        sys.exit(1)

    print(f"\n生成完了: +{total_new}件の新規データ（合計 {len(qs)}問）")
    print_summary(qs, cs)


if __name__ == "__main__":
    main()
