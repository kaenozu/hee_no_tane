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

  test('iOS stays fail-closed on official test banner ID in every mode', () {
    for (final isProduction in [false, true]) {
      expect(
        AdConfig.bannerIdFor(isAndroid: false, isProduction: isProduction),
        AdConfig.iosTestBannerId,
      );
      expect(
        AdConfig.bannerIdFor(isAndroid: false, isProduction: isProduction),
        isNot(AdConfig.androidProductionBannerId),
      );
    }
  });

  test('Android banner selection follows the build mode only', () {
    expect(
      AdConfig.bannerIdFor(isAndroid: true, isProduction: false),
      AdConfig.androidTestBannerId,
    );
    expect(
      AdConfig.bannerIdFor(isAndroid: true, isProduction: true),
      AdConfig.androidProductionBannerId,
    );
  });

  test('test IDs are the Google official sample units', () {
    const googleMobileAdsTestPrefix = 'ca-app-pub-3940256099942544';
    for (final id in [
      AdConfig.androidTestAppId,
      AdConfig.androidTestBannerId,
      AdConfig.iosTestAppId,
      AdConfig.iosTestBannerId,
    ]) {
      expect(id, startsWith(googleMobileAdsTestPrefix));
    }
  });
}
