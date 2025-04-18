import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/models/language.dart';
import 'package:lingua_visual/providers/database_provider.dart';
import 'package:lingua_visual/widgets/flashcards_builder.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/flashcard_widget.dart';
import '../../models/flashcard.dart';
import '../../main.dart'; // For isOnlineProvider

class FlashcardScreen extends HookConsumerWidget {
  const FlashcardScreen({super.key});

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
    final isOnline = ref.watch(isOnlineProvider);
    final flashcardsAsync = isOnline 
        ? ref.watch(flashcardsProvider)
        : ref.watch(offlineFlashcardsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          if (!isOnline)
            IconButton(
              icon: const Icon(Icons.cloud_off),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Currently in offline mode. Cards will sync when online.'),
                  ),
                );
              },
            ),
        ],
      ),
      body: flashcardsAsync.when(
        data: (flashcards) {
          if (flashcards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Flashcards Yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start adding flashcards to begin learning',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFlashcardDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Flashcard'),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: flashcards.length,
            itemBuilder: (context, index) => FlashcardWidget(flashcard: flashcards[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFlashcardDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
