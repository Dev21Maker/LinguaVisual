import 'package:Languador/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';
import 'package:Languador/models/language.dart';
import 'package:Languador/providers/auth_provider.dart' as auth_prov;
import 'package:Languador/providers/flashcard_provider.dart';
import 'package:Languador/providers/settings_provider.dart';
import 'package:Languador/providers/locale_provider.dart';
import 'package:Languador/providers/stack_provider.dart';
import 'package:Languador/widgets/common/webview_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Controller for the delete account functionality
  double _holdProgress = 0.0;
  Timer? _holdTimer;
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
          // ListTile(
          //   leading: const Icon(Icons.translate),
          //   title: Text(l10n.stackListApplicationLocaleChangeTitle),
          //   subtitle: Text(_getLanguageDisplayName(ref.watch(localeProvider))),
          //   trailing: const Icon(Icons.chevron_right),
          //   onTap: () => _showAppLanguageSelector(
          //         context: context,
          //         currentLocale: ref.watch(localeProvider),
          //       ),
          // ),
          
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
              // Open privacy policy in WebView
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebViewScreen(
                    title: l10n.settingsPrivacyPolicyTile,
                    url: 'https://www.termsfeed.com/live/4c25b5da-296c-4840-aed8-f3e40a53a64d',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_support),
            title: Text(l10n.settingsContactSupportTile),
            onTap: () {
              // Open support contact page in WebView
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebViewScreen(
                    title: l10n.settingsContactSupportTile,
                    url: 'https://tally.so/r/nrpQdp',
                  ),
                ),
              );
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
                        // Close dialog first
                        Navigator.pop(context);
                        
                        // Get auth service and sign out
                        final authService = ref.read(auth_prov.authServiceProvider);
                        await authService.signOut(force: true);
                        
                        // Ensure we clear the navigation stack
                        if (mounted) {
                          // Pop all routes until we're at the root, then let the StreamBuilder handle redirection
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                      child: Text(l10n.settingsLogoutConfirmButton, style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),

          // Delete Account Option
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account'),  // Use l10n.settingsDeleteAccountTitle when added to localizations
            subtitle: const Text('Permanently delete your account and all data'), // Use l10n.settingsDeleteAccountSubtitle when added to localizations
            onTap: () {
              _showDeleteAccountDialog(context);
            },
          ),

          const SizedBox(height: 16), // Bottom padding
        ],
      ),
    );
  }
  
  // Method to show delete account dialog with direct hold-to-confirm functionality
  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _holdProgress = 0.0;
    _holdTimer?.cancel();
    _holdTimer = null;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Account'),  // Use l10n.settingsDeleteAccountDialogTitle when added
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This action cannot be undone. All your data will be permanently deleted.',
                      // Use l10n.settingsDeleteAccountDialogContent when added
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Press and hold the button below for 5 seconds to confirm deletion',
                      // Use l10n.settingsDeleteAccountHoldInstructions when added
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: GestureDetector(
                        onLongPressStart: (_) {
                          // Start the timer when user holds down
                          _holdTimer?.cancel();
                          _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
                            setState(() {
                              _holdProgress += 0.02;  // Increment by 2% every 100ms (5 seconds total)
                              if (_holdProgress >= 1.0) {
                                _holdTimer?.cancel();
                                _holdTimer = null;
                                // Proceed with account deletion when progress is complete
                                _deleteAccount(context);
                              }
                            });
                          });
                        },
                        onLongPressEnd: (_) {
                          // Cancel the timer if user releases early
                          _holdTimer?.cancel();
                          _holdTimer = null;
                          setState(() {
                            _holdProgress = 0.0;
                          });
                        },
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              // Progress indicator
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: _holdProgress,
                                    heightFactor: 1.0,
                                    child: Container(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ),
                              // Button text
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.delete_forever, 
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Hold to Delete Account',
                                      // Use l10n.settingsDeleteAccountHoldButton when added
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _holdTimer?.cancel();
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.commonCancel),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Method to handle the actual account deletion
  void _deleteAccount(BuildContext dialogContext) async {
    // Close the confirmation dialog
    if (mounted) {
      Navigator.of(dialogContext).pop();
    }
    
    // Show a loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
    
    try {
      // Get the auth service
      final authService = ref.read(auth_prov.authServiceProvider);
      
      // Delete the user account
      await authService.deleteAccount();
      
      // If we get here, deletion was successful
      if (mounted) {
        // Dismiss the loading overlay
        Navigator.of(context).pop();
        
        // Show success message before navigating
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.green,
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Success', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: const Text(
                'Account deleted successfully',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Navigate to login screen when OK is pressed
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false, // Remove all previous routes
                    );
                  },
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Log the error
      print('Error during account deletion: $e');
      
      if (mounted) {
        // Dismiss the loading overlay
        Navigator.of(context).pop();
        
        // Show error dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to delete account: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }
}
