import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/flashcard.dart';
import '../utils/image_picker_utils.dart';

class FlashcardWidget extends StatefulWidget {
  final Flashcard flashcard;
  final Function(String)? onImageUpdated;

  const FlashcardWidget({
    super.key,
    required this.flashcard,
    this.onImageUpdated,
  });

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget> {
  late Flashcard flashcard;

  @override
  void initState() {
    super.initState();
    flashcard = widget.flashcard;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  flashcard.word,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  flashcard.targetLanguage.code.toUpperCase(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  flashcard.translation,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  flashcard.nativeLanguage.code.toUpperCase(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                if (flashcard.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: flashcard.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 32, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('No image available'),
                    ),
                  ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: FloatingActionButton.small(
                    onPressed: _pickImage,
                    child: const Icon(Icons.image_search),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next review: ${_formatDate(flashcard.srsNextReviewDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Interval: ${flashcard.srsInterval.toStringAsFixed(1)} days',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(int millisecondsSinceEpoch) {
    final date = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Opens the image picker and updates the flashcard image URL.
  Future<void> _pickImage() async {
    final imageUrl = await ImagePickerUtils.pickImage(context);
    if (imageUrl != null) {
      setState(() {
        flashcard = flashcard.copyWith(imageUrl: imageUrl);
      });

      // Notify parent widget about the image update
      if (widget.onImageUpdated != null) {
        widget.onImageUpdated!(imageUrl);
      }
    }
  }
}
