/// AdMob configuration.
///
/// Build-mode contract (single source of truth):
/// - Production IDs are selected ONLY when the Dart AOT product flag
///   (`dart.vm.product`, i.e. `--release` builds) AND the Gradle release task
///   are active. `flutter build appbundle --release` /
///   `flutter build apk --release` satisfy both.
/// - Debug, profile, widget tests, integration tests, and CI always use
///   Google official test IDs.
/// - iOS stays fail-closed on Google official test IDs until a production
///   iOS AdMob app/unit is registered; no build mode can select a
///   production ID on iOS.
///
/// CI validates the merged Android manifest of the debug APK (test ID) and
/// the release AAB (production ID) via `tool/validate_ad_manifest.sh`.
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

  /// True only in Dart product mode (`--release` compiled AOT builds).
  /// Profile and debug modes are intentionally treated as non-production.
  static const bool isProductionBuild = bool.fromEnvironment('dart.vm.product');

  static bool get supportedPlatform => Platform.isAndroid || Platform.isIOS;

  /// App ID declared in `android/app/src/main/AndroidManifest.xml` via the
  /// `adMobAppId` Gradle manifest placeholder. Kept in sync with
  /// `android/app/build.gradle.kts`; both switch on the same release-only
  /// condition.
  static String get androidAppId =>
      androidAppIdForBuild(isProduction: isProductionBuild);

  static String androidAppIdForBuild({required bool isProduction}) =>
      isProduction ? androidProductionAppId : androidTestAppId;

  static String androidBannerIdForBuild({required bool isProduction}) =>
      isProduction ? androidProductionBannerId : androidTestBannerId;

  /// Fail-closed: iOS never returns a production ID because none is
  /// registered; [isProduction] is ignored on iOS by design.
  static String bannerIdFor({
    required bool isAndroid,
    required bool isProduction,
  }) {
    if (!isAndroid) {
      return iosTestBannerId;
    }
    return androidBannerIdForBuild(isProduction: isProduction);
  }

  static String get bannerUnitId => bannerIdFor(
    isAndroid: Platform.isAndroid,
    isProduction: isProductionBuild,
  );
}
