/// Represents the possible outcomes of a flashcard review based on confidence levels.
///
/// These outcomes correspond to a four-button feedback system (Wrong, Hard, Good, Easy)
/// and are used to determine how the card's interval and ease factor
/// should be adjusted.
enum ReviewOutcome {
  /// The user failed to recall the card correctly (Wrong).
  /// This will heavily decrease the interval and ease factor,
  /// and schedule the card to be reviewed again very soon.
  missed,

  /// The user recalled the card correctly but with significant effort (Hard).
  /// This will slightly decrease the interval and ease factor,
  /// and schedule the card to be reviewed again later today.
  hard,

  /// The user recalled the card correctly with moderate effort (Good).
  /// This will increase the interval according to the algorithm
  /// and slightly increase the ease factor.
  good,

  /// The user recalled the card very easily with minimal effort (Easy).
  /// This will increase the interval more than 'good' and
  /// increase the ease factor more significantly.
  easy,
}

/// Represents the type of review exercise used for a flashcard.
///
/// Different review types have different difficulty levels and receive
/// appropriate modifiers in the interval calculation.
enum ReviewType {
  /// Multiple choice review - considered easier than other types.
  /// Modifier: 0.9 (slightly shorter intervals)
  multipleChoice,

  /// Typing the full answer - considered more challenging and effective.
  /// Modifier: 1.1 (slightly longer intervals)
  typing,

  /// Listening comprehension - standard difficulty.
  /// Modifier: 1.0 (standard interval)
  listening,
}

/// Extension to provide utility methods for ReviewType
extension ReviewTypeExtension on ReviewType {
  /// Returns the interval modifier for this review type
  double get intervalModifier {
    switch (this) {
      case ReviewType.multipleChoice:
        return 0.9;
      case ReviewType.typing:
        return 1.1;
      case ReviewType.listening:
        return 1.0;
    }
  }
  
  /// Returns a string representation of this review type
  String get asString {
    switch (this) {
      case ReviewType.multipleChoice:
        return 'multiple_choice';
      case ReviewType.typing:
        return 'typing';
      case ReviewType.listening:
        return 'listening';
    }
  }
  
  /// Creates a ReviewType from a string
  static ReviewType fromString(String? value) {
    switch (value) {
      case 'multiple_choice':
        return ReviewType.multipleChoice;
      case 'typing':
        return ReviewType.typing;
      case 'listening':
        return ReviewType.listening;
      default:
        return ReviewType.typing; // Default to typing if unknown
    }
  }
}
