# Android v1.0 RC1 運用基準

最終更新日: 2026年7月17日

この文書をAndroid v1.0の公開判断に使用する。`docs/10_リリースチェックリスト.md`にあるiPhone、iPad、Webの項目は別マイルストーンであり、Android v1.0のブロッカーにはしない。

## 対象

- 公開対象は承認済み47ペア
- 未承認56ペアはv1.1以降へ延期
- PR #44の意味整合性修正とレビューゲートをmasterへ統合
- 公開47カードの最終画像だけをRC1へ含める

## コード・コンテンツ固定

- [ ] PR #44がsquash merge済み
- [ ] `playableQuestionCount`が47
- [ ] 意味レビュー台帳が47件あり、bundle hashと一致
- [ ] 未承認56ペアがランタイムへ入っていない
- [ ] 最終画像必須のrelease-readinessが成功
- [ ] Flutter、Content、Security、iOS Compile CIが成功

## 本番署名

- [ ] upload keystoreを安全なローカル環境で作成
- [ ] keystoreとパスワードをGitへコミットしない
- [ ] `android/app/keystore.properties.example`からローカル設定を作成
- [ ] 本番署名でAABを生成
- [ ] applicationId、versionName、versionCodeを確認
- [ ] AABと署名証明書のSHA-256を記録

## Play内部テスト

- [ ] 署名済みAABを内部テストへ登録
- [ ] Pre-launch reportを確認
- [ ] Data safetyと実装を一致させる
- [ ] コンテンツレーティングと対象年齢を確定
- [ ] テスター端末へインストール

## Android実機

- [ ] 初回起動、オンボーディング、回答、解説、カード獲得
- [ ] 再起動後の進捗復元
- [ ] 日付変更時の問題更新と古い回答の保存拒否
- [ ] 保存失敗後の再試行と二重加算防止
- [ ] 図鑑、カード詳細、出典リンク
- [ ] PNG共有、共有キャンセル、連打防止
- [ ] データ初期化、オフライン、ダークモード
- [ ] 小型画面、大きな文字、システムバック、アプリ復帰

## ストア

- [ ] プライバシーポリシーの公開HTTPS URL
- [ ] 有効なサポート窓口
- [ ] アイコン、feature graphic、Androidスクリーンショット
- [ ] 短い説明、詳細説明、リリースノート
- [ ] Data safety、年齢区分、ストア説明の整合性

## 公開条件

次をすべて満たすまで一般公開しない。

- RC1のcommit SHAとAAB SHA-256が固定されている
- 自動検証が全件成功している
- Play内部テストでAABが受理されている
- Android実機の必須フローが成功している
- 公開47ペアの内容、出典、画像に未確認点がない
- P0/P1の既知クラッシュ、データ損失、進捗破損が0件

## 別マイルストーン

- App Store Connect、TestFlight、iPhone、iPad
- Web本番ホスティングとブラウザ互換性
- 未承認56ペアの追加公開
