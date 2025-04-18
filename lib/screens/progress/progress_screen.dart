import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/providers/flashcard_provider.dart';


class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              _buildStatisticsCards(context, ref),
              const SizedBox(height: 32),
              Text(
                'Review History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildReviewHistory(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(BuildContext context, WidgetRef ref) {
    final flashcardsAsync = ref.watch(flashcardsProvider);
    final dueFlashcardsAsync = ref.watch(dueFlashcardsProvider);

    return flashcardsAsync.when(
      data: (flashcards) => dueFlashcardsAsync.when(
        data: (dueCards) => GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              context,
              'Total Cards',
              flashcards.length.toString(),
              Icons.school,
              Colors.blue,
            ),
            _buildStatCard(
              context,
              'Due Today',
              dueCards.length.toString(),
              Icons.access_time,
              Colors.orange,
            ),
            _buildStatCard(
              context,
              'Learned Today',
              '0', // TODO: Implement learned today count
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              context,
              'Streak',
              '0', // TODO: Implement streak count
              Icons.local_fire_department,
              Colors.red,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewHistory(BuildContext context, WidgetRef ref) {
    final flashcardsAsync = ref.watch(flashcardsProvider);

    return flashcardsAsync.when(
      data: (flashcards) => Expanded(
        child: ListView.builder(
          itemCount: flashcards.length,
          itemBuilder: (context, index) {
            final card = flashcards[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(card.word),
                subtitle: Text(
                  'Next review: ${_formatDate(card.srsNextReviewDate)}',
                ),
                trailing: Text(
                  'Interval: ${card.srsInterval.toStringAsFixed(1)}d',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  String _formatDate(int millisecondsSinceEpoch) {
    final date = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}