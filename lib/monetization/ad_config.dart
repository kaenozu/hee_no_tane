/// AdMob configuration.
///
/// Production ad IDs are selected only for release builds. Debug, profile,
/// widget tests, and integration tests always use Google official test IDs.
library;

import 'dart:io' show Platform;

class AdConfig {
  const AdConfig._();

  static const androidProductionAppId =
      'ca-app-pub-1121980304554901~6127552891';
  static const androidTestAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const androidProductionBannerId =
      'ca-app-pub-1121980304554901/8311592053';
  static const androidTestBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const iosTestAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const iosTestBannerId = 'ca-app-pub-3940256099942544/2934735716';

  static const isProductionBuild = bool.fromEnvironment('dart.vm.product');

  static bool get supportedPlatform => Platform.isAndroid || Platform.isIOS;

  static String get androidAppId =>
      androidAppIdForBuild(isProduction: isProductionBuild);

  static String androidAppIdForBuild({required bool isProduction}) =>
      isProduction ? androidProductionAppId : androidTestAppId;

  static String androidBannerIdForBuild({required bool isProduction}) =>
      isProduction ? androidProductionBannerId : androidTestBannerId;

  static String get bannerUnitId {
    if (Platform.isAndroid) {
      return androidBannerIdForBuild(isProduction: isProductionBuild);
    }
    return iosTestBannerId;
  }
}
