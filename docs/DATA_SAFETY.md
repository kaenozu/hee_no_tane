# Data safety / App Privacy 回答案

この文書は現在の実装を基準とした申告案。ストア提出直前に依存関係とコードを再確認する。

## 現在の実装

- アカウント登録なし
- 広告SDKなし
- 分析SDKなし
- クラッシュレポートSDKなし
- 外部バックエンドなし
- 位置情報、カメラ、マイク、連絡先を使用しない
- 進行状況は端末内の`SharedPreferences`へ保存
- ユーザー操作によるPNG共有のみ外部アプリまたはブラウザへ渡す

## Google Play Data safety 回答案

### データの収集

原則として「データを収集しない」。

端末内だけで処理し、開発者または第三者のサーバーへ送信しない以下のデータは、現在の実装では外部収集に該当しない想定。

- 回答日
- 連続日数
- 獲得カードID
- 閲覧回数
- テーマ設定
- オンボーディング完了状態

### データの共有

原則として「データを第三者と共有しない」。

カード画像共有はユーザーが明示的に開始し、OSまたはブラウザの共有先選択を通じてユーザーが指定した相手へ渡す機能。ストアフォームの定義変更がないか提出時に再確認する。

### セキュリティ

- 外部送信なし
- アプリ内のデータリセットあり
- 通信経路の暗号化は外部通信を追加した場合に再評価

## Apple App Privacy 回答案

現在の実装では、開発者がユーザーデータを収集しないため「Data Not Collected」を基本案とする。

次を追加した時点で回答を更新する。

- Firebase Analytics / PostHog等の分析
- Crashlytics / Sentry等のクラッシュ収集
- 広告SDK
- アカウントまたはクラウド同期
- 問い合わせフォーム
- リモートコンテンツAPI

## 提出直前の確認コマンド

```bash
rg -n "firebase|analytics|crashlytics|sentry|posthog|amplitude|admob|facebook" pubspec.yaml pubspec.lock lib android ios
rg -n "http://|https://" lib
```

検索結果があれば、実際の送信内容、目的、保持期間、第三者共有を確認して申告を更新する。

## 整合性チェック

次の3箇所は同じ内容でなければならない。

1. アプリ内プライバシーポリシー
2. `web/privacy.html`
3. Google Play Data safety / Apple App Privacy

変更日とアプリバージョンをリリース記録へ残す。
