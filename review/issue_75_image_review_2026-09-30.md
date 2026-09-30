# Issue #75 — 23-pair current-master image re-audit (2026-09-30)

The canonical 23 deferred v1.1 pairs were rechecked against current master.

## Source metadata
- 23/23 question IDs present.
- 23/23 question/card source URLs match.
- 23/23 verifiedAt and verificationLevel values match.
- 23/23 question/card source records are approved and contain direct-evidence review notes.
- Android v1.0 runtime remains 47 pairs; this audit does not restore any deferred pair.

## Human visual review
- approved: 8
- replace_required: 15

Approved:
- q_daily_life_010
- q_food_006
- q_living_things_015
- q_living_things_016
- q_nature_geography_009
- q_sci_002
- q_science_002
- q_science_010

Replacement required:
- q_food_005 — generated pseudo-text
- q_food_009 — misleading unexplained green shape
- q_history_007 — does not communicate former Japanese western standard time
- q_language_002 — does not communicate the idiom/origin
- q_language_005 — weak semantic fit plus generated pseudo-text
- q_language_009 — does not communicate the French etymology
- q_language_010 — indirect fit plus generated pseudo-text
- q_living_things_008 — does not communicate three hearts; tiny generated text
- q_living_things_009 — does not communicate blue blood/hemocyanin
- q_living_things_012 — does not communicate cecotrophy
- q_living_things_013 — does not communicate backward flight
- q_sci_001 — does not communicate atmospheric composition
- q_sci_004 — generated pseudo-text
- q_science_001 — does not communicate diamond/graphite comparison
- q_science_009 — does not communicate GPS atomic clocks

No replace_required pair is restored to the runtime by this change.
