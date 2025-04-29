import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/models/flashcard.dart';
import 'package:lingua_visual/providers/flashcard_provider.dart';
import 'package:lingua_visual/providers/offline_flashcard_provider.dart';
import 'package:lingua_visual/providers/stack_provider.dart';
import 'package:lingua_visual/widgets/flashcard_view.dart';
// import 'package:lingua_visual/widgets/loading_indicator.dart';
import 'package:lingua_visual/package/srs_manager.dart' as srs_package;
import 'package:lingua_visual/package/models/flashcard_item.dart' as srs_model;
import 'package:lingua_visual/package/models/review_outcome.dart' as srs_outcome;
import 'package:collection/collection.dart';

class LearnScreen extends HookConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueItemsState = useState<List<srs_model.FlashcardItem>>([]);
    final reviewedCards = useState<Map<String, (srs_model.FlashcardItem, String)>>({});
    final isLoadingState = useState(true);
    final errorState = useState<String?>(null);
    final showEmptyState = useState(false);
    final selectedStackId = useState<String?>(null);
    final isSessionComplete = useState(false);
    final srsManager = useMemoized(() => srs_package.SRSManager(), []);
    final currentImageUrl = useState<String?>(null);
    final showLoadMoreOption = useState(false);

    String? _getImageUrlForCard(String flashcardId) {
      final flashcardsData = ref.read(flashcardStateProvider).value;
      if (flashcardsData == null || flashcardsData.isEmpty) return null;
      
      final flashcard = flashcardsData.firstWhere(
        (card) => card.id == flashcardId,
        orElse: () => flashcardsData.first,
      );
      return flashcard.imageUrl;
    }

    void updateCurrentImageUrl(String flashcardId) {
      currentImageUrl.value = _getImageUrlForCard(flashcardId);
    }

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
        final flashcardsAsync = ref.read(flashcardStateProvider);
        
        await flashcardsAsync.whenData((flashcards) async {
          srsManager.clear();
          
          if (flashcards.isEmpty) {
            isLoadingState.value = false;
            return;
          }
          
          final filteredFlashcards = selectedStackId.value != null 
              ? flashcards.where((card) {
                  final stack = ref.read(stacksProvider.notifier).getStackById(selectedStackId.value!);
                  return stack.flashcardIds.contains(card.id);
                }).toList()
              : flashcards;
          
          final items = <srs_model.FlashcardItem>[]; 
          for (final Flashcard card in filteredFlashcards) {
            final item = srs_model.FlashcardItem(
              id: card.id,
              languageId: card.targetLanguageCode,
              question: card.word,
              answer: card.translation,
              interval: card.srsInterval.toInt(),
              personalDifficultyFactor: card.srsEaseFactor,
              nextReviewDate: DateTime.fromMillisecondsSinceEpoch(card.srsNextReviewDate),
              lastReviewDate: card.srsLastReviewDate != null ? DateTime.fromMillisecondsSinceEpoch(card.srsLastReviewDate!) : null,
              baseIntervalIndex: card.srsBaseIntervalIndex,
              quickStreak: card.srsQuickStreak,
              isPriority: card.srsIsPriority,
              isInLearningPhase: card.srsIsInLearningPhase,
            );
            items.add(item);
          }
          
          for (final item in items) {
            srsManager.addItem(item);
          }
          
          final dueItems = srsManager.getDueItems(DateTime.now());
          dueItemsState.value = dueItems;
          
          if (dueItems.isEmpty) {
            showLoadMoreOption.value = true;
          }
          
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
                    ListTile(
                      title: const Text('All Cards'),
                      selected: selectedStackId.value == null,
                      onTap: () {
                        selectedStackId.value = null;
                        onStackSelected();
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(),
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

    void _loadNextClosestCards(
      srs_package.SRSManager srsManager,
      ValueNotifier<List<srs_model.FlashcardItem>> dueItemsState,
      ValueNotifier<Map<String, (srs_model.FlashcardItem, String)>> reviewedCards,
      ValueNotifier<bool> isLoadingState,
      ValueNotifier<bool> showLoadMoreOption
    ) {
      isLoadingState.value = true;
      showLoadMoreOption.value = false; // Hide the button while loading

      final allSortedItems = srsManager.getAllItemsSortedByNextReview();
      final reviewedIds = reviewedCards.value.keys.toSet();

      // Filter out cards already reviewed in this session and take the next 30
      final nextClosestItems = allSortedItems
          .where((item) => !reviewedIds.contains(item.id))
          .take(30)
          .toList();

      dueItemsState.value = nextClosestItems;
      isLoadingState.value = false;
    }

    Widget _buildBody(
      BuildContext context,
      bool isLoading,
      String? error,
      List<srs_model.FlashcardItem> dueItems,
      bool showEmpty,
      ValueNotifier<String?> selectedStackId,
      VoidCallback loadDueCards,
      ValueNotifier<bool> isSessionComplete,
      ValueNotifier<Map<String, (srs_model.FlashcardItem, String)>> reviewedCards,
      ValueNotifier<List<srs_model.FlashcardItem>> dueItemsState,
      void Function(String) updateCurrentImageUrl,
      ValueNotifier<String?> currentImageUrl,
      srs_package.SRSManager srsManager,
      WidgetRef ref,
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

      if (showLoadMoreOption.value && dueItemsState.value.isEmpty && !isLoadingState.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No more cards due right now.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _loadNextClosestCards(
                  srsManager,
                  dueItemsState,
                  reviewedCards,
                  isLoadingState,
                  showLoadMoreOption,
                ),
                child: const Text('Review Upcoming Cards (Max 30)'),
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
        onRatingSelected: (rating, flashcard) async {
          srs_outcome.ReviewOutcome outcome;
          switch (rating) {
            case 'Missed':
              outcome = srs_outcome.ReviewOutcome.hard;
              break;
            case 'Got It':
              outcome = srs_outcome.ReviewOutcome.easy;
              break;
            case 'Lucky Guess':
              outcome = srs_outcome.ReviewOutcome.good;
              break;
            default:
              print('Unknown rating: $rating, defaulting to missed'); // Log unexpected ratings
              outcome = srs_outcome.ReviewOutcome.good;
          }
          
          final reviewType = srs_outcome.ReviewType.typing; // Changed to valid value 'typing'
          
          final updatedItem = srsManager.recordReview(
            flashcard.id, 
            outcome, 
            reviewType
          );
          
          if (updatedItem != null) {
            final onlineFlashcardsState = ref.read(flashcardStateProvider);
            if (onlineFlashcardsState.hasValue) {
              final cardToUpdate = onlineFlashcardsState.value!.firstWhereOrNull(
                (card) => card.id == flashcard.id,
              );
              
              if (cardToUpdate != null) {
                final updatedCard = cardToUpdate.copyWith(
                  srsInterval: updatedItem.interval.toDouble(), // Keep?
                  srsEaseFactor: updatedItem.personalDifficultyFactor, // Map PDF to EaseFactor
                  srsNextReviewDate: updatedItem.nextReviewDate.millisecondsSinceEpoch,
                  srsLastReviewDate: updatedItem.lastReviewDate?.millisecondsSinceEpoch, // Added
                  srsBaseIntervalIndex: updatedItem.baseIntervalIndex, // Added
                  srsQuickStreak: updatedItem.quickStreak, // Added
                  srsIsPriority: updatedItem.isPriority, // Added
                  srsIsInLearningPhase: updatedItem.isInLearningPhase, // Added
                );
                await ref.read(flashcardStateProvider.notifier).updateFlashcard(updatedCard);
              }
            }
            
            final offlineFlashcards = ref.read(offlineFlashcardsProvider);
            if (offlineFlashcards.value != null) {
              final cardToUpdate = offlineFlashcards.value!.firstWhereOrNull(
                (card) => card.id == flashcard.id,
              );
              
              if (cardToUpdate != null) {
                final updatedCard = cardToUpdate.copyWith(
                  srsInterval: updatedItem.interval.toDouble(), // Keep?
                  srsEaseFactor: updatedItem.personalDifficultyFactor, // Map PDF to EaseFactor
                  srsNextReviewDate: updatedItem.nextReviewDate.millisecondsSinceEpoch,
                  srsLastReviewDate: updatedItem.lastReviewDate?.millisecondsSinceEpoch, // Added
                  srsBaseIntervalIndex: updatedItem.baseIntervalIndex, // Added
                  srsQuickStreak: updatedItem.quickStreak, // Added
                  srsIsPriority: updatedItem.isPriority, // Added
                  srsIsInLearningPhase: updatedItem.isInLearningPhase, // Added
                );
                await ref.read(offlineFlashcardsProvider.notifier).updateCard(updatedCard);
              }
            }
            
            final newReviewedCards = {...reviewedCards.value};
            newReviewedCards[flashcard.id] = (updatedItem, rating);
            reviewedCards.value = newReviewedCards;
            
            final currentDueItems = List<srs_model.FlashcardItem>.from(dueItemsState.value);
            currentDueItems.removeWhere((item) => item.id == updatedItem.id); 
            dueItemsState.value = currentDueItems;
            
            if (dueItemsState.value.isEmpty) {
              isSessionComplete.value = true;
            }
          }
        },
        showTranslation: false,
      );
    }

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
        ref,
      ),
    );
  }
}
