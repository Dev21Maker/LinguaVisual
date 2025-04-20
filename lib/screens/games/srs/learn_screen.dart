import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/main.dart';
import 'package:lingua_visual/models/flashcard.dart';
import 'package:lingua_visual/providers/flashcard_provider.dart';
import 'package:lingua_visual/providers/settings_provider.dart';
import 'package:lingua_visual/providers/auth_provider.dart' as auth_prov;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:multi_language_srs/multi_language_srs.dart';
import 'package:lingua_visual/widgets/flashcard_view.dart';

class LearnScreen extends HookConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCardsState = useState<List<Flashcard>>([]);
    final isLoadingState = useState(true);
    final errorState = useState<String?>(null);
    final showEmptyState = useState(false);
    final settings = ref.watch(settingsProvider);
    final srsManager = useMemoized(() => SRSManager());

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
        // Fetch due items from SRS package and sort by earliest nextReviewDate
        final srsItems = srsManager.getDueItems(
          DateTime.now(),
          languageId: settings.targetLanguage.code,
        );
        srsItems.sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));
        dueCardsState.value = srsItems.map((item) => Flashcard(
          id: item.id,
          word: item.question,
          targetLanguage: settings.targetLanguage,
          translation: item.answer,
          nativeLanguage: settings.nativeLanguage,
          srsInterval: item.interval.toDouble(),
          srsEaseFactor: item.easeFactor,
          srsNextReviewDate: item.nextReviewDate.millisecondsSinceEpoch,
        )).toList();
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
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
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.home_outlined, size: 20),
                label: const Text('Go Home'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
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
            Builder(
              builder: (context) {
                final total = dueCardsState.value.length;
                final groupSize = 10;
                final group = currentIndex.value ~/ groupSize;
                final start = group * groupSize;
                final end = (start + groupSize > total) ? total : start + groupSize;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (start > 0)
                      const Text('... ', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...List.generate(end - start, (i) {
                      final idx = start + i;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: idx == currentIndex.value
                              ? borderColor
                              : borderColor.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                    if (end < total)
                      const Text(' ...', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            // Flashcard
            Expanded(
              child: FlashcardView(
                flashcards: [flashcard],
                onRatingSelected: (rating, flashcard) async {
                  // Cancel the auto-advance timer when user rates
                  cardTimer.value?.cancel();
                  
                  try {
                    // Update the card's SRS data in Supabase
                    await ref.read(activeLearningProvider.notifier).processCardRating(rating);
                    
                    // Move to next card
                    nextCard();
                    
                    // Start the timer for the next card
                    if (!isSessionComplete.value) {
                      startCardTimer();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating card: ${e.toString()}'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            Text('Card ${currentIndex.value + 1} of ${dueCardsState.value.length}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: borderColor)),
            const SizedBox(height: 24),
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
