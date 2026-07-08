# content_generation_prompts

作成日: 2026-07-07

## 1. カード下書き生成プロンプト

```text
あなたは「へぇの種」という知的暇つぶしアプリの編集者です。
次のトピックについて、出典に基づいた知識カードをJSONで作成してください。

条件:
- 30秒説明は120〜180字。
- 3分深掘りは600〜1,000字。
- 読者は一般成人。専門用語は避ける。
- 医療・法律・投資判断に見える表現は禁止。
- 出典で確認できないことは断定しない。
- 諸説ある場合は confidence_level を C にする。
- 出典URLを sources に残す。

入力:
- topic: {{topic}}
- category: {{category}}
- source_notes: {{source_notes}}

出力JSON:
{{
  "title": "",
  "hook": "",
  "short_body": "",
  "long_body": "",
  "category_slug": "",
  "confidence_level": "A|B|C|D",
  "claims": [
    {{"claim": "", "source_urls": [], "confidence": ""}}
  ],
  "sources": [
    {{"title": "", "url": "", "source_type": "", "retrieved_at": ""}}
  ],
  "quiz": {{
    "question": "",
    "choices": ["", "", ""],
    "answer_index": 0,
    "explanation": ""
  }},
  "related_keywords": []
}}
```

## 2. 主張抽出プロンプト

```text
次の本文から、事実主張を1文ずつ抽出してください。
感想、比喩、導入文は除外してください。
各主張について、出典が必要かを判定してください。

本文:
{{body}}

出力JSON:
{{
  "claims": [
    {{
      "claim": "",
      "requires_source": true,
      "risk": "low|medium|high",
      "reason": ""
    }}
  ]
}}
```

## 3. リライトプロンプト

```text
次の知識カードを、「軽いが雑ではない」文体に整えてください。
事実は追加しないでください。
断定が強すぎる表現は弱めてください。
出典で確認できない内容は削除または「〜とされます」に変更してください。

カード:
{{card_json}}
```

## 4. 類似カード検出プロンプト

```text
新規カードと既存カード一覧を比較し、内容が重複しているものを検出してください。
タイトルが違っても、説明している中心事実が同じなら重複とみなします。

新規カード:
{{new_card}}

既存カード:
{{existing_cards}}

出力JSON:
{{
  "duplicates": [
    {{"card_id": "", "similarity_reason": "", "severity": "low|medium|high"}}
  ]
}}
```
