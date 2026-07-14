> **履歴資料:** この計画は旧「へぇダンジョン」案の記録です。現行仕様ではありません。現行の正本は`README.md`、`docs/02_*`、`docs/03_*`です。

# へぇダンジョン MVP Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build complete offline Flutter mini-game MVP (5-floor quiz RPG) with Home → Battle → Result → Collection flow.

**Architecture:** Domain-driven layered architecture: Models → Services → Data/Repositories → Features/Screens. ChangeNotifier for state, Navigator 2.0 for routing. No Riverpod, no go_router (MVP simplicity).

**Tech Stack:** Flutter 3.44, Dart 3.12, SharedPreferences, existing project at `C:\gemini-desktop\hee_no_tane`

**Reference documents:** `hee_dungeon_spec_design_agent_pack/docs/01_product_spec.md`, `02_system_design.md`, `03_data_design.md`

---

### Task 1: Create Asset Data Files

**Files:**
- Create: `assets/data/questions.json` — 30 verified 4-choice questions across categories
- Create: `assets/data/cards.json` — 30 HeeCards matching question IDs
- Create: `assets/data/enemies.json` — 4 normal enemies + 1 boss enemy
- Modify: `pubspec.yaml` — add assets declarations

**Data format:** Follow spec `03_data_design.md` exactly. Questions use `relatedCardId` linking. All questions `verified: true`. 4 choices exact. `answerIndex` 0-3.

**Enemy config:** Floor 1-2: HP 20-24. Floor 3: HP 28. Floor 4: HP 34. Floor 5 boss: HP 48, attack 10.

### Task 2: Create Domain Models

**Files:**
- Create: `lib/domain/models/question.dart`
- Create: `lib/domain/models/hee_card.dart`
- Create: `lib/domain/models/enemy.dart`
- Create: `lib/domain/models/battle_state.dart` — BattleState (playerHp, enemyHp, combo, floor, currentQuestionIndex, questions, enemy), BattleAnswerResult (isCorrect, damage, playerHpAfter, enemyHpAfter, comboAfter, isFloorCleared, isGameOver, isClear)
- Create: `lib/domain/models/save_data.dart` — SaveData + Settings (serialization via toJson/fromJson)

### Task 3: Create Game Services

**Files:**
- Create: `lib/domain/services/battle_service.dart`
- Create: `lib/domain/services/daily_dungeon_service.dart`
- Create: `lib/domain/services/reward_service.dart`

**BattleService:** `answer(state, selectedIndex) → BattleAnswerResult`. Damage calc: `12 + min(combo*2, 6)`. Enemy damage: `8 + (floor-1)`. Win/lose checks.

**DailyDungeonService:** `generate(date, questions, enemies) → (questions, enemies)`. Filter verified, shuffle by date seed, pick 5, assign enemies per floor.

**RewardService:** `determineReward(questions, ownedCardIds, allCards) → HeeCard?`. Priority: unowned card from today's questions.

### Task 4: Create Data Repositories

**Files:**
- Create: `lib/data/repositories/question_repository.dart`
- Create: `lib/data/repositories/card_repository.dart`
- Create: `lib/data/repositories/enemy_repository.dart`
- Create: `lib/data/repositories/save_repository.dart`

**JSON repos:** Load from `assets/data/` via `rootBundle.loadString()`. Parse with `json.decode`. Return typed lists. Handle errors gracefully (return empty list on failure).

**SaveRepository:** SharedPreferences-backed. Save/load SaveData. Reset method.

### Task 5: Create Settings Screen

**Files:**
- Create: `lib/features/settings/settings_screen.dart`

**Content:** Sound toggle (UI only, no sound implementation v0.1), Data reset button with confirmation dialog, App version display.

### Task 6: Create Collection Screens

**Files:**
- Create: `lib/features/collection/card_list_screen.dart` — Grid of owned/locked cards
- Create: `lib/features/collection/card_detail_screen.dart` — Full card display

### Task 7: Create Result Screen

**Files:**
- Create: `lib/features/result/result_screen.dart`

**Content:** Win state: "CLEAR", correct count, remaining HP, obtained seed/card, button to home. Lose state: "FAILED", floor reached, correct count, learned knowledge, button to home.

### Task 8: Create Battle/Explanation Screens

**Files:**
- Create: `lib/features/battle/battle_screen.dart` — Player HP bar, Enemy HP bar, question text, 4 choice buttons, combo display, floor indicator
- Create: `lib/features/battle/explanation_screen.dart` — Correct/wrong indicator, correct answer, damage dealt/taken, explanation text, next button

### Task 9: Create Dungeon Map Screen

**Files:**
- Create: `lib/features/dungeon/dungeon_map_screen.dart`

**Content:** 5 floor nodes (1-5), current floor highlight, player HP display, enemy type icons, "enter floor" button.

### Task 10: Create Home Screen

**Files:**
- Create: `lib/features/home/home_screen.dart`

**Content:** App title "へぇダンジョン", subtitle, "今日のダンジョン" button, owned card count, streak display, collection button, settings button.

### Task 11: Wire Up App Entry Points

**Files:**
- Modify: `lib/main.dart` — Initialize, preload, run app
- Modify: `lib/app.dart` — MaterialApp with routes, theme (fantasy/dungeon aesthetic)

### Task 12: Write Tests

**Files:**
- Create: `test/domain/models_test.dart`
- Create: `test/domain/services_test.dart`
- Create: `test/data/repositories_test.dart`

**Test cases:** Question/HeelCard/Enemy JSON parse, correct/incorrect judgment, damage calculation, combo bonus, HP0 lose, 5F boss clear, SaveData save/restore.

### Task 13: Final Verification

Run: `flutter pub get && flutter analyze && flutter test`

---
