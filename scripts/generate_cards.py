"""
scripts/generate_cards.py — Gemini API で知識カードを一括生成

使い方:
  python scripts/generate_cards.py --category daily_why --count 10
  python scripts/generate_cards.py --category all --count 30
  python scripts/generate_cards.py --api-key YOUR_KEY --category food_origin --count 5
  python scripts/generate_cards.py --today                   # 今日のデッキを自動生成
  python scripts/generate_cards.py --list-existing            # 既存カード一覧

環境変数 GEMINI_API_KEY か --api-key でAPIキーを指定する
"""

import argparse, json, os, random, re, sys, uuid
from datetime import date
from typing import Any

from google import genai
from google.genai import types

CARDS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "cards")
DECKS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "decks", "daily")
CATEGORIES = {
    "daily_why": "日常生活のなぜ（例：マンホールのふたが丸い理由）",
    "history_bite": "歴史の小ネタ（例：下水道の歴史）",
    "science_nearby": "身近な科学（例：静電気の仕組み）",
    "food_origin": "食べ物の起源（例：天ぷらのルーツ）",
    "language_trivia": "ことばのトリビア（例：ありがとうの語源）",
    "culture_japan": "日本文化の雑学（例：いただきますの語源）",
}

CARD_SCHEMA: dict[str, Any] = {
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "title": {"type": "string", "description": "カードのタイトル（疑問形・12〜25字）"},
            "hook": {"type": "string", "description": "興味を引く一言（15〜30字）"},
            "short_body": {"type": "string", "description": "30秒で読める概要（120〜180字）"},
            "long_body": {"type": "string", "description": "3分で読める深掘り（600〜1000字）"},
            "category": {"type": "string", "enum": list(CATEGORIES.keys())},
            "confidence_level": {"type": "string", "enum": ["A", "B", "C", "D"]},
            "sources": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "title": {"type": "string"},
                        "url": {"type": "string", "description": "実在するURL"},
                        "source_type": {"type": "string", "enum": ["official", "academic", "wiki", "news", "website"]},
                        "retrieved_at": {"type": "string"},
                    },
                    "required": ["title", "url", "source_type"],
                },
            },
            "quiz": {
                "type": "object",
                "properties": {
                    "question": {"type": "string"},
                    "choices": {"type": "array", "items": {"type": "string"}, "minItems": 3, "maxItems": 4},
                    "answer_index": {"type": "integer", "description": "正解の選択肢のインデックス（0始まり）"},
                    "explanation": {"type": "string"},
                },
                "required": ["question", "choices", "answer_index", "explanation"],
            },
        },
        "required": ["title", "hook", "short_body", "long_body", "category", "confidence_level", "sources", "quiz"],
    },
}


def _existing_card_ids() -> set[str]:
    """既存カードのID一覧（拡張子なし）"""
    if not os.path.isdir(CARDS_DIR):
        return set()
    return {f.removesuffix(".json") for f in os.listdir(CARDS_DIR) if f.endswith(".json")}


def _next_id(category: str) -> str:
    """既存カードから次の連番を振る（ID重複回避）"""
    used = _existing_card_ids()
    n = 1
    while True:
        cid = f"card_{category}_{n:03d}"
        if cid not in used:
            return cid
        n += 1


def _existing_titles() -> list[str]:
    """既存カードのタイトル一覧"""
    if not os.path.isdir(CARDS_DIR):
        return []
    titles = []
    for f in sorted(os.listdir(CARDS_DIR)):
        if f.endswith(".json"):
            try:
                with open(os.path.join(CARDS_DIR, f), encoding="utf-8") as fh:
                    titles.append(json.load(fh).get("title", ""))
            except Exception:
                pass
    return titles


