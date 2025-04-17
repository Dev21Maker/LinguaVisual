import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/screens/offline_training_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingua_visual/models/flashcard.dart';
import 'package:lingua_visual/providers/srs_provider.dart';
import 'package:lingua_visual/providers/supabase_provider.dart';
import 'package:lingua_visual/screens/auth/login_screen.dart';
import 'package:lingua_visual/screens/flashcard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lingua_visual/models/language.dart';
import 'package:lingua_visual/providers/settings_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lingua_visual/providers/recraft_api_provider.dart' as recraft;
import 'providers/flashcard_provider.dart';
import 'widgets/flashcard_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Add this provider to track connectivity state
final isOnlineProvider = StateProvider<bool>((ref) => false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try to load environment variables, but don't fail if .env is missing
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: Failed to load .env file: $e');
  }
  
  // Initialize Supabase with fallback values if env vars are missing
  bool isOnline = false;
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? 'https://your-default-project.supabase.co',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-default-anon-key',
    );
    isOnline = true;
  } catch (e) {
    print('Warning: Running in offline mode: $e');
  }
  
  // Initialize settings provider
  final settingsProviderInstance = await initializeSettingsProvider();
  
  runApp(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWithProvider(settingsProviderInstance),
        isOnlineProvider.overrideWith((ref) => isOnline),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinguaVisual',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const InitializationWrapper(),
    );
  }
}

class InitializationWrapper extends ConsumerWidget {
  const InitializationWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return isOnline ? const AuthWrapper() : const OfflineHomeScreen();
  }
}

class OfflineHomeScreen extends ConsumerWidget {
  const OfflineHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LinguaVisual (Offline)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_off),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Offline Mode'),
                  content: const Text(
                    'You are currently in offline mode. Your changes will be saved locally '
                    'and synced when you reconnect to the server.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        // Try to reconnect
                        try {
                          await Supabase.initialize(
                            url: dotenv.env['SUPABASE_URL'] ?? '',
                            anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
                          );
                          ref.read(isOnlineProvider.notifier).state = true;
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to connect to server'),
                            ),
                          );
                        }
                      },
                      child: const Text('TRY RECONNECT'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Scaffold(
          bottomNavigationBar: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.school), text: 'Learn'),
              Tab(icon: Icon(Icons.library_books), text: 'Flashcards'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
          body: TabBarView(
            children: [
              const OfflineLearnScreen(),
              const OfflineFlashcardScreen(),
              SettingsScreen(),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show loading indicator while waiting for auth state
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get the auth state
        final authState = snapshot.data!;

        // Handle different auth states
        switch (authState.event) {
          case AuthChangeEvent.signedIn:
            // User is signed in
            if (authState.session?.user != null) {
              return const HomeScreen();
            }
            return const LoginScreen();

          case AuthChangeEvent.signedOut:
          case AuthChangeEvent.tokenRefreshed:
            // User is signed out or token refresh failed
            return const LoginScreen();

          case AuthChangeEvent.userUpdated:
            // User data was updated - stay on current screen
            return const HomeScreen();

          case AuthChangeEvent.passwordRecovery:
            // TODO: Navigate to password recovery screen
            return const LoginScreen();

          case AuthChangeEvent.mfaChallengeVerified:
            // MFA verification successful - stay on current screen
            return const HomeScreen();

          default:
            // Handle any other auth states
            return const LoginScreen();
        }
      },
    );
  }
}

// Add a loading screen widget
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}

