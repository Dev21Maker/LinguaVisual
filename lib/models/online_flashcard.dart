import 'package:Languador/models/flashcard.dart';

import 'language.dart';

class OnlineFlashcard extends Flashcard {
  final Language targetLanguage;
  final Language nativeLanguage;
  final double srsInterval;
  final double srsEaseFactor;
  final int srsNextReviewDate;
  final int? srsLastReviewDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> stackIds;
  // New AdaptiveFlow fields
  final int srsBaseIntervalIndex;
  final int srsQuickStreak;
  final bool srsIsPriority;
  final bool srsIsInLearningPhase;
  final int? srsBoxValue;

  OnlineFlashcard({
    required String id,
    required String word,
    required this.targetLanguage,
    required String translation,
    required this.nativeLanguage,
    String? imageUrl,
    String? cachedImagePath,
    this.srsInterval = 1.0,
    this.srsEaseFactor = 2.5,
    required this.srsNextReviewDate,
    this.srsLastReviewDate,
    this.createdAt,
    this.updatedAt,
    this.stackIds = const [],
    // Add new fields to constructor with defaults
    this.srsBaseIntervalIndex = 0,
    this.srsQuickStreak = 0,
    this.srsIsPriority = false,
    this.srsIsInLearningPhase = true,
    this.srsBoxValue,
    String? description,
    String? hint,
  }) : super(
          id: id,
          word: word,
          targetLanguageCode: targetLanguage.code,
          translation: translation,
          nativeLanguageCode: nativeLanguage.code,
          imageUrl: imageUrl,
          cachedImagePath: cachedImagePath,
          // Pass fields directly to super
          srsInterval: srsInterval,
          srsEaseFactor: srsEaseFactor,
          srsNextReviewDate: srsNextReviewDate,
          description: description, 
          hint: hint,
          srsLastReviewDate: srsLastReviewDate,
          srsBaseIntervalIndex: srsBaseIntervalIndex,
          srsQuickStreak: srsQuickStreak,
          srsIsPriority: srsIsPriority,
          srsIsInLearningPhase: srsIsInLearningPhase,
          srsBoxValue: srsBoxValue,
        );

  OnlineFlashcard copyWith({
    String? id,
    String? word,
    Language? targetLanguage,
    String? translation,
    Language? nativeLanguage,
    String? imageUrl,
    String? cachedImagePath,
    double? srsInterval,
    double? srsEaseFactor,
    int? srsNextReviewDate,
    int? srsLastReviewDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? stackIds,
    String? description,
    String? hint,
    // Add new fields to copyWith
    int? srsBaseIntervalIndex,
    int? srsQuickStreak,
    bool? srsIsPriority,
    bool? srsIsInLearningPhase,
    int? srsBoxValue,
  }) {
    return OnlineFlashcard(
      id: id ?? this.id,
      word: word ?? this.word,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      translation: translation ?? this.translation,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      imageUrl: imageUrl ?? this.imageUrl,
      cachedImagePath: cachedImagePath ?? this.cachedImagePath,
      srsInterval: srsInterval ?? this.srsInterval,
      srsEaseFactor: srsEaseFactor ?? this.srsEaseFactor,
      srsNextReviewDate: srsNextReviewDate ?? this.srsNextReviewDate,
      srsLastReviewDate: srsLastReviewDate ?? this.srsLastReviewDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stackIds: stackIds ?? this.stackIds,
      description: description ?? this.description,
      hint: hint ?? this.hint,
      // Use new fields in copyWith
      srsBaseIntervalIndex: srsBaseIntervalIndex ?? this.srsBaseIntervalIndex,
      srsQuickStreak: srsQuickStreak ?? this.srsQuickStreak,
      srsIsPriority: srsIsPriority ?? this.srsIsPriority,
      srsIsInLearningPhase: srsIsInLearningPhase ?? this.srsIsInLearningPhase,
      srsBoxValue: srsBoxValue ?? this.srsBoxValue,
    );
  }

  Map<String, dynamic> toMap() {
    final now = DateTime.now().toUtc();
    return {
      'id': id,
      'word': word,
      'target_language': targetLanguage.toMap(),
      'translation': translation,
      'native_language': nativeLanguage.toMap(),
      'image_url': imageUrl,
      'cached_image_path': cachedImagePath,
      'srs_interval': srsInterval,
      'srs_ease_factor': srsEaseFactor,
      'srs_next_review_date': srsNextReviewDate,
      'srs_last_review_date': srsLastReviewDate,
      'created_at': createdAt?.toIso8601String() ?? now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'stack_ids': stackIds,
      'description': description, 
      'hint': hint,
      // Add new fields to map
      'srs_base_interval_index': srsBaseIntervalIndex,
      'srs_quick_streak': srsQuickStreak,
      'srs_is_priority': srsIsPriority ? 1 : 0, // Store bool as int
      'srs_is_in_learning_phase': srsIsInLearningPhase ? 1 : 0, // Store bool as int
      'srs_box_value': srsBoxValue, // Add box value to map
    };
  }

  factory OnlineFlashcard.fromMap(Map<String, dynamic> map) {
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

    // Helper function to handle integer values that might come as strings or doubles
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Parse nested Language objects or fallback to codes
    final targetLangMap = map['target_language'] as Map<String, dynamic>?;
    final nativeLangMap = map['native_language'] as Map<String, dynamic>?;
    final targetLang = targetLangMap != null
        ? Language.fromMap(targetLangMap)
        : Language.fromCode(map['target_language_code'] as String? ?? '');
    final nativeLang = nativeLangMap != null
        ? Language.fromMap(nativeLangMap)
        : Language.fromCode(map['native_language_code'] as String? ?? '');

    return OnlineFlashcard(
      id: (map['id'] ?? '').toString(),
      word: map['word'] as String? ?? '',
      targetLanguage: targetLang,
      translation: map['translation'] as String? ?? '',
      nativeLanguage: nativeLang,
      imageUrl: map['image_url'] as String?,
      cachedImagePath: map['cached_image_path'] as String?,
      srsInterval: parseDouble(map['srs_interval']),
      srsEaseFactor: parseDouble(map['srs_ease_factor']),
      srsNextReviewDate: parseTimestamp(map['srs_next_review_date']),
      srsLastReviewDate: parseTimestamp(map['srs_last_review_date']),
      createdAt: parseDateTime(map['created_at']),
      updatedAt: parseDateTime(map['updated_at']),
      stackIds: List<String>.from(map['stack_ids'] ?? []),
      description: map['description'] as String? ?? '', 
      hint: map['hint'] as String?,
      // Read new fields from map with defaults, using parseInt for ints
      srsBaseIntervalIndex: parseInt(map['srs_base_interval_index']), 
      srsQuickStreak: parseInt(map['srs_quick_streak']), 
      srsIsPriority: (map['srs_is_priority'] == true || map['srs_is_priority'] == 1), // Handle bool or int
      srsIsInLearningPhase: (map['srs_is_in_learning_phase'] == true || map['srs_is_in_learning_phase'] == 1), // Handle bool or int
      srsBoxValue: parseInt(map['srs_box_value']), // Extract box value from map
    );
  }

  @override
  String toString() {
    return 'Flashcard(id: $id, word: $word, targetLanguage: ${targetLanguage.code}, '
        'translation: $translation, nativeLanguage: ${nativeLanguage.code}, '
        'imageUrl: $imageUrl, cachedImagePath: $cachedImagePath, '
        'srsInterval: $srsInterval, srsEaseFactor: $srsEaseFactor, '
        'srsNextReviewDate: $srsNextReviewDate, srsLastReviewDate: $srsLastReviewDate)';
  }
}
