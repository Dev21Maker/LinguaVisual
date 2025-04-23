import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/providers/connectivity_provider.dart';
import 'package:lingua_visual/providers/navigator_provider.dart';
import 'package:lingua_visual/screens/games/games_view.dart';
import 'package:lingua_visual/screens/games/srs/learn_screen.dart';
import 'package:lingua_visual/screens/progress/progress_screen.dart';
import 'package:lingua_visual/screens/settings/settings_screen.dart';
import 'package:lingua_visual/screens/flashcards/flashcard_screen.dart';
import 'package:lingua_visual/screens/auth/login_screen.dart';
import 'package:lingua_visual/providers/settings_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/session_cleanup_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Failed to load .env file: $e');
  }
  
  await Firebase.initializeApp();
  
  final prefs = await SharedPreferences.getInstance();
  final settingsNotifier = SettingsNotifier(prefs);

  final sessionCleanupService = SessionCleanupService();
  await sessionCleanupService.cleanupSessionIfNeeded();

  runApp(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith((ref) => settingsNotifier),
      ],
      child: const MyApp(),
    ),
  );
}

abstract class AppColors {
  // Light Theme Colors
  static const lightPrimary = Color(0xFF2D6CDF);      // Vibrant blue
  static const lightSecondary = Color(0xFF8C6FF3);    // Soft purple
  static const lightSurface = Color(0xFFF8F9FC);      // Nearly white
  static const lightBackground = Color(0xFFFFFFFF);   // Pure white
  static const lightAccent1 = Color(0xFF45C6B1);      // Turquoise
  static const lightAccent2 = Color(0xFFFF9D76);      // Coral
  static const lightNeutral = Color(0xFFF2F4F7);      // Light gray
  static const lightError = Color(0xFFE5484D);        // Red

  // Dark Theme Colors
  static const darkPrimary = Color(0xFF629FFF);      // Lighter blue
  static const darkSecondary = Color(0xFFA894F9);    // Lighter purple
  static const darkSurface = Color(0xFF1C1C1E);      // Dark gray
  static const darkBackground = Color(0xFF000000);    // Pure black
  static const darkAccent1 = Color(0xFF65E6D2);      // Brighter turquoise
  static const darkAccent2 = Color(0xFFFFB599);      // Lighter coral
  static const darkNeutral = Color(0xFF2C2C2E);      // Darker gray
  static const darkError = Color(0xFFFF6B6B);        // Brighter red
}

class AppTheme {
  final bool isDark;

  const AppTheme({required this.isDark});

