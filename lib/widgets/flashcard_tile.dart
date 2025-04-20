import 'package:flutter/material.dart';
import 'package:lingua_visual/models/flashcard.dart';

class FlashcardTile extends StatefulWidget {
  const FlashcardTile({
    required this.card,
    required this.translationVisible,
    required this.changeTranslationVisibility,
    required this.showMoveToStackDialog,
    super.key, 
  });

  final Flashcard card;
  final ValueNotifier<Map<String, bool>> translationVisible;
  final Function(String) changeTranslationVisibility;
  final VoidCallback showMoveToStackDialog;

  @override
  State<FlashcardTile> createState() => _FlashcardTileState();
}

class _FlashcardTileState extends State<FlashcardTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.card.word,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child:
                              (widget.translationVisible.value[widget.card.id] ?? false)
                                  ? Text(
                                    widget.card.translation,
                                    key: ValueKey('shown_${widget.card.id}'),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  )
                                  : Container(
                                    key: ValueKey('hidden_${widget.card.id}'),
                                    height: 20,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '••••••••••',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 16,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                        ),
                        IconButton(
                          iconSize: 22,
                          icon: Icon(
                            (widget.translationVisible.value[widget.card.id] ?? false)
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed:
                              () => widget.changeTranslationVisibility.call(widget.card.id),
                          tooltip:
                              (widget.translationVisible.value[widget.card.id] ?? false)
                                  ? 'Hide translation'
                                  : 'Show translation',
                        ),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            widget.card.targetLanguage.emoji,
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.folder_shared),
                onPressed:
                    () => widget.showMoveToStackDialog.call(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
