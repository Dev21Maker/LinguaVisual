// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// // Auth Screens
// import 'auth/login_screen.dart';
// import 'auth/signup_screen.dart';

// // Main Screens
// import 'home_screen.dart';
// import 'image_picker_screen.dart';

// // Flashcard Screens
// import 'flashcards/flashcard_screen.dart';
// import 'offline/offline_flashcard_screen.dart';
// import 'offline_training_screen.dart';

// // Game Screens
// import 'games/games_view.dart';
// import 'games/srs/learn_screen.dart';
// import 'games/srs/learn_summary_screen.dart';

// // Progress Screens
// import 'progress/progress_screen.dart';

// // Settings Screens
// import 'settings/settings_screen.dart';

// // Stack Screens
// import 'stacks/stack_detail_screen.dart';
// import 'stacks/stack_list_screen.dart';

// // Widgets
// import '../widgets/common/webview_screen.dart';

// /// A class that contains all the route names and paths for the app.
// class AppRoutes {
//   // Route names
//   static const String home = 'home';
//   static const String games = 'games';
//   static const String progress = 'progress';
//   static const String settings = 'settings';
//   static const String login = 'login';
//   static const String signup = 'signup';
//   static const String stacks = 'stacks';
//   static const String stackDetail = 'stackDetail';
//   static const String flashcards = 'flashcards';
//   static const String offlineFlashcards = 'offlineFlashcards';
//   static const String offlineTraining = 'offlineTraining';
//   static const String learn = 'learn';
//   static const String learnSummary = 'learnSummary';
//   static const String imagePicker = 'imagePicker';
//   static const String webview = 'webview';

//   // Paths
//   static const String homePath = '/';
//   static const String gamesPath = '/games';
//   static const String progressPath = '/progress';
//   static const String settingsPath = '/settings';
//   static const String loginPath = '/login';
//   static const String signupPath = '/signup';
//   static const String stacksPath = '/stacks';
//   static const String stackDetailPath = '/stacks/:stackId';
//   static const String flashcardsPath = '/flashcards';
//   static const String offlineFlashcardsPath = '/offline-flashcards';
//   static const String offlineTrainingPath = '/offline-training';
//   static const String learnPath = '/learn';
//   static const String learnSummaryPath = '/learn-summary';
//   static const String imagePickerPath = '/image-picker';
//   static const String webviewPath = '/webview';

//   // Helper method to get stack detail path with parameters
//   static String getStackDetailPath(String stackId) => '/stacks/$stackId';

//   // Helper method to get webview path with parameters
//   static String getWebViewPath({required String url, String title = ''}) => 
//       '/webview?url=${Uri.encodeComponent(url)}&title=${Uri.encodeComponent(title)}';
// }

// /// The main router configuration for the application
// final router = GoRouter(
//   initialLocation: AppRoutes.homePath,
//   debugLogDiagnostics: true,
//   routes: [
//     // Main route with bottom navigation
//     StatefulShellRoute.indexedStack(
//       builder: (context, state, navigationShell) {
//         return ScaffoldWithNavBar(navigationShell: navigationShell);
//       },
//       branches: [
//         // Home Tab
//         StatefulShellBranch(
//           routes: [
//             GoRoute(
//               path: AppRoutes.homePath,
//               name: AppRoutes.home,
//               builder: (context, state) => const HomeScreen(),
//             ),
//           ],
//         ),
//         // Games Tab
//         StatefulShellBranch(
//           routes: [
//             GoRoute(
//               path: AppRoutes.gamesPath,
//               name: AppRoutes.games,
//               builder: (context, state) => const GamesView(),
//             ),
//           ],
//         ),
//         // Progress Tab
//         StatefulShellBranch(
//           routes: [
//             GoRoute(
//               path: AppRoutes.progressPath,
//               name: AppRoutes.progress,
//               builder: (context, state) => const ProgressScreen(),
//             ),
//           ],
//         ),
//         // Settings Tab
//         StatefulShellBranch(
//           routes: [
//             GoRoute(
//               path: AppRoutes.settingsPath,
//               name: AppRoutes.settings,
//               builder: (context, state) => const SettingsScreen(),
//             ),
//           ],
//         ),
//       ],
//     ),

//     // Auth Routes
//     GoRoute(
//       path: AppRoutes.loginPath,
//       name: AppRoutes.login,
//       builder: (context, state) => const LoginScreen(),
//     ),
//     GoRoute(
//       path: AppRoutes.signupPath,
//       name: AppRoutes.signup,
//       builder: (context, state) => const SignUpScreen(),
//     ),