def _build_prompt(category: str, count: int, existing_titles: list[str]) -> str:
    cat_desc = CATEGORIES.get(category, "雑学")
    if category == "all":
        cat_list = "\n".join(f"  {k}: {v}" for k, v in CATEGORIES.items())
        cat_instruction = f"以下のカテゴリから均等に選んで{count}枚のカードを生成してください。\n{cat_list}"
    else:
        cat_instruction = f"カテゴリ「{category}（{cat_desc}）」に関するカードを{count}枚生成してください。"

    existing_block = ""
    if existing_titles:
        existing_block = "\n\n以下のタイトルは既存カードです。テーマが重複しないようにしてください:\n" + "\n".join(f"  - {t}" for t in existing_titles)

    return f"""あなたは「へぇの種」という知的暇つぶしアプリの編集者です。

{cat_instruction}{existing_block}

条件:
- 一般成人向け。専門用語は避けるか、使う場合は説明を入れる。
- 医療・法律・投資判断に見える表現は禁止。
- 出典で確認できないことは断定しない。「〜とされています」「〜と言われています」を使う。
- 諸説ある場合は confidence_level をCにする。
- 出典URLは実在する公的機関・学術機関・ニュースサイトのものを指定する。
- short_bodyは120〜180字、long_bodyは600〜1000字。
- quizの選択肢は3つ、正解は1つ。

出力は必ずJSON配列にしてください。各カードは指定されたスキーマに従うこと。"""


def _validate_card(c: dict) -> str | None:
    """バリデーション。問題があればエラーメッセージを返す"""
    required = ["title", "hook", "short_body", "long_body", "category", "confidence_level", "sources", "quiz"]
    for field in required:
        if field not in c:
            return f"missing field: {field}"
    if c["category"] not in CATEGORIES:
        return f"invalid category: {c['category']}"
    if c["confidence_level"] not in ("A", "B", "C", "D"):
        return f"invalid confidence_level: {c['confidence_level']}"
    if len(c["short_body"]) < 50:
        return f"short_body too short ({len(c['short_body'])} chars)"
    if len(c["long_body"]) < 200:
        return f"long_body too long ({len(c['long_body'])} chars)"
    if not c.get("sources"):
        return "no sources"
    for s in c["sources"]:
        if "url" not in s or "title" not in s:
            return f"source missing url or title: {s}"
    q = c.get("quiz", {})
    if "choices" not in q or len(q.get("choices", [])) < 2:
        return "quiz has fewer than 2 choices"
    if "answer_index" not in q or q["answer_index"] not in range(len(q["choices"])):
        return "quiz answer_index out of range"
    return None


def generate_cards(client: genai.Client, category: str, count: int, batch_size: int = 5) -> list[dict]:
    """Gemini APIでカードを生成する"""
    all_cards: list[dict] = []
    existing_titles = _existing_titles()

    remaining = count
    retries = 0
    max_retries = 3

    while remaining > 0:
        batch = min(batch_size, remaining)
        prompt = _build_prompt(category, batch, existing_titles)

        try:
            response = client.models.generate_content(
                model="gemini-3-flash-preview",
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=CARD_SCHEMA,
                    temperature=1.2,
                    top_p=0.95,
                ),
            )

            if not response.candidates or not response.candidates[0].content.parts:
                print(f"  [SKIP] Empty response for batch", file=sys.stderr)
                retries += 1
                if retries >= max_retries:
                    break
                continue

            raw = response.text
            if raw.startswith("```"):
                raw = re.sub(r"^```(?:json)?\s*", "", raw)
                raw = re.sub(r"\s*```$", "", raw)

            batch_cards: list[dict] = json.loads(raw)

            for c in batch_cards:
                err = _validate_card(c)
                if err:
                    print(f"  [SKIP] validation failed: {err}", file=sys.stderr)
                    continue

                cid = _next_id(c["category"])
                c["id"] = cid
                c["related_card_ids"] = []
                all_cards.append(c)
                existing_titles.append(c["title"])
                print(f"  [OK] {cid}: {c['title']}")

            remaining -= len(batch_cards)
            retries = 0

        except Exception as e:
            print(f"  [ERROR] API call failed: {e}", file=sys.stderr)
            retries += 1
            if retries >= max_retries:
                print(f"  [GIVE UP] after {max_retries} retries", file=sys.stderr)
                break
            continue

    if len(all_cards) >= 2:
        for i, c in enumerate(all_cards):
            next_i = (i + 1) % len(all_cards)
            if next_i != i:
                c["related_card_ids"].append(all_cards[next_i]["id"])

    return all_cards


