import '../models/flashcard_item.dart';
import '../models/review_outcome.dart';

/// Implementation of the AdaptiveFlow spaced repetition algorithm.
///
/// This class provides methods to calculate intervals and adjust personal difficulty factors
/// based on review outcomes, following the AdaptiveFlow SRS algorithm designed for
/// optimal language learning with personalized adaptivity.
class AdaptiveFlowAlgorithm {
  /// Base intervals (in days) for the review schedule
  static const List<int> baseIntervals = [
    0, // Initial state (0)
    0, // Learning phase (1) - same day, hours later
    1, // 1 day (2)
    3, // 3 days (3)
    7, // 7 days (4)
    14, // 14 days (5)
    30, // 30 days (6)
    60, // 60 days (7)
    120, // 120 days (8) - maximum interval
  ];
  
  /// The number of successful reviews required to graduate from learning phase
  static const int learningPhaseRequiredReviews = 3;
  
  /// The default personal difficulty factor for new cards
  static const double defaultPersonalDifficultyFactor = 1.0;
  
  /// The minimum allowed personal difficulty factor
  static const double minimumPersonalDifficultyFactor = 0.5;
  
  /// The maximum allowed personal difficulty factor
  static const double maximumPersonalDifficultyFactor = 2.0;
  
  /// The amount to decrease PDF for a "Quick" response
  static const double quickResponsePdfDecrease = 0.15;
  
  /// The amount to increase PDF for a "Missed" response
  static const double missedResponsePdfIncrease = 0.2;
  
  /// The streak bonus percentage for on-time reviews
  static const double onTimeReviewBonus = 0.05;
  
  /// The streak bonus percentage for consecutive quick responses
  static const double quickStreakBonus = 0.1;
  
  /// The minimum number of consecutive quick responses to trigger a streak bonus
  static const int quickStreakThreshold = 3;
  
  /// The number of steps to go back in the interval sequence when an item is missed
  static const int missedStepBack = 2;

  /// Updates a flashcard's SRS parameters based on the review outcome and type.
  ///
  /// This method implements the core AdaptiveFlow algorithm logic:
  /// - For learning phase cards: progress through initial learning
  /// - For review phase cards: adjust interval and PDF based on performance
  ///
  /// Returns the updated flashcard item.
  FlashcardItem processReview(
    FlashcardItem item, 
    ReviewOutcome outcome, 
    ReviewType reviewType
  ) {
    // Increment the review count
    int newReviews = item.reviews + 1;
    
    // Handle learning phase differently
    if (item.isInLearningPhase) {
      return _processLearningPhaseReview(item, outcome, reviewType, newReviews);
    }
    
    // For graduated cards, process according to the main algorithm
    return _processGraduatedReview(item, outcome, reviewType, newReviews);
  }
  
  /// Processes a review for a card in the learning phase
  FlashcardItem _processLearningPhaseReview(
    FlashcardItem item, 
    ReviewOutcome outcome, 
    ReviewType reviewType,
    int newReviews
  ) {
    // Update the last review type
    String newLastReviewType = reviewType.asString;
    
    // For missed responses in learning phase
    if (outcome == ReviewOutcome.missed) {
      // Reset learning progress (but not completely to 0 to avoid frustration)
      int newLearningProgress = item.learningPhaseProgress > 0 
          ? item.learningPhaseProgress - 1 
          : 0;
      
      // Schedule for review in 30 minutes
      final DateTime newNextReviewDate = DateTime.now().add(Duration(minutes: 30));
      
      return item.copyWith(
        reviews: newReviews,
        learningPhaseProgress: newLearningProgress,
        nextReviewDate: newNextReviewDate,
        lastReviewType: newLastReviewType,
        isPriority: true, // Mark as priority to ensure it appears early in next session
      );
    }
    
    // For successful responses (gotIt or quick)
    int newLearningProgress = item.learningPhaseProgress + 1;
    
    // Check if the card has graduated from learning phase
    bool hasGraduated = newLearningProgress >= learningPhaseRequiredReviews;
    
    // If graduated, move to review phase with initial interval
    if (hasGraduated) {
      // Set initial interval based on performance
      int initialIntervalIndex = outcome == ReviewOutcome.quick ? 3 : 2; // 3 days for quick, 1 day for gotIt
      int newInterval = baseIntervals[initialIntervalIndex];
      
      // Set initial PDF based on performance
      double newPdf = outcome == ReviewOutcome.quick 
          ? defaultPersonalDifficultyFactor - quickResponsePdfDecrease 
          : defaultPersonalDifficultyFactor;
      
      // Calculate next review date
      final DateTime newNextReviewDate = DateTime.now().add(Duration(days: newInterval));
      
      // Update quick streak if applicable
      int newQuickStreak = outcome == ReviewOutcome.quick ? 1 : 0;
      
      return item.copyWith(
        interval: newInterval,
        personalDifficultyFactor: newPdf,
        reviews: newReviews,
        nextReviewDate: newNextReviewDate,
        isInLearningPhase: false, // Graduate from learning phase
        learningPhaseProgress: newLearningProgress,
        quickStreak: newQuickStreak,
        lastReviewType: newLastReviewType,
        isPriority: false,
      );
    }
    
    // Still in learning phase, schedule next review based on progress
    Duration nextReviewDelay;
    if (newLearningProgress == 1) {
      nextReviewDelay = Duration(hours: 1); // First successful review -> 1 hour
    } else {
      nextReviewDelay = Duration(hours: 5); // Second successful review -> 5 hours
    }
    
    final DateTime newNextReviewDate = DateTime.now().add(nextReviewDelay);
    
    return item.copyWith(
      reviews: newReviews,
      learningPhaseProgress: newLearningProgress,
      nextReviewDate: newNextReviewDate,
      lastReviewType: newLastReviewType,
      isPriority: false,
    );
  }
  
