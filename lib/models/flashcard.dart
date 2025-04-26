abstract class Flashcard {
  final String id;
  final String word;
  final String targetLanguageCode;
  final String translation;
  final String nativeLanguageCode;
  final String? imageUrl;
  final String? cachedImagePath;
  final DateTime nextReviewDate;
  final int reviewLevel;
  final double interval;
  final double easeFactor;
  final String description;

  Flashcard({
    required this.id,
    required this.word,
    required this.targetLanguageCode,
    required this.translation,
    required this.nativeLanguageCode,
    this.imageUrl,
    this.cachedImagePath,
    required this.nextReviewDate,
    required this.reviewLevel,
    this.interval = 1.0,
    this.easeFactor = 1.0,
    this.description = '',
  });
}