def save_cards(cards: list[dict], output_dir: str):
    """カードをJSONファイルとして保存"""
    os.makedirs(output_dir, exist_ok=True)
    today = date.today().isoformat()

    for c in cards:
        cid = c["id"]
        path = os.path.join(output_dir, f"{cid}.json")

        for s in c.get("sources", []):
            if "retrieved_at" not in s:
                s["retrieved_at"] = today

        with open(path, "w", encoding="utf-8") as f:
            json.dump(c, f, ensure_ascii=False, indent=2)
        print(f"  Saved: {cid}.json")


def generate_daily_deck(card_count: int = 3):
    """既存カードから今日のデッキを生成"""
    ids = sorted(_existing_card_ids())
    if len(ids) < card_count:
        print(f"Error: only {len(ids)} cards available (need at least {card_count})", file=sys.stderr)
        return

    today = date.today().isoformat()
    seed = today.hashCode() if hasattr(today, "hashCode") else hash(today)
    rng = random.Random(seed)

    selected = rng.sample(ids, card_count)
    deck_path = os.path.join(DECKS_DIR, f"{today}.json")

    os.makedirs(DECKS_DIR, exist_ok=True)
    with open(deck_path, "w", encoding="utf-8") as f:
        json.dump({"date": today, "card_ids": sorted(selected), "generated_at": today}, f, ensure_ascii=False, indent=2)
    print(f"  Deck saved: {deck_path}")
    for cid in sorted(selected):
        print(f"    - {cid}")


def list_existing_cards():
    """既存カード一覧を表示"""
    if not os.path.isdir(CARDS_DIR):
        print("No cards directory found.")
        return
    cards = sorted(os.listdir(CARDS_DIR))
    print(f"Total: {len(cards)} cards\n")
    for fname in cards:
        if not fname.endswith(".json"):
            continue
        path = os.path.join(CARDS_DIR, fname)
        try:
            with open(path, encoding="utf-8") as f:
                data = json.load(f)
            print(f"  {fname.removesuffix('.json')}")
            print(f"    title:    {data.get('title', '?')}")
            print(f"    category: {data.get('category', '?')}")
            print(f"    sources:  {len(data.get('sources', []))}")
            print()
        except Exception as e:
            print(f"  {fname}: error ({e})")


def main():
    parser = argparse.ArgumentParser(description="Gemini API で知識カードを生成")
    parser.add_argument("--api-key", help="Gemini API key（省略時は GEMINI_API_KEY 環境変数）")
    parser.add_argument("--category", choices=list(CATEGORIES.keys()) + ["all"], default="all",
                        help="生成するカテゴリ（all = 全カテゴリ均等）")
    parser.add_argument("--count", type=int, default=10, help="生成するカード枚数")
    parser.add_argument("--batch-size", type=int, default=5, help="1回のAPI呼び出しで生成する枚数")
    parser.add_argument("--output", default=CARDS_DIR, help="出力ディレクトリ")
    parser.add_argument("--today", action="store_true", help="今日のデッキを既存カードから自動生成")
    parser.add_argument("--today-card-count", type=int, default=3, help="今日のデッキのカード枚数")
    parser.add_argument("--list-existing", action="store_true", help="既存カード一覧を表示")
    args = parser.parse_args()

    if args.list_existing:
        list_existing_cards()
        return

    if args.today:
        generate_daily_deck(args.today_card_count)
        return

    api_key = args.api_key or os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("Error: GEMINI_API_KEY 環境変数か --api-key でAPIキーを指定してください", file=sys.stderr)
        sys.exit(1)

    client = genai.Client(api_key=api_key)
    print(f"Generating {args.count} cards (category={args.category}, batch={args.batch_size})...")
    cards = generate_cards(client, args.category, args.count, args.batch_size)
    if cards:
        save_cards(cards, args.output)
        print(f"\nDone. Generated {len(cards)} cards.")
    else:
        print("No cards generated.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
