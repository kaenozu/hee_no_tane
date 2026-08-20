/// AdMob configuration.
///
/// The IDs below are Google's official test IDs. Replace them with the
/// registered production IDs before a monetized release; never use a real
/// production ad unit while developing or running widget tests.
library;

import 'dart:io' show Platform;

class AdConfig {
  const AdConfig._();

  static const androidTestAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosTestAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const androidTestBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const iosTestBannerId = 'ca-app-pub-3940256099942544/2934735716';

  static bool get supportedPlatform => Platform.isAndroid || Platform.isIOS;

  static String get bannerUnitId =>
      Platform.isAndroid ? androidTestBannerId : iosTestBannerId;
}
