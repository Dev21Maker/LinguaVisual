import 'package:Languador/widgets/common/webview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Languador/models/offline_flashcard.dart';
import 'package:Languador/models/online_flashcard.dart';
import 'package:Languador/models/language.dart';
import 'package:Languador/providers/connectivity_provider.dart';
import 'package:Languador/providers/offline_flashcard_provider.dart';
import 'package:Languador/providers/settings_provider.dart';
import 'package:Languador/providers/flashcard_provider.dart';
import 'package:Languador/providers/stack_provider.dart';
import 'package:uuid/uuid.dart';

class FlashCardBuilder extends StatelessWidget {
  const FlashCardBuilder({required this.ref, super.key, this.stackId});

  final WidgetRef ref;
  final String? stackId;

  @override
  Widget build(BuildContext context) {
    return HookBuilder(
      builder: (context) {
        final wordController = useTextEditingController();
        final translationController = useTextEditingController();
        final bulkInputController = useTextEditingController();
        final formKey = GlobalKey<FormState>();
        final settings = ref.read(settingsProvider);
        final isBulkMode = useState(false);

        final targetLanguageState = useState<Language>(settings.targetLanguage);
        final nativeLanguageState = useState<Language>(settings.nativeLanguage);

        Future<bool> _addBulkFlashcards() async {
          bool cardsAdded = false;
          final lines = bulkInputController.text.split('\n');
          for (final line in lines) {
            final parts = line.split('\\');
            if (parts.length == 2) {
              final word = parts[0].trim();
              final translation = parts[1].trim();

              if (word.isNotEmpty && translation.isNotEmpty) {
                final id = const Uuid().v4();
                final newFlashcard = OfflineFlashcard(
                  id: id,
                  word: word,
                  targetLanguageCode: targetLanguageState.value.code,
                  translation: translation,
                  nativeLanguageCode: nativeLanguageState.value.code,
                  srsNextReviewDate: DateTime.now().millisecondsSinceEpoch,
                  srsInterval: 1.0,
                  srsEaseFactor: 2.5,
                );

                // Always save offline first
                await ref.read(offlineFlashcardsProvider.notifier).addFlashcard(newFlashcard);

                // If online, also save to Firestore
                if (ref.read(isOnlineProvider)) {
                  final onlineFlashcard = OnlineFlashcard(
                    id: newFlashcard.id,
                    word: newFlashcard.word,
                    targetLanguage: targetLanguageState.value,
                    translation: newFlashcard.translation,
                    nativeLanguage: nativeLanguageState.value,
                    srsInterval: newFlashcard.srsInterval,
                    srsEaseFactor: newFlashcard.srsEaseFactor,
                    srsNextReviewDate: newFlashcard.srsNextReviewDate,
                  );
                  await ref.read(flashcardStateProvider.notifier).addFlashcard(onlineFlashcard);
                  cardsAdded = true;
                }

                // Add to current stack if a stack is selected
                if (stackId != null) {
                  await ref.read(stacksProvider.notifier).addFlashcardToStack(stackId!, id);
                }
              }
            }
          }
          return cardsAdded;
        }

        Future<String?> _addFlashcardSingle(
            TextEditingController wordController, 
            ValueNotifier<Language> targetLanguageState, 
            TextEditingController translationController, 
            ValueNotifier<Language> nativeLanguageState
        ) async {
          final id = const Uuid().v4();
          final newFlashcard = OfflineFlashcard(
            id: id,
            word: wordController.text,
            targetLanguageCode: targetLanguageState.value.code,
            translation: translationController.text,
            nativeLanguageCode: nativeLanguageState.value.code,
            srsNextReviewDate: DateTime.now().millisecondsSinceEpoch,
            srsInterval: 1.0,
            srsEaseFactor: 2.5,
          );
          
          // Always save offline first
          await ref.read(offlineFlashcardsProvider.notifier).addFlashcard(newFlashcard);
          
          // If online, also save to Firestore
          if (ref.read(isOnlineProvider)) {
            final onlineFlashcard = OnlineFlashcard(
              id: newFlashcard.id,
              word: newFlashcard.word,
              targetLanguage: targetLanguageState.value,
              translation: newFlashcard.translation,
              nativeLanguage: nativeLanguageState.value,
              srsInterval: newFlashcard.srsInterval,
              srsEaseFactor: newFlashcard.srsEaseFactor,
              srsNextReviewDate: newFlashcard.srsNextReviewDate,
            );
            await ref.read(flashcardStateProvider.notifier).addFlashcard(onlineFlashcard);
          }
          
          // Add to current stack if a stack is selected
          if (stackId != null) {
            await ref.read(stacksProvider.notifier).addFlashcardToStack(stackId!, id);
          }
          return id;
        }

        return AlertDialog(
          title: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(child: const Text('Add New Flashcard')),
              Align(
                alignment: Alignment.topRight,
                child: Tooltip(
                  message:
                      isBulkMode.value
                          ? 'Switch to single word input mode'
                          : 'Switch to bulk input mode for multiple words',
                  child: TextButton.icon(
                    onPressed: () {
                      isBulkMode.value = !isBulkMode.value;
                    },
                    icon: Icon(isBulkMode.value ? Icons.note_add : Icons.list),
                    label: Text(isBulkMode.value ? 'Single Mode' : 'Bulk Mode'),
                  ),
                ),
              ),
              TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => WebViewScreen(
                                title: 'Custom Flashcard Builder GPT',
                                url:
                                    'https://chatgpt.com/g/g-6828a6f0d3bc8191aa5d9fdb800f33bf-languador-flashcards-builder',
                              ),
                        ),
                      );
                    },
                    child: const Text('Custom Flashcard Builder GPT'),
                  ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  if (!isBulkMode.value) ...[
                    // Single word mode UI
                    DropdownButtonFormField<Language>(
                      value: targetLanguageState.value,
                      decoration: const InputDecoration(labelText: 'Target Language'),
                      items:
                          supportedLanguages.map((Language language) {
                            return DropdownMenuItem<Language>(
                              value: language,
                              child: Text('${language.name} (${language.nativeName})'),
                            );
                          }).toList(),
                      onChanged: (Language? newValue) {
                        if (newValue != null) {
                          targetLanguageState.value = newValue;
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: wordController,
                      decoration: const InputDecoration(labelText: 'Word', hintText: 'Enter the word to learn'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a word';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Language>(
                      value: nativeLanguageState.value,
                      decoration: const InputDecoration(labelText: 'Native Language'),
                      items:
                          supportedLanguages.map((Language language) {
                            return DropdownMenuItem<Language>(
                              value: language,
                              child: Text('${language.name} (${language.nativeName})'),
                            );
                          }).toList(),
                      onChanged: (Language? newValue) {
                        if (newValue != null) {
                          nativeLanguageState.value = newValue;
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: translationController,
                      decoration: const InputDecoration(labelText: 'Translation', hintText: 'Enter the translation'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a translation';
                        }
                        return null;
                      },
                    ),
                  ] else ...[
                    // Bulk input mode UI
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How to add multiple words:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1. Enter one word pair per line\n'
                            '2. Use \\ to separate word and translation\n'
                            '3. Example: hello\\hola',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'From: ${targetLanguageState.value.name} → To: ${nativeLanguageState.value.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: bulkInputController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'hola\\hello\nmundo\\world\nlibro\\book',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        helperText: 'Press Enter for a new line',
                        helperStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter at least one word pair';
                        }
                        // Validate format of each line
                        final lines = value.split('\n');
                        for (int i = 0; i < lines.length; i++) {
                          final line = lines[i].trim();
                          if (line.isNotEmpty && !line.contains('\\')) {
                            return 'Line ${i + 1} is missing the \\ separator';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  bool cardsAdded = false;
                  
                  if (isBulkMode.value) {
                    cardsAdded = await _addBulkFlashcards();
                  } else {
                    final flashcardId = await _addFlashcardSingle(
                      wordController, 
                      targetLanguageState, 
                      translationController, 
                      nativeLanguageState
                    );
                    cardsAdded = flashcardId != null;
                  }
                  
                  // Close the dialog first
                  if (context.mounted) {
                    Navigator.pop(context);
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isBulkMode.value ? 'Multiple flashcards added successfully' : 'Flashcard added successfully',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Check for missing images after dialog is closed if cards were added
                  }
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  
}
