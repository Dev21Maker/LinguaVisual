class Flashcard {
  final String id;
  final String word;
  final String targetLanguageCode;
  final String translation;
  final String nativeLanguageCode;
  final String? imageUrl;
  final String? cachedImagePath;
  final double srsInterval;
  final double srsEaseFactor;
  final int srsNextReviewDate;
  final int? srsLastReviewDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Flashcard({
    required this.id,
    required this.word,
    required this.targetLanguageCode,
    required this.translation,
    required this.nativeLanguageCode,
    this.imageUrl,
    this.cachedImagePath,
    this.srsInterval = 1.0,
    this.srsEaseFactor = 2.5,
    required this.srsNextReviewDate,
    this.srsLastReviewDate,
    this.createdAt,
    this.updatedAt,
  });

  Flashcard copyWith({
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
    return Flashcard(
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final now = DateTime.now().toUtc();
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
      'created_at': createdAt?.toIso8601String() ?? now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    // Helper function to handle various timestamp formats
    int parseTimestamp(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        try {
          return DateTime.parse(value).millisecondsSinceEpoch;
        } catch (e) {
          return int.tryParse(value) ?? 0;
        }
      }
      return 0;
    }

    // Helper function to parse DateTime from ISO8601 string
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value).toUtc();
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // Helper function to handle numeric values that might come as strings
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Flashcard(
      id: (map['id'] ?? '').toString(),
      word: map['word'] as String? ?? '',
      targetLanguageCode: map['target_language_code'] as String? ?? '',
      translation: map['translation'] as String? ?? '',
      nativeLanguageCode: map['native_language_code'] as String? ?? '',
      imageUrl: map['image_url'] as String?,
      cachedImagePath: map['cached_image_path'] as String?,
      srsInterval: parseDouble(map['srs_interval']),
      srsEaseFactor: parseDouble(map['srs_ease_factor']),
      srsNextReviewDate: parseTimestamp(map['srs_next_review_date']),
      srsLastReviewDate: parseTimestamp(map['srs_last_review_date']),
      createdAt: parseDateTime(map['created_at']),
      updatedAt: parseDateTime(map['updated_at']),
    );
  }

  @override
  String toString() {
    return 'Flashcard(id: $id, word: $word, targetLanguageCode: $targetLanguageCode, '
        'translation: $translation, nativeLanguageCode: $nativeLanguageCode, '
        'imageUrl: $imageUrl, cachedImagePath: $cachedImagePath, '
        'srsInterval: $srsInterval, srsEaseFactor: $srsEaseFactor, '
        'srsNextReviewDate: $srsNextReviewDate, srsLastReviewDate: $srsLastReviewDate)';
  }
}
