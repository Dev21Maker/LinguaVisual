import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offline_flashcard.dart';

class OfflineFlashcardsNotifier extends StateNotifier<AsyncValue<List<OfflineFlashcard>>> {
  OfflineFlashcardsNotifier() : super(const AsyncValue.loading()) {
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final flashcardsJson = prefs.getStringList('offline_flashcards') ?? [];
      final cards = flashcardsJson
          .map((json) => OfflineFlashcard.fromMap(jsonDecode(json)))
          .toList();
      state = AsyncValue.data(cards);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFlashcard(OfflineFlashcard flashcard) async {
    final current = state.value ?? [];
    state = AsyncValue.data([...current, flashcard]);
    await _saveFlashcards();
  }

  Future<void> _saveFlashcards() async {
    final prefs = await SharedPreferences.getInstance();
    final current = state.value ?? [];
    final flashcardsJson = current
        .map((flashcard) => jsonEncode(flashcard.toMap()))
        .toList();
    await prefs.setStringList('offline_flashcards', flashcardsJson);
  }

  Future<void> removeFlashcard(String id) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((flashcard) => flashcard.id != id).toList());
    await _saveFlashcards();
  }

  Future<void> updateCard(OfflineFlashcard updatedCard) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.map((card) =>
      card.id == updatedCard.id ? updatedCard : card
    ).toList());
    await _saveFlashcards();
  }
}

final offlineFlashcardsProvider = StateNotifierProvider<OfflineFlashcardsNotifier, AsyncValue<List<OfflineFlashcard>>>((ref) {
  return OfflineFlashcardsNotifier();
});