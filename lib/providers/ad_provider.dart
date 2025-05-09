import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:Languador/screens/ads/rewarded_ad_screen.dart';

/// Enum for different ad display strategies
enum AdDisplayStrategy {
  /// Show ads after every session
  afterEverySession,
  
  /// Show ads after every N sessions
  afterNSessions,
  
  /// Show ads after specific SRS milestones
  afterSrsMilestones,
  
  /// Show ads when user reaches certain streak
  atSpecificStreak,
  
  /// Never show ads (premium users)
  never,
}

/// Provider for ad-related settings and state
class AdSettingsNotifier extends StateNotifier<AsyncValue<AdSettings>> {
  final Ref ref;
  
  AdSettingsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  /// Load ad settings from persistent storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final strategy = AdDisplayStrategy.values[
        prefs.getInt('ad_display_strategy') ?? 
        AdDisplayStrategy.afterEverySession.index
      ];
      
      final sessionCount = prefs.getInt('ad_session_count') ?? 0;
      final sessionsBeforeAd = prefs.getInt('ad_sessions_before_ad') ?? 3;
      final isPremium = prefs.getBool('is_premium_user') ?? false;
      
      state = AsyncValue.data(AdSettings(
        displayStrategy: isPremium ? AdDisplayStrategy.never : strategy,
        sessionCount: sessionCount,
        sessionsBeforeAd: sessionsBeforeAd,
        isPremiumUser: isPremium,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Increment the session count and return whether an ad should be shown
  Future<bool> incrementSessionAndCheckForAd() async {
    if (state.hasError || !state.hasValue) return false;
    
    final currentSettings = state.value!;
    
    // Premium users never see ads
    if (currentSettings.isPremiumUser) return false;
    
    // Increment session count
    final newSessionCount = currentSettings.sessionCount + 1;
    
    // Check if we should show an ad based on strategy
    bool shouldShowAd = false;
    
    switch (currentSettings.displayStrategy) {
      case AdDisplayStrategy.afterEverySession:
        shouldShowAd = true;
        break;
      case AdDisplayStrategy.afterNSessions:
        shouldShowAd = newSessionCount % currentSettings.sessionsBeforeAd == 0;
        break;
      case AdDisplayStrategy.afterSrsMilestones:
        // This would be handled elsewhere based on SRS progress
        shouldShowAd = false;
        break;
      case AdDisplayStrategy.atSpecificStreak:
        // This would be handled elsewhere based on user streak
        shouldShowAd = false;
        break;
      case AdDisplayStrategy.never:
        shouldShowAd = false;
        break;
    }
    
    // Update state and persist
    state = AsyncValue.data(currentSettings.copyWith(
      sessionCount: newSessionCount,
    ));
    
    // Persist the updated session count
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ad_session_count', newSessionCount);
    } catch (e) {
      debugPrint('Error saving ad session count: $e');
    }
    
    return shouldShowAd;
  }

  /// Update the ad display strategy
  Future<void> updateDisplayStrategy(AdDisplayStrategy strategy) async {
    if (!state.hasValue) return;
    
    final currentSettings = state.value!;
    
    // Update state
    state = AsyncValue.data(currentSettings.copyWith(
      displayStrategy: strategy,
    ));
    
    // Persist the updated strategy
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ad_display_strategy', strategy.index);
    } catch (e) {
      debugPrint('Error saving ad display strategy: $e');
    }
  }

  /// Update the number of sessions before showing an ad
  Future<void> updateSessionsBeforeAd(int sessions) async {
    if (!state.hasValue) return;
    
    final currentSettings = state.value!;
    
    // Update state
    state = AsyncValue.data(currentSettings.copyWith(
      sessionsBeforeAd: sessions,
    ));
    
    // Persist the updated sessions count
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ad_sessions_before_ad', sessions);
    } catch (e) {
      debugPrint('Error saving sessions before ad: $e');
    }
  }

  /// Update premium user status
  Future<void> updatePremiumStatus(bool isPremium) async {
    if (!state.hasValue) return;
    
    final currentSettings = state.value!;
    
    // Update state with premium status and set strategy to never for premium users
    state = AsyncValue.data(currentSettings.copyWith(
      isPremiumUser: isPremium,
      displayStrategy: isPremium ? AdDisplayStrategy.never : currentSettings.displayStrategy,
    ));
    
    // Persist the updated premium status
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium_user', isPremium);
    } catch (e) {
      debugPrint('Error saving premium status: $e');
    }
  }
}

/// Data class for ad settings
class AdSettings {
  final AdDisplayStrategy displayStrategy;
  final int sessionCount;
  final int sessionsBeforeAd;
  final bool isPremiumUser;
  
  const AdSettings({
    required this.displayStrategy,
    required this.sessionCount,
    required this.sessionsBeforeAd,
    required this.isPremiumUser,
  });
  
  AdSettings copyWith({
    AdDisplayStrategy? displayStrategy,
    int? sessionCount,
    int? sessionsBeforeAd,
    bool? isPremiumUser,
  }) {
    return AdSettings(
      displayStrategy: displayStrategy ?? this.displayStrategy,
      sessionCount: sessionCount ?? this.sessionCount,
      sessionsBeforeAd: sessionsBeforeAd ?? this.sessionsBeforeAd,
      isPremiumUser: isPremiumUser ?? this.isPremiumUser,
    );
  }
}

/// Provider for ad settings
final adSettingsProvider = StateNotifierProvider<AdSettingsNotifier, AsyncValue<AdSettings>>((ref) {
  return AdSettingsNotifier(ref);
});

/// Utility function to show a rewarded ad and handle the reward
Future<void> showRewardedAdScreen(
  BuildContext context,
  Widget nextScreen, {
  String? title,
  String? message,
  bool forceShowAd = false,
  Function(RewardItem)? onRewardEarned,
}) async {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => RewardedAdScreen(
        nextScreen: nextScreen,
        messageTitle: title,
        messageBody: message,
        forceShowAd: forceShowAd,
        onRewardEarned: onRewardEarned,
      ),
    ),
  );
}
