#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path

question_explanations = {
    'q_history_005': '国立航空宇宙博物館によると、ライト・フライヤーは1903年12月17日にノースカロライナ州キティホークで初飛行した。最初の飛行はオーヴィルの操縦で12秒間、120フィート（約36m）進んだ。',
    'q_food_010': 'NOAA Fisheriesは、アラスカスケトウダラの製品の一つとして、すり身（imitation crab）を挙げている。',
    'q_daily_life_007': 'メトロポリタン美術館の作品解説によると、この15世紀のカード一組は52枚で、4つのスートから成る。',
    'q_history_009': '大英博物館の作品記録によると、ロゼッタ・ストーンにはヒエログリフ、デモティック、ギリシャ文字の3つの文字体系で同じ勅令が刻まれている。ラテン文字は含まれない。',
    'q_science_008': '造幣局は、1円硬貨の素材をアルミニウム、組成を純アルミニウム、重さを1.0g、直径を20.0mmと示している。',
    'q_daily_life_008': 'HSEのL64表1は、緑を非常脱出・応急手当の標識に割り当て、扉、出口、避難経路、設備、施設を示すとしている。',
}

card_details = {
    'card_food_010': 'NOAA Fisheriesは、アラスカスケトウダラの製品の一つとして、すり身（imitation crab）を挙げている。',
    'card_daily_life_007': 'メトロポリタン美術館の「The Cloisters Playing Cards」は、15世紀の通常のプレイングカードとして唯一知られる完全な一組で、52枚・4スートから成る。',
    'card_science_008': '造幣局の「Circulating Coin Designs」は、現在の1円硬貨を純アルミニウム製、重さ1.0g、直径20.0mmとしている。',
    'card_daily_life_008': '英国HSEの安全標識ガイダンスL64表1では、緑色は非常脱出・応急手当の標識に使われ、扉、出口、避難経路、設備、施設を示す。',
}


def update(path, field, replacements):
    target = Path(path)
    items = json.loads(target.read_text(encoding='utf-8'))
    seen = set()
    for item in items:
        item_id = item.get('id')
        if item_id in replacements:
            item[field] = replacements[item_id]
            seen.add(item_id)
    missing = set(replacements) - seen
    if missing:
        raise SystemExit(f'missing IDs in {path}: {sorted(missing)}')
    target.write_text(
        json.dumps(items, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )


update('assets/data/questions.json', 'explanation', question_explanations)
update('assets/data/cards.json', 'detailText', card_details)

subprocess.run(['git', 'config', 'user.name', 'github-actions[bot]'], check=True)
subprocess.run(
    [
        'git',
        'config',
        'user.email',
        '41898282+github-actions[bot]@users.noreply.github.com',
    ],
    check=True,
)
subprocess.run(
    ['git', 'add', '--', 'assets/data/questions.json', 'assets/data/cards.json'],
    check=True,
)
if subprocess.run(['git', 'diff', '--cached', '--quiet']).returncode == 0:
    print('Display text is already refined; no push required.')
    raise SystemExit(0)
subprocess.run(
    ['git', 'commit', '-m', 'Keep content audit notes out of display text'],
    check=True,
)
subprocess.run(['git', 'push', 'origin', 'HEAD'], check=True)
