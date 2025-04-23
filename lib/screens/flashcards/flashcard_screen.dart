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

class FlashcardScreen extends HookConsumerWidget {
  const FlashcardScreen({super.key});

  void _showAddFlashcardDialog(
    BuildContext context,
    WidgetRef ref,
    String? stackId,
  ) {
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

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Stack'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Stack Name',
                    hintText: 'Enter stack name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter stack description',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    ref
                        .read(stacksProvider.notifier)
                        .createStack(
                          nameController.text,
                          descriptionController.text,
                        );
                    Navigator.pop(context);
                  }
                },
                child: const Text('CREATE'),
              ),
            ],
          ),
    );
  }

  void _showMoveToStackDialog(
    BuildContext context,
    WidgetRef ref,
    Flashcard card,
    String? currentStackId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Stack'),
        content: ref.watch(stacksProvider).when(
          data: (stacks) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentStackId != null)
                  ListTile(
                    leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    title: const Text('Remove from current stack'),
                    onTap: () {
                      ref.read(stacksProvider.notifier).removeFlashcardFromStack(
                        currentStackId,
                        card.id,
                      );
                      Navigator.pop(context);
                    },
                  ),
                if (currentStackId != null)
                  const Divider(),
                if (stacks.isEmpty)
                  const Text('No stacks available. Create a stack first.')
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
                              ref.read(stacksProvider.notifier).removeFlashcardFromStack(
                                stack.id,
                                card.id,
                              );
                            } else {
                              ref.read(stacksProvider.notifier).addFlashcardToStack(
                                stack.id,
                                card.id,
                              );
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
          error: (error, _) => Text('Error: $error'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStackId = useState<String?>(null);
    final stacksAsync = ref.watch(stacksProvider);
    final flashcardsAsync = ref.watch(flashcardStateProvider);
    // Track per-card translation visibility
    final translationVisible = useState<Map<String, bool>>({});
    void _changeTranslationVisibility(String id) =>
        translationVisible.value = {
          ...translationVisible.value,
          id: !(translationVisible.value[id] ?? false),
        };

    return Scaffold(
      appBar: AppBar(
        title: stacksAsync.when(
          data: (stacks) {
            if (selectedStackId.value == null) {
              return const Text('All Flashcards');
            }
            final selectedStack = stacks.firstWhere(
              (stack) => stack.id == selectedStackId.value,
              orElse: () {
                // If selected stack not found, reset to "All Flashcards"
                selectedStackId.value = null;
                return FlashcardStack(
                  id: '',
                  name: 'All Flashcards',
                  description: '',
                  flashcardIds: [],
                  createdAt: DateTime.now(),
                );
              },
            );
            return Text(selectedStack.name);
          },
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Flashcards'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(flashcardStateProvider),
          ),
        ],
      ),
      drawer: Drawer(
        child: stacksAsync.when(
          data:
              (stacks) => ListView(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Flashcard Stacks',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${stacks.length} Stacks',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateStackDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Stack'),
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
                    title: const Text('All Flashcards'),
                    selected: selectedStackId.value == null,
                    onTap: () {
                      selectedStackId.value = null;
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  if (stacks.isEmpty)
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('No stacks yet'),
                      subtitle: Text(
                        'Create a stack to organize your flashcards',
                      ),
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
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Stack'),
                              content: Text('Are you sure you want to delete the stack "${stack.name}"? This will not delete the flashcards.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('CANCEL'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('DELETE', style: TextStyle(color: Colors.red)),
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
                          subtitle: Text('${stack.flashcardIds.length} cards'),
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
                child: Text(
                  'Error loading stacks',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
        ),
      ),
      body: flashcardsAsync.when(
        data: (flashcards) {
          // Filter flashcards based on selected stack
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

          if (filteredFlashcards.isEmpty) {
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
                    'No flashcards available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some flashcards to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredFlashcards.length,
            itemBuilder: (context, index) {
              final card = filteredFlashcards[index];
              return FlashcardTile(
                card: card, 
                translationVisible: translationVisible, 
                changeTranslationVisibility: (p0) => _changeTranslationVisibility(p0), 
                showMoveToStackDialog: () =>  _showMoveToStackDialog(
                            context,
                            ref,
                            card,
                            selectedStackId.value,
                          ),
                getEmoji: () {
                  if(ref.read(isOnlineProvider.notifier).state) {
                    return card.targetLanguage.emoji;
                  } else {
                    return supportedLanguages.firstWhere((element) => element.code == card.targetLanguageCode,).emoji;
                  }
                },
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
                  Text(
                    'Error loading flashcards',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => _showAddFlashcardDialog(context, ref, selectedStackId.value),
        child: const Icon(Icons.add),
      ),
    );
  }
}
