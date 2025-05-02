import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Define the provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  // Default locale (e.g., English)
  // TODO: Load the saved locale from storage (e.g., SharedPreferences) if available
  return LocaleNotifier(const Locale('en'));
});

// Define the StateNotifier
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(Locale initialLocale) : super(initialLocale);

  void setLocale(Locale newLocale) {
    if (state != newLocale) {
      state = newLocale;
      // TODO: Save the selected locale to storage (e.g., SharedPreferences)
    }
  }
}
