import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/models/language.dart';
import 'package:lingua_visual/providers/auth_provider.dart' as auth_prov;
import 'package:lingua_visual/providers/settings_provider.dart';

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
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Text(
                'Select ${isNativeLanguage ? "Native" : " Default Target"} Language',
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
                      leading: isSelected 
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                        : const SizedBox(width: 24),
                      title: Text(language.name),
                      subtitle: Text(language.nativeName),
                      onTap: () async {
                        try {
                          if (isNativeLanguage) {
                            await ref.read(settingsProvider.notifier)
                                .setNativeLanguage(language);
                          } else {
                            await ref.read(settingsProvider.notifier)
                                .setTargetLanguage(language);
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
  
 @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Language Settings Section
          ListTile(
            title: Text(
              'Language Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Target Language - Default'),
            subtitle: Text(
              '${settings.targetLanguage.name} (${settings.targetLanguage.nativeName})',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageSelector(
              context: context,
              isNativeLanguage: false,
              currentLanguage: settings.targetLanguage,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: const Text('Native Language'),
            subtitle: Text(
              '${settings.nativeLanguage.name} (${settings.nativeLanguage.nativeName})',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageSelector(
              context: context,
              isNativeLanguage: true,
              currentLanguage: settings.nativeLanguage,
            ),
          ),
          
          const Divider(),
          
          // Review Settings Section
          ListTile(
            title: Text(
              'Review Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Review Reminders'),
            subtitle: const Text('Get notified when cards are due'),
            value: true, // TODO: Connect to actual state
            onChanged: (bool value) {
              // TODO: Implement reminder toggle
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Daily Review Limit'),
            subtitle: const Text('20 cards'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement review limit setting
            },
          ),
          
          const Divider(),
          
          // App Settings Section
          ListTile(
            title: Text(
              'App Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle dark/light theme'),
            value: ref.watch(settingsProvider).isDarkMode,
            onChanged: (bool value) {
               ref.read(settingsProvider.notifier).setDarkMode(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up space'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Cache'),
                  content: const Text('This will clear all cached images. Continue?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Implement cache clearing
                        Navigator.pop(context);
                      },
                      child: const Text('CLEAR'),
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
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Privacy Policy'),
            onTap: () {
              // TODO: Implement privacy policy view
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_support),
            title: const Text('Contact Support'),
            onTap: () {
              // TODO: Implement support contact
            },
          ),

          const Divider(height: 32), // Add visual separation

          // Account Section
          ListTile(
            title: Text(
              'Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            subtitle: const Text('Sign out of your account'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog
                        final authService = ref.read(auth_prov.authServiceProvider);
                        await authService.signOut(force: true);
                        // No navigation needed - StreamBuilder will handle it
                      },
                      child: const Text(
                        'LOGOUT',
                        style: TextStyle(color: Colors.red),
                      ),
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
