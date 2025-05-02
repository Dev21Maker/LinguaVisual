import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/providers/offline_flashcard_provider.dart';
import '../widgets/flashcard_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OfflineTrainingScreen extends HookConsumerWidget {
  const OfflineTrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashcards = ref.watch(offlineFlashcardsProvider);
    final currentIndexState = useState(0);
    final currentIndex = currentIndexState.value;
    final l10n = AppLocalizations.of(context)!;

    if (flashcards.value?.isEmpty ?? true) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.offlineTrainingNoCards)),
      );
    }

    // Get current card, handling index bounds
    final currentOfflineCard = currentIndex < flashcards.value!.length ? flashcards.value![currentIndex] : null;

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
                  title: Text(l10n.offlineTrainingCompleteTitle),
                  content: Text(l10n.offlineTrainingCompleteContent(flashcards.value!.length)),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(); // Return to previous screen
                      },
                      child: Text(l10n.offlineTrainingCompleteButton),
                    ),
                  ],
                ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.offlineTrainingAppBarTitle(currentIndex + 1, flashcards.value!.length)),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close),
            label: Text(l10n.offlineTrainingEndSessionButton),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: FlashcardView(
            flashcards: currentOfflineCard != null ? [currentOfflineCard] : [], 
            onRatingSelected: (rating, _) => onRatingSelected(rating),
          ),
        ),
      ),
    );
  }
}
