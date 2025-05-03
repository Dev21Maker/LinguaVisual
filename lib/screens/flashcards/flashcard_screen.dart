import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/models/flashcard.dart';
import 'package:lingua_visual/models/flashcard_stack.dart';
import 'package:lingua_visual/models/language.dart';
import 'package:lingua_visual/providers/connectivity_provider.dart';
import 'package:lingua_visual/providers/flashcard_provider.dart';
import 'package:lingua_visual/providers/stack_provider.dart';
import 'package:lingua_visual/widgets/flashcard_tile.dart';
import 'package:lingua_visual/widgets/flashcards_builder.dart';
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
                    return Column(
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
                          Text(l10n.flashcardsNoStacksAvailable)
                        else
                          SizedBox(
                            width: double.maxFinite,
                            height: 300, // Fixed height for scrollable list
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: stacks.length,
                              itemBuilder: (context, index) {
                                final stack = stacks[index];
                                final isCurrentStack = stack.id == currentStackId;
                                final isCardInStack = stack.flashcardIds.contains(card.id);

                                return ListTile(
                                  enabled: !isCurrentStack,
                                  leading: const Icon(Icons.folder),
                                  title: Text(stack.name),
                                  trailing: isCardInStack ? const Icon(Icons.check) : null,
                                  onTap: () {
                                    if (isCardInStack) {
                                      ref.read(stacksProvider.notifier).removeFlashcardFromStack(stack.id, card.id);
                                    } else {
                                      ref.read(stacksProvider.notifier).addFlashcardToStack(stack.id, card.id);
                                    }
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text('${l10n.commonError}: $error'),
                ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel))],
          ),
    );
  }

  Future<void> _updateCardImage(BuildContext context, WidgetRef ref, String cardId, String newImageUrl) async {
    final flashcardProvider = ref.read(flashcardStateProvider.notifier);
    await flashcardProvider.updateCardImage(cardId, newImageUrl);
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
            // Add menu button here
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: l10n.flashcardsReverseOrderTooltip,
              onSelected: (value) {
                switch (value) {
                  case 'toggle_order':
                    toggleOrder();
                    break;
                  case 'refresh':
                    // Discard the result but still call refresh
                    ref.refresh(flashcardStateProvider);
                    ref.refresh(stacksProvider);
                    break;
                }
              },
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<String>>[
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
        actions: const [], // Remove the original actions
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
