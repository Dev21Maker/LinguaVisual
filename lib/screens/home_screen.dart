import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/providers/tab_index_provider.dart';
import 'package:lingua_visual/screens/flashcards/flashcard_screen.dart';
import 'package:lingua_visual/screens/games/games_view.dart';
import 'package:lingua_visual/screens/progress/progress_screen.dart';
import 'package:lingua_visual/screens/settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(tabIndexProvider);

    return DefaultTabController(
      length: 4,
      initialIndex: currentIndex,
      child: HookBuilder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);

          useEffect(() {
            void listener() {
              if (tabController.index != currentIndex) {
                ref.read(tabIndexProvider.notifier).setIndex(tabController.index);
              }
            }

            tabController.addListener(listener);
            return () => tabController.removeListener(listener);
          }, [tabController]);

          return SafeArea(
            child: Scaffold(
              bottomNavigationBar: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SafeArea(
                  child: TabBar(
                    controller: tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.school), text: 'Learn'),
                      Tab(icon: Icon(Icons.library_books), text: 'Flashcards'),
                      Tab(icon: Icon(Icons.bar_chart), text: 'Progress'),
                      Tab(icon: Icon(Icons.settings), text: 'Settings'),
                    ],
                  ),
                ),
              ),
              body: TabBarView(
                controller: tabController,
                children: const [GamesView(), FlashcardScreen(), ProgressScreen(), SettingsScreen()],
              ),
            ),
          );
        },
      ),
    );
  }
}
