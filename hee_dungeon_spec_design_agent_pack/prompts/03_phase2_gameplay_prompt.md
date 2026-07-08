# 03. Phase 2 Gameplay Prompt

Phase 2として、データモデル、JSON読み込み、バトルロジックを実装してください。

## 実装対象

- Question model
- HeeCard model
- Enemy model
- SaveData modelの雛形
- QuestionRepository
- CardRepository
- EnemyRepository
- BattleService
- DailyDungeonService

## データ

`data/*.sample.json` を `assets/data/` 相当に配置し、アプリから読み込んでください。

## 重要ルール

- `verified: false` の問題は出題しない
- choicesは必ず4件
- answerIndexは0〜3
- sourceNoteが空の問題は出題しない

## 完了条件

- JSONから問題、カード、敵を読み込める
- 日付seedで5問を選べる
- 正誤判定できる
- 正解時に敵HPが減る
- 不正解時にプレイヤーHPが減る
- ユニットテストがある
- flutter analyze が通る
- flutter test が通る
