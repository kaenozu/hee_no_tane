# 02. へぇダンジョン 基本設計書 v0.1

## 1. 技術方針

### 1.1 採用技術

| 項目 | 採用 |
|---|---|
| フレームワーク | Flutter |
| 言語 | Dart |
| 初期対象 | Android |
| 状態管理 | Riverpod推奨。ただしAIエージェントが難しい場合はChangeNotifier可 |
| 画面遷移 | go_router推奨。難しければNavigatorで可 |
| ローカル保存 | shared_preferences または Hive |
| 初期データ | JSON同梱 |
| サーバー | なし |
| 認証 | なし |
| 広告 | v0.1ではなし |
| 課金 | v0.1ではなし |

Flutter公式ドキュメントにはアプリ設計のガイドがあり、UI、ロジック、データ層を分ける構成と相性がよい。出典: https://docs.flutter.dev/app-architecture/guide

## 2. アーキテクチャ

### 2.1 基本構成

```text
UI Layer
  ↓
Controller / State Layer
  ↓
Domain Service Layer
  ↓
Repository Layer
  ↓
Local JSON / Local Save
```

### 2.2 各層の責務

#### UI Layer

- 画面表示
- ボタンタップ受付
- アニメーション
- 状態に応じた描画

#### Controller / State Layer

- 画面状態の保持
- Service呼び出し
- Loading/Error/Success管理
- 画面遷移判断

#### Domain Service Layer

- ゲームロジック
- バトル計算
- ダンジョン生成
- 報酬決定
- 日替わりseed処理

#### Repository Layer

- JSON読み込み
- セーブデータ読み書き
- カード/問題/敵データ取得

## 3. 推奨ディレクトリ構成

```text
lib/
  main.dart
  app.dart

  core/
    constants/
      app_constants.dart
    routing/
      app_router.dart
    utils/
      date_seed.dart
      result.dart

  domain/
    models/
      question.dart
      hee_card.dart
      enemy.dart
      dungeon_run.dart
      battle_state.dart
      save_data.dart
    services/
      battle_service.dart
      daily_dungeon_service.dart
      reward_service.dart

  data/
    repositories/
      question_repository.dart
      card_repository.dart
      enemy_repository.dart
      save_repository.dart

  features/
    home/
      home_screen.dart
      home_controller.dart
    dungeon/
      dungeon_map_screen.dart
      dungeon_controller.dart
    battle/
      battle_screen.dart
      battle_controller.dart
      explanation_screen.dart
    result/
      result_screen.dart
    collection/
      card_list_screen.dart
      card_detail_screen.dart
    settings/
      settings_screen.dart

assets/
  data/
    questions.json
    cards.json
    enemies.json
  images/
    characters/
    enemies/
    cards/
    ui/
  sounds/

test/
  domain/
  data/
  features/
```

## 4. 状態管理設計

### 4.1 管理する状態

| 状態 | 内容 | 保存対象 |
|---|---|---|
| AppSettings | 音、リセット等 | Yes |
| SaveData | 総プレイ数、図鑑、連続日数 | Yes |
| DailyDungeon | 今日の問題、階層構成 | 一部Yes |
| BattleState | 現在敵HP、選択問題、コンボ | No |
| ResultState | 勝敗、獲得カード | No |

Flutterではアプリ状態をどう管理するかが重要であり、公式ドキュメントでも状態管理が独立したテーマとして扱われている。出典: https://docs.flutter.dev/data-and-backend/state-mgmt/intro

### 4.2 保存方針

v0.1ではローカル保存だけ。

保存するもの:

- ownedCardIds
- totalPlayCount
- totalClearCount
- lastPlayedDate
- streakDays
- settings

保存しないもの:

- バトル中の一時状態
- 現在画面
- アニメーション状態

## 5. データ読み込み設計

### 5.1 起動時読み込み

アプリ起動時に以下を読み込む。

- questions.json
- cards.json
- enemies.json
- saveData

読み込み失敗時はクラッシュさせず、エラー画面または初期データなし画面を表示する。

### 5.2 verifiedフィルタ

