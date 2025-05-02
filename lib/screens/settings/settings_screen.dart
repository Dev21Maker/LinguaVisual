import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/models/language.dart';
import 'package:lingua_visual/providers/auth_provider.dart' as auth_prov;
import 'package:lingua_visual/providers/flashcard_provider.dart';
import 'package:lingua_visual/providers/settings_provider.dart';
import 'package:lingua_visual/providers/locale_provider.dart';
import 'package:lingua_visual/providers/stack_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _showLanguageSelector({
    required BuildContext context,
    required bool isNativeLanguage,
    required Language currentLanguage,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Text(
                l10n.settingsSelectLanguageTitle(isNativeLanguage ? "Native" : "Default Target"),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: supportedLanguages.length,
                  itemBuilder: (context, index) {
                    final language = supportedLanguages[index];
                    final isSelected = language.code == currentLanguage.code;

                    return ListTile(
                      leading:
                          isSelected
                              ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                              : const SizedBox(width: 24),
                      title: Text(language.name),
                      subtitle: Text(language.nativeName),
                      onTap: () async {
                        try {
                          if (isNativeLanguage) {
                            await ref.read(settingsProvider.notifier).setNativeLanguage(language);
                          } else {
                            await ref.read(settingsProvider.notifier).setTargetLanguage(language);
                          }
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save language preference: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to get language display name
  String _getLanguageDisplayName(Locale locale) {
    // You might want a more robust way to get display names, maybe from Language model
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'pl':
        return 'Polski';
      default:
        return locale.languageCode;
    }
  }

  // Method to show the app language selector dialog
  void _showAppLanguageSelector({
    required BuildContext context,
    required Locale currentLocale,
  }) {
    final supportedLocales = AppLocalizations.supportedLocales;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.stackListApplicationLocaleDialogTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: supportedLocales.length,
              itemBuilder: (context, index) {
                final locale = supportedLocales[index];
                return RadioListTile<Locale>(
                  title: Text(_getLanguageDisplayName(locale)),
                  value: locale,
                  groupValue: currentLocale,
                  onChanged: (Locale? value) {
                    if (value != null) {
                      ref.read(localeProvider.notifier).setLocale(value);
                      Navigator.of(dialogContext).pop(); // Close the dialog
                    }
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.commonCancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // Language Settings Section
          ListTile(
            title: Text(
              l10n.settingsLanguageSectionTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsTargetLanguageTile),
            subtitle: Text('${settings.targetLanguage.name} (${settings.targetLanguage.nativeName})'),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => _showLanguageSelector(
                  context: context,
                  isNativeLanguage: false,
                  currentLanguage: settings.targetLanguage,
                ),
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l10n.settingsNativeLanguageTile),
            subtitle: Text('${settings.nativeLanguage.name} (${settings.nativeLanguage.nativeName})'),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => _showLanguageSelector(
                  context: context,
                  isNativeLanguage: true,
                  currentLanguage: settings.nativeLanguage,
                ),
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l10n.stackListApplicationLocaleChangeTitle),
            subtitle: Text(_getLanguageDisplayName(ref.watch(localeProvider))),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAppLanguageSelector(
                  context: context,
                  currentLocale: ref.watch(localeProvider),
                ),
          ),
          
          const Divider(),

          // Review Settings Section
          ListTile(
            title: Text(
              l10n.settingsReviewSectionTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: Text(l10n.settingsReviewRemindersTile),
            subtitle: Text(l10n.settingsReviewRemindersSubtitle),
            value: true, // TODO: Connect to actual state
            onChanged: (bool value) {
              // TODO: Implement reminder toggle
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(l10n.settingsReviewLimitTile),
            subtitle: Text(l10n.settingsReviewLimitSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement review limit setting
            },
          ),

          const Divider(),

          // App Settings Section
          ListTile(
            title: Text(
              l10n.settingsAppSettingsSectionTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: Text(l10n.settingsDarkModeTile),
            subtitle: Text(l10n.settingsDarkModeSubtitle),
            value: ref.watch(settingsProvider).isDarkMode,
            onChanged: (bool value) {
              ref.read(settingsProvider.notifier).setDarkMode(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: Text(l10n.settingsClearDataTile),
            subtitle: Text(l10n.settingsClearDataSubtitle),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                  title: Text(l10n.settingsClearDataDialogTitle),
                  content: Text(l10n.settingsClearDataDialogContent),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
                    TextButton(
                      onPressed: () async {
                        // await ref.read(offlineFlashcardsProvider.notifier).clearOfflineData();
                        await ref.read(flashcardStateProvider.notifier).clearOfflineFlashcardData();
                        await ref.read(stacksProvider.notifier).clearOfflineStackData();
                        Navigator.pop(context); // Close dialog
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.settingsClearDataSuccessSnackbar),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: Text(l10n.settingsClearDataButtonPositive),
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(),

          // About Section
          ListTile(
            title: Text(
              l10n.settingsAboutSectionTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(l10n.settingsVersionTile),
            subtitle: Text(l10n.settingsVersionValue),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: Text(l10n.settingsPrivacyPolicyTile),
            onTap: () {
              // TODO: Implement privacy policy view
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_support),
            title: Text(l10n.settingsContactSupportTile),
            onTap: () {
              // TODO: Implement support contact
            },
          ),

          const Divider(height: 32), // Add visual separation
          // Account Section
          ListTile(
            title: Text(
              l10n.settingsAccountSectionTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.settingsLogoutTitle),
            subtitle: Text(l10n.settingsLogoutSubtitle),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                  title: Text(l10n.settingsLogoutDialogTitle),
                  content: Text(l10n.settingsLogoutDialogContent),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.settingsLogoutCancelButton),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog
                        final authService = ref.read(auth_prov.authServiceProvider);
                        await authService.signOut(force: true);
                        // No navigation needed - StreamBuilder will handle it
                      },
                      child: Text(l10n.settingsLogoutConfirmButton, style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16), // Bottom padding
        ],
      ),
    );
  }
}
