/// lib/features/settings/legal_screen.dart
///
/// プライバシーポリシーとサポート情報をアプリ内で表示する。
library;

import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DocumentScreen(
      title: 'プライバシーポリシー',
      intro: '最終更新日: 2026年7月12日',
      sections: [
        _DocumentSection(
          heading: '保存する情報',
          body:
              'へぇのタネは、獲得したカード、回答日、連続日数、閲覧回数、テーマ設定、オンボーディング完了状態を端末内に保存します。アカウント登録はありません。',
        ),
        _DocumentSection(
          heading: '外部への送信',
          body:
              'アプリは、利用状況の分析、広告配信、個人識別を目的としたデータ送信を行いません。カード共有を利用した場合のみ、ユーザーが選んだ共有先へ生成画像がOSの共有機能を通じて渡されます。',
        ),
        _DocumentSection(
          heading: '端末権限',
          body:
              'カメラ、位置情報、連絡先、マイク、写真ライブラリへの常時アクセスは要求しません。共有先アプリ側で追加の権限が必要になる場合があります。',
        ),
        _DocumentSection(
          heading: 'データの削除',
          body:
              '設定画面の「データリセット」で端末内データを削除できます。アプリをアンインストールした場合も、通常はOSによってアプリのローカルデータが削除されます。',
        ),
        _DocumentSection(
          heading: '外部サービス',
          body:
              '共有先や外部リンクを開いた後の情報取扱いは、それぞれのサービスのプライバシーポリシーに従います。',
        ),
        _DocumentSection(
          heading: '変更と問い合わせ',
          body:
              '内容を変更する場合は、アプリ内または配布ページで更新日を案内します。問い合わせは、配布ストアに表示される開発者連絡先をご利用ください。',
        ),
      ],
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DocumentScreen(
      title: 'サポート',
      intro: '不具合報告の前に、以下を確認してください。',
      sections: [
        _DocumentSection(
          heading: '起動できない・データを読めない',
          body:
              '起動画面またはエラー画面の「再試行」をお試しください。保存データの破損が表示された場合は、内容を確認したうえで初期化できます。初期化すると進行状況は元に戻せません。',
        ),
        _DocumentSection(
          heading: '今日の1問が変わらない',
          body:
              '問題は端末の日付を基準に1日1回更新されます。端末の日時設定が自動になっているか確認してください。',
        ),
        _DocumentSection(
          heading: '共有できない',
          body:
              '共有先アプリがインストールされているか確認してください。Web版ではブラウザによって共有ではなくPNGのダウンロードになる場合があります。',
        ),
        _DocumentSection(
          heading: '報告に含めてほしい情報',
          body:
              '端末名、OSバージョン、アプリのバージョン、発生までの操作、表示されたメッセージ、可能であればスクリーンショットを添えてください。',
        ),
        _DocumentSection(
          heading: '問い合わせ先',
          body:
              '配布ストアに表示される開発者連絡先からお問い合わせください。クイズ内容の誤りは、問題文と正しい根拠が分かる資料名を添えてください。',
        ),
      ],
    );
  }
}

class _DocumentScreen extends StatelessWidget {
  final String title;
  final String intro;
  final List<_DocumentSection> sections;

  const _DocumentScreen({
    required this.title,
    required this.intro,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Text(intro, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          for (final section in sections) ...[
            Text(
              section.heading,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(section.body, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _DocumentSection {
  final String heading;
  final String body;

  const _DocumentSection({required this.heading, required this.body});
}
