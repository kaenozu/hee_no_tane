import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Coordinates the UMP consent flow before any ad SDK/request is started.
///
/// Consent failures are fail-closed for ads but fail-open for the core app:
/// the app can launch, while ads remain disabled for that session.
class AdConsent {
  AdConsent._();

  static bool _canRequestAds = false;

  static bool get canRequestAds => _canRequestAds;

  static Future<void> prepare() async {
    _canRequestAds = false;

    final information = ConsentInformation.instance;
    try {
      final updated = await _requestConsentInfoUpdate(
        information,
      ).timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (!updated) return;
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) {
          _canRequestAds = false;
        }
      });
      _canRequestAds = await information.canRequestAds();
    } catch (_) {
      // Consent/network/platform failures must not block the core app.
      _canRequestAds = false;
    }
  }

  static Future<bool> _requestConsentInfoUpdate(
    ConsentInformation information,
  ) {
    final completer = Completer<bool>();
    information.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => completer.complete(true),
      (_) => completer.complete(false),
    );
    return completer.future;
  }
}
