abstract class Flashcard {
  final String id;
  final String word;
  final String targetLanguageCode;
  final String translation;
  final String nativeLanguageCode;
  final String? imageUrl;
  final String? cachedImagePath;
  final int srsNextReviewDate; 
  final double srsInterval; 
  final double srsEaseFactor; 
  final String description;

  final int? srsLastReviewDate; 
  final int srsBaseIntervalIndex;
  final int srsQuickStreak;
  final bool srsIsPriority;
  final bool srsIsInLearningPhase;

  Flashcard({
    required this.id,
    required this.word,
    required this.targetLanguageCode,
    required this.translation,
    required this.nativeLanguageCode,
    this.imageUrl,
    this.cachedImagePath,
    required this.srsNextReviewDate, 
    this.srsInterval = 0.0, 
    this.srsEaseFactor = 1.0, 
    this.description = '',
    this.srsLastReviewDate,
    this.srsBaseIntervalIndex = 0,
    this.srsQuickStreak = 0,
    this.srsIsPriority = false,
    this.srsIsInLearningPhase = true,
  });
}
