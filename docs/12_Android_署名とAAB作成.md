# Android upload key・署名済みAAB作成手順

最終更新日: 2026年7月17日

## 重要事項

- 実際のkeystore、パスワード、alias、`keystore.properties`はGitへコミットしない。
- `.gitignore`では`android/app/*.jks`、`android/app/*.keystore`、`android/app/keystore.properties`を除外している。
- upload keyを紛失すると更新作業に影響するため、暗号化したバックアップを複数保管する。
- コマンド履歴やCIログへパスワードを直接残さない。

## 1. upload keystore作成

JDKの`keytool`を使用する。ファイル名とaliasは必要に応じて変更する。

```bash
keytool -genkeypair \
  -v \
  -keystore android/app/upload-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

対話入力するパスワード、氏名、組織情報を安全に記録する。コマンド引数へパスワードを直接書かない。

## 2. 証明書確認

```bash
keytool -list -v \
  -keystore android/app/upload-keystore.jks \
  -alias upload
```

次を記録する。

- alias
- 有効期限
- SHA-1
- SHA-256

パスワードや秘密鍵そのものは記録用Issueへ貼らない。

## 3. keystore.properties作成

サンプルをコピーする。

```bash
cp android/app/keystore.properties.example android/app/keystore.properties
```

Windows PowerShellの場合:

```powershell
Copy-Item android/app/keystore.properties.example android/app/keystore.properties
```

ローカルの`android/app/keystore.properties`を次の形式で編集する。

```properties
storeFile=upload-keystore.jks
storePassword=<STORE_PASSWORD>
keyAlias=upload
keyPassword=<KEY_PASSWORD>
```

`<...>`を実値へ置き換える。完成したファイルは共有・添付・コミットしない。

## 4. Git除外確認

```bash
git status --short --ignored android/app
```

少なくとも次がignoredとして扱われることを確認する。

- `android/app/upload-keystore.jks`
- `android/app/keystore.properties`

さらに、追跡済みでないことを確認する。

```bash
git ls-files android/app/upload-keystore.jks android/app/keystore.properties
```

出力が空でなければ、AABを作る前に追跡状態を修正する。

## 5. 依存関係と検証

```bash
flutter clean
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
```

公開対象コンテンツの最終確認:

```bash
dart run tool/generate_content_bundle.dart --check
dart run tool/validate_semantic_reviews.dart
dart run tool/validate_runtime_content.dart
dart run tool/validate_content.dart
dart run tool/audit_content_sources.dart --require-approved
dart run tool/validate_release_readiness.dart --require-final-images
```

## 6. 署名済みAAB作成

```bash
flutter build appbundle --release
```

標準の成果物:

```text
build/app/outputs/bundle/release/app-release.aab
```

release署名設定が不足している場合、Gradleはビルドを失敗させる。debug署名へ自動フォールバックさせない。

## 7. 成果物ハッシュ

Linux / macOS:

```bash
shasum -a 256 build/app/outputs/bundle/release/app-release.aab
```

Windows PowerShell:

```powershell
Get-FileHash build/app/outputs/bundle/release/app-release.aab -Algorithm SHA256
```

次をRC1証跡へ記録する。

- Git commit SHA
- アプリversionName / versionCode
- AAB SHA-256
- upload証明書SHA-256
- ビルド日時
- Flutter / Dartバージョン

## 8. AAB情報確認

Android SDKの`bundletool`またはPlay Consoleのアップロード結果で次を確認する。

- applicationId: `com.heenotane.hee_no_tane_app`
- versionName: `1.0.0`
- versionCode: `1`
- minSdk / targetSdk
- 署名証明書
- 対象ABIとリソース構成

## 9. Play内部テスト

- Play ConsoleへAABをアップロードする。
- versionCode重複、署名不一致、manifest警告がないことを確認する。
- 内部テストリリースを作成し、テスターへ配布する。
- Pre-launch reportを確認する。
- 実機結果を`docs/testing/`のテンプレートへ記録する。

## 10. 作業後

- `keystore.properties`を安全な場所へ保持する。
- keystoreの暗号化バックアップを確認する。
- AABを秘密鍵と同じ場所だけに保管しない。
- チャット、Issue、PR、スクリーンショットへ秘密情報が写っていないことを確認する。
