import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_consent.dart';

class HeeAdBanner extends StatefulWidget {
  const HeeAdBanner({super.key});

  @override
  State<HeeAdBanner> createState() => _HeeAdBannerState();
}

class _HeeAdBannerState extends State<HeeAdBanner> {
  static const int _maxLoadAttempts = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);

  BannerAd? _bannerAd;
  bool _loaded = false;
  int _loadAttempts = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    AdConsent.canRequestAdsListenable.addListener(_handleConsentChanged);
    if (!kIsWeb && AdConfig.supportedPlatform && AdConsent.canRequestAds) {
      _loadAd();
    }
  }

  void _handleConsentChanged() {
    if (!mounted || kIsWeb || !AdConfig.supportedPlatform) return;
    if (!AdConsent.canRequestAds) {
      _retryTimer?.cancel();
      _retryTimer = null;
      final ad = _bannerAd;
      _bannerAd = null;
      ad?.dispose();
      if (_loaded) {
        setState(() => _loaded = false);
      }
      return;
    }

    if (!_loaded && _bannerAd == null) {
      _loadAttempts = 0;
      _loadAd();
    }
  }

  void _loadAd() {
    if (!AdConsent.canRequestAds) return;
    if (_loadAttempts >= _maxLoadAttempts) return;
    if (_bannerAd != null) return;
    _loadAttempts += 1;

    late final BannerAd ad;
    ad = BannerAd(
      adUnitId: AdConfig.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loadedAd) {
          if (!mounted) {
            loadedAd.dispose();
            return;
          }
          if (!AdConsent.canRequestAds) {
            loadedAd.dispose();
            return;
          }
          if (!identical(_bannerAd, loadedAd)) {
            loadedAd.dispose();
            return;
          }
          setState(() {
            _loaded = true;
          });
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          if (identical(_bannerAd, failedAd)) {
            _bannerAd = null;
          }
          if (!mounted) return;
          if (!AdConsent.canRequestAds) return;
          if (_loadAttempts >= _maxLoadAttempts) return;
          _retryTimer = Timer(_baseRetryDelay * (1 << (_loadAttempts - 1)), () {
            _retryTimer = null;
            if (!mounted) return;
            if (_loaded) return;
            if (!AdConsent.canRequestAds) return;
            if (_bannerAd != null) return;
            _loadAd();
          });
        },
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    AdConsent.canRequestAdsListenable.removeListener(_handleConsentChanged);
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _bannerAd == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
