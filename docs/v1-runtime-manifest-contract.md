# Android v1.0 runtime manifest contract

The editorial generated bundle retains 70 source pairs. Android v1.0 runtime remains fail-closed at 47 reviewed pairs by applying `Rc1ContentPolicy`; the 23 Issue #75 pairs stay deferred for v1.1 re-audit.

`content_manifest.json` must describe the runtime boundary rather than the editorial source count:

- `playableQuestionCount` = 47;
- `bundleHash` = the hash of the 47-pair runtime bundle returned by `Rc1ContentPolicy`;
- source `questions.json`, `cards.json`, and `content_bundle.json` remain intact and are not treated as approval of deferred pairs.

`dart run tool/generate_content_bundle.dart --check` is the deterministic drift gate for both the source bundle and runtime manifest. `tool/validate_content.dart` validates all 70 editable source pairs while checking manifest runtime counts against the 47-pair RC1 boundary, so source reviewability and release exposure cannot be confused.