class LearnScreen extends HookConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCardsState = useState<List<Flashcard>>([]);
    final dueCards = dueCardsState.value;
    final setDueCards = dueCardsState.value;
    final currentCardState = useState<Flashcard?>(null);
    final currentCard = currentCardState.value;
    final setCurrentCard = currentCardState.value;
    final isLoadingState = useState(true);
    final isLoading = isLoadingState.value;
    final setIsLoading = isLoadingState.value;
    final errorState = useState<String?>(null);
    final error = errorState.value;
    final setError = errorState.value;

    Future<void> loadDueCards() async {
      isLoadingState.value = true;
      errorState.value = null;
      
      try {
        final supabaseService = ref.read(supabaseServiceProvider);
        final cards = await supabaseService.fetchDueCards();
        
        if (cards.isEmpty) {
          await loadDueCards(); // Fetch cards again after creating a new one
          final updatedCards = await supabaseService.fetchDueCards();
          dueCardsState.value = updatedCards;
          currentCardState.value = updatedCards.isNotEmpty ? updatedCards.first : null;
        } else {
          dueCardsState.value = cards;
          currentCardState.value = cards.isNotEmpty ? cards.first : null;
        }
      } catch (e) {
        errorState.value = e.toString();
      } finally {
        isLoadingState.value = false;
      }
    }

    Future<void> _createNewCard(WidgetRef ref) async {
      final supabaseService = ref.read(supabaseServiceProvider);
      final settings = ref.read(settingsProvider);
      
      // Fetch new word data from Supabase function
      final wordData = await supabaseService.fetchNewWordViaFunction(
        targetLanguageCode: settings.targetLanguage.code,
        nativeLanguageCode: settings.nativeLanguage.code,
      );

      // Generate image using Recraft API
      String? imageUrl;
      try {
        final recraftApi = ref.read(recraft.recraftApiProvider);
        imageUrl = await recraftApi.getImageUrl(wordData['word']!);
      } catch (e) {
        // Log error but continue without image
        print('Failed to generate image: $e');
      }

      // Create new flashcard with initial SRS data
      final newFlashcard = Flashcard(
        id: const Uuid().v4(),
        word: wordData['word']!,
        targetLanguageCode: settings.targetLanguage.code,
        translation: wordData['translation']!,
        nativeLanguageCode: settings.nativeLanguage.code,
        imageUrl: imageUrl,
        srsNextReviewDate: DateTime.now().millisecondsSinceEpoch,
        srsInterval: 1.0,
        srsEaseFactor: 2.5,
      );

      // Insert the new card
      await supabaseService.insertCard(newFlashcard);
    }

    useEffect(() {
      loadDueCards();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
        actions: [
          if (!isLoading)
            TextButton.icon(
              onPressed: loadDueCards,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildBody(
            context,
            ref,
            isLoading: isLoading,
            error: error,
            currentCard: currentCard,
            dueCards: dueCards,
            onRatingSelected: (rating) async {
              try {
                if (currentCardState.value == null) return;
                
                final srsService = ref.read(srsProvider);
                final supabaseService = ref.read(supabaseServiceProvider);
                
                // Calculate new SRS values using the SRS service
                final updatedCard = srsService.calculateNextReview(
                  currentCardState.value!,
                  rating,
                );
                
                // Update card in Supabase
                await supabaseService.updateCard(updatedCard);
                
                // Update local state
                final newDueCards = List<Flashcard>.from(dueCards)..removeAt(0);
                dueCardsState.value = newDueCards;
                currentCardState.value = newDueCards.isNotEmpty ? newDueCards.first : null;
                
                // If no more cards, try to fetch new ones
                if (newDueCards.isEmpty) {
                  await loadDueCards();
                }
                
                // Reset the flashcard view
                ref.read(flashcardViewProvider.notifier).reset();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update card: ${e.toString()}')),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref, {
    required bool isLoading,
    required String? error,
    required Flashcard? currentCard,
    required List<Flashcard> dueCards,
    required Future<void> Function(String rating) onRatingSelected,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading cards',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(activeLearningProvider.notifier).loadDueCards(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (currentCard == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No cards due for review',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Great job! Take a break or check back later.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(activeLearningProvider.notifier).loadDueCards(),
              icon: const Icon(Icons.refresh),
              label: const Text('Check Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Text(
          'Cards remaining: ${dueCards.length}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: FlashcardView(
            flashcards: [currentCard!],  // Wrap in list
            onRatingSelected: (rating, flashcard) => onRatingSelected(rating),
          ),
        ),
      ],
    );
  }
}

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              _buildStatisticsCards(context, ref),
              const SizedBox(height: 32),
              Text(
                'Review History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildReviewHistory(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(BuildContext context, WidgetRef ref) {
    final flashcardsAsync = ref.watch(flashcardsProvider);
    final dueFlashcardsAsync = ref.watch(dueFlashcardsProvider);

    return flashcardsAsync.when(
      data: (flashcards) => dueFlashcardsAsync.when(
        data: (dueCards) => GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              context,
              'Total Cards',
              flashcards.length.toString(),
              Icons.school,
              Colors.blue,
            ),
            _buildStatCard(
              context,
              'Due Today',
              dueCards.length.toString(),
              Icons.access_time,
              Colors.orange,
            ),
            _buildStatCard(
              context,
              'Learned Today',
              '0', // TODO: Implement learned today count
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              context,
              'Streak',
              '0', // TODO: Implement streak count
              Icons.local_fire_department,
              Colors.red,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewHistory(BuildContext context, WidgetRef ref) {
    final flashcardsAsync = ref.watch(flashcardsProvider);

    return flashcardsAsync.when(
      data: (flashcards) => Expanded(
        child: ListView.builder(
          itemCount: flashcards.length,
          itemBuilder: (context, index) {
            final card = flashcards[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(card.word),
                subtitle: Text(
                  'Next review: ${_formatDate(card.srsNextReviewDate)}',
                ),
                trailing: Text(
                  'Interval: ${card.srsInterval.toStringAsFixed(1)}d',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  String _formatDate(int millisecondsSinceEpoch) {
    final date = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

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
                'Select ${isNativeLanguage ? "Native" : "Target"} Language',
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
            title: const Text('Target Language'),
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
            value: false, // TODO: Connect to actual theme state
            onChanged: (bool value) {
              // TODO: Implement theme toggle
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
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: Scaffold(
          bottomNavigationBar: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.school), text: 'Learn'),
              Tab(icon: Icon(Icons.library_books), text: 'Flashcards'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Progress'),
            ],
          ),
          body: TabBarView(
            children: [
              LearnScreen(),
              FlashcardScreen(),
              ProgressScreen(),
            ],
          ),
        ),
      ),
    );
  }
}

// Add this provider for offline flashcards
final offlineFlashcardsProvider = StateNotifierProvider<OfflineFlashcardsNotifier, List<Flashcard>>((ref) {
  return OfflineFlashcardsNotifier();
});

class OfflineFlashcardsNotifier extends StateNotifier<List<Flashcard>> {
  OfflineFlashcardsNotifier() : super([]) {
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    final prefs = await SharedPreferences.getInstance();
    final flashcardsJson = prefs.getStringList('offline_flashcards') ?? [];
    state = flashcardsJson
        .map((json) => Flashcard.fromMap(jsonDecode(json)))
        .toList();
  }

  Future<void> addFlashcard(Flashcard flashcard) async {
    state = [...state, flashcard];
    await _saveFlashcards();
  }

  Future<void> _saveFlashcards() async {
    final prefs = await SharedPreferences.getInstance();
    final flashcardsJson = state
        .map((flashcard) => jsonEncode(flashcard.toMap()))
        .toList();
    await prefs.setStringList('offline_flashcards', flashcardsJson);
  }

  Future<void> removeFlashcard(int id) async {
    state = state.where((flashcard) => flashcard.id != id).toList();
    await _saveFlashcards();
  }

  Future<void> updateCard(Flashcard updatedCard) async {
    state = state.map((card) => 
      card.id == updatedCard.id ? updatedCard : card
    ).toList();
    await _saveFlashcards();
  }
}

class OfflineLearnScreen extends ConsumerWidget {
  const OfflineLearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashcards = ref.watch(offlineFlashcardsProvider);
    
    if (flashcards.isEmpty) {
      return const Center(
        child: Text('No flashcards available offline'),
      );
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${flashcards.length} cards available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const OfflineTrainingScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Training'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OfflineFlashcardScreen extends HookConsumerWidget {
  const OfflineFlashcardScreen({super.key});

  void _showAddFlashcardDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return HookBuilder(builder: (context) {
          final wordController = useTextEditingController();
          final translationController = useTextEditingController();
          final bulkInputController = useTextEditingController();
          final formKey = GlobalKey<FormState>();
          final settings = ref.read(settingsProvider);
          final isBulkMode = useState(false);
          
          final targetLanguageState = useState<Language>(settings.targetLanguage);
          final nativeLanguageState = useState<Language>(settings.nativeLanguage);

          Future<void> _addBulkFlashcards() async {
            final lines = bulkInputController.text.split('\n');
            for (final line in lines) {
              final parts = line.split('\\');
              if (parts.length == 2) {
                final word = parts[0].trim();
                final translation = parts[1].trim();
                
                if (word.isNotEmpty && translation.isNotEmpty) {
                  final newFlashcard = Flashcard(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    word: word,
                    translation: translation,
                    targetLanguageCode: targetLanguageState.value.code,
                    nativeLanguageCode: nativeLanguageState.value.code,
                    srsNextReviewDate: DateTime.now().millisecondsSinceEpoch,
                    srsInterval: 1.0,
                    srsEaseFactor: 2.5,
                  );

                  await ref.read(offlineFlashcardsProvider.notifier)
                      .addFlashcard(newFlashcard);
                }
              }
            }
          }

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add New Flashcard'),
                Tooltip(
                  message: isBulkMode.value 
                      ? 'Switch to single word input mode'
                      : 'Switch to bulk input mode for multiple words',
                  child: TextButton.icon(
                    onPressed: () {
                      isBulkMode.value = !isBulkMode.value;
                    },
                    icon: Icon(isBulkMode.value ? Icons.note_add : Icons.list),
                    label: Text(isBulkMode.value ? 'Single Mode' : 'Bulk Mode'),
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isBulkMode.value) ...[
                      // Single word mode UI
                      DropdownButtonFormField<Language>(
                        value: targetLanguageState.value,
                        decoration: const InputDecoration(
                          labelText: 'Target Language',
                        ),
                        items: supportedLanguages.map((Language language) {
                          return DropdownMenuItem<Language>(
                            value: language,
                            child: Text('${language.name} (${language.nativeName})'),
                          );
                        }).toList(),
                        onChanged: (Language? newValue) {
                          if (newValue != null) {
                            targetLanguageState.value = newValue;
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: wordController,
                        decoration: const InputDecoration(
                          labelText: 'Word',
                          hintText: 'Enter the word to learn',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a word';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Language>(
                        value: nativeLanguageState.value,
                        decoration: const InputDecoration(
                          labelText: 'Native Language',
                        ),
                        items: supportedLanguages.map((Language language) {
                          return DropdownMenuItem<Language>(
                            value: language,
                            child: Text('${language.name} (${language.nativeName})'),
                          );
                        }).toList(),
                        onChanged: (Language? newValue) {
                          if (newValue != null) {
                            nativeLanguageState.value = newValue;
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: translationController,
                        decoration: const InputDecoration(
                          labelText: 'Translation',
                          hintText: 'Enter the translation',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a translation';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      // Bulk input mode UI
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'How to add multiple words:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1. Enter one word pair per line\n'
                              '2. Use \\ to separate word and translation\n'
                              '3. Example: hello\\hola',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'From: ${targetLanguageState.value.name} → To: ${nativeLanguageState.value.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: bulkInputController,
                        maxLines: 8,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: 'hello\\hola\nworld\\mundo\nbook\\libro',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          helperText: 'Press Enter for a new line',
                          helperStyle: TextStyle(color: Colors.grey[600]),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter at least one word pair';
                          }
                          // Validate format of each line
                          final lines = value.split('\n');
                          for (int i = 0; i < lines.length; i++) {
                            final line = lines[i].trim();
                            if (line.isNotEmpty && !line.contains('\\')) {
                              return 'Line ${i + 1} is missing the \\ separator';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    if (isBulkMode.value) {
                      await _addBulkFlashcards();
                    } else {
                      final newFlashcard = Flashcard(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        word: wordController.text,
                        translation: translationController.text,
                        targetLanguageCode: targetLanguageState.value.code,
                        nativeLanguageCode: nativeLanguageState.value.code,
                        srsNextReviewDate: DateTime.now().millisecondsSinceEpoch,
                        srsInterval: 1.0,
                        srsEaseFactor: 2.5,
                      );

                      await ref.read(offlineFlashcardsProvider.notifier)
                          .addFlashcard(newFlashcard);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isBulkMode.value 
                                ? 'Multiple flashcards added successfully'
                                : 'Flashcard added successfully'
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                child: const Text('ADD'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashcards = ref.watch(offlineFlashcardsProvider);

    return Scaffold(
      body: flashcards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No flashcards available',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFlashcardDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Flashcard'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: flashcards.length,
              itemBuilder: (context, index) {
                final flashcard = flashcards[index];
                return Dismissible(
                  key: Key(flashcard.id.toString()), // Convert id to String for Key
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    ref.read(offlineFlashcardsProvider.notifier)
                        .removeFlashcard(int.parse(flashcard.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Flashcard deleted'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(flashcard.word),
                      subtitle: Text(flashcard.translation),
                      trailing: Text(
                        'Last reviewed: ${flashcard.srsLastReviewDate != null ? "Yes" : "No"}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFlashcardDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
