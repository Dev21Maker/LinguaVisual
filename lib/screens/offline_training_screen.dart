import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/models/flashcard_converters.dart';
import 'package:lingua_visual/providers/offline_flashcard_provider.dart';
import '../widgets/flashcard_view.dart';

class OfflineTrainingScreen extends HookConsumerWidget {
  const OfflineTrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashcards = ref.watch(offlineFlashcardsProvider);
    final currentIndexState = useState(0);
    final currentIndex = currentIndexState.value;

    if (flashcards.value?.isEmpty ?? true) {
      return const Scaffold(
        body: Center(child: Text('No flashcards available')),
      );
    }

    final currentCard = flashcards.value![currentIndex];

    Future<void> onRatingSelected(String rating) async {
      // Update SRS data based on rating
      final now = DateTime.now().millisecondsSinceEpoch;
      final updatedOfflineCard = flashcards.value![currentIndex].copyWith(
        srsNextReviewDate: now + 1000, // Placeholder for actual SRS logic
        srsLastReviewDate: now,
      );

      // Update the card in storage
      await ref
          .read(offlineFlashcardsProvider.notifier)
          .updateCard(updatedOfflineCard);

      // Move to next card or finish
      if (currentIndex < flashcards.value!.length - 1) {
        currentIndexState.value = currentIndex + 1;
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => AlertDialog(
                  title: const Text('Training Complete!'),
                  content: Text('You reviewed ${flashcards.value!.length} cards'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(
                          context,
                        ).pop(); // Return to previous screen
                      },
                      child: const Text('FINISH'),
                    ),
                  ],
                ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Card ${currentIndex + 1}/${flashcards.value!.length}'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close),
            label: const Text('End Session'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: FlashcardView(
            flashcards: [FlashcardConverters.offlineToFlashcardItem(currentCard)],  // Wrap in list
            onRatingSelected: (rating, _) => onRatingSelected(rating),
          ),
        ),
      ),
    );
  }
}
