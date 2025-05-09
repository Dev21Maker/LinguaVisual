import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Languador/providers/tab_index_provider.dart';
import 'package:Languador/screens/flashcards/flashcard_screen.dart';
import 'package:Languador/screens/games/games_view.dart';
import 'package:Languador/screens/progress/progress_screen.dart';
import 'package:Languador/screens/settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(tabIndexProvider);

    return SafeArea(
      top: true,
      bottom: true,
      child: DefaultTabController(
        length: 4,
        initialIndex: currentIndex,
        child: HookBuilder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);

            useEffect(() {
              void listener() {
                if (tabController.index != currentIndex) {
                  ref
                      .read(tabIndexProvider.notifier)
                      .setIndex(tabController.index);
                }
              }

              tabController.addListener(listener);
              return () => tabController.removeListener(listener);
            }, [tabController]);

            return Scaffold(
              resizeToAvoidBottomInset: false,
              // bottomNavigationBar: SafeArea(
              //   bottom: true,
              //   child: BottomNavigationBar(items: [
              //     BottomNavigationBarItem(
              //       icon: Icon(Icons.school),
              //       label: 'Learn',
              //     ),
              //     BottomNavigationBarItem(
              //       icon: Icon(Icons.library_books),
              //       label: 'Flashcards',
              //     ),
              //     BottomNavigationBarItem(
              //       icon: Icon(Icons.bar_chart),
              //       label: 'Progress',
              //     ),
              //     BottomNavigationBarItem(
              //       icon: Icon(Icons.settings),
              //       label: 'Settings',
              //     ),
              //   ])

                // Container(
                //   color: Theme.of(context).scaffoldBackgroundColor,
                //   padding: EdgeInsets.only(bottom: 20.0),
                //   child: TabBar(
                //     controller: tabController,
                //     tabs: const [
                //       Tab(icon: Icon(Icons.school), text: 'Learn'),
                //       Tab(icon: Icon(Icons.library_books), text: 'Flashcards'),
                //       Tab(icon: Icon(Icons.bar_chart), text: 'Progress'),
                //       Tab(icon: Icon(Icons.settings), text: 'Settings'),
                //     ],
                //   ),
                // ),
              // ),
              body: TabBarView(
                controller: tabController,
                children: const [
                  GamesView(),
                  FlashcardScreen(),
                  ProgressScreen(),
                  SettingsScreen(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
