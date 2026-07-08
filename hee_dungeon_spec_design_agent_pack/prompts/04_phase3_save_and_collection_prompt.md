# 04. Phase 3 Save and Collection Prompt

Phase 3として、ローカル保存、報酬、図鑑を実装してください。

## 実装対象

- SaveRepository
- ownedCardIds保存
- totalPlayCount保存
- totalClearCount保存
- streakDays保存
- RewardService
- 図鑑表示
- カード詳細
- 設定画面のデータリセット

## 報酬仕様

- 5Fボス撃破でクリア
- クリア時に、その日出題された問題のrelatedCardIdから未所持カードを1枚選ぶ
- UI上は「へぇの種が発芽した」という演出にする
- 内部的にはHeeCardをownedCardIdsに追加する

## 完了条件

- クリア時にカードを獲得できる
- 図鑑に獲得カードが表示される
- アプリ再起動後も保持される
- データリセットできる
- flutter analyze が通る
- flutter test が通る
