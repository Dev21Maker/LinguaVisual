import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/models/flashcard.dart';
import 'package:lingua_visual/providers/flashcard_provider.dart';
import 'package:lingua_visual/providers/stack_provider.dart';
import 'package:lingua_visual/widgets/flashcard_view.dart';
import 'package:lingua_visual/package/srs_manager.dart' as srs_package;
import 'package:lingua_visual/package/algorithm/adaptive_flow_algorithm.dart' show SrsItem;

// LearnScreen Widget: Manages the Spaced Repetition System (SRS) learning session.
class LearnScreen extends HookConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- State Variables using Hooks ---
    // Holds the list of SRS items currently due for review.
    final dueItemsState = useState<List<SrsItem>>([]);
    // Stores cards reviewed in the current session and the rating given ('Quick', 'Good', 'Missed').
    final reviewedCards = useState<Map<String, (SrsItem, String)>>({});
    // Tracks if the screen is currently loading data.
    final isLoadingState = useState(true);
    // Holds any error message that occurred during loading or processing.
    final errorState = useState<String?>(null);
    // Controls whether to show a message indicating no cards are due.
    final showEmptyState = useState(false);
    // Stores the ID of the currently selected flashcard stack (null means all cards).
    final selectedStackId = useState<String?>(null);
    // Indicates if the current learning session is complete (all due cards reviewed).
    final isSessionComplete = useState(false);
    // Manages the SRS logic (adding items, getting due items, processing reviews).
    final srsManager = useMemoized(() => srs_package.SRSManager(), []);
    // Controls visibility of the 'Load More Cards' option when initial due list is empty.
    final showLoadMoreOption = useState(false);
    
    // --- Function: Process flashcards and load due cards ---
    Future<void> processFlashcardsAndLoadDueCards(AsyncValue<List<Flashcard>> flashcardsAsync) async {
      // Reset state for loading sequence
      isLoadingState.value = true;
      errorState.value = null;
      showEmptyState.value = false;
      dueItemsState.value = [];
      showLoadMoreOption.value = false;

      try {
        // Handle error state
        if (flashcardsAsync.hasError) {
          errorState.value = flashcardsAsync.error.toString();
          isLoadingState.value = false;
          return;
        }
        
        // Make sure we have data
        if (!flashcardsAsync.hasValue || flashcardsAsync.value == null) {
          showEmptyState.value = true;
          isLoadingState.value = false;
          return;
        }
        
        final flashcards = flashcardsAsync.value!;
        
        // Clear any previous items in the SRS manager
        srsManager.clear();
        
        debugPrint('Flashcards loaded length: ${flashcards.length}');

        if (flashcards.isEmpty) {
          showEmptyState.value = true;
          isLoadingState.value = false;
          return;
        }
        
        // Filter flashcards based on selected stack
        List<Flashcard> filteredFlashcards;
        if (selectedStackId.value != null) {
          try {
            final stack = ref.read(stacksProvider.notifier).getStackById(selectedStackId.value!);
            filteredFlashcards = flashcards.where((card) => stack.flashcardIds.contains(card.id)).toList();
            debugPrint('Filtered flashcards length: ${filteredFlashcards.length}');
            debugPrint('Filtered flashcards first: ${filteredFlashcards.first}');
          } catch (e) {
            debugPrint("Error finding stack ${selectedStackId.value}: $e");
            errorState.value = "Error loading stack. Showing all cards.";
            selectedStackId.value = null;
            filteredFlashcards = List<Flashcard>.from(flashcards);
          }
        } else {
          filteredFlashcards = List<Flashcard>.from(flashcards);
        }
        
        // Add filtered flashcards to SRS manager
        for (final Flashcard card in filteredFlashcards) {
          srsManager.loadOrUpdateItemFromFlashcard(card);
        }
        
        // Get due items
        final dueItems = srsManager.getDueItems(now: DateTime.now().millisecondsSinceEpoch);
        dueItemsState.value = dueItems;
        
        // // Show load more option if no due items but we have flashcards
        if (dueItems.isEmpty && filteredFlashcards.isNotEmpty) {
          showLoadMoreOption.value = true;
        }
        
        // // Show empty state if no due items and no load more option
        if (dueItems.isEmpty && !showLoadMoreOption.value) {
          showEmptyState.value = true;
        }
        
      } catch (e) {
        errorState.value = e.toString();
        debugPrint('Error loading due cards: $e');
      } finally {
        // Always set loading to false at the end
        isLoadingState.value = false;
      }
    }
    
    // --- Function: Load Due Cards ---
    // This is the public method that can be called from outside
    Future<void> loadDueCards() async {
      final flashcardsAsync = ref.watch(flashcardStateProvider);
      
      // If flashcards are still loading, set loading state and wait
      if (flashcardsAsync.isLoading) {
        isLoadingState.value = true;
        return; // Wait for the useEffect to trigger when loading completes
      }
      print('Not loading');
      // Otherwise, process the flashcards immediately
      await processFlashcardsAndLoadDueCards(flashcardsAsync);
    }
    
    // Watch the flashcard state to react to changes
    final flashcardsAsync = ref.watch(flashcardStateProvider);
    
    // Effect to process flashcards when they become available
    useEffect(() {
      if (!flashcardsAsync.isLoading) {
        // Use the function that takes flashcardsAsync as a parameter
        processFlashcardsAndLoadDueCards(flashcardsAsync);
      }
      return null;
    }, [flashcardsAsync]);

    // --- useEffect Hooks ---
    // First useEffect: Watch for changes to the flashcard provider
    useEffect(() {
      final subscription = ref.listenManual(flashcardStateProvider, (previous, next) {
        // Only reload if we have data and it's different from before
        if (next.hasValue && (previous == null || !previous.hasValue || previous.value != next.value)) {
          loadDueCards();
        }
      });
      
      // Initial load
      loadDueCards();
      
      return subscription.close;
    }, const []); // Empty dependency array means this runs once on mount

    // Second useEffect: Watch for changes to selectedStackId
    useEffect(() {
      if (selectedStackId.value != null) {
        loadDueCards();
      }
      return null;
    }, [selectedStackId.value]);

    // --- Function: Show Stack Selector Dialog ---
    // Displays a dialog allowing the user to select a flashcard stack or 'All Cards'.
    void showStackSelector(
      BuildContext context,
      WidgetRef ref,
      ValueNotifier<String?> selectedStackId, // Current selection state
      VoidCallback onStackSelected, // Callback when selection changes
    ) {
      // Watch the state of the stacks provider.
      final stacksAsync = ref.watch(stacksProvider);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Stack'),
          content: SizedBox(
            width: double.maxFinite, // Use available width
            // Handle loading, error, and data states for stacks.
            child: stacksAsync.when(
              data: (stacks) {
                // Build the list of stack options.
                return ListView(
                  shrinkWrap: true, // Fit content size
                  children: [
                    // Option for 'All Cards'.
                    ListTile(
                      title: const Text('All Cards'),
                      selected: selectedStackId.value == null, // Highlight if selected
                      onTap: () {
                        selectedStackId.value = null; // Update state
                        onStackSelected(); // Trigger callback (reloads cards)
                        Navigator.pop(context); // Close dialog
                      },
                    ),
                    const Divider(), // Separator
                    // Generate options for each available stack.
                    ...stacks.map((stack) {
                      // Watch flashcards to calculate count (could be optimized).
                      final flashcardsAsync = ref.watch(flashcardStateProvider);
                      // Calculate the number of cards in this stack.
                      final dueCount = flashcardsAsync.whenOrNull(
                        data: (flashcards) => flashcards
                            .where((card) => stack.flashcardIds.contains(card.id))
                            .length,
                      ) ?? 0;

                      // List tile for the specific stack.
                      return ListTile(
                        title: Text(stack.name),
                        subtitle: Text('$dueCount cards'),
                        selected: selectedStackId.value == stack.id, // Highlight if selected
                        onTap: () {
                          selectedStackId.value = stack.id; // Update state
                          onStackSelected(); // Trigger callback
                          Navigator.pop(context); // Close dialog
                        },
                      );
                    }),
                  ],
                );
              },
              // Show loading indicator while stacks are fetched.
              loading: () => const Center(child: CircularProgressIndicator()),
              // Show error message if stacks fail to load.
              error: (error, _) => Text('Error: $error'),
            ),
          ),
        ),
      );
    }

    // --- Function: Load Next Closest Cards ---
    // Fetches a small batch of the next upcoming (not yet due) cards 
    // when the initial due list is empty or exhausted.
    void loadNextClosestCards() async {
      isLoadingState.value = true; // Indicate loading
      showLoadMoreOption.value = false; // Hide the button while loading

      // Get all items from the SRS manager, sorted by their next review date.
      final allSortedItems = srsManager.getAllItemsSortedByNextReview();
      // Get IDs of cards already reviewed in this session.
      final reviewedIds = reviewedCards.value.keys.toSet();
      // Get IDs of cards currently in the due list.
      final currentDueIds = Set<String>.from(dueItemsState.value.map((item) => item.id));

      // Find the next 5 items that haven't been reviewed and aren't already in the due list.
      final nextClosestSrsItems = allSortedItems
          .where((item) => !reviewedIds.contains(item.id) && !currentDueIds.contains(item.id))
          .take(5) // Limit to a small batch
          .toList();

      // If new items were found, add them to the due list.
      if (nextClosestSrsItems.isNotEmpty) {
        dueItemsState.value = [...dueItemsState.value, ...nextClosestSrsItems];
      } else {
        // If no more upcoming items were found, hide the 'Load More' option.
        showLoadMoreOption.value = false;
      }
      
      isLoadingState.value = false; // Loading finished
    }

    // --- Function: Build Body Content ---
    // Determines what to display based on loading, error, and data states.
    Widget buildBody(
      BuildContext context,
      bool isLoading, // Current loading state
      String? error, // Current error message
      List<SrsItem> dueItems, // List of due SRS items
      bool showEmpty, // Whether to show the empty state message
      ValueNotifier<String?> selectedStackId, // Current stack selection
      VoidCallback loadDueCards, // Callback to reload due cards
      ValueNotifier<bool> isSessionComplete, // Session completion state
      ValueNotifier<Map<String, (SrsItem, String)>> reviewedCards, // State for reviewed cards
      ValueNotifier<List<SrsItem>> dueItemsState, // State for due items
      srs_package.SRSManager srsManager, // The SRS manager instance
      WidgetRef ref, // Reference to the widget's context
    ) {
      if (isLoading) {
        // Show a loading indicator while data is being fetched.
        return const Center(child: CircularProgressIndicator());
      }

      if (error != null) {
        // Display an error message if one occurred during loading or processing.
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
        // Display a message if there are no due cards.
        // This could be because the session is complete or initially no cards were due.
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

      // Get the list of flashcards from the provider.
      final flashcardsData = ref.watch(flashcardStateProvider).valueOrNull ?? [];
      // Filter the flashcards to only those that are currently in the dueItems list.
      final dueFlashcards = dueItems
          .map((srsItem) => flashcardsData.firstWhere(
                (card) => card.id == srsItem.id,
              ))
          .where((card) => card != null)
          .cast<Flashcard>()
          .toList();

      // Display the FlashcardView widget with the due flashcards.
      // The key ensures the widget rebuilds when the first card changes.
      return FlashcardView(
        key: ValueKey(dueFlashcards.isNotEmpty ? dueFlashcards[0].id : 'empty'),
        flashcards: dueFlashcards,
        // Callback executed when the user selects a rating ('Quick', 'Good', 'Hard').
        onRatingSelected: (rating, flashcard) async {
          // Map the button label to the SRS rating format
          // The expected values for AdaptiveFlow are 'quick', 'got', 'missed'
          String srsRating;
          switch (rating) {
            case 'Lucky Guess':
              srsRating = 'quick';  // Maps to "Quick" in AdaptiveFlow
              break;
            case 'Got It':
              srsRating = 'got';    // Maps to "Got It" in AdaptiveFlow
              break;
            case 'Missed':
              srsRating = 'missed'; // Maps to "Missed" in AdaptiveFlow
              break;
            default:
              srsRating = 'got';    // Default fallback
          }

          debugPrint('Processing answer for card ${flashcard.id} with rating: $srsRating');
          debugPrint('BEFORE - Next review: ${DateTime.fromMillisecondsSinceEpoch(flashcard.srsNextReviewDate).toIso8601String()}, PDF: ${flashcard.srsEaseFactor}, Interval: ${flashcard.srsInterval}');
          
          // Process the answer in the SRS system
          final updatedItem = await srsManager.recordReview(
            flashcard.id, 
            srsRating,
            reviewType: "mc"
          );
          
          // If the SRS manager successfully processed the review:
          if (updatedItem != null) {
            debugPrint('AFTER - Next review: ${DateTime.fromMillisecondsSinceEpoch(updatedItem.nextReview).toIso8601String()}, PDF: ${updatedItem.pdf}, Interval: ${updatedItem.lastInterval}');
            
            // --- Update Flashcard State (Online Provider) ---
            // Get the current state of online flashcards.
            final onlineFlashcardsState = ref.read(flashcardStateProvider);
            if (onlineFlashcardsState.hasValue) {
              // First check if the flashcard exists in the current state
              final cardIndex = onlineFlashcardsState.value!.indexWhere(
                (card) => card.id == flashcard.id
              );
              
              if (cardIndex >= 0) {
                // Card exists, create an updated version
                final cardToUpdate = onlineFlashcardsState.value![cardIndex];
                
                // Create an updated flashcard object with new SRS data.
                final updatedCard = cardToUpdate.copyWith(
                  srsInterval: updatedItem.lastInterval, 
                  srsEaseFactor: updatedItem.pdf, // Map PDF to EaseFactor
                  srsNextReviewDate: updatedItem.nextReview, // Use directly
                  srsLastReviewDate: DateTime.now().millisecondsSinceEpoch,
                  srsBaseIntervalIndex: updatedItem.baseIndex,
                  srsQuickStreak: updatedItem.streakQuick,
                  srsIsInLearningPhase: updatedItem.box != null,
                );
                
                debugPrint('Updating flashcard: ${updatedCard.word} with new next review date: ${DateTime.fromMillisecondsSinceEpoch(updatedCard.srsNextReviewDate).toIso8601String()}');
                
                // Persist the updated flashcard using the provider (handles sync + offline cache).
                await ref.read(flashcardStateProvider.notifier).updateFlashcard(updatedCard);
              } else {
                debugPrint('Error: Could not find card ${flashcard.id} to update in flashcard provider');
              }
            }
            
            // --- Update Local UI State ---
            // Add the reviewed card and its rating to the session's reviewed list.
            final newReviewedCards = Map<String, (SrsItem, String)>.from(reviewedCards.value);
            newReviewedCards[flashcard.id] = (updatedItem, rating);
            reviewedCards.value = newReviewedCards;
            
            // Remove the reviewed card from the list of currently due items.
            final currentDueItems = List<SrsItem>.from(dueItemsState.value);
            currentDueItems.removeWhere((item) => item.id == updatedItem.id); 
            dueItemsState.value = currentDueItems;
            
            // Check if the due items list is now empty, signifying session completion.
            if (dueItemsState.value.isEmpty) {
              isSessionComplete.value = true;
              // Potentially show a completion message or navigate away.
            }
          }
        },
        showTranslation: false, // Example parameter, adjust as needed
      );
    }

    // Build the main screen structure using Scaffold.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Cards'),
        // Add actions to the AppBar.
        actions: [
          // Button to open the stack selector dialog.
          IconButton(
            icon: const Icon(Icons.filter_list), // Filter icon
            tooltip: 'Select Stack', // Tooltip for accessibility
            onPressed: () {
              // Call the function to show the stack selector dialog.
              showStackSelector(
                context,
                ref,
                selectedStackId, // Pass the state notifier for selection
                loadDueCards, // Pass the callback to reload cards on selection change
              );
            },
          ),
        ],
      ),
      // Set the body of the Scaffold to the content generated by buildBody.
      body: buildBody(
        context,
        isLoadingState.value, // Pass current loading state
        errorState.value, // Pass current error state
        dueItemsState.value, // Pass list of due items
        showEmptyState.value, // Pass empty state flag
        selectedStackId, // Pass selected stack state
        loadDueCards, // Pass the load function for retry/reload
        isSessionComplete, // Pass session completion state
        reviewedCards, // Pass reviewed cards map
        dueItemsState, // Pass due items list state (needed for FlashcardView key?)
        srsManager, // Pass the SRS manager instance
        ref, // Pass the WidgetRef
      ),
    );
  }
}
