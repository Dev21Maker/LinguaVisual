import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/flashcard_stack.dart';

final stacksProvider = StateNotifierProvider<StacksNotifier, AsyncValue<List<FlashcardStack>>>((ref) {
  return StacksNotifier();
});

class StacksNotifier extends StateNotifier<AsyncValue<List<FlashcardStack>>> {
  StacksNotifier() : super(const AsyncValue.loading()) {
    loadStacks();
  }

  Future<void> loadStacks() async {
    try {
      // TODO: Implement actual loading from your database
      state = const AsyncValue.data([]);
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

      state.whenData((stacks) {
        state = AsyncValue.data([...stacks, newStack]);
      });

      // TODO: Save to your database
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addFlashcardToStack(String stackId, String flashcardId) async {
    state.whenData((stacks) {
      final updatedStacks = stacks.map((stack) {
        if (stack.id == stackId) {
          return stack.copyWith(
            flashcardIds: [...stack.flashcardIds, flashcardId],
          );
        }
        return stack;
      }).toList();
      state = AsyncValue.data(updatedStacks);
    });
    // TODO: Save to your database
  }

  Future<void> removeFlashcardFromStack(String stackId, String flashcardId) async {
    state.whenData((stacks) {
      final updatedStacks = stacks.map((stack) {
        if (stack.id == stackId) {
          return stack.copyWith(
            flashcardIds: stack.flashcardIds.where((id) => id != flashcardId).toList(),
          );
        }
        return stack;
      }).toList();
      state = AsyncValue.data(updatedStacks);
    });
    // TODO: Save to your database
  }
}