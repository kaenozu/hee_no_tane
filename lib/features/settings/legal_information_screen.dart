/// Legal, privacy, and support information shown inside the app.
library;

import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/core/app_version_info.dart';

enum LegalInformationSection { privacyPolicy, support, version }

class LegalInformationScreen extends StatelessWidget {
  final LegalInformationSection initialSection;
  final AppVersionInfo versionInfo;

  const LegalInformationScreen({
    super.key,
    this.initialSection = LegalInformationSection.privacyPolicy,
    this.versionInfo = const AppVersionInfo.unavailable(),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: _titleForSection(initialSection)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: _sectionsForType(initialSection),
      ),
    );
  }

  Text _titleForSection(LegalInformationSection section) {
    return switch (section) {
      LegalInformationSection.privacyPolicy => const Text('プライバシーポリシー'),
      LegalInformationSection.support => const Text('サポート'),
      LegalInformationSection.version => const Text('バージョン情報'),
    };
  }

  List<Widget> _sectionsForType(LegalInformationSection section) {
    return switch (section) {
      LegalInformationSection.privacyPolicy => _privacyPolicySections(),
      LegalInformationSection.support => _supportSections(),
      LegalInformationSection.version => _versionSections(),
    };
  }

  List<Widget> _privacyPolicySections() => const [
    _Section(
      title: '収集する情報',
      body:
          'へぇのタネは、クイズの回答状況、獲得カード、閲覧数、連続利用日数、設定を端末内に保存します。'
          'これらの利用データは開発者のサーバーへ送信しません。'
          'また、本アプリでは広告表示のためにGoogle AdMobを使用しており、'
          '広告の表示・タップ時にデバイス情報（デバイスモデル、OSバージョン、画面サイズなど）および'
          '広告識別子がGoogleへ送信されます。詳細はGoogleのプライバシーポリシーをご確認ください。',
    ),
    _Section(
      title: '外部共有',
      body:
          'カード画像を共有するときだけ、利用者が選択した共有先アプリまたはブラウザ機能へ画像を渡します。'
          '共有を実行しない限り、画像が外部へ送られることはありません。'
          '共有先でのデータの取り扱いは、そのサービスの規約とプライバシーポリシーに従います。',
    ),
    _Section(
      title: '第三者提供',
      body:
          '法令に基づく場合を除き、個人情報を第三者に提供することはありません。'
          'ただし、広告配信のためにGoogle（Google LLC）へデバイス情報および広告識別子が送信されます。'
          'Googleがこれらの情報を取り扱う方法については、Googleのプライバシーポリシーをご確認ください。',
    ),
    _Section(
      title: '保存期間と削除',
      body:
          'データは端末内に保存されます。設定画面の「データリセット」から、端末内に保存されたアプリデータを削除できます。'
          'アプリをアンインストールした場合も、通常は端末内の保存データが削除されます。',
    ),
  ];

  List<Widget> _supportSections() => const [
    _Section(
      title: 'お問い合わせ',
      body:
          '不具合報告やご要望は、ストア掲載ページの開発者連絡先からお知らせください。'
          '返信には時間がかかる場合があります。',
    ),
    _Section(
      title: '不具合報告時にご協力ください',
      body:
          '- 発生した操作手順\n'
          '- 使用している端末名とOSバージョン\n'
          '- 画面のスクリーンショット（可能であれば）',
    ),
    _Section(
      title: 'コンテンツについて',
      body:
          '掲載内容は一般的な知識・娯楽を目的としています。医療、法律、投資などの専門的助言ではありません。'
          '誤りを見つけた場合は、上記のお問い合わせからご連絡ください。',
    ),
    _Section(
      title: '免責事項',
      body:
          '正確性の維持に努めていますが、すべての情報の完全性や最新性を保証するものではありません。'
          '利用によって生じた損害について、法令で認められる範囲を超えて責任を負うものではありません。',
    ),
  ];

  List<Widget> _versionSections() {
    final versionLabel = versionInfo.isAvailable
        ? versionInfo.displayValue
        : '取得できません';
    final featureTitle = versionInfo.version.isEmpty
        ? '主な機能'
        : 'v${versionInfo.version}の機能';

    return [
      _Section(title: 'アプリ情報', body: 'へぇのタネ\nバージョン $versionLabel'),
      _Section(
        title: featureTitle,
        body:
            '- 1日1問の日替わりクイズ\n'
            '- 解説と知識カードの獲得\n'
            '- カード図鑑・共有・統計\n'
            '- 端末内保存、テーマ設定\n'
            '- Android、iOS、Web対応',
      ),
      const _Section(
        title: '含まれない機能',
        body:
            '- 課金\n'
            '- アカウント・ログイン\n'
            '- クラウド同期\n'
            '- プッシュ通知',
      ),
      const _Section(
        title: '対象年齢',
        body:
            '本アプリは幅広い年齢層が利用できますが、児童向けサービスとして個人情報を収集する設計ではありません。'
            '保護者の管理が必要な端末では、端末側の機能をご利用ください。',
      ),
    ];
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
