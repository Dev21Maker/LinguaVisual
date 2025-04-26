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
  /// - For 'missed': Reset interval and increase personal difficulty factor
  /// - For 'gotIt': Increase interval according to the algorithm and keep PDF unchanged
  /// - For 'quick': Increase interval more than 'gotIt' and decrease personal difficulty factor
  ///
  /// Returns the updated flashcard item.
  FlashcardItem processReview(FlashcardItem item, ReviewOutcome outcome, [ReviewType reviewType = ReviewType.typing]) {
    // Increment the review count
    int newReviews = item.reviews + 1;
    
    // Calculate new interval and personal difficulty factor based on the outcome
    int newInterval;
    double newPdf;
    
    switch (outcome) {
      case ReviewOutcome.missed:
        // Reset interval and increase personal difficulty factor
        newInterval = 1;
        newPdf = _adjustPdf(item.personalDifficultyFactor, 0.20);
        break;
        
      case ReviewOutcome.gotIt:
        // Standard interval progression
        if (item.reviews == 0) {
          newInterval = initialInterval;
        } else if (item.reviews == 1) {
          newInterval = 6; // Second review as "gotIt" jumps to 6 days
        } else {
          newInterval = (item.interval * item.personalDifficultyFactor).round();
        }
        newPdf = item.personalDifficultyFactor; // Keep PDF unchanged
        break;
        
      case ReviewOutcome.quick:
        // Larger interval increase and PDF decrease
        if (item.reviews == 0) {
          newInterval = 4; // First review as "quick" jumps to 4 days
        } else if (item.reviews == 1) {
          newInterval = 8; // Second review as "quick" jumps to 8 days
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
    String newLastReviewType = reviewType?.asString ?? 'typing';
    
    // Return updated flashcard
    return item.copyWith(
      interval: newInterval,
      personalDifficultyFactor: newPdf,
      reviews: newReviews,
      nextReviewDate: newNextReviewDate,
      lastReviewType: newLastReviewType,
      isPriority: outcome == ReviewOutcome.missed,
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
