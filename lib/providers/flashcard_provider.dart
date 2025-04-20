import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_visual/providers/settings_provider.dart';
import 'package:lingua_visual/providers/supabase_provider.dart';
// import 'package:uuid/uuid.dart';
import '../models/flashcard.dart';
// import 'database_provider.dart'; // now using Firestore
// import 'api_provider.dart';
// import 'srs_provider.dart';
import '../services/recraft_api_service.dart';

// Existing providers
final flashcardsProvider = FutureProvider<List<Flashcard>>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.getFlashcards();
});

final dueFlashcardsProvider = FutureProvider<List<Flashcard>>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.fetchDueCards();
});

final recraftApiProvider = Provider((ref) => RecraftApiService());

// New providers for managing active learning state
class ActiveLearningState {
  final List<Flashcard> dueCards;
  final Flashcard? currentCard;
  final bool isLoading;
  final String? error;

  const ActiveLearningState({
    this.dueCards = const [],
    this.currentCard,
    this.isLoading = false,
    this.error,
  });

  ActiveLearningState copyWith({
    List<Flashcard>? dueCards,
    Flashcard? currentCard,
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

      // final flashcard = Flashcard(
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
      
      final newDueCards = List<Flashcard>.from(state.dueCards)..removeAt(0);
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
final flashcardStateProvider = StateNotifierProvider<FlashcardStateNotifier, AsyncValue<List<Flashcard>>>((ref) {
  return FlashcardStateNotifier(ref);
});

class FlashcardStateNotifier extends StateNotifier<AsyncValue<List<Flashcard>>> {
  final Ref ref;

  FlashcardStateNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      final List<Flashcard> flashcards = await firebaseService.getFlashcards();
      state = AsyncValue.data(flashcards);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFlashcard(Flashcard flashcard) async {
    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      await firebaseService.insertCard(flashcard);
      await _loadFlashcards(); // Reload the flashcards after adding
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeFlashcard(String id) async {
    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      await firebaseService.deleteCard(id);
      await _loadFlashcards();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateFlashcard(Flashcard flashcard) async {
    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      await firebaseService.updateCard(flashcard);
      await _loadFlashcards();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
