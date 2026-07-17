# Approved Content Semantic Review

- Review date: 2026-07-17
- Release content version: `1.0.0+1`
- Reviewed release pairs: 47
- Reviewer: ChatGPT-assisted full-pair review

## Scope

Every pair in `assets/data/content_bundle.json` was reviewed across the complete user-visible fact:

1. the question and all four choices address the same subject;
2. `answerIndex` points to the factually correct choice;
3. the explanation answers and supports the question;
4. the card title, short text, and detail text describe the same fact;
5. the cited source supports the reviewed fact;
6. the question and card retain the same content fingerprint.

The machine-readable approval record is `review/approved_semantic_reviews.json`. It is tied to both the generated bundle hash and each pair's SHA-256 content hash. Any later release-content change requires a new semantic review record.

## Corrections made

| Question ID | Previous inconsistency | Resolution |
| --- | --- | --- |
| `q_food_008` | Honey/blood-sugar question used dashi choices and a dashi card | Unified the question, choices, answer, explanation, card, and source note around honey's effect on blood sugar |
| `q_history_011` | Statue of Liberty question used postage-stamp choices and card text | Unified the pair around France's gift of the Statue of Liberty |
| `q_language_007` | The meaning of `如し` used `うだつ` choices and card text | Unified the pair around the comparative meaning “～のようだ” |
| `q_nature_geography_013` | An Awaji population question used island-name choices | Replaced the choices with population values and aligned the card to the 2020 census figure |
| `q_nature_geography_015` | A coastal tsunami-height question used tsunami-generation choices and card text | Unified the pair around shallow-water deceleration and wave-height amplification |
| `q_science_011` | A quicklime reaction question used soap choices and card text | Unified the pair around calcium oxide reacting with water to form calcium hydroxide and release heat |

## Result

- 47 of 47 release pairs reviewed.
- 6 inconsistent pairs corrected.
- 41 pairs required no semantic content change.
- No unresolved semantic mismatch remains in the approved runtime bundle.
