import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:Languador/screens/ads/rewarded_ad_screen.dart';
import 'package:Languador/services/ad_service.dart';

/// A screen that shows a summary of the learning session
/// and displays a rewarded ad for additional cards
class LearnSummaryScreen extends ConsumerStatefulWidget {
  final int cardsReviewed;
  final int correctAnswers;
  final int quickAnswers;
  final int missedAnswers;
  final Duration sessionDuration;
  final VoidCallback onContinue;
  final VoidCallback? onLoadMoreCards;
  final bool showAd;

  const LearnSummaryScreen({
    super.key,
    required this.cardsReviewed,
    required this.correctAnswers,
    required this.quickAnswers,
    required this.missedAnswers,
    required this.sessionDuration,
    required this.onContinue,
    this.onLoadMoreCards,
    this.showAd = true,
  });

  @override
  ConsumerState<LearnSummaryScreen> createState() => _LearnSummaryScreenState();
}

class _LearnSummaryScreenState extends ConsumerState<LearnSummaryScreen> {
  final AdService _adService = AdService();
  bool _adInitialized = false;
  bool _showAdButton = true;

  @override
  void initState() {
    super.initState();
    _initializeAds();
    if (widget.showAd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showRewardedAd();
          }
        });
      });
    }
  }

  Future<void> _initializeAds() async {
    try {
      await _adService.initialize();
      if (mounted) {
        setState(() {
          _adInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing ads: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _showRewardedAd() {
    if (!_adInitialized) {
      debugPrint('Ad service not initialized yet, skipping ad display');
      return;
    }
    
    if (!_showAdButton) {
      debugPrint('Ad display already in progress, skipping');
      return;
    }
    
    setState(() {
      _showAdButton = false; 
    });
    
    _adService.showRewardedAd(
      onUserEarnedReward: (ad, reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        
        if (widget.onLoadMoreCards != null) {
          widget.onLoadMoreCards!();
        }
        
        if (mounted) {
          setState(() {
            _showAdButton = true;
          });
        }
      },
    ).then((adShown) {
      if (!adShown && mounted) {
        setState(() {
          _showAdButton = true;
        });
      }
    }).catchError((error) {
      debugPrint('Error showing rewarded ad: $error');
      if (mounted) {
        setState(() {
          _showAdButton = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.learnReviewSummaryTitle),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.celebration,
                size: 64,
                color: Colors.amber,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.learnSessionCompleteTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Stats Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.assignment_turned_in),
                        title: const Text("Cards Reviewed"),
                        trailing: Text(
                          '${widget.cardsReviewed}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: const Text("Correct Answers"),
                        trailing: Text(
                          '${widget.correctAnswers}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.bolt, color: Colors.blue),
                        title: const Text("Quick Answers"),
                        trailing: Text(
                          '${widget.quickAnswers}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.close, color: Colors.red),
                        title: const Text("Missed Answers"),
                        trailing: Text(
                          '${widget.missedAnswers}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.timer),
                        title: const Text("Session Duration"),
                        trailing: Text(
                          _formatDuration(widget.sessionDuration),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
            
              
              const SizedBox(height: 24),
              
              // Continue button
              ElevatedButton(
                onPressed: widget.onContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text("Home"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
