# へぇダンジョン / へぇの種 統合ゲーム企画パッケージ

## 目的

このZIPは、AIエージェントに実装指示を出すための仕様書・設計書・タスク分解・初期データ仕様をまとめたものです。

方針は以下です。

- アプリ本体はゲームとして作る
- 旧案「へぇの種」は、ゲーム内の報酬・図鑑・知識カード・収集要素として統合する
- 最初のMVPは Android / Flutter / オフライン / 広告なし / 課金なし
- アプリ内でAIに問い合わせる機能はv0.1では入れない
- 問題データは `assets/data/questions.json` 相当のJSONで管理する

## ZIP内ファイル

```text
AGENTS.md
README.md
docs/
  01_product_spec.md
  02_system_design.md
  03_data_design.md
  04_ai_agent_playbook.md
  05_github_issues.md
  06_release_checklist.md
prompts/
  01_initial_codex_prompt.md
  02_phase1_core_prompt.md
  03_phase2_gameplay_prompt.md
  04_phase3_save_and_collection_prompt.md
  05_review_prompt.md
data/
  questions.sample.json
  cards.sample.json
  enemies.sample.json
.github/workflows/
  flutter_ci.yml
```

## 推奨の使い方

1. 既存リポジトリがない場合はFlutterプロジェクトを新規作成する
2. `AGENTS.md` をリポジトリ直下に置く
3. `docs/` と `data/` をリポジトリに入れる
4. `prompts/01_initial_codex_prompt.md` をAIエージェントに渡す
5. 以降は `docs/05_github_issues.md` のIssue単位で実装させる

## 確認できた事実

- Flutterは単一コードベースでモバイル、Web、デスクトップ等を作れるフレームワークとして公式に説明されている。出典: https://flutter.dev/
- Flutter公式ドキュメントは、アプリ設計をUI、ロジック、データ等の層で整理するアーキテクチャ指針を提供している。出典: https://docs.flutter.dev/app-architecture/guide
- Flutter公式ドキュメントは、アプリ状態を扱うための状態管理をテーマとして扱っている。出典: https://docs.flutter.dev/data-and-backend/state-mgmt/intro
- Google Play BillingはAndroidアプリ内でデジタル商品やコンテンツを販売する仕組みとして公式に説明されている。出典: https://developer.android.com/google/play/billing
- Google Playでは、新規アプリ・更新アプリについてtarget API level要件が設定されている。出典: https://support.google.com/googleplay/android-developer/answer/11926878?hl=en
- AppleのApp Store Review GuidelinesはSafety、Performance、Business、Design、Legal等のセクションで構成されている。出典: https://developer.apple.com/app-store/review/guidelines/

## 確認できない情報

- 「へぇダンジョン」「へぇの種」「へぇローグ」の商標・ストア名の空き状況
- 競合アプリに対する勝率
- 実際の継続率、DL数、広告収益
- AIエージェントがあなたのローカル環境で一発でAPKビルドまで成功するか

## 推測

- 個人開発では、読み物アプリ単体より、ゲームとして起動理由を作り、その報酬として知識カードを集める形の方が継続率を作りやすい可能性が高い。
- 初期段階では広告・課金・通知・オンライン同期を入れない方が、AIエージェント実装の成功率が高い。