  /// Processes a review for a graduated card (in review phase)
  FlashcardItem _processGraduatedReview(
    FlashcardItem item, 
    ReviewOutcome outcome, 
    ReviewType reviewType,
    int newReviews
  ) {
    // Calculate new interval, PDF, and other parameters based on the outcome
    int newInterval;
    double newPdf;
    int newQuickStreak;
    bool newIsPriority;
    
    // Get the current interval index in the sequence
    int currentIntervalIndex = _getIntervalIndex(item.interval);
    
    switch (outcome) {
      case ReviewOutcome.missed:
        // Go back in the interval sequence
        int newIntervalIndex = currentIntervalIndex > missedStepBack 
            ? currentIntervalIndex - missedStepBack 
            : 2; // Minimum of 1 day (index 2)
        
        newInterval = baseIntervals[newIntervalIndex];
        
        // Increase PDF (make card harder)
        newPdf = _adjustPdf(item.personalDifficultyFactor, missedResponsePdfIncrease);
        
        // Reset quick streak
        newQuickStreak = 0;
        
        // Mark as priority
        newIsPriority = true;
        break;
        
      case ReviewOutcome.gotIt:
        // Move to next interval in sequence
        int newIntervalIndex = currentIntervalIndex < baseIntervals.length - 1 
            ? currentIntervalIndex + 1 
            : baseIntervals.length - 1;
        
        newInterval = baseIntervals[newIntervalIndex];
        
        // Keep PDF the same
        newPdf = item.personalDifficultyFactor;
        
        // Reset quick streak
        newQuickStreak = 0;
        
        // Not a priority
        newIsPriority = false;
        break;
        
      case ReviewOutcome.quick:
        // Move to next interval in sequence
        int newIntervalIndex = currentIntervalIndex < baseIntervals.length - 1 
            ? currentIntervalIndex + 1 
            : baseIntervals.length - 1;
        
        newInterval = baseIntervals[newIntervalIndex];
        
        // Decrease PDF (make card easier)
        newPdf = _adjustPdf(item.personalDifficultyFactor, -quickResponsePdfDecrease);
        
        // Increment quick streak
        newQuickStreak = item.quickStreak + 1;
        
        // Not a priority
        newIsPriority = false;
        break;
    }
    
    // Apply review type modifier
    double typeModifier = reviewType.intervalModifier;
    newInterval = (newInterval * typeModifier).round();
    
    // Apply streak bonuses
    double bonusMultiplier = 1.0;
    
    // On-time review bonus
    DateTime now = DateTime.now();
    bool isOnTime = !item.nextReviewDate.isAfter(now.add(Duration(days: 1)));
    if (isOnTime) {
      bonusMultiplier += onTimeReviewBonus;
    }
    
    // Quick streak bonus
    if (outcome == ReviewOutcome.quick && newQuickStreak >= quickStreakThreshold) {
      bonusMultiplier += quickStreakBonus;
    }
    
    // Apply bonus to interval
    newInterval = (newInterval * bonusMultiplier).round();
    
    // Apply personal difficulty factor
    newInterval = (newInterval * newPdf).round();
    
    // Ensure interval is at least 1 day
    newInterval = newInterval < 1 ? 1 : newInterval;
    
    // Calculate next review date
    final DateTime newNextReviewDate = DateTime.now().add(Duration(days: newInterval));
    
    // Update the last review type
    String newLastReviewType = reviewType.asString;
    
    return item.copyWith(
      interval: newInterval,
      personalDifficultyFactor: newPdf,
      reviews: newReviews,
      nextReviewDate: newNextReviewDate,
      quickStreak: newQuickStreak,
      lastReviewType: newLastReviewType,
      isPriority: newIsPriority,
    );
  }
  
