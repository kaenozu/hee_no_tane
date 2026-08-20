# へぇのタネ

日替わりの四択クイズに答え、関連する知識カードを集めるFlutterアプリです。

## 現行MVP

- 1日1問の日替わりクイズ
- 回答後の解説表示と知識カード獲得
- 獲得カードの一覧・詳細・共有
- 端末内保存、ストリーク、回答数、閲覧数
- 初回オンボーディング、テーマ設定、全データリセット
- Flutterクライアント（Android / iOS / Web）

アカウント、バックエンド、広告、サブスクリプション、管理画面、オンラインAI生成は現行MVPに含みません。コンテンツは `assets/data` に同梱し、リリース前にレビュー工程で承認します。

## 広告による収益化（実装済み・本番ID待ち）

ホーム画面にGoogle Mobile Adsのバナー枠を追加しています。無料利用を制限せず、広告サービスが失敗してもクイズ・保存データの起動を妨げない設計です。

- 開発・テスト時はGoogle公式テストApp ID / バナーIDを使用
- 本番公開前にAdMobでへぇの種用の広告ユニットを作成し、`lib/monetization/ad_config.dart`、`android/app/src/main/AndroidManifest.xml`、`ios/Runner/Info.plist`のテストIDを本番IDへ置換
- 本番ID未設定のまま公開しない（テスト広告は収益にならず、誤クリック防止のため）
- AdMobアカウント、広告ユニット作成、収益受取設定、ストアの広告表示申告はコード外のリリース作業

## コンテンツの安全契約

問題とカードは、定義済みの検証・承認条件を満たすものだけをruntime対象にします。

主な条件:

- 問題が `verified: true`
- 問題とカードの `source.reviewStatus` が `approved`
- HTTPS出典、確認日、verification levelが有効
- question / card の出典情報と `contentHash` が整合
- 4択、正答位置、解説、カード本文、画像等を含むhashが現在内容と一致
- 画像レビューが `approved` または許可されたplaceholder状態

**stored / edited件数と、実際にrelease runtimeへ含める承認済み件数を同一視しません。** 未監査・未承認コンテンツはfail-closedで除外します。

## 開発と検証

```bash
flutter pub get
dart run tool/validate_content.dart
dart run tool/audit_content_sources.dart --require-approved
dart run tool/content_review.dart export --output build/content_review.csv
dart run tool/content_review.dart import --input build/content_review.csv
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
flutter build apk --debug
flutter build appbundle --release
git diff --check
```

CIではcontent gate、静的解析、テスト、Web build、Android build等を検証します。CI用署名鍵は配布署名の証拠として扱いません。

## コンテンツ変更の原則

- question / card の意味整合性を維持する
- 出典は主張を直接裏付けるページ・箇所を記録する
- 正答、選択肢、解説、カード本文の事実を揃える
- `contentHash`、semantic review、bundle / manifestを同期する
- 画像は自動チェックだけで最終承認済みと扱わず、release対象は必要な目視レビューを完了する
- pending / rejected なpairをruntimeへ混入させない

## Release gate

コード・CIの成功だけでは一般公開可能とは判定しません。少なくとも次を分離して確認します。

1. runtime対象コンテンツの承認状態
2. release対象画像の最終レビュー
3. bundle / manifest / count整合
4. Flutter / Content / Security 等のCI
5. Android実機受入
6. 配布用署名
7. Play Console / store情報

## 主な資料

- `docs/02_要件定義_仕様書.md` — MVP要件
- `docs/03_システム設計書.md` — システム構成
- `docs/10_リリースチェックリスト.md` — リリース確認
- `docs/13_リリース判定.md` — 公開判定
- `docs/14_コンテンツ出典運用.md` 以降 — 出典・承認・監査

## 現在の作業管理

READMEには変動しやすいruntime件数、個別PR、画像承認進捗を固定しません。最新のRC対象、監査pending、画像レビュー、署名・内部テストの状態は GitHub Issues / Pull Requests とリリース判定資料を正としてください。
