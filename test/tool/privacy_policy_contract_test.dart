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
      expect(policy, isNot(contains('広告SDK、利用分析SDK、クラッシュ収集SDKを組み込んでいません')));
    },
  );
}
