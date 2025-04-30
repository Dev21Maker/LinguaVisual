import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/offline_flashcard.dart';

class OfflineFlashcardsNotifier extends StateNotifier<AsyncValue<List<OfflineFlashcard>>> {
  final String? userId;

  OfflineFlashcardsNotifier(this.userId) : super(const AsyncValue.loading()) {
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'offline_flashcards_$userId';
      final flashcardsJson = prefs.getStringList(key) ?? [];
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
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final current = state.value ?? [];
    final flashcardsJson = current
        .map((flashcard) => jsonEncode(flashcard.toMap()))
        .toList();
    final key = 'offline_flashcards_$userId';
    await prefs.setStringList(key, flashcardsJson);
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

  Future<void> clearOfflineData() async {
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'offline_flashcards_$userId';
    await prefs.remove(key);
    state = const AsyncValue.data([]);
  }
}

final offlineFlashcardsProvider = StateNotifierProvider<OfflineFlashcardsNotifier, AsyncValue<List<OfflineFlashcard>>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  return OfflineFlashcardsNotifier(userId);
});