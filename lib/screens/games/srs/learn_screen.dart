import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/main.dart';
import 'package:lingua_visual/models/flashcard.dart';
import 'package:lingua_visual/providers/flashcard_provider.dart';
import 'package:lingua_visual/providers/supabase_provider.dart';
import 'package:lingua_visual/widgets/flashcard_view.dart';
// import 'screens/progress_screen.dart';
// import 'screens/settings_screen.dart';
import 'package:lingua_visual/providers/auth_provider.dart' as auth_prov;
import 'package:flutter_hooks/flutter_hooks.dart';

class LearnScreen extends HookConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCardsState = useState<List<Flashcard>>([]);
    final isLoadingState = useState(true);
    final errorState = useState<String?>(null);
    final showEmptyState = useState(false);

    // --- Flashcard login/session refresh logic ---
    final _loginTimer = useRef<Timer?>(null);
    final authService = ref.read(auth_prov.authServiceProvider);
    final isMounted = useIsMounted();

    Future<void> refreshSession() async {
      try {
        await authService.initializeAuthState();
      } catch (e) {
        if (isMounted()) {
          errorState.value = 'Session expired. Please log in again.';
        }
      }
    }

    useEffect(() {
      // Initial session refresh
      refreshSession();
      // Start periodic refresh every 7 seconds
      _loginTimer.value = Timer.periodic(const Duration(seconds: 7), (_) {
        refreshSession();
      });
      return () {
        _loginTimer.value?.cancel();
      };
    }, const []);

    // --- End flashcard login/session refresh logic ---

    Future<void> loadDueCards() async {
      // Reset states
      isLoadingState.value = true;
      errorState.value = null;
      showEmptyState.value = false;
      dueCardsState.value = [];
      
      // Start a timer to show empty state after 7 seconds
      Future.delayed(const Duration(seconds: 7), () {
        if (isLoadingState.value) {
          showEmptyState.value = true;
        }
      });

      try {
        final supabaseService = ref.read(supabaseServiceProvider);
        final cards = await supabaseService.fetchDueCards();
        
        if (cards.isEmpty) {
          await ref.read(activeLearningProvider.notifier).loadDueCards();
          final updatedCards = await supabaseService.fetchDueCards();
          dueCardsState.value = updatedCards;
        } else {
          dueCardsState.value = cards;
        }
      } catch (e) {
        errorState.value = e.toString();
      } finally {
        isLoadingState.value = false;
      }
    }

    useEffect(() {
      loadDueCards();
      return null;
    }, const []);

    if (isLoadingState.value) {
      if (showEmptyState.value) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Taking longer than expected...',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your internet connection',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                IconButton(
                  onPressed: () {
                    showEmptyState.value = false;
                    isLoadingState.value = true;
                    loadDueCards();
                  },
                  icon: const Icon(Icons.refresh),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return const LoadingScreen();
    }

    if (errorState.value != null) {
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
              errorState.value!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: loadDueCards,
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

    if (isLoadingState.value || dueCardsState.value.isEmpty) {
      return Center(
        child: isLoadingState.value
            ? const LoadingScreen()
            : Text('No cards due for review!'),
      );
    }

    // --- Flashcard study logic with 7-second timeout ---
    final currentIndex = useState(0);
    final cardTimer = useRef<Timer?>(null);
    final isSessionComplete = useState(false);

    void nextCard() {
      if (currentIndex.value < dueCardsState.value.length - 1) {
        currentIndex.value++;
      } else {
        isSessionComplete.value = true;
      }
    }

    void startCardTimer() {
      cardTimer.value?.cancel();
      cardTimer.value = Timer(const Duration(seconds: 7), nextCard);
    }

    useEffect(() {
      if (!isSessionComplete.value) {
        startCardTimer();
      } else {
        cardTimer.value?.cancel();
      }
      return () {
        cardTimer.value?.cancel();
      };
    }, [currentIndex.value, isSessionComplete.value]);

    if (isSessionComplete.value) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session Complete')),
        body: Center(
          child: Card(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF23272F)
                : Colors.white,
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.celebration, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 24),
                  Text('You have finished all due flashcards!',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final flashcard = dueCardsState.value[currentIndex.value];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                dueCardsState.value.length,
                (idx) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: idx == currentIndex.value
                        ? borderColor
                        : borderColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Flashcard
            Card(
              color: cardBg,
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
                side: BorderSide(color: borderColor, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      flashcard.word,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold, color: textColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        nextCard();
                        startCardTimer();
                      },
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: borderColor,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Card ${currentIndex.value + 1} of ${dueCardsState.value.length}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: borderColor)),
          ],
        ),
      ),
    );
    // --- End flashcard study logic ---
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
            flashcards: [currentCard],  // Wrap in list
            onRatingSelected: (rating, flashcard) => onRatingSelected(rating),
          ),
        ),
      ],
    );
  }
}
