import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/stack_provider.dart';
import 'stack_detail_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StackListScreen extends ConsumerWidget {
  const StackListScreen({super.key});

  void _showCreateStackDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.stackListCreateDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.stackListCreateNameLabel,
                hintText: l10n.stackListCreateNameHint,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: l10n.stackListCreateDescLabel,
                hintText: l10n.stackListCreateDescHint,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
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
            child: Text(l10n.stackListCreateButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stacksAsync = ref.watch(stacksProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stackListAppBarTitle),
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
                      l10n.stackListEmptyTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.stackListEmptySubtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateStackDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.stackListEmptyButton),
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
                        l10n.stackListCardSubtitle(stack.flashcardIds.length, stack.description),
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
            l10n.stackListErrorLoading,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.stackListCreateFabTooltip,
        onPressed: () => _showCreateStackDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}