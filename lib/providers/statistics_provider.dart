import 'package:hooks_riverpod/hooks_riverpod.dart';

class Statistics {
  final int totalCards;
  final int dueToday;
  final int learnedToday;
  final int streak;

  Statistics({
    required this.totalCards,
    required this.dueToday,
    required this.learnedToday,
    required this.streak,
  });
}

final statisticsProvider = StateNotifierProvider<StatisticsNotifier, AsyncValue<Statistics>>((ref) {
  return StatisticsNotifier();
});

class StatisticsNotifier extends StateNotifier<AsyncValue<Statistics>> {
  StatisticsNotifier() : super(const AsyncValue.loading()) {
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    try {
      state = const AsyncValue.loading();
      
      final stats = Statistics(
        totalCards: 0,
        dueToday: 0,
        learnedToday: 0,
        streak: 0,
      );
      
      state = AsyncValue.data(stats);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}