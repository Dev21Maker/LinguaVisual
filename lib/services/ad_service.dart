import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service to manage ads in the application
class AdService {
  static final AdService _instance = AdService._internal();
  
  factory AdService() => _instance;
  
  AdService._internal();

  bool _isInitialized = false;
  int _interstitialLoadAttempts = 0;
  int _rewardedLoadAttempts = 0;
  final int _maxLoadAttempts = 3;
  
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Test ad units for development
  static const String _testBannerAdUnitId = 'ca-app-pub-9881290136478504/4053762209';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-9881290136478504/3415150725';

  // Production ad units (replace with actual IDs when available)
  static const String _prodBannerAdUnitId = '';
  static const String _prodInterstitialAdUnitId = '';
  static const String _prodRewardedAdUnitId = '';

  /// Initialize the AdMob SDK
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await MobileAds.instance.initialize();
      
      // Set test device IDs to avoid getting invalid activity errors
      // when testing with real devices
      RequestConfiguration configuration = RequestConfiguration(
        testDeviceIds: ['EMULATOR'],
      );
      MobileAds.instance.updateRequestConfiguration(configuration);
      
      _isInitialized = true;
      debugPrint('AdService initialized successfully');
      
      // Load interstitial ad after initialization
      _loadInterstitialAd();
      
      // Load rewarded ad after initialization
      _loadRewardedAd();
    } catch (e) {
      debugPrint('Error initializing AdService: $e');
    }
  }

  /// Get the appropriate banner ad unit ID based on environment
  String get bannerAdUnitId {
    if (kDebugMode) {
      return _testBannerAdUnitId;
    } else {
      return _prodBannerAdUnitId;
    }
  }

  /// Get the appropriate interstitial ad unit ID based on environment
  String get interstitialAdUnitId {
    if (kDebugMode) {
      return _testInterstitialAdUnitId;
    } else {
      return _prodInterstitialAdUnitId;
    }
  }

  /// Get the appropriate rewarded ad unit ID based on environment
  String get rewardedAdUnitId {
    if (kDebugMode) {
      return _testRewardedAdUnitId;
    } else {
      return _prodRewardedAdUnitId;
    }
  }

  /// Create a banner ad
  BannerAd createBannerAd({
    required AdSize size,
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  /// Load an interstitial ad
  void _loadInterstitialAd() {
    if (_interstitialAd != null) return;
    
    debugPrint('Loading interstitial ad...');
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          debugPrint('Interstitial ad loaded successfully');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialLoadAttempts += 1;
          _interstitialAd = null;
          debugPrint('Interstitial ad failed to load: $error');
          
          if (_interstitialLoadAttempts < _maxLoadAttempts) {
            debugPrint('Retrying interstitial ad load (attempt $_interstitialLoadAttempts)');
            Future.delayed(const Duration(seconds: 1), _loadInterstitialAd);
          }
        },
      ),
    );
  }

  /// Show an interstitial ad
  Future<bool> showInterstitialAd() async {
    if (!_isInitialized) {
      debugPrint('AdService not initialized yet');
      await initialize();
    }
    
    if (_interstitialAd == null) {
      debugPrint('Interstitial ad not ready yet');
      _loadInterstitialAd();
      return false;
    }

    bool adShown = false;
    
    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) {
          debugPrint('Interstitial ad showed full screen content');
          adShown = true;
        },
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          debugPrint('Interstitial ad dismissed');
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          debugPrint('Interstitial ad failed to show: $error');
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitialAd();
        },
      );

      await _interstitialAd!.show();
      return adShown;
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _loadInterstitialAd();
      return false;
    }
  }

  /// Load a rewarded ad
  void _loadRewardedAd() {
    if (_rewardedAd != null) return;
    
    // Check if we've tried too many times recently to avoid rate limiting
    if (_rewardedLoadAttempts >= _maxLoadAttempts) {
      debugPrint('Too many ad load attempts recently, waiting before trying again');
      // Reset attempts after a longer delay
      Future.delayed(const Duration(seconds: 10), () {
        _rewardedLoadAttempts = 0;
        _loadRewardedAd();
      });
      return;
    }
    
    debugPrint('Loading rewarded ad...');
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _rewardedLoadAttempts = 0;
          debugPrint('Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedLoadAttempts += 1;
          _rewardedAd = null;
          debugPrint('Rewarded ad failed to load: $error');
          
          if (_rewardedLoadAttempts < _maxLoadAttempts) {
            // Exponential backoff to avoid rate limiting
            final backoffSeconds = 2 * _rewardedLoadAttempts;
            debugPrint('Retrying rewarded ad load (attempt $_rewardedLoadAttempts) in $backoffSeconds seconds');
            Future.delayed(Duration(seconds: backoffSeconds), _loadRewardedAd);
          }
        },
      ),
    );
  }

  /// Show a rewarded ad
  Future<bool> showRewardedAd({
    required OnUserEarnedRewardCallback onUserEarnedReward,
  }) async {
    if (!_isInitialized) {
      debugPrint('AdService not initialized yet');
      await initialize();
    }
    
    if (_rewardedAd == null) {
      debugPrint('Rewarded ad not ready yet, loading now...');
      _loadRewardedAd();
      // Wait a bit to see if the ad loads quickly
      await Future.delayed(const Duration(seconds: 3));
      
      // Check again if the ad is loaded
      if (_rewardedAd == null) {
        debugPrint('Rewarded ad still not ready after waiting');
        return false;
      }
    }

    bool adShown = false;
    
    try {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (RewardedAd ad) {
          debugPrint('Rewarded ad showed full screen content');
          adShown = true;
        },
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          debugPrint('Rewarded ad dismissed');
          ad.dispose();
          _rewardedAd = null;
          
          // Don't immediately reload the ad to avoid rate limiting
          // Instead schedule a delayed reload
          Future.delayed(const Duration(seconds: 2), _loadRewardedAd);
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          debugPrint('Rewarded ad failed to show: $error');
          ad.dispose();
          _rewardedAd = null;
          
          // Don't immediately reload the ad to avoid rate limiting
          // Instead schedule a delayed reload
          Future.delayed(const Duration(seconds: 2), _loadRewardedAd);
        },
      );

      await _rewardedAd!.show(onUserEarnedReward: onUserEarnedReward);
      return adShown;
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
      _rewardedAd?.dispose();
      _rewardedAd = null;
      
      // Don't immediately reload the ad to avoid rate limiting
      // Instead schedule a delayed reload
      Future.delayed(const Duration(seconds: 5), _loadRewardedAd);
      return false;
    }
  }

  /// Dispose of any active ads
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
  }
}
