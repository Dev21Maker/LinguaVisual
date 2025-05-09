import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Languador/services/ad_service.dart';

/// A screen that shows an interstitial ad and then navigates to the next screen
/// This is typically shown at natural transition points in the app
class InterstitialAdScreen extends ConsumerStatefulWidget {
  final Widget nextScreen;
  final String? messageTitle;
  final String? messageBody;
  final int displayDurationMs;
  final bool forceShowAd;

  const InterstitialAdScreen({
    super.key,
    required this.nextScreen,
    this.messageTitle,
    this.messageBody,
    this.displayDurationMs = 2000, // Default 2 seconds
    this.forceShowAd = false,
  });

  @override
  ConsumerState<InterstitialAdScreen> createState() => _InterstitialAdScreenState();
}

class _InterstitialAdScreenState extends ConsumerState<InterstitialAdScreen> {
  bool _isLoading = true;
  bool _adShown = false;
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
    
    // Show the interstitial ad
    bool adShown = false;
    
    if (widget.forceShowAd) {
      // If we force show ad, wait for it to load
      adShown = await _adService.showInterstitialAd();
    } else {
      // Otherwise just try to show it if it's ready
      adShown = await _adService.showInterstitialAd();
    }
    
    
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
                "Loading...",
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
            ],
          ],
        ),
      ),
    );
  }
}