  Color get primary => isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
  Color get secondary => isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  Color get surface => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get background => isDark ? AppColors.darkBackground : AppColors.lightBackground;
  Color get accent1 => isDark ? AppColors.darkAccent1 : AppColors.lightAccent1;
  Color get accent2 => isDark ? AppColors.darkAccent2 : AppColors.lightAccent2;
  Color get neutral => isDark ? AppColors.darkNeutral : AppColors.lightNeutral;
  Color get error => isDark ? AppColors.darkError : AppColors.lightError;
  Color get onPrimary => isDark ? Colors.black : Colors.white;
  Color get onSecondary => isDark ? Colors.black : Colors.white;
  Color get onBackground => isDark ? Colors.white : Colors.black;
  Color get onSurface => isDark ? Colors.white : Colors.black;
  Color get onError => Colors.white;
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(AppTheme theme) {
    return ThemeData(
      useMaterial3: true,
      brightness: theme.isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: theme.isDark ? Brightness.dark : Brightness.light,
        primary: theme.primary,
        onPrimary: theme.onPrimary,
        secondary: theme.secondary,
        onSecondary: theme.onSecondary,
        background: theme.background,
        onBackground: theme.onBackground,
        surface: theme.surface,
        onSurface: theme.onSurface,
        error: theme.error,
        onError: theme.onError,
      ),
      scaffoldBackgroundColor: theme.background,
      cardColor: theme.surface,
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: theme.surface,
        foregroundColor: theme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: theme.primary.withOpacity(0.1),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: theme.onPrimary,
          elevation: 2,
          shadowColor: theme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        color: theme.surface,
        elevation: 2,
        shadowColor: theme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.neutral,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primary, width: 2),
        ),
      ),
      
      // Icon theme
      iconTheme: IconThemeData(
        color: theme.primary,
        size: 24,
      ),
      
      // Text theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: theme.onBackground,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: theme.onBackground,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: theme.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: theme.onBackground,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: theme.onBackground.withOpacity(0.8),
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigatorKey = ref.watch(navigatorKeyProvider);
    
    final settings = ref.watch(settingsProvider);
    final themeMode = settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;

    useEffect(() {
      final connectivity = Connectivity();
      // Initial connectivity check
      ConnectivityService.checkConnectivity().then((hasConnection) {
        ref.read(isOnlineProvider.notifier).state = hasConnection;
      });
      
      // Listen for connectivity changes
      final subscription = connectivity.onConnectivityChanged.listen((result) {
        final hasConnection = result != ConnectivityResult.none;
        ref.read(isOnlineProvider.notifier).state = hasConnection;
      });
      
      return subscription.cancel;
    }, const []);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'LinguaVisual',
      theme: _buildTheme(const AppTheme(isDark: false)),
      darkTheme: _buildTheme(const AppTheme(isDark: true)),
      themeMode: themeMode,
      home: Consumer(
        builder: (context, ref, child) {
          final isOnline = ref.watch(isOnlineProvider);
          if (!isOnline) return const OfflineHomeScreen();
          
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }

              if (snapshot.hasData) {
                return const HomeScreen();
              }

              return const LoginScreen();
            },
          );
        },
      ),
    );
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
                  content: HookBuilder(
                    builder: (context) {
                      final isReconnecting = useState(false);
                      
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'You are currently in offline mode. Your changes will be saved locally '
                            'and synced when you reconnect to the server.'
                          ),
                          if (isReconnecting.value) ...[
                            const SizedBox(height: 16),
                            const LinearProgressIndicator(),
                            const SizedBox(height: 8),
                            const Text(
                              'Attempting to reconnect...',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                    HookBuilder(
                      builder: (context) {
                        final isReconnecting = useState(false);
                        
                        return TextButton(
                          onPressed: isReconnecting.value
                            ? null
                            : () async {
                                isReconnecting.value = true;
                                try {
                                  // If successful, update online status
                                  ref.read(isOnlineProvider.notifier).state = true;
                                  
                                  // Try to sync offline data if available
                                  // final syncService = ref.read(syncServiceProvider);
                                  // await syncService.syncOfflineData();
                                  
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Successfully reconnected to server'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to connect: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    isReconnecting.value = false;
                                  }
                                }
                              },
                          child: Text(
                            isReconnecting.value ? 'CONNECTING...' : 'TRY RECONNECT',
                          ),
                        );
                      },
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
              LearnScreen(),
              FlashcardScreen(),
              SettingsScreen(),
            ],
          ),
        ),
      ),
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 4, // Updated from 3 to 4
        child: Scaffold(
          bottomNavigationBar: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.school), text: 'Learn'),
              Tab(icon: Icon(Icons.library_books), text: 'Flashcards'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Progress'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'), // New tab
            ],
          ),
          body: TabBarView(
            children: [
              GamesView(),
              FlashcardScreen(),
              ProgressScreen(),
              SettingsScreen(), // Added SettingsScreen
            ],
          ),
        ),
      ),
    );
  }
}

// class OfflineFlashcardsNotifier extends StateNotifier<AsyncValue<List<Flashcard>>> {
//   OfflineFlashcardsNotifier() : super(const AsyncValue.loading()) {
//     _loadFlashcards();
//   }

//   Future<void> _loadFlashcards() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final flashcardsJson = prefs.getStringList('offline_flashcards') ?? [];
//       final cards = flashcardsJson
//           .map((json) => Flashcard.fromMap(jsonDecode(json)))
//           .toList();
//       state = AsyncValue.data(cards);
//     } catch (e, st) {
//       state = AsyncValue.error(e, st);
//     }
//   }

//   Future<void> addFlashcard(Flashcard flashcard) async {
//     final current = state.value ?? [];
//     state = AsyncValue.data([...current, flashcard]);
//     await _saveFlashcards();
//   }

//   Future<void> _saveFlashcards() async {
//     final prefs = await SharedPreferences.getInstance();
//     final current = state.value ?? [];
//     final flashcardsJson = current
//         .map((flashcard) => jsonEncode(flashcard.toMap()))
//         .toList();
//     await prefs.setStringList('offline_flashcards', flashcardsJson);
//   }

