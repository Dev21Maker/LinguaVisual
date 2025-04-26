import 'package:uuid/uuid.dart';

/// Represents a flashcard item in the AdaptiveFlow spaced repetition system.
///
/// This model contains all the necessary information for a flashcard,
/// including content and SRS-specific fields for scheduling reviews.
class FlashcardItem {
  /// Unique identifier for the flashcard.
  final String id;

  /// Language identifier (e.g., 'en', 'es', 'fr').
  final String languageId;

  /// The question or front side of the flashcard.
  final String question;

  /// The answer or back side of the flashcard.
  final String answer;

  /// The interval in days until the next review.
  int interval;

  /// The Personal Difficulty Factor (PDF) reflecting the perceived difficulty of the card.
  /// Lower values mean the card is easier, higher values mean it's harder.
  /// Range: 0.5 (very easy) to 2.0 (very difficult)
  double personalDifficultyFactor;

  /// The number of times this card has been reviewed.
  int reviews;

  /// The date when this card is due for review.
  DateTime nextReviewDate;

  /// The number of consecutive "Quick" responses for this card.
  /// Used for streak bonuses in the AdaptiveFlow algorithm.
  int quickStreak;

  /// The last review type used for this card.
  /// Possible values: 'typing', 'multiple_choice', 'listening'
  String? lastReviewType;

  /// Flag indicating if this card is in the initial learning phase.
  /// Cards in learning phase follow a different review schedule.
  bool isInLearningPhase;

  /// The number of successful reviews in the learning phase.
  /// A card graduates from learning phase after completing all required reviews.
  int learningPhaseProgress;

  /// Flag indicating if this card should be prioritized in the next review session.
  /// Set to true when a card is missed and needs additional reinforcement.
  bool isPriority;

  /// Creates a new flashcard item.
  ///
  /// If [id] is not provided, a UUID will be generated.
  /// Initial SRS values are set to defaults for new cards.
  FlashcardItem({
    String? id,
    required this.languageId,
    required this.question,
    required this.answer,
    this.interval = 0,
    this.personalDifficultyFactor = 1.0,
    this.reviews = 0,
    DateTime? nextReviewDate,
    this.quickStreak = 0,
    this.lastReviewType,
    this.isInLearningPhase = true,
    this.learningPhaseProgress = 0,
    this.isPriority = false,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.nextReviewDate = nextReviewDate ?? DateTime.now();

  /// Creates a copy of this flashcard item with the given fields replaced with new values.
  FlashcardItem copyWith({
    String? id,
    String? languageId,
    String? question,
    String? answer,
    int? interval,
    double? personalDifficultyFactor,
    int? reviews,
    DateTime? nextReviewDate,
    int? quickStreak,
    String? lastReviewType,
    bool? isInLearningPhase,
    int? learningPhaseProgress,
    bool? isPriority,
  }) {
    return FlashcardItem(
      id: id ?? this.id,
      languageId: languageId ?? this.languageId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      interval: interval ?? this.interval,
      personalDifficultyFactor: personalDifficultyFactor ?? this.personalDifficultyFactor,
      reviews: reviews ?? this.reviews,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      quickStreak: quickStreak ?? this.quickStreak,
      lastReviewType: lastReviewType ?? this.lastReviewType,
      isInLearningPhase: isInLearningPhase ?? this.isInLearningPhase,
      learningPhaseProgress: learningPhaseProgress ?? this.learningPhaseProgress,
      isPriority: isPriority ?? this.isPriority,
    );
  }

  /// Converts this flashcard item to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'languageId': languageId,
      'question': question,
      'answer': answer,
      'interval': interval,
      'personalDifficultyFactor': personalDifficultyFactor,
      'reviews': reviews,
      'nextReviewDate': nextReviewDate.toIso8601String(),
      'quickStreak': quickStreak,
      'lastReviewType': lastReviewType,
      'isInLearningPhase': isInLearningPhase,
      'learningPhaseProgress': learningPhaseProgress,
      'isPriority': isPriority,
    };
  }

  /// Creates a flashcard item from a JSON map.
  factory FlashcardItem.fromJson(Map<String, dynamic> json) {
    return FlashcardItem(
      id: json['id'],
      languageId: json['languageId'],
      question: json['question'],
      answer: json['answer'],
      interval: json['interval'],
      personalDifficultyFactor: json['personalDifficultyFactor'],
      reviews: json['reviews'],
      nextReviewDate: DateTime.parse(json['nextReviewDate']),
      quickStreak: json['quickStreak'] ?? 0,
      lastReviewType: json['lastReviewType'],
      isInLearningPhase: json['isInLearningPhase'] ?? true,
      learningPhaseProgress: json['learningPhaseProgress'] ?? 0,
      isPriority: json['isPriority'] ?? false,
    );
  }
}
