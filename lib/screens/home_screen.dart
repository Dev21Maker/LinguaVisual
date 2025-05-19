import 'package:Languador/providers/tab_index_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'games/games_view.dart';
import 'flashcards/flashcard_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(tabIndexProvider);

    return SafeArea(
      top: false,
      child: Scaffold(
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

              return SafeArea(
                top: false,
                child: Scaffold(
                  bottomNavigationBar: TabBar(
                    controller: tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.school), text: 'Learn'),
                      Tab(icon: Icon(Icons.library_books), text: 'Flashcards'),
                      // TODO (keep this tab for now) - Tab(icon: Icon(Icons.bar_chart), text: 'Progress'),
                      Tab(icon: Icon(Icons.settings), text: 'Settings'),
                    ],
                  ),
                  body: TabBarView(
                    controller: tabController,
                    children: const [
                      GamesView(), 
                      FlashcardScreen(), 
                      // TODO (keep this tab for now) - ProgressScreen(), 
                      SettingsScreen()
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}