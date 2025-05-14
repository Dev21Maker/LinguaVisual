import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Languador/models/flashcard.dart';
import 'package:Languador/services/groq_service.dart';
import 'package:Languador/providers/flashcard_provider.dart';

// Provider for managing flashcard sentence generation and description updates
final flashcardSentenceProvider = StateNotifierProvider<FlashcardSentenceNotifier, AsyncValue<Map<String, String>>>((ref) {
  return FlashcardSentenceNotifier(ref);
});

class FlashcardSentenceNotifier extends StateNotifier<AsyncValue<Map<String, String>>> {
  final Ref _ref;
  final GroqService _groqService = GroqService();
  
  FlashcardSentenceNotifier(this._ref) : super(const AsyncData({}));
  
  // Get a generated sentence for a flashcard that has a description
  Future<String> getSentenceForFlashcard(Flashcard flashcard) async {
    // Check if we already have a generated sentence
    final currentState = state.valueOrNull ?? {};
    if (currentState.containsKey(flashcard.id)) {
      return currentState[flashcard.id]!;
    }
    
    // If the flashcard doesn't have a description, return empty
    if (flashcard.description == null) {
      return '';
    }
    
    // Generate a sentence using Groq
    state = const AsyncLoading();
    
    try {
      final sentence = await _groqService.generateSentence(
        flashcard.word, 
        flashcard.targetLanguageCode
      );
      
      // Update state with the new sentence
      final newSentences = Map<String, String>.from(currentState);
      newSentences[flashcard.id] = sentence;
      state = AsyncData(newSentences);
      
      return sentence;
    } catch (e) {
      debugPrint('Error generating sentence: $e');
      state = AsyncError(e, StackTrace.current);
      return "Example: ${flashcard.word}"; // Fallback
    }
  }
  
  // Update a flashcard's description
  Future<bool> updateFlashcardDescription(Flashcard flashcard, String description) async {
    try {
      // Since we need to work with the concrete type for the state notifier, we need to cast or check
      final flashcardsNotifier = _ref.read(flashcardStateProvider.notifier);
      final currentFlashcards = _ref.read(flashcardStateProvider).valueOrNull ?? [];
      
      // Find the flashcard in the current list
      final cardToUpdate = currentFlashcards.firstWhere(
        (card) => card.id == flashcard.id,
        orElse: () => throw Exception('Flashcard not found'),
      );
      
      // Create an updated flashcard with the new description
      // Since cardToUpdate is of the concrete type OnlineFlashcard, we can use copyWith
      final updatedCard = cardToUpdate.copyWith(description: description);
      
      // Update the flashcard in the provider
      await flashcardsNotifier.updateFlashcard(updatedCard);
      
      // Generate a sentence for this flashcard now that it has a description
      await getSentenceForFlashcard(updatedCard);
      
      return true;
    } catch (e) {
      debugPrint('Error updating flashcard description: $e');
      return false;
    }
  }
  
  // Clear sentence for a specific flashcard
  void clearSentence(String flashcardId) {
    final currentSentences = state.valueOrNull ?? {};
    if (currentSentences.containsKey(flashcardId)) {
      final newSentences = Map<String, String>.from(currentSentences);
      newSentences.remove(flashcardId);
      state = AsyncData(newSentences);
    }
  }

  // Clear all generated sentences
  void clearAllSentences() {
    state = const AsyncData({});
  }
}
