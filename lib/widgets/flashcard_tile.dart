import 'package:flutter/material.dart';
import 'package:lingua_visual/models/flashcard.dart';
import 'package:lingua_visual/widgets/image_prompt_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FlashcardTile<T extends Flashcard> extends StatefulWidget {
  const FlashcardTile({
    required this.card,
    required this.translationVisible,
    required this.changeTranslationVisibility,
    required this.showMoveToStackDialog,
    required this.getEmoji,
    required this.onImageUpdated,
    super.key,
  });

  final T card;
  final ValueNotifier<Map<String, bool>> translationVisible;
  final Function(String) changeTranslationVisibility;
  final VoidCallback showMoveToStackDialog;
  final String Function() getEmoji;
  final Function(String, String) onImageUpdated;

  @override
  State<FlashcardTile> createState() => _FlashcardTileState();
}

class _FlashcardTileState extends State<FlashcardTile> {
  Future<void> _showImagePickerDialog() async {
    final imageUrl = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => ImagePromptDialog(
            word: widget.card.word.toString(),
            onImageSelected: (url) {
              Navigator.pop(context, url);
            },
            barrierDismissible: true,
          ),
    );

    if (imageUrl != null && mounted) {
      widget.onImageUpdated(widget.card.id, imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(child: Text(widget.card.word, overflow: TextOverflow.clip, style: Theme.of(context).textTheme.titleLarge)),
                      SizedBox(width: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            iconSize: 22,
                            icon: const Icon(Icons.image),
                            onPressed: _showImagePickerDialog,
                            tooltip: 'Change image',
                          ),
                          IconButton(
                            icon: const Icon(Icons.folder_shared),
                            onPressed: () => widget.showMoveToStackDialog.call(),
                            tooltip: 'Move to stack',
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                      SizedBox(width: 8),
                      Text(widget.getEmoji.call(), style: const TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child:
                              (widget.translationVisible.value[widget.card.id] ?? false)
                                  ? Text(
                                    widget.card.translation,
                                    overflow: TextOverflow.clip,
                                    key: ValueKey('shown_${widget.card.id}'),
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  )
                                  : Text(
                                    '••••••••••',
                                    key: ValueKey('hidden_${widget.card.id}'),
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16, letterSpacing: 2),
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
                        onPressed: () => widget.changeTranslationVisibility.call(widget.card.id),
                        tooltip:
                            (widget.translationVisible.value[widget.card.id] ?? false)
                                ? 'Hide translation'
                                : 'Show translation',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.card.imageUrl != null && widget.card.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0, bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: widget.card.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
