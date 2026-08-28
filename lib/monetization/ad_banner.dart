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
    if (!kIsWeb && AdConfig.supportedPlatform && AdConsent.canRequestAds) {
      _loadAd();
    }
  }

  void _loadAd() {
    if (_loadAttempts >= _maxLoadAttempts) return;
    _loadAttempts += 1;

    final ad = BannerAd(
      adUnitId: AdConfig.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // 一時的なネットワーク要因でセッション中ずっと空枠になるのを避ける
          // ため、指数バックオフで有限回再試行する。
          if (!mounted || _loadAttempts >= _maxLoadAttempts) return;
          _retryTimer = Timer(
            _baseRetryDelay * (1 << (_loadAttempts - 1)),
            () {
              if (mounted && !_loaded) _loadAd();
            },
          );
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
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
