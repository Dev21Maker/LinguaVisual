import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/providers/stack_provider.dart';
import '../../models/flashcard_stack.dart';
import '../../providers/flashcard_provider.dart';

class StackDetailScreen extends ConsumerWidget {
  final FlashcardStack stack;

  const StackDetailScreen({
    super.key,
    required this.stack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashcardsAsync = ref.watch(flashcardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(stack.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              // TODO: Start practice session with this stack's cards
            },
          ),
        ],
      ),
      body: flashcardsAsync.when(
        data: (allFlashcards) {
          final stackFlashcards = allFlashcards
              .where((card) => stack.flashcardIds.contains(card.id))
              .toList();

          if (stackFlashcards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.note_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No flashcards in this stack',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add flashcards to start practicing',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: stackFlashcards.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final flashcard = stackFlashcards[index];
              return Card(
                child: ListTile(
                  title: Text(flashcard.word),
                  subtitle: Text(flashcard.translation),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      ref.read(stacksProvider.notifier).removeFlashcardFromStack(
                        stack.id,
                        flashcard.id,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error loading flashcards',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Show dialog to add existing flashcards to this stack
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}