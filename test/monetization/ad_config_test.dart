import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/monetization/ad_config.dart';

void main() {
  test('debug and test builds use official Android test IDs', () {
    expect(
      AdConfig.androidAppIdForBuild(isProduction: false),
      AdConfig.androidTestAppId,
    );
    expect(
      AdConfig.androidBannerIdForBuild(isProduction: false),
      AdConfig.androidTestBannerId,
    );
  });

  test('release builds use registered Android production IDs', () {
    expect(
      AdConfig.androidAppIdForBuild(isProduction: true),
      AdConfig.androidProductionAppId,
    );
    expect(
      AdConfig.androidBannerIdForBuild(isProduction: true),
      AdConfig.androidProductionBannerId,
    );
  });

  test('production and test IDs cannot be accidentally mixed', () {
    expect(
      AdConfig.androidAppIdForBuild(isProduction: false),
      isNot(AdConfig.androidProductionAppId),
    );
    expect(
      AdConfig.androidBannerIdForBuild(isProduction: false),
      isNot(AdConfig.androidProductionBannerId),
    );
  });
}
