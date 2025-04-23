import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/providers/flashcard_provider.dart';
import 'package:lingua_visual/providers/offline_flashcard_provider.dart';
import 'package:lingua_visual/providers/connectivity_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingua_visual/providers/stack_provider.dart';
import 'package:multi_language_srs/multi_language_srs.dart';
import 'package:lingua_visual/widgets/flashcard_view.dart';

class LearnScreen extends HookConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueItemsState = useState<List<FlashcardItem>>([]);
    final reviewedCards = useState<Map<String, (FlashcardItem, String)>>({});
    final isLoadingState = useState(true);
    final errorState = useState<String?>(null);
    final showEmptyState = useState(false);
    final selectedStackId = useState<String?>(null);
    final isSessionComplete = useState(false);
    final srsManager = useMemoized(() => SRSManager(), []);
    final isOnline = ref.watch(isOnlineProvider);

    // Effect to save reviewed cards when leaving screen
    useEffect(() {
      return () async {
        if (reviewedCards.value.isNotEmpty) {
          final isOnline = ref.read(isOnlineProvider);
          
          for (final entry in reviewedCards.value.entries) {
            final (flashcardItem, rating) = entry.value;
            try {
              if (isOnline) {
                final cardToUpdate = ref.read(flashcardStateProvider).value?.firstWhere((card) => card.id == flashcardItem.id);
                if (cardToUpdate != null) {
                  final updatedCard = cardToUpdate.copyWith(
                    srsInterval: flashcardItem.interval.toDouble(),
                    srsEaseFactor: flashcardItem.easeFactor,
                    srsNextReviewDate: flashcardItem.nextReviewDate.millisecondsSinceEpoch,
                  );
                  await ref.read(flashcardStateProvider.notifier).updateFlashcard(updatedCard);
                }
              } else {
                final cardToUpdate = ref.read(offlineFlashcardsProvider).value?.firstWhere((card) => card.id == flashcardItem.id);
                if (cardToUpdate != null) {
                  final updatedCard = cardToUpdate.copyWith(
                    srsInterval: flashcardItem.interval.toDouble(),
                    srsEaseFactor: flashcardItem.easeFactor,
                    srsNextReviewDate: flashcardItem.nextReviewDate.microsecondsSinceEpoch,
                  );
                  await ref.read(offlineFlashcardsProvider.notifier).updateCard(updatedCard);
                }
              }
            } catch (e) {
              print('Failed to save reviewed card: $e');
            }
          }
        }
      };
    }, []);

    Future<void> loadDueCards() async {
      isLoadingState.value = true;
      errorState.value = null;
      showEmptyState.value = false;
      dueItemsState.value = [];

      final emptyStateTimer = Timer(const Duration(seconds: 7), () {
        if (isLoadingState.value) {
          showEmptyState.value = true;
        }
      });

      try {
        final flashcardsAsync = isOnline 
            ? ref.read(flashcardStateProvider) 
            : ref.read(offlineFlashcardsProvider);

        flashcardsAsync.when(
          data: (cards) {
            // Get all cards if no stack is selected, otherwise filter by stack
            final filteredCards = selectedStackId.value == null
                ? cards  // Use all cards
                : cards.where((card) {
                    final stack = ref.watch(stacksProvider).value?.firstWhere(
                      (s) => s.id == selectedStackId.value,
                    );
                    return stack?.flashcardIds.contains(card.id) ?? false;
                  }).toList();
            
            srsManager.clear();
            
            for (final card in filteredCards) {
              final flashcardItem = FlashcardItem(
                id: card.id,
                question: card.word,
                answer: card.translation,
                languageId: card.targetLanguageCode,
                interval: card.interval.toInt(),
                easeFactor: card.easeFactor,
                nextReviewDate: card.nextReviewDate,
                reviews: 0,
              );
              srsManager.addItem(flashcardItem);
            }

            final dueItems = srsManager.getDueItems(DateTime.now());
            dueItemsState.value = dueItems;
            
            if (dueItems.isEmpty) {
              showEmptyState.value = true;
            }
            
            isLoadingState.value = false;
            emptyStateTimer.cancel();
          },
          loading: () {
            isLoadingState.value = true;
          },
          error: (error, stack) {
            errorState.value = error.toString();
            isLoadingState.value = false;
            emptyStateTimer.cancel();
          },
        );
      } catch (e) {
        errorState.value = e.toString();
        isLoadingState.value = false;
        emptyStateTimer.cancel();
      }
    }

    // Effect to load cards when stack selection changes
    useEffect(() {
      loadDueCards();
      return;
    }, [selectedStackId.value]);

    return Scaffold(
      appBar: AppBar(
        title: ref.watch(stacksProvider).when(
          data: (stacks) {
            if (selectedStackId.value == null) {
              return Text('All Cards ${isOnline ? "" : "(Offline)"}');
            }
            final stackName = stacks
                .firstWhere((s) => s.id == selectedStackId.value)
                .name;
            return Text('Learning: $stackName ${isOnline ? "" : "(Offline)"}');
          },
          loading: () => const Text('Learning'),
          error: (_, __) => const Text('Learning'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showStackSelector(context, ref, selectedStackId, loadDueCards),
          ),
        ],
      ),
      body: _buildBody(
        context,
        isLoadingState.value,
        errorState.value,
        dueItemsState.value,
        showEmptyState.value,
        selectedStackId,
        loadDueCards,
        isSessionComplete,
        reviewedCards,
        dueItemsState,
      ),
    );
  }

  void _showStackSelector(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String?> selectedStackId,
    VoidCallback onStackSelected,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Stack',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ref.watch(stacksProvider).when(
                data: (stacks) => ListView(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.all_inclusive),
                      ),
                      title: const Text('All Cards'),
                      selected: selectedStackId.value == null,
                      onTap: () {
                        selectedStackId.value = null;
                        onStackSelected();
                        Navigator.pop(context);
                      },
                    ),
                    if (stacks.isNotEmpty) const Divider(),
                    ...stacks.map(
                      (stack) => ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.folder),
                        ),
                        title: Text(stack.name),
                        subtitle: Text(
                          '${stack.flashcardIds.length} cards',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        selected: stack.id == selectedStackId.value,
                        onTap: () {
                          selectedStackId.value = stack.id;
                          onStackSelected();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(
                  child: Text('Error loading stacks'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isLoading,
    String? error,
    List<FlashcardItem> dueItems,
    bool showEmpty,
    ValueNotifier<String?> selectedStackId,
    VoidCallback loadDueCards,
    ValueNotifier<bool> isSessionComplete,
    ValueNotifier<Map<String, (FlashcardItem, String)>> reviewedCards,
    ValueNotifier<List<FlashcardItem>> dueItemsState,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadDueCards,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (dueItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              showEmpty ? 'No cards due for review!' : 'Loading cards...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    // Your existing flashcard review UI here
    return Consumer(
      builder: (context, ref, _) {
        return FlashcardView(
          flashcards: dueItems,
          onRatingSelected: (rating, flashcard) {
            // Calculate new SRS parameters based on the rating
            double newInterval;
            double newEaseFactor = flashcard.easeFactor;
            const minimumEaseFactor = 1.3;

            switch (rating.toLowerCase()) {
              case 'again':
                newInterval = 1.0;
                newEaseFactor = max(minimumEaseFactor, flashcard.easeFactor - 0.2);
                break;
              case 'hard':
                newInterval = flashcard.interval * 1.2;
                newEaseFactor = max(minimumEaseFactor, flashcard.easeFactor - 0.15);
                break;
              case 'good':
                newInterval = flashcard.interval * flashcard.easeFactor;
                break;
              case 'easy':
                newInterval = flashcard.interval * flashcard.easeFactor * 1.3;
                newEaseFactor = min(2.5, flashcard.easeFactor + 0.15);
                break;
              default:
                newInterval = flashcard.interval.toDouble();
            }

            // Create updated FlashcardItem
            final updatedItem = FlashcardItem(
              id: flashcard.id,
              question: flashcard.question,
              answer: flashcard.answer,
              languageId: flashcard.languageId,
              interval: newInterval.toInt(),
              easeFactor: newEaseFactor,
              nextReviewDate: DateTime.now().add(Duration(days: newInterval.toInt())),
              reviews: flashcard.reviews + 1,
            );

            // Store the reviewed card and update state
            final newReviewedCards = {...reviewedCards.value};
            newReviewedCards[flashcard.id] = (updatedItem, rating);
            reviewedCards.value = newReviewedCards;

            // Remove card from due items
            final newDueItems = dueItemsState.value.where((item) => item.id != flashcard.id).toList();
            dueItemsState.value = newDueItems;

            // Check if session is complete
            if (newDueItems.isEmpty) {
              isSessionComplete.value = true;
            }
          },
        );
      },
    );
  }
}