  /// Adjusts the personal difficulty factor by the given delta, ensuring it stays within bounds
  double _adjustPdf(double currentPdf, double delta) {
    double newPdf = currentPdf + delta;
    
    if (newPdf < minimumPersonalDifficultyFactor) {
      return minimumPersonalDifficultyFactor;
    }
    
    if (newPdf > maximumPersonalDifficultyFactor) {
      return maximumPersonalDifficultyFactor;
    }
    
    return newPdf;
  }
  
  /// Gets the index of the given interval in the baseIntervals array
  int _getIntervalIndex(int interval) {
    // Find the closest match in the baseIntervals array
    for (int i = 0; i < baseIntervals.length; i++) {
      if (interval <= baseIntervals[i]) {
        return i;
      }
    }
    
    // If larger than any interval, return the last index
    return baseIntervals.length - 1;
  }
  
  /// Determines the optimal review type for a flashcard based on its difficulty
  ReviewType getOptimalReviewType(FlashcardItem item) {
    // Higher PDF (harder cards) should use typing more often
    if (item.personalDifficultyFactor > 1.5) {
      return ReviewType.typing;
    }
    
    // Medium difficulty cards should use a mix, with listening being common
    if (item.personalDifficultyFactor > 0.8) {
      // Avoid using the same review type twice in a row if possible
      if (item.lastReviewType == ReviewType.listening.asString) {
        return ReviewType.typing;
      }
      return ReviewType.listening;
    }
    
    // Easier cards can use multiple choice more often
    // Avoid using the same review type twice in a row if possible
    if (item.lastReviewType == ReviewType.multipleChoice.asString) {
      return ReviewType.listening;
    }
    return ReviewType.multipleChoice;
  }
  
  /// Suggests an optimal daily review session length based on due items
  int suggestSessionLength(List<FlashcardItem> dueItems) {
    // Base suggestion on number of due items with some constraints
    int baseLength = dueItems.length;
    
    // Count priority items (they need more attention)
    int priorityItems = dueItems.where((item) => item.isPriority).length;
    
    // Add extra time for priority items
    int suggestedLength = baseLength + priorityItems;
    
    // Cap at reasonable limits
    if (suggestedLength < 5) return 5; // Minimum session length
    if (suggestedLength > 30) return 30; // Maximum session length
    
    return suggestedLength;
  }
  
  /// Prioritizes flashcards for review based on various factors
  List<FlashcardItem> prioritizeReviews(List<FlashcardItem> dueItems) {
    // Sort by multiple factors:
    // 1. Priority flag (true comes first)
    // 2. Learning phase items (true comes first)
    // 3. Overdue items (earlier due date comes first)
    // 4. Higher PDF (harder items come first)
    return List.from(dueItems)..sort((a, b) {
      // Priority flag comparison (true comes first)
      if (a.isPriority != b.isPriority) {
        return a.isPriority ? -1 : 1;
      }
      
      // Learning phase comparison (learning phase items come first)
      if (a.isInLearningPhase != b.isInLearningPhase) {
        return a.isInLearningPhase ? -1 : 1;
      }
      
      // Due date comparison (earlier comes first)
      int dateComparison = a.nextReviewDate.compareTo(b.nextReviewDate);
      if (dateComparison != 0) {
        return dateComparison;
      }
      
      // PDF comparison (higher PDF comes first)
      return b.personalDifficultyFactor.compareTo(a.personalDifficultyFactor);
    });
  }
}
