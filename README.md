# へぇのタネ

1日1問、約30秒の雑学クイズに答え、解説付きの知識カードを集めるFlutterアプリです。

## 現在の機能

- 初回起動オンボーディング
- 日付に応じた「今日の1問」
- 回答、解説、カード獲得
- 獲得カードの図鑑とカテゴリ絞り込み
- 連続回答日数、回答数、閲覧数の端末内保存
- 1080×1350 PNGのカード共有
- ライト／ダークテーマ
- データリセット
- アプリ内プライバシーポリシー、サポート、OSSライセンス
- 起動・読込・保存失敗時の再試行と復旧導線

アカウント、広告、分析SDK、外部バックエンドは使用していません。進行状況は端末内の`SharedPreferences`へ保存します。

## 開発環境

```bash
flutter pub get
dart run tool/validate_content.dart
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
flutter build apk --debug
```

CIでは上記に加えて、macOS runnerで署名なしiOS release buildを実行します。

## コンテンツ

- `assets/data/questions.json`
- `assets/data/cards.json`

`tool/validate_content.dart`は、JSON構文、必須項目、ID重複、選択肢、回答番号、カテゴリ、カード参照、画像ファイル、`verified`フラグを検証します。

`verified: true`は構造上の公開可否フラグであり、自動ファクトチェックを意味しません。リリース対象コンテンツは、人手で出典と説明の一致を確認してください。

## Android release signing

リリースビルドは署名情報がない場合に失敗する設計です。ローカルでは`android/app/keystore.properties`を作成します。このファイルとkeystoreはGit管理対象外です。

```properties
storeFile=upload-keystore.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

```bash
flutter build appbundle --release
```

GitHub Actionsの`Build release artifacts`を利用する場合は、Repository secretsへ以下を登録します。

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

workflow_dispatchでストア用build numberを入力すると、署名済みAABとWeb bundleをartifactとして生成します。

## 公開ページ

Flutter Webを公開すると、次の静的ページも同じ配布先に配置されます。

- `/privacy.html`
- `/support.html`

Google Play Console、App Store Connectには、実際に公開したURLを登録してください。

## アプリ識別子

- Android: `com.heenotane.hee_no_tane_app`
- iOS: `com.heenotane.heeNoTaneApp`

ストアへ初回登録した後は識別子を変更できないため、登録前に最終確認してください。

## リリース手順

詳細は以下を参照してください。

- `docs/RELEASE_CHECKLIST.md`
- `docs/STORE_LISTING_JA.md`
- `docs/DATA_SAFETY.md`

## 未完了の外部確認

コードと自動テストだけでは次を完了できません。

- Android実機の共有シート、システムバック、小型画面
- iPhone/iPad実機の共有シート、スワイプバック、ポップオーバー位置
- 複数ブラウザのWeb Share APIとダウンロードフォールバック
- Play Console / App Store Connect登録
- Android upload keyとApple署名証明書の保管
- ストアスクリーンショットと実際の審査提出

実機結果はIssue #16へ記録します。
