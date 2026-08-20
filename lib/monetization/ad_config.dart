/// AdMob configuration.
///
/// Android uses the registered production IDs. iOS remains on Google's
/// official test IDs until a separate iOS AdMob app and banner unit exist.
library;

import 'dart:io' show Platform;

class AdConfig {
  const AdConfig._();

  static const androidAppId = 'ca-app-pub-1121980304554901~6127552891';
  static const iosTestAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const androidBannerId = 'ca-app-pub-1121980304554901/8311592053';
  static const iosTestBannerId = 'ca-app-pub-3940256099942544/2934735716';

  static bool get supportedPlatform => Platform.isAndroid || Platform.isIOS;

  static String get bannerUnitId =>
      Platform.isAndroid ? androidBannerId : iosTestBannerId;
}
