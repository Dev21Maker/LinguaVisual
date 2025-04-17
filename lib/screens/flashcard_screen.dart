import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/flashcard_widget.dart';

class FlashcardScreen extends ConsumerWidget {
  const FlashcardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashcardsAsync = ref.watch(flashcardsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
      ),
      body: flashcardsAsync.when(
        data: (flashcards) => ListView.builder(
          itemCount: flashcards.length,
          itemBuilder: (context, index) => FlashcardWidget(flashcard: flashcards[index]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