`verified == true` の問題だけを出題対象にする。

```dart
final playableQuestions = allQuestions.where((q) => q.verified).toList();
```

## 6. 日替わりダンジョン生成

### 6.1 Seed

日付文字列をseedにする。

```text
seed = yyyy-MM-dd
```

例:

```text
2026-07-08
```

### 6.2 問題抽出

v0.1では以下でよい。

```text
1. verified == true の問題だけ抽出
2. seedでシャッフル
3. 5問取得
4. 5F目をボス問題扱いにする
```

### 6.3 同日の再プレイ

v0.1では同じ日でも再プレイ可能。

ただし報酬は1日1回だけにする。

## 7. バトル処理設計

### 7.1 入力

- Question
- Enemy
- PlayerState
- selectedIndex

### 7.2 出力

- 正誤
- 与ダメージ
- 被ダメージ
- 更新後Enemy HP
- 更新後Player HP
- comboCount
- battleFinished

### 7.3 BattleService API案

```dart
class BattleService {
  BattleAnswerResult answer({
    required BattleState state,
    required int selectedIndex,
  });

  int calculateDamage({required int comboCount});

  int calculateEnemyDamage({required int floor});

  bool isCorrect(Question question, int selectedIndex);
}
```

## 8. 報酬処理設計

### 8.1 RewardService

役割:

- クリア時のへぇカード選定
- 既に持っているカードとの重複処理
- SaveData更新

### 8.2 報酬仕様

v0.1:

- クリア時に、その日出題された問題に関連するカードを1枚獲得
- 未所持カードを優先
- 全部所持済みなら重複演出のみ

### 8.3 へぇの種表現

内部データとしては `HeeCard` を直接獲得する。

UI上は以下の演出にする。

```text
へぇの種を発見！
↓
種が芽生えた！
↓
「バイカル湖」カードを獲得！
```

## 9. エラー設計

### 9.1 JSON読み込み失敗

- エラーメッセージ表示
- ホームには入れるが、ダンジョン開始は無効
- ログ出力

### 9.2 セーブデータ破損

- バックアップがなければ初期化確認を出す
- v0.1では簡易的に初期化でもよい

### 9.3 問題不足

verified問題が5問未満の場合:

- ダンジョン開始不可
- 「問題データが不足しています」と表示

## 10. テスト設計

### 10.1 ユニットテスト

必須:

- Question JSON parse
- HeeCard JSON parse
- Enemy JSON parse
- verified問題だけ抽出
- 正誤判定
- ダメージ計算
- 被ダメージ計算
- 敵撃破判定
- プレイヤー敗北判定
- 報酬カード選定

### 10.2 Widgetテスト

必須:

- ホーム画面表示
- 今日のダンジョンボタン表示
- クイズ問題表示
- 選択肢タップ
- 正解表示
- リザルト表示

### 10.3 手動テスト

- 初回起動
- ダンジョン開始
- 5問回答
- 勝利
- 敗北
- 図鑑反映
- 再起動後も保存
- データリセット

## 11. CI設計

GitHub Actionsで以下を実行する。

```text
flutter pub get
flutter analyze
flutter test
```

debug APK buildはPhase 4以降で追加してよい。

Google Playではtarget API level要件が存在するため、ストア公開前にはAndroid SDK/Gradle設定の確認が必要。出典: https://support.google.com/googleplay/android-developer/answer/11926878?hl=en

## 12. 将来拡張時の設計余地

### 12.1 広告

v0.3以降。

- 報酬2倍
- 敗北時復活
- ヒント獲得

強制広告は避ける。

### 12.2 課金

v1.0以降。

- 広告削除
- 追加問題パック
- テーマスキン

Google Play Billing対応が必要。出典: https://developer.android.com/google/play/billing

### 12.3 iOS

Apple App Store Review GuidelinesはSafety、Performance、Business、Design、Legal等の観点で審査指針を構成しているため、iOS版公開時は課金、広告、プライバシー、品質の見直しが必要。出典: https://developer.apple.com/app-store/review/guidelines/
