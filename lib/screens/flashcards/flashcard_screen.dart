import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Languador/models/flashcard.dart';
import 'package:Languador/models/flashcard_stack.dart';
import 'package:Languador/models/language.dart';
import 'package:Languador/providers/connectivity_provider.dart';
import 'package:Languador/providers/flashcard_provider.dart';
import 'package:Languador/providers/stack_provider.dart';
import 'package:Languador/widgets/flashcard_tile.dart';
import 'package:Languador/widgets/flashcards_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FlashcardScreen extends HookConsumerWidget {
  const FlashcardScreen({super.key});

  void _showAddFlashcardDialog(BuildContext context, WidgetRef ref, String? stackId) {
    showDialog(
      context: context,
      builder:
          (context) => FlashCardBuilder(
            ref: ref,
            stackId: stackId, // Pass the current stack ID
          ),
    );
  }

  void _showCreateStackDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.flashcardsCreateStackDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.flashcardsStackNameLabel,
                    hintText: l10n.flashcardsStackNameHint,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.flashcardsStackDescriptionLabel,
                    hintText: l10n.flashcardsStackDescriptionHint,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    ref.read(stacksProvider.notifier).createStack(nameController.text, descriptionController.text);
                    Navigator.pop(context);
                  }
                },
                child: Text(l10n.commonCreate),
              ),
            ],
          ),
    );
  }

  void _showMoveToStackDialog(BuildContext context, WidgetRef ref, Flashcard card, String? currentStackId) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.flashcardsMoveToStackDialogTitle),
            content: ref
                .watch(stacksProvider)
                .when(
                  data: (stacks) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (currentStackId != null)
                            ListTile(
                              leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              title: Text(l10n.flashcardsRemoveFromCurrentStack),
                              onTap: () {
                                ref.read(stacksProvider.notifier).removeFlashcardFromStack(currentStackId, card.id);
                                Navigator.pop(context);
                              },
                            ),
                          if (currentStackId != null) const Divider(),
                          if (stacks.isEmpty)
                            ListTile(
                              leading: const Icon(Icons.warning, color: Colors.amber),
                              title: Text(l10n.flashcardsNoStacksAvailable),
                            )
                          else
                            ...stacks
                                .where((stack) => stack.id != currentStackId)
                                .map(
                                  (stack) => ListTile(
                                    leading: const Icon(Icons.folder),
                                    title: Text(stack.name),
                                    subtitle: Text('${stack.flashcardIds.length} cards'),
                                    onTap: () {
                                      ref.read(stacksProvider.notifier).addFlashcardToStack(stack.id, card.id);
                                      Navigator.pop(context);
                                    },
                                  ),
                                )
                                .toList(),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.language, color: Colors.blue),
                            title: const Text("Create Stack by Language"),
                            onTap: () {
                              Navigator.pop(context);
                              _createStacksByLanguage(context, ref);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, _) => Center(
                    child: Text(l10n.stackListErrorLoading, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel))],
          ),
    );
  }

  Future<void> _updateCardImage(BuildContext context, WidgetRef ref, String cardId, String newImageUrl) async {
    final flashcardProvider = ref.read(flashcardStateProvider.notifier);
    await flashcardProvider.updateCardImage(cardId, newImageUrl);
  }

  void _createStacksByLanguage(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final flashcardsAsync = ref.watch(flashcardStateProvider);
    final stacksAsync = ref.watch(stacksProvider);
    
    if (flashcardsAsync is AsyncData && stacksAsync is AsyncData) {
      final flashcards = flashcardsAsync.value;
      final stacks = stacksAsync.value;
      
      // Group flashcards by targetLanguageCode
      final Map<String, List<String>> languageMap = {};
      try {
        for (final card in flashcards!) {
          if (!languageMap.containsKey(card.targetLanguageCode)) {
            languageMap[card.targetLanguageCode] = [];
          }
          languageMap[card.targetLanguageCode]!.add(card.id);
        } 
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.flashcardsErrorLoadingFlashcards)),
        );
        return;
      }
      
      if (languageMap.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.flashcardsNoFlashcards)),
        );
        return;
      }
      
      // Create a stack for each language
      int stacksCreated = 0;
      
      for (final entry in languageMap.entries) {
        // Get language name from supported languages
        final language = supportedLanguages.firstWhere(
          (lang) => lang.code == entry.key,
          orElse: () => Language(nativeName: entry.key, code: entry.key, name: entry.key, emoji: '📝'),
        );
        
        // Check if a stack with this language name already exists
        if (stacks == null) {
          return;
        }
        final existingStack = stacks.where((s) => s.name == language.name).toList();
        
        if (existingStack.isNotEmpty) {
          // Stack exists - add cards that aren't already in the stack
          final stack = existingStack.first;
          final missingCards = entry.value.where((id) => !stack.flashcardIds.contains(id)).toList();
          
          for (final cardId in missingCards) {
            await ref.read(stacksProvider.notifier).addFlashcardToStack(stack.id, cardId);
          }
          
          if (missingCards.isNotEmpty) {
            stacksCreated++;
          }
        } else {
          // Create new stack with language name
          await ref.read(stacksProvider.notifier).createStack(
            language.name, 
            "${language.name} ${l10n.flashcardsStackDescriptionLabel}",
          );
          
          // Get the newly created stack
          final updatedStacks = ref.read(stacksProvider).value ?? [];
          final newStack = updatedStacks.firstWhere((s) => s.name == language.name);
          
          // Add all cards of this language to the stack
          for (final cardId in entry.value) {
            await ref.read(stacksProvider.notifier).addFlashcardToStack(newStack.id, cardId);
          }
          
          stacksCreated++;
        }
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            stacksCreated > 0 
                ? "Created $stacksCreated language stacks" 
                : "Language stacks already exist",
          ),
        ),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.flashcardsErrorLoadingFlashcards),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedStackId = useState<String?>(null);
    final stacksAsync = ref.watch(stacksProvider);
    final flashcardsAsync = ref.watch(flashcardStateProvider);
    final translationVisible = useState<Map<String, bool>>({});
    final isReversed = useState<bool>(false);

    useEffect(() {
      SharedPreferences.getInstance().then((prefs) {
        isReversed.value = prefs.getBool('flashcards_reversed') ?? false;
      });
      return null;
    }, []);

    Future<void> toggleOrder() async {
      final prefs = await SharedPreferences.getInstance();
      isReversed.value = !isReversed.value;
      await prefs.setBool('flashcards_reversed', isReversed.value);
    }

    void changeTranslationVisibility(String id) =>
        translationVisible.value = {...translationVisible.value, id: !(translationVisible.value[id] ?? false)};

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: stacksAsync.when(
                data: (stacks) {
                  if (selectedStackId.value == null) {
                    return Text(l10n.flashcardsAllFlashcardsDropdown);
                  }
                  final selectedStack = stacks.firstWhere(
                    (stack) => stack.id == selectedStackId.value,
                    orElse: () {
                      selectedStackId.value = null;
                      return FlashcardStack(
                        id: '',
                        name: l10n.flashcardsAllFlashcardsDropdown,
                        description: '',
                        flashcardIds: [],
                        createdAt: DateTime.now(),
                      );
                    },
                  );
                  return Text(selectedStack.name);
                },
                loading: () => Text(l10n.flashcardsLoadingStacks),
                error: (_, __) => Text(l10n.flashcardsAppBarTitle),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () => toggleOrder(),
              tooltip: l10n.sortLatest,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: l10n.flashcardsReverseOrderTooltip,
              onSelected: (value) {
                switch (value) {
                  case 'toggle_order':
                    toggleOrder();
                    break;
                  case 'refresh':
                    ref.refresh(flashcardStateProvider);
                    ref.refresh(stacksProvider);
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                PopupMenuItem<String>(
                  value: 'toggle_order',
                  child: Row(
                    children: [
                      Icon(
                        isReversed.value ? Icons.sort_rounded : Icons.sort_by_alpha_rounded,
                        size: 20,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 8),
                      Text(isReversed.value ? l10n.sortOldest : l10n.sortLatest),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20, color: Theme.of(context).iconTheme.color),
                      const SizedBox(width: 8),
                      Text(l10n.actionRefresh),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: stacksAsync.when(
          data:
              (stacks) => ListView(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: Theme.of(context).primaryColor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.stackListAppBarTitle, style: const TextStyle(color: Colors.white, fontSize: 24)),
                        const SizedBox(height: 8),
                        Text('${stacks.length} stacks', style: const TextStyle(color: Colors.white70)),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateStackDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.flashcardsCreateStackMenuItem),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.all_inclusive),
                    title: Text(l10n.flashcardsAllFlashcardsDropdown),
                    selected: selectedStackId.value == null,
                    onTap: () {
                      selectedStackId.value = null;
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  if (stacks.isEmpty)
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(l10n.stackListEmptyTitle),
                      subtitle: Text(l10n.stackListEmptySubtitle),
                    )
                  else
                    ...stacks.map(
                      (stack) => Dismissible(
                        key: ValueKey(stack.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          color: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text(l10n.dialogDeleteTitle),
                                  content: Text('Are you sure you want to delete ${stack.name}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text(l10n.commonCancel),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: Text(l10n.commonCreate, style: const TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                          );
                        },
                        onDismissed: (_) {
                          ref.read(stacksProvider.notifier).deleteStack(stack.id);
                        },
                        child: ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(stack.name),
                          subtitle: Text(l10n.stackListCardSubtitle(stack.flashcardIds.length, stack.description)),
                          selected: selectedStackId.value == stack.id,
                          onTap: () {
                            selectedStackId.value = stack.id;
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                ],
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, _) => Center(
                child: Text(l10n.stackListErrorLoading, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
        ),
      ),
      body: flashcardsAsync.when(
        data: (flashcards) {
          final filteredFlashcards =
              selectedStackId.value != null
                  ? flashcards.where((card) {
                    final stack = stacksAsync.value?.firstWhere(
                      (s) => s.id == selectedStackId.value,
                      orElse: () => stacksAsync.value!.last,
                    );
                    return stack?.flashcardIds.contains(card.id) ?? false;
                  }).toList()
                  : flashcards;

          final displayedFlashcards = isReversed.value ? filteredFlashcards.reversed.toList() : filteredFlashcards;

          if (displayedFlashcards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.flashcardsNoFlashcards, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    l10n.flashcardsAddSomeFlashcards,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: displayedFlashcards.length,
            itemBuilder: (context, index) {
              final card = displayedFlashcards[index];
              return FlashcardTile(
                card: card,
                translationVisible: translationVisible,
                changeTranslationVisibility: (p0) => changeTranslationVisibility(p0),
                showMoveToStackDialog: () => _showMoveToStackDialog(context, ref, card, selectedStackId.value),
                getEmoji: () {
                  if (ref.read(isOnlineProvider.notifier).state) {
                    return card.targetLanguage.emoji;
                  } else {
                    return supportedLanguages.firstWhere((element) => element.code == card.targetLanguageCode).emoji;
                  }
                },
                onImageUpdated: (cardId, imageUrl) => _updateCardImage(context, ref, cardId, imageUrl),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(l10n.flashcardsErrorLoadingFlashcards, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    l10n.flashcardsGenericError,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFlashcardDialog(context, ref, selectedStackId.value),
        child: const Icon(Icons.add),
      ),
    );
  }
}
