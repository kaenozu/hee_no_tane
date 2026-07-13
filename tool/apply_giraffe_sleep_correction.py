import json
from pathlib import Path

questions_path = Path('assets/data/questions.json')
cards_path = Path('assets/data/cards.json')

questions = json.loads(questions_path.read_text(encoding='utf-8'))
cards = json.loads(cards_path.read_text(encoding='utf-8'))

question = next(item for item in questions if item['id'] == 'q_living_things_002')
card = next(item for item in cards if item['id'] == 'card_living_things_002')

expected_question = {
    'category': 'living_things',
    'difficulty': 'normal',
    'question': '野生のキリンの1日の平均睡眠時間は、だいたいどれくらいの長さだと言われているでしょうか？',
    'choices': ['約20分', '約4時間', '約8時間', '約12時間'],
    'answerIndex': 0,
    'explanation': '野生のキリンは肉食獣などの天敵から身を守るため、非常に短い睡眠をとります。1回数分程度の「うたた寝」を細切れに繰り返し、1日の合計睡眠時間はわずか20分程度と言われています。動物界でも屈指の短眠家として有名です。',
    'relatedCardId': 'card_living_things_002',
    'sourceNote': 'ナショナルジオグラフィック 日本版',
    'verified': True,
}
for key, value in expected_question.items():
    if question.get(key) != value:
        raise SystemExit(
            f'q_living_things_002 changed unexpectedly: {key}={question.get(key)!r}'
        )
if 'source' in question:
    raise SystemExit('q_living_things_002 unexpectedly has structured source')

expected_card = {
    'title': 'キリンの超短眠術',
    'category': 'living_things',
    'shortText': '世界で最も睡眠時間が短いといわれる動物。',
    'detailText': 'キリンは立ったまま数分間の眠りを繰り返します。深い眠りにつくのは稀で、首を丸めて座って眠る姿は非常に珍しい光景です。厳しい自然界を生き抜くための究極の適応といえます。',
    'imageAsset': 'assets/images/cards/card_living_things_002.png',
    'rarity': 'rare',
    'sourceNote': 'ナショナルジオグラフィック 日本版',
}
for key, value in expected_card.items():
    if card.get(key) != value:
        raise SystemExit(
            f'card_living_things_002 changed unexpectedly: {key}={card.get(key)!r}'
        )
if 'source' in card:
    raise SystemExit('card_living_things_002 unexpectedly has structured source')

source = {
    'title': 'Behavioural sleep in the giraffe (Giraffa camelopardalis) in a zoological garden',
    'publisher': 'Journal of Sleep Research',
    'url': 'https://pubmed.ncbi.nlm.nih.gov/8795798/',
    'verifiedAt': '2026-07-13',
    'verificationLevel': 'primary',
    'reviewStatus': 'approved',
}

question.update(
    {
        'question': '1996年に発表されたキリンの行動睡眠研究で、観察場所として題名に示されているのは？',
        'choices': ['動物園', '野生のサバンナ', '大学の睡眠実験室', '海洋公園'],
        'answerIndex': 0,
        'explanation': 'ToblerとSchwierinが1996年に発表した論文の題名は「動物園におけるキリンの行動睡眠」で、観察場所として動物園が示されている。',
        'sourceNote': 'Tobler・Schwierin（1996）Journal of Sleep Research',
        'verified': True,
        'source': source,
    }
)

card.update(
    {
        'title': '動物園で調べたキリンの睡眠',
        'shortText': '1996年の行動睡眠研究は動物園が対象。',
        'detailText': 'ToblerとSchwierinは、動物園におけるキリンの行動睡眠を報告した。論文は1996年にJournal of Sleep Researchへ掲載された。',
        'sourceNote': 'Tobler・Schwierin（1996）Journal of Sleep Research',
        'source': source,
    }
)

questions_path.write_text(
    json.dumps(questions, ensure_ascii=False, indent=2) + '\n',
    encoding='utf-8',
)
cards_path.write_text(
    json.dumps(cards, ensure_ascii=False, indent=2) + '\n',
    encoding='utf-8',
)

updated_question = next(item for item in questions if item['id'] == 'q_living_things_002')
updated_card = next(item for item in cards if item['id'] == 'card_living_things_002')
assert updated_question['answerIndex'] == 0
assert updated_question['choices'][0] == '動物園'
assert updated_question['source']['reviewStatus'] == 'approved'
assert updated_question['source']['verificationLevel'] == 'primary'
assert updated_question['source']['url'] == updated_card['source']['url']
combined = (
    updated_question['question']
    + updated_question['explanation']
    + updated_card['shortText']
    + updated_card['detailText']
)
for rejected in ['20分', '天敵', '世界で最も', '立ったまま数分']:
    assert rejected not in combined