//   Future<void> removeFlashcard(String id) async {
//     final current = state.value ?? [];
//     state = AsyncValue.data(current.where((flashcard) => flashcard.id != id).toList());
//     await _saveFlashcards();
//   }

//   Future<void> updateCard(Flashcard updatedCard) async {
//     final current = state.value ?? [];
//     state = AsyncValue.data(current.map((card) =>
//       card.id == updatedCard.id ? updatedCard : card
//     ).toList());
//     await _saveFlashcards();
//   }
// }

// final offlineFlashcardsProvider = StateNotifierProvider<OfflineFlashcardsNotifier, AsyncValue<List<Flashcard>>>((ref) {
//   return OfflineFlashcardsNotifier();
// });

// class OfflineLearnScreen extends ConsumerWidget {
//   const OfflineLearnScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final flashcardsAsync = ref.watch(offlineFlashcardsProvider);

//     return flashcardsAsync.when(
//       loading: () => const Center(child: CircularProgressIndicator()),
//       error: (err, stack) => Center(child: Text('Error loading flashcards')), // Optionally show error
//       data: (flashcards) {
//         if (flashcards.isEmpty) {
//           return const Center(
//             child: Text('No flashcards available offline'),
//           );
//         }
//         return Scaffold(
//           body: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   '${flashcards.length} cards available',
//                   style: Theme.of(context).textTheme.titleLarge,
//                 ),
//                 const SizedBox(height: 24),
//                 ElevatedButton.icon(
//                   onPressed: () {
//                     Navigator.of(context).push(
//                       MaterialPageRoute(
//                         builder: (context) => const OfflineTrainingScreen(),
//                       ),
//                     );
//                   },
//                   icon: const Icon(Icons.play_arrow),
//                   label: const Text('Start Training'),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 32,
//                       vertical: 16,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class OfflineFlashcardScreen extends HookConsumerWidget {
//   const OfflineFlashcardScreen({super.key});

//   void _showAddFlashcardDialog(BuildContext context, WidgetRef ref) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return FlashCardBuilder(
//           ref: ref,
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final flashcardsAsync = ref.watch(offlineFlashcardsProvider);

//     return flashcardsAsync.when(
//       loading: () => const Center(child: CircularProgressIndicator()),
//       error: (err, stack) => Center(child: Text('Error loading flashcards')), // Optionally show error
//       data: (flashcards) => Scaffold(
//         body: flashcards.isEmpty
//             ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       'No flashcards available',
//                       style: TextStyle(fontSize: 18),
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton.icon(
//                       onPressed: () => _showAddFlashcardDialog(context, ref),
//                       icon: const Icon(Icons.add),
//                       label: const Text('Add Your First Flashcard'),
//                     ),
//                   ],
//                 ),
//               )
//             : ListView.builder(
//                 itemCount: flashcards.length,
//                 itemBuilder: (context, index) {
//                   final flashcard = flashcards[index];
//                   return Dismissible(
//                     key: Key(flashcard.id), // Convert id to String for Key
//                     background: Container(
//                       color: Colors.red,
//                       alignment: Alignment.centerRight,
//                       padding: const EdgeInsets.only(right: 16),
//                       child: const Icon(Icons.delete, color: Colors.white),
//                     ),
//                     direction: DismissDirection.endToStart,
//                     onDismissed: (direction) {
//                       ref.read(offlineFlashcardsProvider.notifier)
//                           .removeFlashcard(flashcard.id);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Flashcard deleted'),
//                           backgroundColor: Colors.red,
//                         ),
//                       );
//                     },
//                     child: Card(
//                       margin: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 8,
//                       ),
//                       child: ListTile(
//                         title: Text(flashcard.word),
//                         subtitle: Text(flashcard.translation),
//                         trailing: Text(
//                           'Last reviewed: ${flashcard.srsLastReviewDate != null ? "Yes" : "No"}',
//                           style: Theme.of(context).textTheme.bodySmall,
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//         floatingActionButton: FloatingActionButton(
//           onPressed: () => _showAddFlashcardDialog(context, ref),
//           child: const Icon(Icons.add),
//         ),
//       ),
//     );
//   }
// }
