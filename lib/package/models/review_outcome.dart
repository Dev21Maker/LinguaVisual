/// Represents the possible outcomes of a flashcard review in the AdaptiveFlow SRS system.
///
/// These outcomes correspond to the simplified three-button feedback system
/// and are used to determine how the card's interval and personal difficulty factor
/// should be adjusted.
enum ReviewOutcome {
  /// The user failed to recall the card and needs to review it again soon.
  /// This will decrease the interval and increase the personal difficulty factor.
  missed,

  /// The user recalled the card correctly but with some effort.
  /// This will increase the interval according to the algorithm while
  /// keeping the personal difficulty factor unchanged.
  gotIt,

  /// The user recalled the card easily and quickly with minimal effort.
  /// This will increase the interval more than 'gotIt' and
  /// decrease the personal difficulty factor.
  quick,
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
