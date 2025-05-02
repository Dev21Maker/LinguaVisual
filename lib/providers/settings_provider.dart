import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';

class SettingsState {
  final Language nativeLanguage;
  final Language targetLanguage;
  final bool isDarkMode;
  final bool enableNotifications;
  final int dailyReviewLimit;

  const SettingsState({
    required this.nativeLanguage,
    required this.targetLanguage,
    this.isDarkMode = false,
    this.enableNotifications = true,
    this.dailyReviewLimit = 20,
  });

  SettingsState copyWith({
    Language? nativeLanguage,
    Language? targetLanguage,
    bool? isDarkMode,
    bool? enableNotifications,
    int? dailyReviewLimit,
  }) {
    return SettingsState(
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;
  static const String _nativeLanguageKey = 'nativeLanguageCode';
  static const String _targetLanguageKey = 'targetLanguageCode';
  static const String _isDarkModeKey = 'isDarkMode';

  SettingsNotifier(this._prefs)
    : super(
        SettingsState(
          nativeLanguage: _getInitialNativeLanguage(_prefs),
          targetLanguage: _getInitialTargetLanguage(_prefs),
          isDarkMode: _prefs.getBool(_isDarkModeKey) ?? false,
        ),
      );

  static Language _getInitialNativeLanguage(SharedPreferences prefs) {
    final savedCode = prefs.getString(_nativeLanguageKey);
    return supportedLanguages.firstWhere(
      (l) => l.code == savedCode,
      orElse: () => supportedLanguages.firstWhere((l) => l.code == 'en'),
    );
  }

  static Language _getInitialTargetLanguage(SharedPreferences prefs) {
    final savedCode = prefs.getString(_targetLanguageKey);
    return supportedLanguages.firstWhere(
      (l) => l.code == savedCode,
      orElse: () => supportedLanguages.firstWhere((l) => l.code == 'es'),
    );
  }

  Future<void> setNativeLanguage(Language language) async {
    await _prefs.setString(_nativeLanguageKey, language.code);
    state = state.copyWith(nativeLanguage: language);
  }

  Future<void> setTargetLanguage(Language language) async {
    await _prefs.setString(_targetLanguageKey, language.code);
    state = state.copyWith(targetLanguage: language);
  }

  Future<void> setDarkMode(bool isDark) async {
    await _prefs.setBool(_isDarkModeKey, isDark);
    state = state.copyWith(isDarkMode: isDark);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  throw UnimplementedError('Need to initialize with SharedPreferences instance');
});
