import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/monetization/ad_config.dart';

void main() {
  test('uses Google test identifiers until production IDs are recorded', () {
    expect(AdConfig.androidTestAppId, 'ca-app-pub-3940256099942544~3347511713');
    expect(
      AdConfig.androidTestBannerId,
      'ca-app-pub-3940256099942544/6300978111',
    );
    expect(AdConfig.iosTestAppId, 'ca-app-pub-3940256099942544~1458002511');
    expect(AdConfig.iosTestBannerId, 'ca-app-pub-3940256099942544/2934735716');
  });
}
