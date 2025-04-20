import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/providers/flashcard_provider.dart';
import 'package:lingua_visual/providers/supabase_provider.dart';
import 'package:lingua_visual/services/firebase_service.dart';
import 'package:uuid/uuid.dart';
import '../models/flashcard_stack.dart';

final stacksProvider = StateNotifierProvider<StacksNotifier, AsyncValue<List<FlashcardStack>>>((ref) {
  return StacksNotifier(ref);
});

class StacksNotifier extends StateNotifier<AsyncValue<List<FlashcardStack>>> {
  final Ref ref;

  StacksNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadStacks();
  }

  Future<void> loadStacks() async {
    try {
      final FirebaseService firebaseService = ref.read(firebaseServiceProvider);
      final stacks = await firebaseService.getStacks();
      state = AsyncValue.data(stacks);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
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

      final firebaseService = ref.read(firebaseServiceProvider);
      await firebaseService.createStack(newStack);
      await loadStacks(); // Reload stacks to get the Firestore-generated ID
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteStack(String id) async {
    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      await firebaseService.deleteStack(id);
      await loadStacks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFlashcardToStack(String stackId, String flashcardId) async {
    try {
      state.whenData((stacks) async {
        final stack = stacks.firstWhere((s) => s.id == stackId);
        final updatedStack = stack.copyWith(
          flashcardIds: [...stack.flashcardIds, flashcardId],
        );

        final firebaseService = ref.read(firebaseServiceProvider);
        await firebaseService.updateStack(updatedStack);

        // Update local state
        final updatedStacks = stacks.map((s) => 
          s.id == stackId ? updatedStack : s
        ).toList();
        state = AsyncValue.data(updatedStacks);

        // Update the flashcard's stackIds
        final flashcardsState = ref.read(flashcardStateProvider);
        flashcardsState.whenData((flashcards) async {
          final flashcard = flashcards.firstWhere((f) => f.id == flashcardId);
          final updatedFlashcard = flashcard.copyWith(
            stackIds: [...flashcard.stackIds, stackId],
          );

          await firebaseService.updateCard(updatedFlashcard);

          final updatedFlashcards = flashcards.map((f) =>
            f.id == flashcardId ? updatedFlashcard : f
          ).toList();
          ref.read(flashcardStateProvider.notifier).state = AsyncValue.data(updatedFlashcards);
        });
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeFlashcardFromStack(String stackId, String flashcardId) async {
    try {
      state.whenData((stacks) async {
        final stack = stacks.firstWhere((s) => s.id == stackId);
        final updatedStack = stack.copyWith(
          flashcardIds: stack.flashcardIds.where((id) => id != flashcardId).toList(),
        );

        final firebaseService = ref.read(firebaseServiceProvider);
        await firebaseService.updateStack(updatedStack);

        // Update local state
        final updatedStacks = stacks.map((s) =>
          s.id == stackId ? updatedStack : s
        ).toList();
        state = AsyncValue.data(updatedStacks);

        // Update the flashcard's stackIds
        final flashcardsState = ref.read(flashcardStateProvider);
        flashcardsState.whenData((flashcards) async {
          final flashcard = flashcards.firstWhere((f) => f.id == flashcardId);
          final updatedFlashcard = flashcard.copyWith(
            stackIds: flashcard.stackIds.where((id) => id != stackId).toList(),
          );

          await firebaseService.updateCard(updatedFlashcard);

          final updatedFlashcards = flashcards.map((f) =>
            f.id == flashcardId ? updatedFlashcard : f
          ).toList();
          ref.read(flashcardStateProvider.notifier).state = AsyncValue.data(updatedFlashcards);
        });
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
