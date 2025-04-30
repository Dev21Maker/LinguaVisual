import '../models/flashcard_item.dart';
import '../models/review_outcome.dart';

/// Implementation of the SM-2 spaced repetition algorithm adapted for compatibility
/// with the AdaptiveFlow SRS system.
///
/// This class provides methods to calculate intervals and adjust personal difficulty factors
/// based on review outcomes, following an adaptation of the SuperMemo SM-2 algorithm.
class SM2Algorithm {
  /// The initial interval (in days) for a new card reviewed as "Got It".
  static const int initialInterval = 1;
  
  /// The default personal difficulty factor for new cards.
  static const double defaultPersonalDifficultyFactor = 1.0;
  
  /// The minimum allowed personal difficulty factor.
  static const double minimumPersonalDifficultyFactor = 0.5;

  /// Updates a flashcard's SRS parameters based on the review outcome.
  ///
  /// This method implements a modified SM-2 algorithm logic adapted for AdaptiveFlow:
  /// - For 'hard': Reset interval and increase personal difficulty factor
  /// - For 'good': Small interval progression with slight PDF increase
  /// - For 'easy': Increase interval more than 'good' and decrease personal difficulty factor
  ///
  /// Returns the updated flashcard item.
  FlashcardItem processReview(FlashcardItem item, ReviewOutcome outcome, [ReviewType reviewType = ReviewType.typing]) {
    // Increment the review count
    int newReviews = item.reviews + 1;
    
    // Calculate new interval and personal difficulty factor based on the outcome
    int newInterval = item.interval;
    double newPdf = item.personalDifficultyFactor;
    
    switch (outcome) {
      case ReviewOutcome.hard:
        // Reset interval and increase personal difficulty factor
        newInterval = 1;
        newPdf = _adjustPdf(item.personalDifficultyFactor, 0.20);
        break;
        
      case ReviewOutcome.good:
        // Small interval progression with slight PDF increase
        if (item.reviews == 0) {
          newInterval = initialInterval;
        } else if (item.reviews == 1) {
          newInterval = 4; // Second review as "hard" should be a bit shorter than "good"
        } else {
          newInterval = (item.interval * 0.8).round(); // Reduce interval by 20%
        }
        newPdf = _adjustPdf(item.personalDifficultyFactor, 0.05); // Small increase for hard
        break;
        
      case ReviewOutcome.easy:
        // Larger interval increase and PDF decrease
        if (item.reviews == 0) {
          newInterval = 4; // First review as "easy" jumps to 4 days
        } else if (item.reviews == 1) {
          newInterval = 8; // Second review as "easy" jumps to 8 days
        } else {
          newInterval = (item.interval * item.personalDifficultyFactor * 1.3).round();
        }
        newPdf = _adjustPdf(item.personalDifficultyFactor, -0.15);
        break;
    }
    
    // Apply review type modifier if provided
    if (reviewType != null) {
      newInterval = (newInterval * reviewType.intervalModifier).round();
    }
    
    // Calculate the next review date
    final DateTime newNextReviewDate = DateTime.now().add(Duration(days: newInterval));
    
    // Update last review type
    String newLastReviewType = reviewType.asString;
    
    // Return updated flashcard
    return item.copyWith(
      interval: newInterval,
      personalDifficultyFactor: newPdf,
      reviews: newReviews,
      nextReviewDate: newNextReviewDate,
      lastReviewType: newLastReviewType,
      isPriority: outcome == ReviewOutcome.hard,
    );
  }
  
  /// Adjusts the personal difficulty factor by the given delta, ensuring it stays within bounds.
  double _adjustPdf(double currentPdf, double delta) {
    double newPdf = currentPdf + delta;
    
    if (newPdf < minimumPersonalDifficultyFactor) {
      return minimumPersonalDifficultyFactor;
    }
    
    if (newPdf > 2.0) {
      return 2.0;
    }
    
    return newPdf;
  }
}