//     // Stack Management
//     GoRoute(
//       path: AppRoutes.stacksPath,
//       name: AppRoutes.stacks,
//       builder: (context, state) => const StackListScreen(),
//     ),
//     // GoRoute(
//     //   path: AppRoutes.stackDetailPath,
//     //   name: AppRoutes.stackDetail,
//     //   builder: (context, state) {
//     //     final stackId = state.pathParameters['stackId']!;
//     //     return StackDetailScreen(
//     //       stackId: stackId
//     //     );
//     //   },
//     // ),

//     // Flashcard Routes
//     GoRoute(
//       path: AppRoutes.flashcardsPath,
//       name: AppRoutes.flashcards,
//       builder: (context, state) => const FlashcardScreen(),
//     ),
//     GoRoute(
//       path: AppRoutes.offlineFlashcardsPath,
//       name: AppRoutes.offlineFlashcards,
//       builder: (context, state) => const OfflineFlashcardScreen(),
//     ),
//     GoRoute(
//       path: AppRoutes.offlineTrainingPath,
//       name: AppRoutes.offlineTraining,
//       builder: (context, state) => const OfflineTrainingScreen(),
//     ),

//     // Learning Flow
//     GoRoute(
//       path: AppRoutes.learnPath,
//       name: AppRoutes.learn,
//       builder: (context, state) => const LearnScreen(),
//     ),
//     GoRoute(
//       path: AppRoutes.learnSummaryPath,
//       name: AppRoutes.learnSummary,
//       builder: (context, state) => const LearnSummaryScreen(

//       ),
//     ),

//     // Utility Routes
//     GoRoute(
//       path: AppRoutes.imagePickerPath,
//       name: AppRoutes.imagePicker,
//       builder: (context, state) => const ImagePickerScreen(),
//     ),
//     GoRoute(
//       path: AppRoutes.webviewPath,
//       name: AppRoutes.webview,
//       builder: (context, state) {
//         final url = state.uri.queryParameters['url']!;
//         final title = state.uri.queryParameters['title'] ?? '';
//         return WebViewScreen(url: url, title: title);
//       },
//     ),
//   ],
//   errorBuilder: (context, state) => Scaffold(
//     body: Center(
//       child: Text('Page not found: ${state.uri.path}'),
//     ),
//   ),
// );

// class ScaffoldWithNavBar extends StatelessWidget {
//   final StatefulNavigationShell navigationShell;

//   const ScaffoldWithNavBar({
//     super.key,
//     required this.navigationShell,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: navigationShell,
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: navigationShell.currentIndex,
//         onTap: (index) => _onTap(context, index),
//         type: BottomNavigationBarType.fixed,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.games),
//             label: 'Games',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.insights),
//             label: 'Progress',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: 'Settings',
//           ),
//         ],
//       ),
//     );
//   }

//   void _onTap(BuildContext context, int index) {
//     navigationShell.goBranch(
//       index,
//       initialLocation: index == navigationShell.currentIndex,
//     );
//   }
// }

// // Extension methods for easy navigation
// extension GoRouterExtension on BuildContext {
//   // Navigation methods
//   void goToLogin() => goNamed(AppRoutes.login);
//   void goToSignUp() => goNamed(AppRoutes.signup);
//   void goToHome() => goNamed(AppRoutes.home);
//   void goToSettings() => goNamed(AppRoutes.settings);
//   void goToStacks() => goNamed(AppRoutes.stacks);
//   void goToStackDetails(String stackId) => go(AppRoutes.getStackDetailPath(stackId));
//   void goToFlashcards() => goNamed(AppRoutes.flashcards);
//   void goToOfflineFlashcards() => goNamed(AppRoutes.offlineFlashcards);
//   void goToOfflineTraining() => goNamed(AppRoutes.offlineTraining);
//   void goToGames() => goNamed(AppRoutes.games);
//   void goToLearn() => goNamed(AppRoutes.learn);
//   void goToLearnSummary() => goNamed(AppRoutes.learnSummary);
//   void goToProgress() => goNamed(AppRoutes.progress);
//   void goToImagePicker() => goNamed(AppRoutes.imagePicker);
//   void goToWebView({required String url, String title = ''}) => 
//       go(AppRoutes.getWebViewPath(url: url, title: title));
  
//   // Push methods (for modals or dialogs that should be in the navigation stack)
//   void pushToLogin() => pushNamed(AppRoutes.login);
//   void pushToSignUp() => pushNamed(AppRoutes.signup);
//   void pushToStackDetails(String stackId) => push(AppRoutes.getStackDetailPath(stackId));
  
//   // Replace methods (for login/logout flows)
//   void replaceWithLogin() => goNamed(AppRoutes.login, extra: {'replace': true});
//   void replaceWithHome() => goNamed(AppRoutes.home, extra: {'replace': true});
// }