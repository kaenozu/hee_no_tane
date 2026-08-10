#!/usr/bin/env python3
# One-shot migration for PR #80. Removed after generated source artifacts are committed.
import json
from pathlib import Path

CARDS_PATH = Path('assets/data/cards.json')
TARGET_IDS = {
    'card_bio_002','card_bio_005','card_daily_life_001','card_daily_life_006','card_daily_life_007','card_daily_life_008','card_daily_life_009','card_daily_life_010',
    'card_food_001','card_food_002','card_food_003','card_food_005','card_food_006','card_food_008','card_food_009','card_food_010','card_food_011','card_food_012','card_food_013',
    'card_geo_004','card_geo_005','card_his_001','card_his_002','card_history_005','card_history_007','card_history_009','card_history_011','card_history_012','card_history_013',
    'card_lang_003','card_language_001','card_language_002','card_language_005','card_language_006','card_language_007','card_language_009','card_language_010',
    'card_life_002','card_life_003','card_life_004','card_living_things_002','card_living_things_006','card_living_things_008','card_living_things_009','card_living_things_012','card_living_things_013','card_living_things_014','card_living_things_015','card_living_things_016','card_living_things_017','card_living_things_018',
    'card_nature_geography_001','card_nature_geography_006','card_nature_geography_008','card_nature_geography_009','card_nature_geography_013','card_nature_geography_014','card_nature_geography_015','card_nature_geography_016',
    'card_sci_001','card_sci_002','card_sci_004','card_science_001','card_science_002','card_science_005','card_science_006','card_science_008','card_science_009','card_science_010','card_science_011',
}

REVIEW = {
    'status': 'pending',
    'reviewedAt': '2026-08-10',
    'note': 'Generated card image (Pollinations batch, 220x160). Quality gate PASS. Awaiting human visual review for claim accuracy.',
}


def main() -> None:
    cards = json.loads(CARDS_PATH.read_text(encoding='utf-8'))
    found = set()
    for card in cards:
        card_id = card.get('id')
        if card_id in TARGET_IDS:
            card['imageReview'] = dict(REVIEW)
            found.add(card_id)

    missing = TARGET_IDS - found
    unexpected = found - TARGET_IDS
    if missing or unexpected or len(found) != 70:
        raise SystemExit(
            f'image review migration mismatch: found={len(found)} missing={sorted(missing)} unexpected={sorted(unexpected)}'
        )

    CARDS_PATH.write_text(
        json.dumps(cards, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    print(f'Updated {len(found)} card image reviews to pending in {CARDS_PATH}.')


if __name__ == '__main__':
    main()
