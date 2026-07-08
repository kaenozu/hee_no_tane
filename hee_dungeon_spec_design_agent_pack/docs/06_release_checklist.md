# 06. リリース前チェックリスト

## 1. v0.1内部確認

- [ ] Androidで起動できる
- [ ] ホーム画面が表示される
- [ ] 今日のダンジョンを開始できる
- [ ] 5問回答できる
- [ ] クリアできる
- [ ] 敗北できる
- [ ] へぇカードが獲得できる
- [ ] 図鑑に反映される
- [ ] アプリ再起動後も保存される
- [ ] データリセットできる
- [ ] `flutter analyze` が通る
- [ ] `flutter test` が通る
- [ ] debug APKが生成できる

## 2. 問題データ確認

- [ ] 全問題にsourceNoteがある
- [ ] 全問題がverified true/falseを持つ
- [ ] verified falseが出題されない
- [ ] answerIndexが0〜3
- [ ] choicesが4件
- [ ] 解説が短く自然
- [ ] 子ども向けに不適切な問題がない

## 3. Google Play公開前に必要な確認

- [ ] target API level要件を満たす
- [ ] パッケージ名を決める
- [ ] アプリアイコンを作る
- [ ] スクリーンショットを作る
- [ ] プライバシーポリシーを用意する
- [ ] ストア説明文を作る
- [ ] 年齢レーティングを確認する
- [ ] 問題データの出典・権利を確認する

Google Playではtarget API level要件が設定されているため、公開前に公式要件の確認が必要。出典: https://support.google.com/googleplay/android-developer/answer/11926878?hl=en

## 4. 広告/課金を入れる前の確認

- [ ] Google Play Billingの対応範囲を確認する
- [ ] 広告SDKのプライバシー要件を確認する
- [ ] 課金商品IDを設計する
- [ ] 復元処理を設計する
- [ ] 子ども向け・ファミリー向け扱いを確認する

Google Play BillingはAndroidアプリ内でデジタル商品やコンテンツを販売するための仕組み。出典: https://developer.android.com/google/play/billing

## 5. iOS展開前に必要な確認

- [ ] App Store Review Guidelinesを確認する
- [ ] IAP/外部リンク/広告/プライバシーの扱いを確認する
- [ ] iOS向けUI崩れを確認する
- [ ] App Tracking Transparencyが必要か確認する

AppleのApp Store Review GuidelinesはSafety、Performance、Business、Design、Legalなどの観点で整理されている。出典: https://developer.apple.com/app-store/review/guidelines/
