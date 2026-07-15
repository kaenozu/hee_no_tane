# Content review batch 3

**Review date:** 2026-07-15
**Decision:** 5 pairs approved; 2 initially considered pairs held back.

## Selection criteria

- Existing `reviewStatus` was not `approved`.
- Stable, non-medical, non-financial, non-legal claims.
- Primary or official institutional material was directly accessible.
- The current question, answer, explanation, and card text could remain unchanged.
- Five distinct categories were selected.

## Approved pairs

| Pair | Category | Claim decomposition | Primary-source finding | Decision |
| --- | --- | --- | --- | --- |
| `q_food_005` / `card_food_005` | food | The red flesh is receptacle tissue; each surface achene is a botanical fruit containing a seed. | Carnegie Museums states both points directly. | approved |
| `q_nature_geography_015` / `card_nature_geography_015` | nature_geography | Tsunamis are commonly caused by major undersea earthquakes and propagate as ocean waves. | NOAA identifies earthquakes and undersea eruptions as causes and describes propagation. | approved |
| `q_living_things_015` / `card_living_things_015` | living_things | A camel hump stores fat rather than water; stored fat is used when food is scarce. | Library of Congress states both points directly. | approved |
| `q_science_010` / `card_science_010` | science | Lift involves pressure variation and turning airflow; the simple equal-transit story is insufficient. | NASA Glenn explains both pressure and flow-turning accounts and rejects equal-transit oversimplification. | approved |
| `q_history_011` / `card_history_011` | history | The Penny Black was an 1840 pioneering postage stamp tied to prepaid modern postal reform. | Smithsonian National Postal Museum identifies the 1840 Penny Black within the world’s first postage stamps and documents its use. | approved |

## Held back

- `q_his_002` / `card_his_002`: accessible official material did not directly support every quantity in the current text.
- `q_language_010` / `card_language_010`: no directly accessible primary source supported the whole current wording.

## Validation results

- CSV export and risk report generation: passed.
- CSV import dry-run and write import: passed.
- Content validation: passed with 103 questions, 103 cards, and 32 playable questions.
- Approved-source audit: passed.
- Release blocker invariant: each selected pair retains only `image_generic_placeholder`.
- Unselected question/card object equality check: passed.
- `flutter analyze`: passed.
- `flutter test`: passed.
- `git diff --check`: passed after normalizing the committed risk CSV to LF line endings.

## Invariants

- No question text, choices, answer indexes, explanations, card text, rarity, image path, or image review metadata is intentionally changed.
- Unselected question/card objects must remain semantically identical.
- Selected pairs must retain only `image_generic_placeholder` in the release blocker manifest.

## Known duplicate cleanup — 2026-07-15

| Group | Keep | Replace | Delete / scope reduction |
| --- | --- | --- | --- |
| Strawberry fruit structure | `q_food_005` | `q_food_011` → capsaicin receptor TRPV1 | Original strawberry claim removed from `q_food_011` |
| Octopus hearts | `q_living_things_008` | `q_bio_003` → cuttlebone buoyancy; `q_living_things_006` → vampire squid detritivory | Two duplicate octopus-heart claims removed |
| Sandwich name origin | `q_food_006` | `q_lang_003` → Hepburn `SHI` spelling | Card-playing anecdote removed from maintained question/card copy |

The four replacement claims were checked against directly accessible original research or an official government table. The generated risk CSV must contain no duplicate edge for these groups.
