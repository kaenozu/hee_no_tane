/// Legal, privacy, and support information shown inside the app.
library;

import 'package:flutter/material.dart';

class LegalInformationScreen extends StatelessWidget {
  const LegalInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('プライバシーとサポート')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: const [
          _Section(
            title: 'データの取り扱い',
            body:
                'へぇのタネは、クイズの回答状況、獲得カード、閲覧数、連続利用日数、設定を端末内に保存します。現在のバージョンでは、これらの利用データを開発者のサーバーへ送信しません。',
          ),
          _Section(
            title: '外部共有',
            body:
                'カード画像を共有するときだけ、利用者が選択した共有先アプリまたはブラウザ機能へ画像を渡します。共有を実行しない限り、画像が外部へ送られることはありません。共有先でのデータの取り扱いは、そのサービスの規約とプライバシーポリシーに従います。',
          ),
          _Section(
            title: '保存データの削除',
            body:
                '設定画面の「データリセット」から、端末内に保存されたアプリデータを削除できます。アプリをアンインストールした場合も、通常は端末内の保存データが削除されます。',
          ),
          _Section(
            title: 'コンテンツについて',
            body:
                '掲載内容は一般的な知識・娯楽を目的としています。医療、法律、投資などの専門的助言ではありません。誤りを見つけた場合は、ストア掲載ページのサポート窓口からご連絡ください。',
          ),
          _Section(
            title: '免責事項',
            body:
                '正確性の維持に努めていますが、すべての情報の完全性や最新性を保証するものではありません。利用によって生じた損害について、法令で認められる範囲を超えて責任を負うものではありません。',
          ),
          _Section(
            title: '対象年齢',
            body:
                '本アプリは幅広い年齢層が利用できますが、児童向けサービスとして個人情報を収集する設計ではありません。保護者の管理が必要な端末では、端末側の機能をご利用ください。',
          ),
          _Section(
            title: 'アプリ情報',
            body: 'へぇのタネ\nバージョン 1.0.0\n最終更新日 2026年7月12日',
          ),
        ],
      ),
    );
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
