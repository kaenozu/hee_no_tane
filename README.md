# へぇのタネ

日替わりの四択クイズに答え、関連する知識カードを集めるFlutterアプリです。

## 現行MVP

- 1日1問の日替わりクイズ
- 正誤にかかわらず解説を表示し、回答完了後に関連カードを獲得
- 獲得カードの一覧・詳細・共有
- 端末内保存、ストリーク、回答数、カード閲覧数
- 初回オンボーディング、テーマ設定、全データリセット
- Android、iOS、Webを対象とするFlutterクライアント

アカウント、バックエンド、広告、サブスクリプション、管理画面、オンラインAI生成は現行MVPには含まれません。コンテンツは`assets/data`に同梱され、リリース前にリポジトリ上のレビュー工程で承認します。

## コンテンツ公開条件

問題と関連カードは、次の条件をすべて満たす組だけが実行時の出題対象になります。

- 問題が`verified: true`
- 問題とカードの`source.reviewStatus`が`approved`
- HTTPSの出典URL、確認日、確認レベルが有効
- 問題とカードの出典URLおよび`contentHash`が一致
- 4択、正答位置、解説、カード本文、画像パス、希少度を含むSHA-256が現在の内容と一致
- 画像レビューが`approved`または`generic_placeholder`

承認CSVは、問題文、全選択肢、正答位置、解説、カード本文、画像レビュー、レビュー注記、内容ハッシュを保持します。

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
```

GitHub Actionsでは、上記のコンテンツ検証、静的解析、テスト、Webビルド、Android Debug APK、短期CI鍵を用いたRelease AABのコンパイル確認を実行します。CI鍵は配布署名には使用しません。

## 主な資料

- `docs/02_要件定義_仕様書.md`: 現行MVPの要件
- `docs/03_システム設計書.md`: ローカル完結型の構成
- `docs/10_リリースチェックリスト.md`: 自動検証と人手確認
- `docs/13_リリース判定.md`: 現在の公開判定
- `docs/14_コンテンツ出典運用.md`以降: 出典・承認・リスク監査

## 現在の公開判定

一般公開は保留です。コードとCIで確認できる項目とは別に、未承認コンテンツの人手確認、実機共有、配布用署名、ストア登録情報などが必要です。詳細は`docs/13_リリース判定.md`を参照してください。
