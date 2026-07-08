# へぇの種 - ドキュメント一式

作成日: 2026-07-07

## 概要

「へぇの種」は、毎日3枚の短い知識カードを読むことで、ちょっとした知識欲を満たす知的暇つぶしアプリです。学習管理アプリではなく、SNSや動画の代わりに1分で読める「へぇ」を提供する体験を中心に設計しています。

## ZIP内の構成

```text
hee_no_tane/
├─ docs/
│  ├─ 01_企画書.md
│  ├─ 02_要件定義_仕様書.md
│  ├─ 03_システム設計書.md
│  ├─ 04_AI_コンテンツ_ファクトチェック設計.md
│  ├─ 05_MVP開発計画_バックログ.md
│  ├─ 06_収益化_KPI_リスク.md
│  ├─ 07_画面ワイヤー_コピー.md
│  └─ 08_出典_調査メモ.md
├─ sample/
│  ├─ db_schema.sql
│  ├─ api_contract_openapi.yaml
│  └─ sample_cards.json
├─ prompts/
│  └─ content_generation_prompts.md
├─ diagrams/
│  ├─ architecture.mmd
│  └─ content_pipeline.mmd
└─ へぇの種_仕様設計書.docx
```

## 今回の前提

### 確認できた事実

- 短時間・小単位で学ぶ microlearning は、短い学習コンテンツを集中的に届ける手法として説明されている。
- Duolingo は Q1 2026 の株主向け資料で DAU 5,650万人、課金ユーザー 1,250万人を公表している。これは「短時間学習 + 習慣化 + ゲーム性」が大規模に成立しうる参考事例であり、このアプリの成功を保証するものではない。
- Wikimedia Analytics API には、ページビューや「よく見られたページ」等を取得する公式エンドポイントがある。
- Wikimedia API 利用時は User-Agent を設定し、過剰な並列アクセスを避ける必要がある。
- Google Play は Data safety section の記入を開発者に求め、Apple は App Review Guidelines で UGC や課金等の要件を定めている。

### 確認できない情報

- 日本国内で「知的暇つぶし」専用アプリにどの程度の課金需要があるか。
- 月額300〜500円のサブスクが成立するか。
- AI生成 + 人手承認で、十分なコンテンツ量と品質を低コストで維持できるか。

### 推測

- 最初から高額サブスクではなく、無料 + 広告 + 低価格プレミアム、または買い切り知識パックの方が受け入れられやすい。
- 「学習」「教養」よりも「へぇ」「散歩」「つまみ読み」のような軽い見せ方の方が継続率が出やすい。

## 参照情報

- **Duolingo Q1 2026 Shareholder Letter**  
  URL: https://investors.duolingo.com/static-files/aab30d54-eb91-422e-b365-c03859fea85c  
  用途: Q1 2026 metrics: DAUs 56.5M, paid subscribers 12.5M, both +21% YoY. Used only as evidence that short-session gamified learning can scale, not as proof this app will scale.
- **Wikimedia Analytics API**  
  URL: https://doc.wikimedia.org/generated-data-platform/aqs/analytics-api/  
  用途: Official documentation for page views, most-viewed / most-edited pages, and related Wikimedia analytics endpoints.
- **Wikimedia Analytics API - Page view analytics**  
  URL: https://doc.wikimedia.org/generated-data-platform/aqs/analytics-api/reference/page-views.html  
  用途: Page view analytics endpoints provide page-view data for Wikimedia projects, with data available from July 1, 2015.
- **Wikimedia API Etiquette**  
  URL: https://www.mediawiki.org/wiki/API:Etiquette  
  用途: Requires informative User-Agent and recommends considerate, serial requests.
- **Wikimedia Analytics API Access Policy**  
  URL: https://doc.wikimedia.org/generated-data-platform/aqs/analytics-api/documentation/access-policy.html  
  用途: User-Agent header is required; clients without User-Agent may be blocked.
- **Wikimedia Foundation Terms of Use**  
  URL: https://foundation.wikimedia.org/wiki/Policy:Terms_of_Use  
  用途: Wikimedia content is provided under free/open licenses; content is informational and not professional advice.
- **Creative Commons BY-SA 3.0 Deed**  
  URL: https://creativecommons.org/licenses/by-sa/3.0/deed.en  
  用途: Attribution and ShareAlike obligations when reusing/remixing licensed material.
- **Google Play Data safety section**  
  URL: https://support.google.com/googleplay/android-developer/answer/10787469?hl=en  
  用途: Developers must disclose how apps collect, share, and protect user data in Play Console.
- **Google Play User Data policy**  
  URL: https://support.google.com/googleplay/android-developer/answer/10144311?hl=en  
  用途: Data safety labels must be accurate, up to date, and consistent with the privacy policy.
- **Apple App Review Guidelines**  
  URL: https://developer.apple.com/app-store/review/guidelines/  
  用途: Guidelines cover user-generated content moderation, purchases, and review requirements.
- **ATD - What Is Microlearning?**  
  URL: https://www.td.org/talent-development-glossary-terms/what-is-microlearning  
  用途: Microlearning is focused, bite-sized learning content in short bursts.
- **OpenAI API Pricing**  
  URL: https://developers.openai.com/api/docs/pricing  
  用途: Current pricing reference as of document creation; costs must be rechecked before implementation.
