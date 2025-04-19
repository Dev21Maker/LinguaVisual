import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/main.dart';
import 'package:lingua_visual/models/flashcard.dart';
import 'package:lingua_visual/models/language.dart';
import 'package:lingua_visual/providers/settings_provider.dart';
import 'package:lingua_visual/providers/flashcard_provider.dart';
import 'package:uuid/uuid.dart';

class FlashCardBuilder extends StatelessWidget {
  const FlashCardBuilder({
    required this.ref,
    super.key, String? stackId,
  });

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return HookBuilder(builder: (context) {
      final wordController = useTextEditingController();
      final translationController = useTextEditingController();
      final bulkInputController = useTextEditingController();
      final formKey = GlobalKey<FormState>();
      final settings = ref.read(settingsProvider);
      final isBulkMode = useState(false);
      
      final targetLanguageState = useState<Language>(settings.targetLanguage);
      final nativeLanguageState = useState<Language>(settings.nativeLanguage);
    
      Future<void> _addBulkFlashcards() async {
        final lines = bulkInputController.text.split('\n');
        for (final line in lines) {
          final parts = line.split('\\');
          if (parts.length == 2) {
            final word = parts[0].trim();
            final translation = parts[1].trim();
            
            if (word.isNotEmpty && translation.isNotEmpty) {
              final newFlashcard = Flashcard(
                id: const Uuid().v4(), // Use UUID instead of timestamp
                word: word,
                translation: translation,
                targetLanguageCode: targetLanguageState.value.code,
                nativeLanguageCode: nativeLanguageState.value.code,
                srsNextReviewDate: DateTime.now().millisecondsSinceEpoch,
                srsInterval: 1.0,
                srsEaseFactor: 2.5,
              );

              if (ref.read(isOnlineProvider)) {
                await ref.read(flashcardStateProvider.notifier).addFlashcard(newFlashcard);
              } else {
                await ref.read(offlineFlashcardsProvider.notifier).addFlashcard(newFlashcard);
              }
            }
          }
        }
      }
    
      return AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Add New Flashcard'),
            Tooltip(
              message: isBulkMode.value 
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
                    decoration: const InputDecoration(
                      labelText: 'Target Language',
                    ),
                    items: supportedLanguages.map((Language language) {
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
                    decoration: const InputDecoration(
                      labelText: 'Word',
                      hintText: 'Enter the word to learn',
                    ),
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
                    decoration: const InputDecoration(
                      labelText: 'Native Language',
                    ),
                    items: supportedLanguages.map((Language language) {
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
                    decoration: const InputDecoration(
                      labelText: 'Translation',
                      hintText: 'Enter the translation',
                    ),
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
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How to add multiple words:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Enter one word pair per line\n'
                          '2. Use \\ to separate word and translation\n'
                          '3. Example: hello\\hola',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
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
                      hintText: 'hello\\hola\nworld\\mundo\nbook\\libro',
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                if (isBulkMode.value) {
                  await _addBulkFlashcards();
                } else {
                  final newFlashcard = Flashcard(
                    id: const Uuid().v4(), // Use UUID instead of timestamp
                    word: wordController.text,
                    translation: translationController.text,
                    targetLanguageCode: targetLanguageState.value.code,
                    nativeLanguageCode: nativeLanguageState.value.code,
                    srsNextReviewDate: DateTime.now().millisecondsSinceEpoch,
                    srsInterval: 1.0,
                    srsEaseFactor: 2.5,
                  );

                  if (ref.read(isOnlineProvider)) {
                    await ref.read(flashcardStateProvider.notifier).addFlashcard(newFlashcard);
                  } else {
                    await ref.read(offlineFlashcardsProvider.notifier).addFlashcard(newFlashcard);
                  }
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isBulkMode.value 
                            ? 'Multiple flashcards added successfully'
                            : 'Flashcard added successfully'
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('ADD'),
          ),
        ],
      );
    });
  }
}
