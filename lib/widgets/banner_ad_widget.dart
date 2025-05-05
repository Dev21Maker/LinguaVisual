import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lingua_visual/services/ad_service.dart';

/// A widget that displays a banner ad
/// This can be placed at the top or bottom of any screen
class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  final double height;

  /// Creates a banner ad widget
  /// 
  /// [adSize] - The size of the ad to display (default: AdSize.banner)
  /// [height] - The height of the widget (default: 60)
  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.height = 60,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  /// Load a banner ad
  void _loadBannerAd() {
    _bannerAd = _adService.createBannerAd(
      size: widget.adSize,
      onAdLoaded: (Ad ad) {
        setState(() {
          _isAdLoaded = true;
        });
        debugPrint('Banner ad loaded');
      },
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        ad.dispose();
        debugPrint('Banner ad failed to load: $error');
        setState(() {
          _isAdLoaded = false;
        });
      },
    );

    _bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null || !_isAdLoaded) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'Ad loading...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      width: _bannerAd!.size.width.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
