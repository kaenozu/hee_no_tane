# AGENTS.md

## Project

へぇダンジョン: 知識で進む1分クイズRPG。

旧案「へぇの種」は独立アプリではなく、ゲーム内の報酬・カード図鑑要素として統合する。

## Non-negotiable scope for v0.1

Do not implement:

- Ads
- In-app purchases
- Login
- Server backend
- Cloud sync
- Push notifications
- In-app AI generation
- Gacha mechanics
- Ranking/friends

Implement first:

- Offline Android Flutter MVP
- 5-question daily dungeon
- Multiple-choice trivia battle
- HP/damage/win/lose logic
- Reward card collection
- Local save
- Tests

## Commands

Always run after changes:

```bash
flutter pub get
flutter analyze
flutter test
```

When requested for APK:

```bash
flutter build apk --debug
```

## Architecture rules

- Keep UI and domain logic separate.
- Put battle logic in services, not directly in widgets.
- Put JSON/local persistence in repositories.
- Use models for Question, HeeCard, Enemy, SaveData, BattleState.
- `verified: false` questions must never be used in gameplay.
- All question choices must have exactly 4 items.
- `answerIndex` must be 0, 1, 2, or 3.

## Reporting format

After each task, report:

```text
## Implemented
- ...

## Files changed
- ...

## Checks
- flutter analyze: pass/fail
- flutter test: pass/fail
- flutter build apk --debug: pass/fail/not run

## Remaining issues
- ...

## Next recommended task
- ...
```
