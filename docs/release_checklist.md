# へぇダンジョン リリースチェックリスト

## 必須ゲート

- `powershell -ExecutionPolicy Bypass -File scripts/verify_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/verify_content.ps1`
- `flutter analyze`
- `flutter test`
- `flutter build web --no-web-resources-cdn`
- `flutter build apk --release`
- `flutter build appbundle --release`

CIでは `verify_content` / `analyze` / `test` / `build web` / `build apk --release` を実行する。
`verify_content.ps1` はFlutterを起動せず、問題・カード・敵データと音声/画像アセットの整合を高速に確認する。
カードの `imageAsset` は未提供なら空文字にする。値を入れた場合は、実在する空でない画像ファイルであることを検証する。
Google Play提出前はローカルまたはリリース環境で `build appbundle --release` も必ず実行する。
Androidストア署名まで含めて確認する場合は
`powershell -ExecutionPolicy Bypass -File scripts/verify_release.ps1 -RequireStoreSigning`
を実行する。

## Android署名

ストア提出前に `android/app/keystore.properties.example` をコピーして
`android/app/keystore.properties` を作成する。
新規keystoreを作る場合は、プロジェクトルートから
`powershell -ExecutionPolicy Bypass -File scripts/generate_keystore.ps1`
を実行する。

```properties
storeFile=release.keystore
storePassword=...
keyAlias=release
keyPassword=...
```

`android/app/keystore.properties` と keystore 本体は秘密情報なのでコミットしない。
未設定時のローカルrelease buildはdebug署名フォールバックで通るが、ストア提出には使わない。

ストア提出用AABを作る前に以下を確認する。

- `android/app/keystore.properties` が存在する
- `storeFile` のkeystoreファイルが存在する
- `storePassword` / `keyAlias` が本番値になっている
- `keyPassword` を別に設定する場合は本番値になっている
- `flutter build appbundle --release` の成果物を提出する

## 現在の確認済み項目

- Web production build 成功
- Android release APK build 成功
- Android release AAB build 成功
- CI設定にWeb buildとAndroid release APK buildを追加済み
- リリース検証スクリプトを追加済み
- ホームから5階クリア、報酬保存、ホーム帰還までのWidgetテスト成功
- 小画面ホーム、ダンジョン入場、結果画面のWidgetテスト成功
- データ不足時の安全停止テスト成功
- 設定リセット時の音状態復帰テスト成功
- `http://127.0.0.1:8097/` のローカル配信応答確認

## リリース前の手動確認

- Android実機で起動できる
- Android実機でBGM/SEが鳴る
- 設定でサウンドOFFにするとBGM/SEが止まる
- 5階クリア後、結果画面からホームに戻れる
- 戻る操作で完了済みバトルへ戻らない
- 日本語フォントが欠けない
- 320px相当の幅で主要ボタンがはみ出さない

## 未検証・注意

- iOS実ビルドはWindows環境では未検証
- `share_plus` は現時点でビルド成功するが、Kotlin Gradle Plugin移行警告が出る
- Google Play提出には正式なrelease keystoreが必要
