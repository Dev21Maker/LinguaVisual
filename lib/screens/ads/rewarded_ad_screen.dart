import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:Languador/services/ad_service.dart';

/// A screen that shows a rewarded ad and provides a reward to the user
/// This is typically shown when the user wants to get a reward for watching an ad
class RewardedAdScreen extends ConsumerStatefulWidget {
  final Widget nextScreen;
  final String? messageTitle;
  final String? messageBody;
  final int displayDurationMs;
  final bool forceShowAd;
  final Function(RewardItem)? onRewardEarned;

  const RewardedAdScreen({
    super.key,
    required this.nextScreen,
    this.messageTitle,
    this.messageBody,
    this.displayDurationMs = 2000, // Default 2 seconds
    this.forceShowAd = false,
    this.onRewardEarned,
  });

  @override
  ConsumerState<RewardedAdScreen> createState() => _RewardedAdScreenState();
}

class _RewardedAdScreenState extends ConsumerState<RewardedAdScreen> {
  bool _isLoading = true;
  bool _adShown = false;
  bool _rewardEarned = false;
  late Timer _timer;
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _showAdAndNavigate();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _showAdAndNavigate() async {
    // Initialize ad service if needed
    await _adService.initialize();
    
    // Show the rewarded ad
    bool adShown = false;
    
    if (widget.forceShowAd) {
      // If we force show ad, wait for it to load
      adShown = await _adService.showRewardedAd(
        onUserEarnedReward: (ad, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          setState(() {
            _rewardEarned = true;
          });
          
          // Call the callback if provided
          if (widget.onRewardEarned != null) {
            widget.onRewardEarned!(reward);
          }
        },
      );
    } else {
      // Otherwise just try to show it if it's ready
      adShown = await _adService.showRewardedAd(
        onUserEarnedReward: (ad, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          setState(() {
            _rewardEarned = true;
          });
          
          // Call the callback if provided
          if (widget.onRewardEarned != null) {
            widget.onRewardEarned!(reward);
          }
        },
      );
    }
    
    // TODO: Replace with actual ad ID when available
    // Placeholder for ad ID: 'YOUR_REWARDED_AD_ID_HERE'
    
    setState(() {
      _adShown = adShown;
      _isLoading = false;
    });
    
    // If ad was shown, navigation will happen via ad callback
    // If ad wasn't shown, we'll navigate after a short delay
    if (!adShown) {
      _timer = Timer(Duration(milliseconds: widget.displayDurationMs), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => widget.nextScreen),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                "Loading rewarded ad...",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else if (!_adShown) ...[
              // Show custom message if ad wasn't shown
              if (widget.messageTitle != null)
                Text(
                  widget.messageTitle!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (widget.messageTitle != null && widget.messageBody != null)
                const SizedBox(height: 16),
              if (widget.messageBody != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    widget.messageBody!,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 32),
              Text(
                "Redirecting...",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ] else if (_rewardEarned) ...[
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                "Reward Earned!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Thank you for watching the ad.",
                style: TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
