import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/stack_provider.dart';
import 'stack_detail_screen.dart';

class StackListScreen extends ConsumerWidget {
  const StackListScreen({super.key});

  void _showCreateStackDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                ref.read(stacksProvider.notifier).createStack(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stacksAsync = ref.watch(stacksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Stacks'),
      ),
      body: stacksAsync.when(
        data: (stacks) => stacks.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No stacks yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a stack to organize your flashcards',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateStackDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Stack'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: stacks.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final stack = stacks[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(stack.name),
                      subtitle: Text(
                        '${stack.flashcardIds.length} cards • ${stack.description}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StackDetailScreen(stack: stack),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error loading stacks',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateStackDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}