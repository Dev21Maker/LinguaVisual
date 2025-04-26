import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/models/flashcard.dart' show Flashcard;
import 'package:lingua_visual/providers/flashcard_provider.dart';
import 'package:lingua_visual/providers/offline_flashcard_provider.dart';
import 'package:lingua_visual/providers/connectivity_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingua_visual/providers/stack_provider.dart';
import 'package:lingua_visual/package/models/flashcard_item.dart' show FlashcardItem;
import 'package:lingua_visual/package/models/review_outcome.dart' as srs_model;
import 'package:lingua_visual/package/srs_manager.dart' as srs_package ;
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
    final srsManager = useMemoized(() => srs_package.SRSManager(), []);
    final isOnline = ref.watch(isOnlineProvider);
    final currentImageUrl = useState<String?>(null);

    String? _getImageUrlForCard(String flashcardId) {
      final isOnline = ref.read(isOnlineProvider);
      if (isOnline) {
        final flashcardsData = ref.read(flashcardStateProvider).value;
        if (flashcardsData == null || flashcardsData.isEmpty) return null;
        
        final flashcard = flashcardsData.firstWhere(
          (card) => card.id == flashcardId,
          orElse: () => flashcardsData.first,
        );
        return flashcard.imageUrl;
      } else {
        final flashcardsData = ref.read(offlineFlashcardsProvider).value;
        if (flashcardsData == null || flashcardsData.isEmpty) return null;
        
        final flashcard = flashcardsData.firstWhere(
          (card) => card.id == flashcardId,
          orElse: () => flashcardsData.first,
        );
        return flashcard.imageUrl;
      }
    }

    void updateCurrentImageUrl(String flashcardId) {
      currentImageUrl.value = _getImageUrlForCard(flashcardId);
    }

    useEffect(() {
      return () async {
        if (reviewedCards.value.isNotEmpty) {
          final isOnline = ref.read(isOnlineProvider);
          
          for (final entry in reviewedCards.value.entries) {
            final (flashcardItem, rating) = entry.value;
            try {
              if (isOnline) {
                final flashcardsData = ref.read(flashcardStateProvider).value;
                if (flashcardsData == null || flashcardsData.isEmpty) continue;
                
                final cardToUpdate = flashcardsData.firstWhere(
                  (card) => card.id == flashcardItem.id,
                  orElse: () => flashcardsData.first,
                );
                
                final updatedCard = cardToUpdate.copyWith(
                  srsInterval: flashcardItem.interval.toDouble(),
                  srsEaseFactor: flashcardItem.personalDifficultyFactor,
                  srsNextReviewDate: flashcardItem.nextReviewDate.millisecondsSinceEpoch,
                );
                await ref.read(flashcardStateProvider.notifier).updateFlashcard(updatedCard);
              } else {
                final flashcardsData = ref.read(offlineFlashcardsProvider).value;
                if (flashcardsData == null || flashcardsData.isEmpty) continue;
                
                final cardToUpdate = flashcardsData.firstWhere(
                  (card) => card.id == flashcardItem.id,
                  orElse: () => flashcardsData.first,
                );
                
                final updatedCard = cardToUpdate.copyWith(
                  srsInterval: flashcardItem.interval.toDouble(),
                  srsEaseFactor: flashcardItem.personalDifficultyFactor,
                  srsNextReviewDate: flashcardItem.nextReviewDate.millisecondsSinceEpoch,
                );
                await ref.read(offlineFlashcardsProvider.notifier).updateCard(updatedCard);
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
        
        await flashcardsAsync.whenData((flashcards) async {
          srsManager.clear();
          
          if (flashcards.isEmpty) {
            isLoadingState.value = false;
            return;
          }
          
          // Only filter by stack if a stack is selected
          final filteredFlashcards = selectedStackId.value != null 
              ? flashcards.where((card) {
                  final stack = ref.read(stacksProvider.notifier).getStackById(selectedStackId.value!);
                  return stack.flashcardIds.contains(card.id);
                }).toList()
              : flashcards;
          
          for (final Flashcard card in filteredFlashcards) {
            final srsItem = FlashcardItem(
              id: card.id,
              languageId: card.targetLanguageCode,
              question: card.word,
              answer: card.translation,
              interval: card.interval.toInt(),
              personalDifficultyFactor: card.easeFactor,
              nextReviewDate: card.nextReviewDate,
            );
            
            srsManager.addItem(srsItem);
          }
          
          final dueItems = srsManager.getDueItems(DateTime.now());
          dueItemsState.value = dueItems;
          
          isLoadingState.value = false;
          if (dueItems.isEmpty) {
            showEmptyState.value = true;
          }
        });
      } catch (e) {
        isLoadingState.value = false;
        errorState.value = e.toString();
        debugPrint('Error loading due cards: $e');
      } finally {
        emptyStateTimer.cancel();
      }
    }

    useEffect(() {
      loadDueCards();
      return null;
    }, [selectedStackId.value]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showStackSelector(
                context,
                ref,
                selectedStackId,
                loadDueCards,
              );
            },
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
        updateCurrentImageUrl,
        currentImageUrl,
        srsManager,
      ),
    );
  }

  void _showStackSelector(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String?> selectedStackId,
    VoidCallback onStackSelected,
  ) {
    final stacksAsync = ref.watch(stacksProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Stack'),
        content: SizedBox(
          width: double.maxFinite,
          child: stacksAsync.when(
            data: (stacks) {
              return ListView(
                shrinkWrap: true,
                children: [
                  // Add "All Cards" option
                  ListTile(
                    title: const Text('All Cards'),
                    selected: selectedStackId.value == null,
                    onTap: () {
                      selectedStackId.value = null;
                      onStackSelected();
                      Navigator.pop(context);
                    },
                  ),
                  // Add divider
                  const Divider(),
                  // List all stacks
                  ...stacks.map((stack) {
                    final flashcardsAsync = ref.watch(flashcardStateProvider);
                    final dueCount = flashcardsAsync.whenOrNull(
                      data: (flashcards) => flashcards
                          .where((card) => stack.flashcardIds.contains(card.id))
                          .length,
                    ) ?? 0;

                    return ListTile(
                      title: Text(stack.name),
                      subtitle: Text('$dueCount cards'),
                      selected: selectedStackId.value == stack.id,
                      onTap: () {
                        selectedStackId.value = stack.id;
                        onStackSelected();
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error: $error'),
          ),
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
    void Function(String) updateCurrentImageUrl,
    ValueNotifier<String?> currentImageUrl,
    srs_package.SRSManager srsManager,
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

    if (dueItems.isNotEmpty) {
      updateCurrentImageUrl(dueItems.first.id);
    }

    return FlashcardView(
      flashcards: dueItems,
      imageUrl: currentImageUrl.value,
      onRatingSelected: (rating, flashcard) {
        srs_model.ReviewOutcome outcome;
        switch (rating.toLowerCase()) {
          case 'again':
            outcome = srs_model.ReviewOutcome.missed;
            break;
          case 'hard':
          case 'good': 
            outcome = srs_model.ReviewOutcome.gotIt;
            break;
          case 'easy':
            outcome = srs_model.ReviewOutcome.quick;
            break;
          default:
            outcome = srs_model.ReviewOutcome.gotIt;
        }
        
        final reviewType = srs_model.ReviewType.typing;
        
        final updatedItem = srsManager.recordReview(
          flashcard.id, 
          outcome, 
          reviewType
        );
        
        if (updatedItem != null) {
          final newReviewedCards = {...reviewedCards.value};
          newReviewedCards[flashcard.id] = (updatedItem, rating);
          reviewedCards.value = newReviewedCards;
          
          final newDueItems = dueItemsState.value.where((item) => item.id != flashcard.id).toList();
          dueItemsState.value = newDueItems;
          
          if (newDueItems.isNotEmpty) {
            updateCurrentImageUrl(newDueItems.first.id);
          } else {
            currentImageUrl.value = null;
          }
          
          if (newDueItems.isEmpty) {
            isSessionComplete.value = true;
          }
        }
      },
      showTranslation: false,
    );
  }
}
