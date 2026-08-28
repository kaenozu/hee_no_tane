import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Coordinates the UMP consent flow before any ad SDK/request is started.
///
/// Consent failures are fail-closed for ads but fail-open for the core app:
/// the app can launch, while ads remain disabled for that session.
class AdConsent {
  AdConsent._();

  @visibleForTesting
  static const consentInfoUpdateTimeout = Duration(seconds: 5);

  static bool _canRequestAds = false;

  static bool get canRequestAds => _canRequestAds;

  /// Whether UMP requires an entry point for changing privacy options.
  ///
  /// Plugin failures deliberately return false so the settings screen never
  /// makes the core app depend on UMP.
  static Future<bool> privacyOptionsRequired() async {
    try {
      return await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  /// Shows the UMP privacy-options form and refreshes the ad-request gate.
  static Future<bool> showPrivacyOptions() async {
    try {
      FormError? formError;
      await ConsentForm.showPrivacyOptionsForm((error) {
        formError = error;
      });
      if (formError != null) return false;
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      return true;
    } catch (_) {
      _canRequestAds = false;
      return false;
    }
  }

  static Future<void> prepare() async {
    _canRequestAds = false;

    final information = ConsentInformation.instance;
    try {
      final updated = await _requestConsentInfoUpdate(information);
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
    return _requestConsentInfoUpdateWithTimeout(
      (onSuccess, onError) => information.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        onSuccess,
        onError,
      ),
    );
  }

  @visibleForTesting
  static Future<bool> requestConsentInfoUpdateForTesting(
    void Function(
      void Function() onSuccess,
      void Function(FormError? error) onError,
    )
    request, {
    Duration timeout = consentInfoUpdateTimeout,
  }) {
    return _requestConsentInfoUpdateWithTimeout(request, timeout: timeout);
  }

  static Future<bool> _requestConsentInfoUpdateWithTimeout(
    void Function(
      void Function() onSuccess,
      void Function(FormError? error) onError,
    )
    request, {
    Duration timeout = consentInfoUpdateTimeout,
  }) {
    final completer = Completer<bool>();
    void complete(bool value) {
      if (!completer.isCompleted) completer.complete(value);
    }

    request(() => complete(true), (error) => complete(false));
    return completer.future.timeout(timeout, onTimeout: () => false);
  }
}
