import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Languador/models/online_flashcard.dart';
import 'package:Languador/providers/flashcard_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/flashcard_stack.dart';
import '../providers/firebase_provider.dart';
import '../services/firebase_service.dart';

final stacksProvider = StateNotifierProvider<StacksNotifier, AsyncValue<List<FlashcardStack>>>((ref) {
  return StacksNotifier(ref);
});

class StacksNotifier extends StateNotifier<AsyncValue<List<FlashcardStack>>> {
  final Ref ref;
  static const String _offlineStacksKey = 'offline_stacks';

  StacksNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadStacks();
  }

  Future<void> _saveOfflineStacks(List<FlashcardStack> stacks) async {
    final prefs = await SharedPreferences.getInstance();
    final stacksJson = stacks.map((stack) => jsonEncode(stack.toMap())).toList();
    await prefs.setStringList(_offlineStacksKey, stacksJson);
  }

  Future<List<FlashcardStack>> _loadOfflineStacks() async {
    final prefs = await SharedPreferences.getInstance();
    final stacksJson = prefs.getStringList(_offlineStacksKey) ?? [];
    return stacksJson
        .map((json) => FlashcardStack.fromMap(jsonDecode(json)))
        .toList();
  }

  Future<void> loadStacks() async {
    try {
      final FirebaseService firebaseService = ref.read(firebaseServiceProvider);
      final stacks = await firebaseService.getStacks();
      state = AsyncValue.data(stacks);
      // Save to offline storage
      await _saveOfflineStacks(stacks);
    } catch (error, stackTrace) {
      // If loading from Firebase fails, try loading from offline storage
      try {
        final offlineStacks = await _loadOfflineStacks();
        state = AsyncValue.data(offlineStacks);
      } catch (e) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  FlashcardStack getStackById(String id) {
    final stacks = state.value ?? [];
    return stacks.firstWhere((stack) => stack.id == id);
  }

  Future<void> createStack(String name, String description, {String? imageUrl}) async {
    try {
      final newStack = FlashcardStack(
        id: const Uuid().v4(),
        name: name,
        description: description,
        createdAt: DateTime.now(),
        flashcardIds: [],
        imageUrl: imageUrl,
      );

      // Save to offline storage first
      final currentStacks = state.value ?? [];
      final updatedStacks = [...currentStacks, newStack];
      await _saveOfflineStacks(updatedStacks);

      try {
        // Try to save to Firebase
        final firebaseService = ref.read(firebaseServiceProvider);
        await firebaseService.createStack(newStack);
        await loadStacks(); // Reload stacks to get the Firestore-generated ID
      } catch (e) {
        // If Firebase fails, keep the local state
        state = AsyncValue.data(updatedStacks);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteStack(String id) async {
    try {
      // Delete from offline storage first
      final currentStacks = state.value ?? [];
      final updatedStacks = currentStacks.where((stack) => stack.id != id).toList();
      await _saveOfflineStacks(updatedStacks);

      try {
        // Try to delete from Firebase
        final firebaseService = ref.read(firebaseServiceProvider);
        await firebaseService.deleteStack(id);
        await loadStacks();
      } catch (e) {
        // If Firebase fails, keep the local state
        state = AsyncValue.data(updatedStacks);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFlashcardToStack(String stackId, String flashcardId) async {
    try {
      final currentStacks = state.value ?? [];
      final stack = currentStacks.firstWhere((s) => s.id == stackId);
      
      // Check if flashcard is already in stack
      if (stack.flashcardIds.contains(flashcardId)) {
        return;
      }

      final updatedStack = stack.copyWith(
        flashcardIds: [...stack.flashcardIds, flashcardId],
      );

      // Update offline storage first
      final updatedStacks = currentStacks.map((s) => 
        s.id == stackId ? updatedStack : s
      ).toList();
      
      // Update state immediately
      state = AsyncValue.data(updatedStacks);
      
      // Save to offline storage
      await _saveOfflineStacks(updatedStacks);

      try {
        // Try to update Firebase
        final firebaseService = ref.read(firebaseServiceProvider);
        await firebaseService.updateStack(updatedStack);

        // Update the flashcard's stackIds
        final flashcardsState = ref.read(flashcardStateProvider);
        if (flashcardsState.hasValue) {
          final flashcards = flashcardsState.value!;
          final flashcard = flashcards.firstWhere((f) => f.id == flashcardId);
          final updatedFlashcard = flashcard.copyWith(
            stackIds: [...(flashcard.stackIds ?? []), stackId],
          );
          await firebaseService.updateCard(updatedFlashcard);
          ref.read(flashcardStateProvider.notifier).state = AsyncValue.data(
            flashcards.map((f) => f.id == flashcardId ? updatedFlashcard as OnlineFlashcard : f).toList()
          );
        }
      } catch (e) {
        // Firebase error - state is already updated locally, so we can ignore
        print('Firebase update failed: $e');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> removeFlashcardFromStack(String stackId, String flashcardId) async {
    try {
      final currentStacks = state.value ?? [];
      final stack = currentStacks.firstWhere((s) => s.id == stackId);
      final updatedStack = stack.copyWith(
        flashcardIds: stack.flashcardIds.where((id) => id != flashcardId).toList(),
      );

      // Update offline storage first
      final updatedStacks = currentStacks.map((s) =>
        s.id == stackId ? updatedStack : s
      ).toList();
      await _saveOfflineStacks(updatedStacks);

      // Update state immediately
      state = AsyncValue.data(updatedStacks);

      try {
        // Try to update Firebase
        final firebaseService = ref.read(firebaseServiceProvider);
        await firebaseService.updateStack(updatedStack);

        // Update the flashcard's stackIds
        final flashcardsState = ref.read(flashcardStateProvider);
        if (flashcardsState.hasValue) {
          final flashcards = flashcardsState.value!;
          final flashcard = flashcards.firstWhere((f) => f.id == flashcardId);
          final updatedFlashcard = flashcard.copyWith(
            stackIds: (flashcard.stackIds ?? []).where((id) => id != stackId).toList(),
          );
          await firebaseService.updateCard(updatedFlashcard);
          ref.read(flashcardStateProvider.notifier).state = AsyncValue.data(
            flashcards.map((f) => f.id == flashcardId ? updatedFlashcard as OnlineFlashcard : f).toList()
          );
        }
      } catch (e) {
        // If Firebase fails, state is already updated locally
        print('Firebase update failed: $e');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> clearOfflineStackData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_offlineStacksKey);
      state = const AsyncValue.data([]); // Reset state to empty
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      // Optionally rethrow or log the error
    }
  }
}
