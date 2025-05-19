import 'package:Languador/screens/home_screen.dart';
import 'package:Languador/screens/router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Languador/providers/connectivity_provider.dart';
import 'package:Languador/providers/locale_provider.dart';
import 'package:Languador/providers/navigator_provider.dart';
import 'package:Languador/providers/tab_index_provider.dart';
import 'package:Languador/screens/games/srs/learn_screen.dart';
import 'package:Languador/screens/settings/settings_screen.dart';
import 'package:Languador/screens/flashcards/flashcard_screen.dart';
import 'package:Languador/screens/auth/login_screen.dart';
import 'package:Languador/providers/settings_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Failed to load .env file: $e');
  }

  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(overrides: [settingsProvider.overrideWith((ref) => SettingsNotifier(prefs))], child: const MyApp()),
  );
}

abstract class AppColors {
  // Light Theme Colors
  static const lightPrimary = Color(0xFF2D6CDF); // Vibrant blue
  static const lightSecondary = Color(0xFF8C6FF3); // Soft purple
  static const lightSurface = Color(0xFFF8F9FC); // Nearly white
  static const lightBackground = Color(0xFFFFFFFF); // Pure white
  static const lightAccent1 = Color(0xFF45C6B1); // Turquoise
  static const lightAccent2 = Color(0xFFFF9D76); // Coral
  static const lightNeutral = Color(0xFFF2F4F7); // Light gray
  static const lightError = Color(0xFFE5484D); // Red

  // Dark Theme Colors
  static const darkPrimary = Color(0xFF629FFF); // Lighter blue
  static const darkSecondary = Color(0xFFA894F9); // Lighter purple
  static const darkSurface = Color(0xFF1C1C1E); // Dark gray
  static const darkBackground = Color(0xFF000000); // Pure black
  static const darkAccent1 = Color(0xFF65E6D2); // Brighter turquoise
  static const darkAccent2 = Color(0xFFFFB599); // Lighter coral
  static const darkNeutral = Color(0xFF2C2C2E); // Darker gray
  static const darkError = Color(0xFFFF6B6B); // Brighter red
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: theme.surface,
        elevation: 2,
        shadowColor: theme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.neutral,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primary, width: 2),
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(color: theme.primary, size: 24),

      // Text theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: theme.onBackground, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: theme.onBackground, fontSize: 24, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: theme.onBackground, fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: theme.onBackground, fontSize: 16),
        bodyMedium: TextStyle(color: theme.onBackground.withOpacity(0.8), fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currentLocale = ref.watch(localeProvider); // Use this for MaterialApp.locale
    final navigatorKey = ref.watch(navigatorKeyProvider);

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
      debugShowCheckedModeBanner: false,
      // routerConfig: router,
      // routerDelegate: router.routerDelegate,
      navigatorKey: navigatorKey,
      title: 'Languador',
      theme: _buildTheme(const AppTheme(isDark: false)),
      darkTheme: _buildTheme(const AppTheme(isDark: true)),
      themeMode: themeMode,
      locale: currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('pl'), // Polish
      ],
      routes: {
        '/home' :(context) => const HomeScreen(),
      },
      home: InitScreen(),
    );
  }
}


class InitScreen extends StatelessWidget {
  const InitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
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
    );
  }
}

class OfflineHomeScreen extends ConsumerWidget {
  const OfflineHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(tabIndexProvider);

    return Scaffold(
      body: DefaultTabController(
        length: 3,
        initialIndex: currentIndex,
        child: HookBuilder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);

            useEffect(() {
              void listener() {
                ref.read(tabIndexProvider.notifier).setIndex(tabController.index);
              }

              tabController.addListener(listener);
              return () => tabController.removeListener(listener);
            }, [tabController]);

            return Scaffold(
              bottomNavigationBar: TabBar(
                controller: tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.school), text: 'Learn'),
                  Tab(icon: Icon(Icons.library_books), text: 'Flashcards'),
                  Tab(icon: Icon(Icons.settings), text: 'Settings'),
                ],
              ),
              body: TabBarView(
                controller: tabController,
                children: const [LearnScreen(), FlashcardScreen(), SettingsScreen()],
              ),
            );
          },
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
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading...')],
        ),
      ),
    );
  }
}


