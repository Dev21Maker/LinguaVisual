import '../models/flashcard_item.dart';
import '../models/review_outcome.dart';

/// Implementation of a confidence-based spaced repetition algorithm.
///
/// This algorithm adjusts card intervals, ease factors, and scheduling based on
/// the user's confidence level when answering (wrong, hard, good, easy).
class ConfidenceBasedAlgorithm {
  /// The minimum allowed ease factor
  static const double minimumEaseFactor = 1.3;
  
  /// The default ease factor for new cards
  static const double defaultEaseFactor = 2.5;
  
  /// The maximum allowed ease factor
  static const double maximumEaseFactor = 3.0;
  
  /// The factor to reduce interval by for wrong answers
  static const double wrongIntervalFactor = 0.2;
  
  /// The factor to reduce interval by for hard answers
  static const double hardIntervalFactor = 0.8;
  
  /// The ease factor decrease for wrong answers
  static const double wrongEaseDecrease = 0.2;
  
  /// The ease factor decrease for hard answers
  static const double hardEaseDecrease = 0.05;
  
  /// The ease factor increase for good/easy answers
  static const double correctEaseIncrease = 0.05;
  
  /// Minutes to wait before reshowing a wrong answer
  static const int wrongRescheduleMinutes = 5;
  
  /// Minutes to wait before reshowing a hard answer
  static const int hardRescheduleMinutes = 20;

  /// Updates a flashcard's SRS parameters based on the review outcome and confidence level.
  ///
  /// This method implements the confidence-based algorithm logic:
  /// - For hard answers: Shrink interval heavily, decrease ease, schedule soon, repeat today
  /// - For good answers: Shrink interval slightly, decrease ease slightly, later today
  /// - For easy answers: Grow interval, increase ease, future days
  ///
  /// Returns the updated flashcard item.
  FlashcardItem processReview(
    FlashcardItem item, 
    ReviewOutcome outcome, 
    [ReviewType reviewType = ReviewType.typing]
  ) {
    // Increment the review count
    int newReviews = item.reviews + 1;
    
    // Calculate new parameters based on confidence level (outcome)
    int newInterval = item.interval;
    double newEaseFactor = item.personalDifficultyFactor; // Current ease factor (PDF)
    DateTime newNextReviewDate;
    bool shouldRepeatToday;
    
    switch (outcome) {
      case ReviewOutcome.hard:
        // Wrong answer - difficult card
        newInterval = (item.interval * wrongIntervalFactor).round();
        if (newInterval < 1) newInterval = 1; // Ensure minimum interval of 1 day
        
        // Decrease ease factor
        newEaseFactor = _adjustEaseFactor(item.personalDifficultyFactor, -wrongEaseDecrease);
        
        // Schedule for review very soon (e.g., 5 minutes)
        newNextReviewDate = DateTime.now().add(Duration(minutes: wrongRescheduleMinutes));
        
        // Card should repeat today
        shouldRepeatToday = true;
        break;
        
      case ReviewOutcome.good:
        // Hard answer - correct but with difficulty
        newInterval = (item.interval * hardIntervalFactor).round();
        if (newInterval < 1) newInterval = 1; // Ensure minimum interval of 1 day
        
        // Slightly decrease ease factor
        newEaseFactor = _adjustEaseFactor(item.personalDifficultyFactor, -hardEaseDecrease);
        
        // Schedule for review later today (e.g., 20 minutes)
        newNextReviewDate = DateTime.now().add(Duration(minutes: hardRescheduleMinutes));
        
        // Card should repeat today
        shouldRepeatToday = true;
        break;
        
      case ReviewOutcome.easy:
        // Good answer - correct with moderate effort
        // Grow interval based on ease factor
        newInterval = (item.interval * item.personalDifficultyFactor).round();
        if (newInterval < 1) newInterval = 1; // Ensure minimum interval of 1 day
        
        // Slightly increase ease factor
        newEaseFactor = _adjustEaseFactor(item.personalDifficultyFactor, correctEaseIncrease);
        
        // Schedule for review in the future based on new interval
        newNextReviewDate = DateTime.now().add(Duration(days: newInterval));
        
        // Card should not repeat today
        shouldRepeatToday = false;
        break;
    }
    
    // Apply review type modifier if needed
    double modifier = reviewType.intervalModifier;
    // Only apply modifier for future reviews (not for today's repeats)
    if (!shouldRepeatToday) {
      newNextReviewDate = DateTime.now().add(
        Duration(days: (newInterval * modifier).round())
      );
    }
    
    // Update last review type
    String newLastReviewType = reviewType.asString;
    
    // Update repeatedToday count if needed
    int newRepeatedToday = shouldRepeatToday ? item.repeatedToday + 1 : 0;
    
    // Mark as priority if it should repeat today
    bool newIsPriority = shouldRepeatToday;
    
    // Return updated flashcard
    return item.copyWith(
      interval: newInterval,
      personalDifficultyFactor: newEaseFactor,
      reviews: newReviews,
      nextReviewDate: newNextReviewDate,
      lastReviewType: newLastReviewType,
      repeatedToday: newRepeatedToday,
      isPriority: newIsPriority,
    );
  }
  
  /// Adjusts the ease factor by the given delta, ensuring it stays within bounds.
  double _adjustEaseFactor(double currentFactor, double delta) {
    double newFactor = currentFactor + delta;
    
    if (newFactor < minimumEaseFactor) {
      return minimumEaseFactor;
    }
    
    if (newFactor > maximumEaseFactor) {
      return maximumEaseFactor;
    }
    
    return newFactor;
  }
  
  /// Prioritizes flashcards for review based on multiple factors.
  List<FlashcardItem> prioritizeReviews(List<FlashcardItem> dueItems) {
    // Sort by multiple factors:
    // 1. Priority flag (true comes first) - used for cards that need to repeat today
    // 2. Due date (earlier comes first)
    // 3. Higher repeatedToday count (more repeats means it's struggling and needs attention)
    // 4. Lower ease factor (harder cards should be reviewed before easier ones)
    return List.from(dueItems)..sort((a, b) {
      // Priority flag comparison (true comes first)
      if (a.isPriority != b.isPriority) {
        return a.isPriority ? -1 : 1;
      }
      
      // Due date comparison (earlier comes first)
      int dateComparison = a.nextReviewDate.compareTo(b.nextReviewDate);
      if (dateComparison != 0) {
        return dateComparison;
      }
      
      // Repeated today comparison (more repeats comes first)
      if (a.repeatedToday != b.repeatedToday) {
        return b.repeatedToday.compareTo(a.repeatedToday);
      }
      
      // Ease factor comparison (lower ease factor comes first - harder cards)
      return a.personalDifficultyFactor.compareTo(b.personalDifficultyFactor);
    });
  }
}
