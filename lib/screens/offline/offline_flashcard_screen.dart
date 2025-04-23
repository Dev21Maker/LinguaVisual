import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/offline_flashcard_provider.dart';
import '../../widgets/flashcards_builder.dart';

class OfflineFlashcardScreen extends HookConsumerWidget {
  const OfflineFlashcardScreen({super.key});

  void _showAddFlashcardDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return FlashCardBuilder(
          ref: ref,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashcardsAsync = ref.watch(offlineFlashcardsProvider);

    return flashcardsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading flashcards')),
      data: (flashcards) => Scaffold(
        body: flashcards.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No flashcards available',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddFlashcardDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Flashcard'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: flashcards.length,
                itemBuilder: (context, index) {
                  final flashcard = flashcards[index];
                  return Dismissible(
                    key: Key(flashcard.id),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      ref.read(offlineFlashcardsProvider.notifier)
                          .removeFlashcard(flashcard.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Flashcard deleted'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(flashcard.word),
                        subtitle: Text(flashcard.translation),
                        trailing: Text(
                          'Last reviewed: ${flashcard.srsLastReviewDate != null ? "Yes" : "No"}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddFlashcardDialog(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}