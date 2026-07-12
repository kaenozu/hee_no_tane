# リリースチェックリスト

正式配布では、コードのCI成功だけでなく、署名済み成果物・実機確認・ストア情報・コンテンツ確認をすべて完了する。

## 1. コードとコンテンツ

- [ ] `dart run tool/validate_content.dart` が成功
- [ ] `dart format --output=none --set-exit-if-changed lib test tool` が成功
- [ ] `flutter analyze` が成功
- [ ] `flutter test` が成功
- [ ] `flutter build web --release --no-web-resources-cdn` が成功
- [ ] `flutter build apk --debug` が成功
- [ ] CIのiOS署名なしrelease buildが成功
- [ ] 公開対象の全問題・全カードを人手で確認
- [ ] 問題文、正解、解説、カード本文が同じ主張をしている
- [ ] 数値や「世界一」「日本一」などの表現に確認日と根拠がある
- [ ] 出典名が曖昧でなく、編集者が原資料へ戻れる
- [ ] 医療・法律・投資に関する断定的助言がない

## 2. Android

- [ ] Application ID `com.heenotane.hee_no_tane_app`を最終確認
- [ ] upload keystoreを作成し、安全な場所へバックアップ
- [ ] GitHub Actions secretsを登録
- [ ] `Build release artifacts`から署名済みAABを生成
- [ ] Play Consoleの内部テストへAABをアップロード
- [ ] Play App Signingを設定
- [ ] 内部テスト版を実機へインストール
- [ ] 新規インストール、更新、アンインストールを確認
- [ ] システムバックと画面回転を確認
- [ ] 小型端末と大画面端末で文字切れがない
- [ ] LINE、X、Google Drive等へのPNG共有を確認
- [ ] 共有キャンセルと連打で異常がない

## 3. iOS / iPadOS

- [ ] Bundle ID `com.heenotane.heeNoTaneApp`を最終確認
- [ ] Apple Developer ProgramのTeamと証明書を設定
- [ ] App Store Connectへアプリを登録
- [ ] Archiveを作成しValidate Appを通過
- [ ] TestFlightへアップロード
- [ ] iPhone実機で新規起動、回答、保存、図鑑を確認
- [ ] iOSのスワイプバック中に保存状態が壊れない
- [ ] iPadの共有ポップオーバー位置が正常
- [ ] 共有キャンセルや画面閉鎖中にクラッシュしない

## 4. Web

- [ ] release workflowのWeb artifactを公開環境へ配置
- [ ] HTTPSで配信
- [ ] `/privacy.html`が公開されている
- [ ] `/support.html`が公開されている
- [ ] Chrome、Safari、Edgeで起動
- [ ] リロード後もアプリが開く
- [ ] Web Share API対応ブラウザで共有
- [ ] 非対応ブラウザでPNGダウンロード
- [ ] PWAインストール後の名称とアイコンを確認

## 5. ストア情報

- [ ] アプリ名を全プラットフォームで「へぇのタネ」に統一
- [ ] 説明文、短い説明、カテゴリ、年齢区分を登録
- [ ] スマートフォン用スクリーンショットを作成
- [ ] iPad対応を維持する場合はiPad用素材を作成
- [ ] プライバシーポリシーURLを登録
- [ ] サポートURLを登録
- [ ] 開発者連絡先を登録
- [ ] Data safety / App Privacy回答を実装と照合
- [ ] 広告なし、アカウントなし、課金なしの説明が一致

## 6. リリース判定

以下のいずれかが残る場合は一般公開しない。

- P0/P1の再現可能なクラッシュ
- 保存データ消失または古いデータによる上書き
- 正解が誤っている問題
- 共有画像に本文の欠落・文字化けがある
- プライバシー申告と実装が一致しない
- 署名鍵のバックアップがない

すべて完了後、内部テスト → クローズドテスト → 段階公開の順に進める。
