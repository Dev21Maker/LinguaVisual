import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Languador/providers/stack_provider.dart';
import '../../models/flashcard_stack.dart';
import '../../providers/flashcard_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StackDetailScreen extends ConsumerWidget {
  final FlashcardStack stack;

  const StackDetailScreen({
    super.key,
    required this.stack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashcardsAsync = ref.watch(flashcardsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(stack.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: l10n.stackDetailStartPracticeTooltip,
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
                    l10n.stackDetailEmptyTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.stackDetailEmptySubtitle,
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
                    tooltip: l10n.stackDetailRemoveCardTooltip,
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
            l10n.stackDetailErrorLoading,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.stackDetailAddCardTooltip,
        onPressed: () {
          // TODO: Show dialog to add existing flashcards to this stack
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}