import 'package:lingua_visual/models/flashcard.dart';

class OfflineFlashcard extends Flashcard {
  final double srsInterval;
  final double srsEaseFactor;
  final int srsNextReviewDate;
  final int? srsLastReviewDate;

  OfflineFlashcard({
    required super.id,
    required super.word,
    required super.targetLanguageCode,
    required super.translation,
    required super.nativeLanguageCode,
    super.imageUrl,
    super.cachedImagePath,
    this.srsInterval = 1.0,
    this.srsEaseFactor = 2.5,
    required this.srsNextReviewDate,
    this.srsLastReviewDate,
  }) : super(
          nextReviewDate: DateTime.fromMillisecondsSinceEpoch(srsNextReviewDate),
          reviewLevel: 0,
        );

  factory OfflineFlashcard.fromMap(Map<String, dynamic> map) {
    return OfflineFlashcard(
      id: map['id'] as String? ?? '',
      word: map['word'] as String? ?? '',
      targetLanguageCode: map['target_language_code'] as String? ?? '',
      translation: map['translation'] as String? ?? '',
      nativeLanguageCode: map['native_language_code'] as String? ?? '',
      imageUrl: map['image_url'] as String?,
      cachedImagePath: map['cached_image_path'] as String?,
      srsInterval: (map['srs_interval'] as num?)?.toDouble() ?? 1.0,
      srsEaseFactor: (map['srs_ease_factor'] as num?)?.toDouble() ?? 2.5,
      srsNextReviewDate: map['srs_next_review_date'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      srsLastReviewDate: map['srs_last_review_date'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'target_language_code': targetLanguageCode,
      'translation': translation,
      'native_language_code': nativeLanguageCode,
      'image_url': imageUrl,
      'cached_image_path': cachedImagePath,
      'srs_interval': srsInterval,
      'srs_ease_factor': srsEaseFactor,
      'srs_next_review_date': srsNextReviewDate,
      'srs_last_review_date': srsLastReviewDate,
    };
  }

  OfflineFlashcard copyWith({
    String? id,
    String? word,
    String? targetLanguageCode,
    String? translation,
    String? nativeLanguageCode,
    String? imageUrl,
    String? cachedImagePath,
    double? srsInterval,
    double? srsEaseFactor,
    int? srsNextReviewDate,
    int? srsLastReviewDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OfflineFlashcard(
      id: id ?? this.id,
      word: word ?? this.word,
      targetLanguageCode: targetLanguageCode ?? this.targetLanguageCode,
      translation: translation ?? this.translation,
      nativeLanguageCode: nativeLanguageCode ?? this.nativeLanguageCode,
      imageUrl: imageUrl ?? this.imageUrl,
      cachedImagePath: cachedImagePath ?? this.cachedImagePath,
      srsInterval: srsInterval ?? this.srsInterval,
      srsEaseFactor: srsEaseFactor ?? this.srsEaseFactor,
      srsNextReviewDate: srsNextReviewDate ?? this.srsNextReviewDate,
      srsLastReviewDate: srsLastReviewDate ?? this.srsLastReviewDate,
    );
  }
}
