# Issue #75 — 23-pair current-master re-audit

Updated 2026-10-01.

## Source metadata
- 23/23 question IDs present.
- 23/23 question/card source URLs match.
- 23/23 verifiedAt and verificationLevel values match.
- 23/23 question/card source records are approved and contain direct-evidence review notes.
- Android v1.0 runtime remains 47 pairs; this work does not restore deferred pairs to v1.0.

## Image review
- Initial audit on 2026-09-30: 8 approved / 15 replace_required.
- The 15 rejected images were replaced on 2026-10-01 with repository-specific 220x160 illustrations.
- Replacement illustrations contain no text or logos and were visually checked against each card claim.
- Current result: 23/23 imageReview = approved.

Replaced question IDs:
- q_food_005
- q_food_009
- q_history_007
- q_language_002
- q_language_005
- q_language_009
- q_language_010
- q_living_things_008
- q_living_things_009
- q_living_things_012
- q_living_things_013
- q_sci_001
- q_sci_004
- q_science_001
- q_science_009

## Runtime boundary
The v1.0 RC1 exclusion list remains unchanged at 23 IDs and the runtime count remains 47. Any v1.1 restoration decision is separate from this image/source audit.
