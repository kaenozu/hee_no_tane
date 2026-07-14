# へぇのタネ リリース欠陥報告

> このテンプレートをGitHub Issueまたはレビュー文書へコピーして使用する。

## タイトル

`[P?][Platform] 短い症状 - 画面/機能`

例:

```text
[P1][iPad] カード共有時にクラッシュする - カード詳細
```

## 1. 基本情報

| 項目 | 記入内容 |
|---|---|
| Defect ID |  |
| 発見日 | YYYY-MM-DD |
| 報告者 |  |
| Repository | `kaenozu/hee_no_tane` |
| Branch / Tag |  |
| Commit SHA |  |
| App version |  |
| Build number |  |
| Related test case | 例: `SHARE-001` |
| Platform | Android / iPhone / iPad / Web |
| Status | Open / In Progress / Fixed / Retest / Verified / Won't Fix |
| Severity | P0 / P1 / P2 / P3 |
| Frequency | Always / Often / Sometimes / Once |

## 2. 概要

1〜3文で、どの環境で何をすると何が起きるかを書く。


## 3. 重要度

### 選択した重要度

- [ ] P0
- [ ] P1
- [ ] P2
- [ ] P3

### 判定基準

| 重要度 | 基準 | リリース判断 |
|---|---|---|
| P0 | データ破壊、重大なセキュリティ/プライバシー問題、全端末で起動不能、法令・ストアポリシー重大違反 | 即時公開停止 |
| P1 | 主要フロー不能、再現性の高いクラッシュ、保存消失、回答・正答・カードの重大誤表示、配布不能 | 修正・再検証まで公開不可 |
| P2 | 回避可能な機能不良、特定端末/ブラウザの共有・表示・アクセシビリティ問題 | 原則修正。残す場合は承認必要 |
| P3 | 軽微な表示、文言、操作性、低頻度で影響の小さい問題 | リスク受容可能だが記録する |

### 重要度の理由

- 影響する主要機能:
- 影響する利用者/環境の範囲:
- データ損失の有無:
- セキュリティ/プライバシー影響:
- ストア審査への影響:
- 回避策の有無:

## 4. 環境

### 端末/OS

| 項目 | 記入内容 |
|---|---|
| Device |  |
| OS / Browser |  |
| OS / Browser version |  |
| Screen size / viewport |  |
| Orientation | Portrait / Landscape |
| Text size / Dynamic Type |  |
| Screen reader | None / TalkBack / VoiceOver |
| Input | Touch / Mouse / Keyboard |
| Locale |  |
| Time zone |  |
| Local date/time |  |
| Network | Wi-Fi / Mobile / Offline |
| Install path | Play internal / TestFlight / Web URL / Other |

### アプリ状態

| 項目 | 記入内容 |
|---|---|
| Clean install / Upgrade |  |
| Onboarding completed | Yes / No |
| Today answered | Yes / No |
| Question ID / text |  |
| Card ID / title |  |
| Owned card count |  |
| Total play count |  |
| Streak days |  |
| Theme | System / Light / Dark |

## 5. 事前条件

1. 
2. 

## 6. 再現手順

最小手順を番号付きで記載する。

1. 
2. 
3. 

## 7. 期待結果


## 8. 実際の結果

エラーメッセージは画面に表示された文字を正確に記録する。個人情報や秘密情報は除外する。


## 9. 再現性

| 試行 | 結果 | 備考 |
|---:|---|---|
| 1 | Reproduced / Not reproduced |  |
| 2 | Reproduced / Not reproduced |  |
| 3 | Reproduced / Not reproduced |  |

再現率: `__/__`

## 10. 影響範囲

- [ ] Androidのみ
- [ ] iPhoneのみ
- [ ] iPadのみ
- [ ] Webのみ
- [ ] 複数プラットフォーム
- [ ] 全プラットフォーム
- [ ] 特定OSバージョン
- [ ] 特定画面サイズ
- [ ] 大きな文字のみ
- [ ] スクリーンリーダーのみ
- [ ] オフラインのみ
- [ ] アップグレードのみ
- [ ] クリーンインストールのみ

詳細:


## 11. データ・プライバシー確認

| 確認項目 | Yes / No / Unknown | 詳細 |
|---|---|---|
| 保存データが失われた |  |  |
| 保存データが重複・破損した |  |  |
| 別問題/カードを回答済み表示した |  |  |
| 意図しない権限を要求した |  |  |
| 意図しない外部通信が発生した |  |  |
| 個人情報または内部情報が表示/共有された |  |  |
| ストア開示との不整合が生じる |  |  |
| コンテンツの正答・出典・画像に誤りがある |  |  |

`Yes`または`Unknown`がある場合、P0/P1の可能性を再評価する。

## 12. 証跡

- Screenshot:
- Screen recording:
- Console/log:
- Play Console/App Store Connect:
- Network capture/privacy report:
- Related PR/Issue:

証跡から次を削除またはマスクする。

- Apple ID、Googleアカウント
- メールアドレス、氏名
- 通知内容
- 共有先の私的な投稿・ファイル
- 署名鍵、トークン、秘密情報

## 13. ログ

関連する最小限のログを貼る。秘密情報を含む完全ログは公開Issueへ貼らない。

```text
paste sanitized logs here
```

## 14. 初期分析

### 確認できた事実

- 

### 未確認

- 

### 推測される原因

- 

推測は事実と分離し、根拠となるファイル、コード行、ログまたは再現条件を書く。

## 15. 回避策

- 回避策あり / なし:
- 利用者が実行可能か:
- データ損失を防げるか:
- ストア説明またはサポート案内が必要か:

## 16. 修正方針

- 対象ファイル/コンポーネント:
- 変更概要:
- データ移行の要否:
- プライバシー/ストア申告更新の要否:
- コンテンツ再承認の要否:
- 自動テスト追加:
- 実機回帰ケース:

## 17. 修正情報

| 項目 | 記入内容 |
|---|---|
| Fix PR |  |
| Fix commit SHA |  |
| Fixed version/build |  |
| Unit/widget test |  |
| CI run |  |
| Reviewer |  |

## 18. 再テスト

| 項目 | 記入内容 |
|---|---|
| Retest date |  |
| Tester |  |
| Device/OS |  |
| Build |  |
| Original case result | Pass / Fail |
| Regression cases |  |
| Evidence |  |

### 再テスト手順

1. 元の再現手順を実行する。
2. 修正対象ケースを実行する。
3. 主要回帰として、問題回答、保存復元、共有、リセットのうち影響範囲を実行する。
4. 別プラットフォームまたは別端末への副作用を確認する。

### 再テスト結果


## 19. 最終処理

- [ ] Verified: 修正を対象Releaseビルドで確認した
- [ ] Accepted risk: 影響、回避策、公開判断を承認した
- [ ] Duplicate: 重複先を記録した
- [ ] Won't Fix: 理由と将来条件を記録した
- [ ] Cannot Reproduce: 実施環境と試行回数を記録した

最終コメント:


## 20. 承認

| 役割 | 氏名 | 日付 | 判定 | コメント |
|---|---|---|---|---|
| 修正担当 |  |  |  |  |
| 再テスト担当 |  |  |  |  |
| リリース判断 |  |  |  |  |
