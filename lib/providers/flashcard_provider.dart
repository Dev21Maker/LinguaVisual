import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_visual/providers/firebase_provider.dart';
import 'package:lingua_visual/providers/navigator_provider.dart';
import 'package:lingua_visual/widgets/image_prompt_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/online_flashcard.dart';
import '../services/recraft_api_service.dart';

// Existing providers
final flashcardsProvider = FutureProvider<List<OnlineFlashcard>>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.getFlashcards();
});

final dueFlashcardsProvider = FutureProvider<List<OnlineFlashcard>>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.fetchDueCards();
});

final recraftApiProvider = Provider((ref) => RecraftApiService());

// New providers for managing active learning state
class ActiveLearningState {
  final List<OnlineFlashcard> dueCards;
  final OnlineFlashcard? currentCard;
  final bool isLoading;
  final String? error;

  const ActiveLearningState({
    this.dueCards = const [],
    this.currentCard,
    this.isLoading = false,
    this.error,
  });

  ActiveLearningState copyWith({
    List<OnlineFlashcard>? dueCards,
    OnlineFlashcard? currentCard,
    bool? isLoading,
    String? error,
  }) {
    return ActiveLearningState(
      dueCards: dueCards ?? this.dueCards,
      currentCard: currentCard ?? this.currentCard,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ActiveLearningNotifier extends StateNotifier<ActiveLearningState> {
  final Ref ref;

  ActiveLearningNotifier(this.ref) : super(const ActiveLearningState());

  Future<void> loadDueCards() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final firebaseService = ref.read(firebaseServiceProvider);
      final cards = await firebaseService.fetchDueCards();
      
      if (cards.isEmpty) {
        await _fetchAndInsertNewWord();
        final updatedCards = await firebaseService.fetchDueCards();
        state = state.copyWith(
          dueCards: updatedCards,
          currentCard: updatedCards.isNotEmpty ? updatedCards.first : null,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          dueCards: cards,
          currentCard: cards.first,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _fetchAndInsertNewWord() async {
    try {
      // final firebaseService = ref.read(firebaseServiceProvider);
      // final settings = ref.read(settingsProvider);
      
      // TODO: Implement fetchNewWordViaFunction for Firebase or handle this feature.
      // final wordData = await firebaseService.fetchNewWordViaFunction(
      //   targetLanguageCode: settings.targetLanguage.code,
      //   nativeLanguageCode: settings.nativeLanguage.code,
      // );
      // For now, throw UnimplementedError or handle as needed.
      throw UnimplementedError('fetchNewWordViaFunction is not implemented for Firebase');
      
      // String? imageUrl;
      // try {
      //   final recraftApi = ref.read(recraftApiProvider);
      //   imageUrl = await recraftApi.getImageUrl(wordData['word']!);
      // } catch (e) {
      //   // Log error but continue without image
      //   print('Failed to generate image: $e');
      // }

      // final flashcard = OnlineFlashcard(
      //   id: wordData['id'],
      //   word: wordData['word'],
      //   targetLanguageCode: settings.targetLanguage.code,
      //   translation: wordData['translation'],
      //   nativeLanguageCode: settings.nativeLanguage.code,
      //   imageUrl: imageUrl,
      //   srsNextReviewDate: DateTime.now().millisecondsSinceEpoch,
      //   srsInterval: 1.0,
      //   srsEaseFactor: 2.5,
      // );
      
      // await firebaseService.insertCard(flashcard);
    } catch (e) {
      state = state.copyWith(error: 'Failed to fetch new word: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> processCardRating(String rating) async {
    try {
      if (state.currentCard == null) return;
      
      final newDueCards = List<OnlineFlashcard>.from(state.dueCards)..removeAt(0);
      state = state.copyWith(
        dueCards: newDueCards,
        currentCard: newDueCards.isNotEmpty ? newDueCards.first : null,
      );
      
      if (newDueCards.isEmpty) {
        await loadDueCards();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final activeLearningProvider = StateNotifierProvider<ActiveLearningNotifier, ActiveLearningState>((ref) {
  return ActiveLearningNotifier(ref);
});

// Add this new state class
class FlashcardViewState {
  final bool isFlipped;
  final bool isTranslationVisible;

  const FlashcardViewState({
    this.isFlipped = false,
    this.isTranslationVisible = false,
  });

  FlashcardViewState copyWith({
    bool? isFlipped,
    bool? isTranslationVisible,
  }) {
    return FlashcardViewState(
      isFlipped: isFlipped ?? this.isFlipped,
      isTranslationVisible: isTranslationVisible ?? this.isTranslationVisible,
    );
  }
}

// Add this new provider
final flashcardViewProvider = StateNotifierProvider.autoDispose<FlashcardViewNotifier, FlashcardViewState>((ref) {
  return FlashcardViewNotifier();
});

class FlashcardViewNotifier extends StateNotifier<FlashcardViewState> {
  FlashcardViewNotifier() : super(const FlashcardViewState());

  void toggleCard() {
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  void toggleTranslation() {
    state = state.copyWith(isTranslationVisible: !state.isTranslationVisible);
  }

  void reset() {
    state = const FlashcardViewState();
  }
}

// Add this to your existing providers
final flashcardStateProvider = StateNotifierProvider<FlashcardStateNotifier, AsyncValue<List<OnlineFlashcard>>>((ref) {
  return FlashcardStateNotifier(ref);
});

class FlashcardStateNotifier extends StateNotifier<AsyncValue<List<OnlineFlashcard>>> {
  final Ref ref;
  static const String _offlineFlashcardsKey = 'offline_flashcards';

  FlashcardStateNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadFlashcards();
  }

  Future<void> _saveOfflineFlashcards(List<OnlineFlashcard> flashcards) async {
    final prefs = await SharedPreferences.getInstance();
    final flashcardsJson = flashcards.map((card) => jsonEncode(card.toMap())).toList();
    await prefs.setStringList(_offlineFlashcardsKey, flashcardsJson);
  }

  Future<List<OnlineFlashcard>> _loadOfflineFlashcards() async {
    final prefs = await SharedPreferences.getInstance();
    final flashcardsJson = prefs.getStringList(_offlineFlashcardsKey) ?? [];
    return flashcardsJson
        .map((json) => OnlineFlashcard.fromMap(jsonDecode(json)))
        .toList();
  }

  Future<void> _loadFlashcards() async {
    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      final List<OnlineFlashcard> flashcards = await firebaseService.getFlashcards();
      state = AsyncValue.data(flashcards);
      await _saveOfflineFlashcards(flashcards); // Save fetched cards offline
      // await _checkForMissingImages(); // Check for images *after* successful load
    } catch (e, st) { // Re-add st here
      // If Firebase fails, try loading from offline storage
      try {
        final offlineFlashcards = await _loadOfflineFlashcards();
        state = AsyncValue.data(offlineFlashcards);
      } catch (offlineError) { // Keep this catch simple
        // If both fail, report the original Firebase error and stack trace
        state = AsyncValue.error(e, st); // Pass original e and st
      }
    }
  }

  Future<void> addFlashcard(OnlineFlashcard flashcard) async {
    // Get current state or default to empty list if loading/error
    final currentFlashcards = state.value ?? [];
    // Generate a new ID if one isn't provided or handle as needed
    final newFlashcard = flashcard.id.isEmpty
      ? flashcard.copyWith(id: const Uuid().v4())
      : flashcard;
    final updatedFlashcards = [...currentFlashcards, newFlashcard];

    // Update state immediately
    state = AsyncValue.data(updatedFlashcards);

    await _saveOfflineFlashcards(updatedFlashcards);

    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      // For now, we assume the locally generated ID is sufficient or Firebase handles updates correctly.
      await firebaseService.insertCard(newFlashcard);
      // _checkForMissingImages(); // Check images after adding
    } catch (e) {
      // Log Firebase error, but keep local state
      print('Firebase addFlashcard failed: $e');
      // Optionally, set a flag indicating sync failure
      // Revert to error state if Firebase fails? Or keep local state?
                                       // Let's keep the local state for offline-first
      state = AsyncValue.data(updatedFlashcards); // Keep local changes
    }
  }

  Future<void> _checkForMissingImages() async {
    // Only proceed if state is AsyncData
    if (state is! AsyncData<List<OnlineFlashcard>>) return;
    final currentFlashcards = state.value!; // Safe to access value now

    final cardsWithoutImages = currentFlashcards
        .where((card) => card.imageUrl == null)
        .toList();

    if (cardsWithoutImages.isEmpty) return;

    final context = ref.read(navigatorKeyProvider).currentContext;
    if (context == null) {
      print("Warning: BuildContext not available in _checkForMissingImages.");
      return; // Cannot show dialog without context
    }

    for (final card in cardsWithoutImages) {
      // Ensure context is still valid before showing dialog in loop
      if (!context.mounted) {
        print("Warning: Context became unmounted during _checkForMissingImages loop.");
        continue;
      }
      final imageUrl = await showDialog<String>(
        context: context,
        barrierDismissible: false, // Keep false for now to ensure user interaction
        builder: (dialogContext) => ImagePromptDialog(
          word: card.word,
          onImageSelected: (url) async {
            // 1. Update card in Firebase
            final updatedCard = card.copyWith(imageUrl: url);
            final firebaseService = ref.read(firebaseServiceProvider);
            try {
               await firebaseService.updateCard(updatedCard);
               // 2. Update state *directly*
               final currentStateValue = state.value; // Re-check state value
               if (currentStateValue != null) {
                  final newStateValue = currentStateValue.map((c) =>
                     c.id == updatedCard.id ? updatedCard : c
                  ).toList();
                  state = AsyncValue.data(newStateValue);
                  await _saveOfflineFlashcards(newStateValue); // Save updated state
               }
            } catch (e) {
                print("Error updating card image in Firebase from dialog: $e");
                // Optionally show an error to the user via a snackbar/toast
            }
            // Ensure dialog is popped if onImageSelected doesn't do it implicitly
            // Check ImagePromptDialog implementation. Assuming it pops itself.
          },
        ),
      );

      if (imageUrl != null) {
         final updatedCard = card.copyWith(imageUrl: imageUrl);
         final firebaseService = ref.read(firebaseServiceProvider);
         try {
             await firebaseService.updateCard(updatedCard);
             // Update state directly here too
             final currentStateValue = state.value;
             if (currentStateValue != null) {
                final newStateValue = currentStateValue.map((c) =>
                   c.id == updatedCard.id ? updatedCard : c
                ).toList();
                state = AsyncValue.data(newStateValue);
                await _saveOfflineFlashcards(newStateValue);
             }
         } catch (e) {
             print("Error updating card image directly from dialog return: $e");
         }
      }
    }
  }

  Future<void> removeFlashcard(String id) async {
    final currentFlashcards = state.value ?? [];
    final updatedFlashcards = currentFlashcards.where((card) => card.id != id).toList();

    state = AsyncValue.data(updatedFlashcards);

    await _saveOfflineFlashcards(updatedFlashcards);

    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      await firebaseService.deleteCard(id);
    } catch (e) {
      // Log Firebase error, but keep local state
      print('Firebase removeFlashcard failed: $e');
      // state = AsyncValue.error(e, st); // Keep local changes?
      state = AsyncValue.data(updatedFlashcards); // Keep local changes
    }
  }

  Future<void> updateFlashcard(OnlineFlashcard flashcard) async {
    final currentFlashcards = state.value ?? [];
    final updatedFlashcards = currentFlashcards.map((card) =>
      card.id == flashcard.id ? flashcard : card
    ).toList();

    state = AsyncValue.data(updatedFlashcards);

    await _saveOfflineFlashcards(updatedFlashcards);

    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      await firebaseService.updateCard(flashcard);
    } catch (e) {
      // Log Firebase error, but keep local state
      print('Firebase updateFlashcard failed: $e');
      // state = AsyncValue.error(e, st); // Keep local changes?
      state = AsyncValue.data(updatedFlashcards); // Keep local changes
    }
  }

  // Add method to clear offline flashcard data
  Future<void> clearOfflineFlashcardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_offlineFlashcardsKey);
      state = const AsyncValue.data([]); // Reset state to empty
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      // Optionally rethrow or log the error
      print('Error clearing offline flashcard data: $e');
    }
  }

  Future<void> updateCardImage(String cardId, String newImageUrl) async {
    final currentState = state;
    if (currentState is AsyncData<List<OnlineFlashcard>>) {
      final updatedCards =
          currentState.value.map((card) {
            if (card.id == cardId) {
              return card.copyWith(imageUrl: newImageUrl);
            }
            return card;
          }).toList();

      state = AsyncData(updatedCards);

      final firebaseService = ref.read(firebaseServiceProvider);
      final cardToUpdate = updatedCards.firstWhere((card) => card.id == cardId);
      await firebaseService.updateCard(cardToUpdate);
    }
  }
}
