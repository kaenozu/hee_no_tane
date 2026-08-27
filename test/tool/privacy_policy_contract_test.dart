import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'public privacy policy discloses the implemented AdMob and consent flow',
    () {
      final policy = File('web/privacy.html').readAsStringSync();

      expect(policy, contains('Google AdMob'));
      expect(policy, contains('広告識別子'));
      expect(policy, contains('デバイス情報'));
      expect(policy, contains('同意'));
      expect(policy, contains('Google LLC'));
      expect(policy, contains('プライバシー設定の案内'));

      final repositoryPolicy = File(
        'docs/privacy_policy.md',
      ).readAsStringSync();
      expect(repositoryPolicy, contains('Google AdMob'));
      expect(repositoryPolicy, contains('Google UMP'));
      expect(
        repositoryPolicy,
        isNot(
          contains('広告配信SDK、アクセス解析SDKおよび利用者データを外部へ送信するクラッシュ解析SDKを使用していません'),
        ),
      );

      final dataSafety = File(
        'docs/store/google-play-data-safety.md',
      ).readAsStringSync();
      expect(dataSafety, contains('Google AdMob'));
      expect(dataSafety, contains('広告目的でデータを使用しますか | **はい'));
      expect(dataSafety, isNot(contains('広告ID、端末ID、独自利用者IDなし')));

      final support = File('docs/store/support-page-ja.md').readAsStringSync();
      expect(support, contains('Google AdMob'));
      expect(support, isNot(contains('広告、アプリ内課金、サブスクリプションはありません')));
    },
  );
}
