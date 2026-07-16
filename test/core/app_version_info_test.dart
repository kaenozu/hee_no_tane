import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/core/app_version_info.dart';

void main() {
  test('parses and formats validated app version metadata', () {
    final info = AppVersionInfo.fromJson(const <String, dynamic>{
      'version': '1.2.3',
      'buildNumber': '45',
    });

    expect(info.isAvailable, isTrue);
    expect(info.displayValue, '1.2.3 (45)');
    expect(info.settingsSubtitle, 'へぇのタネ v1.2.3 (45)');
  });

  test('rejects incomplete app version metadata', () {
    expect(
      () => AppVersionInfo.fromJson(const <String, dynamic>{
        'version': '1.2.3',
      }),
      throwsFormatException,
    );
  });
}
