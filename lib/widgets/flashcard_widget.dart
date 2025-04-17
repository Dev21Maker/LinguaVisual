import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/flashcard.dart';

class FlashcardWidget extends StatelessWidget {
  final Flashcard flashcard;

  const FlashcardWidget({
    super.key,
    required this.flashcard,
  });

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
                  flashcard.targetLanguageCode.toUpperCase(),
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
                  flashcard.nativeLanguageCode.toUpperCase(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            if (flashcard.imageUrl != null) ...[
              const SizedBox(height: 8),
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
              ),
            ],
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
}
