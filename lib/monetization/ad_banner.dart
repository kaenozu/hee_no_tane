import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

class HeeAdBanner extends StatefulWidget {
  const HeeAdBanner({super.key});

  @override
  State<HeeAdBanner> createState() => _HeeAdBannerState();
}

class _HeeAdBannerState extends State<HeeAdBanner> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && AdConfig.supportedPlatform) {
      _loadAd();
    }
  }

  void _loadAd() {
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
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
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
