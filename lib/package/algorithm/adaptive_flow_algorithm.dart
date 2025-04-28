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
  
  /// The amount to decrease PDF for an "easy" response
  static const double easyResponsePdfDecrease = 0.15;
  
  /// The amount to increase PDF for a "missed" response
  static const double missedResponsePdfIncrease = 0.2;
  
  /// The streak bonus percentage for on-time reviews
  static const double onTimeReviewBonus = 0.05;
  
  /// The streak bonus percentage for consecutive "easy" responses
  static const double easyStreakBonus = 0.1;
  
  /// The minimum number of consecutive "easy" responses to trigger a streak bonus
  static const int easyStreakThreshold = 3;
  
  /// The number of steps to go back in the interval sequence when an item is missed
  static const int missedStepBack = 2;

  /// Modifiers applied to the interval based on review type difficulty
  static const Map<ReviewType, double> reviewTypeModifiers = {
    ReviewType.multipleChoice: 0.9, // Easier, slightly shorter interval
    ReviewType.listening: 1.0,      // Standard interval
    ReviewType.typing: 1.1,         // Harder, slightly longer interval
  };

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
        repeatedToday: item.repeatedToday + 1,
        isPriority: true, // Mark as priority to ensure it appears early in next session
      );
    }
    
    // For hard responses in learning phase
    if (outcome == ReviewOutcome.hard) {
      // Keep learning progress the same
      int newLearningProgress = item.learningPhaseProgress;
      
      // Schedule for review in 1 hour
      final DateTime newNextReviewDate = DateTime.now().add(Duration(hours: 1));
      
      return item.copyWith(
        reviews: newReviews,
        learningPhaseProgress: newLearningProgress,
        nextReviewDate: newNextReviewDate,
        lastReviewType: newLastReviewType,
        repeatedToday: item.repeatedToday + 1,
        isPriority: true, // Mark as priority but less urgent than missed
      );
    }
    
    // For successful responses (good or easy)
    int newLearningProgress = item.learningPhaseProgress + 1;
    
    // Check if we've completed the required number of successful reviews to graduate
    bool shouldGraduate = newLearningProgress >= learningPhaseRequiredReviews;
    
    DateTime newNextReviewDate;
    if (shouldGraduate) {
      // Graduate to review phase: first review after 1 day
      // (or 2 days for "easy" responses)
      int graduationInterval = outcome == ReviewOutcome.easy ? 2 : 1;
      newNextReviewDate = DateTime.now().add(Duration(days: graduationInterval));
    } else {
      // Still in learning phase: next review after 4 hours
      // (or 8 hours for "easy" responses)
      int learningHours = outcome == ReviewOutcome.easy ? 8 : 4;
      newNextReviewDate = DateTime.now().add(Duration(hours: learningHours));
    }
    
    return item.copyWith(
      reviews: newReviews,
      learningPhaseProgress: newLearningProgress,
      isInLearningPhase: !shouldGraduate,
      interval: shouldGraduate ? (outcome == ReviewOutcome.easy ? 2 : 1) : 0,
      nextReviewDate: newNextReviewDate,
      lastReviewType: newLastReviewType,
      repeatedToday: 0,
    );
  }
  
  /// Processes a review for a graduated card (in review phase)
  FlashcardItem _processGraduatedReview(
    FlashcardItem item, 
    ReviewOutcome outcome, 
    ReviewType reviewType,
    int newReviews
  ) {
    final now = DateTime.now();
    double currentPdf = item.personalDifficultyFactor;
    int currentBaseIndex = item.baseIntervalIndex;
    int currentQuickStreak = item.quickStreak;
    int nextBaseIndex = currentBaseIndex;
    double pdfDelta = 0.0;
    double bonusMultiplier = 1.0;
    bool setPriority = false;

    // 1. Handle Missed Outcome
    if (outcome == ReviewOutcome.missed || outcome == ReviewOutcome.hard) {
      // Increase PDF
      pdfDelta = missedResponsePdfIncrease;
      // Step back in interval sequence
      nextBaseIndex = (currentBaseIndex - missedStepBack).clamp(1, baseIntervals.length - 1); // Clamp ensures we don't go below index 1
      // Set priority flag
      setPriority = true;
      // Reset quick streak
      currentQuickStreak = 0;
    } else {
      // 2. Handle Correct Outcomes (Easy/Good)
      setPriority = false; // Clear priority flag on correct review

      if (outcome == ReviewOutcome.easy) {
        // Decrease PDF
        pdfDelta = -easyResponsePdfDecrease;
        // Increment quick streak
        currentQuickStreak++;
        // Advance interval sequence
        nextBaseIndex = (currentBaseIndex + 1).clamp(1, baseIntervals.length - 1);
      } else { // ReviewOutcome.good
        // No PDF change for 'good'
        pdfDelta = 0.0;
        // Reset quick streak for 'good'
        currentQuickStreak = 0;
        // Advance interval sequence
        nextBaseIndex = (currentBaseIndex + 1).clamp(1, baseIntervals.length - 1);
      }

      // 3. Apply Bonuses (only for correct outcomes)
      // On-time bonus (review done within ~20% tolerance of interval)
      if (item.lastReviewDate != null) {
          final expectedReviewDate = item.lastReviewDate!.add(Duration(days: item.interval));
          final daysLate = now.difference(expectedReviewDate).inDays;
          // Allow some flexibility (e.g., reviewed within 20% of the interval duration past the due date)
          if (daysLate.abs() <= (item.interval * 0.2).ceil()) {
              bonusMultiplier += onTimeReviewBonus;
          }
      }

      // Easy streak bonus
      if (currentQuickStreak >= easyStreakThreshold) {
        bonusMultiplier += easyStreakBonus;
      }
    }

    // 4. Adjust PDF
    double newPdf = _adjustPdf(currentPdf, pdfDelta);

    // 5. Calculate Next Interval Duration
    double baseIntervalDays = baseIntervals[nextBaseIndex].toDouble();
    double reviewModifier = reviewTypeModifiers[reviewType] ?? 1.0;
    double calculatedIntervalDays = baseIntervalDays * newPdf * reviewModifier * bonusMultiplier;

    // Apply max interval cap (convert days to int, ensure minimum 1 day if not index 1 which is hours)
    int newIntervalDays = calculatedIntervalDays.round().clamp(nextBaseIndex == 1 ? 0 : 1, baseIntervals.last);
    if (nextBaseIndex == 1 && newIntervalDays == 0) { // Special case for first step (hours)
       // Calculate in hours based on PDF/modifiers if base is 0 days
       // Example: Base interval 1 is 'same day, hours later'. Let's target ~4 hours base.
       calculatedIntervalDays = (4 / 24.0) * newPdf * reviewModifier * bonusMultiplier; 
       // Still store 0 in interval field, but use hours for nextReviewDate
       newIntervalDays = 0; 
    } else {
        // If calculated interval forces index beyond max, use max interval index
        if (newIntervalDays >= baseIntervals.last) {
            nextBaseIndex = baseIntervals.length - 1;
            newIntervalDays = baseIntervals.last;
        }
    }


    // 6. Calculate Next Review Date
    Duration nextDuration;
    if (nextBaseIndex == 1 && newIntervalDays == 0) { // Use hours for index 1
         int hours = (calculatedIntervalDays * 24).round().clamp(1, 12); // Clamp hours e.g. 1-12h
         nextDuration = Duration(hours: hours);
    } else if (outcome == ReviewOutcome.missed || outcome == ReviewOutcome.hard) {
        // For missed/hard, schedule relative to NOW, e.g., 10-30 minutes for immediate re-review
         nextDuration = Duration(minutes: 30); // Review again soon
         setPriority = true; // Ensure priority remains set
         // Keep nextBaseIndex stepped back, but force immediate review
    } else {
        nextDuration = Duration(days: newIntervalDays);
    }
    DateTime newNextReviewDate = now.add(nextDuration);

    // 7. Update Item
    return item.copyWith(
      interval: newIntervalDays, // Store calculated interval days
      baseIntervalIndex: nextBaseIndex,
      personalDifficultyFactor: newPdf,
      reviews: newReviews,
      lastReviewDate: now, // Update last review date
      nextReviewDate: newNextReviewDate,
      quickStreak: currentQuickStreak,
      lastReviewType: reviewType.asString,
      isPriority: setPriority,
      repeatedToday: (outcome == ReviewOutcome.missed || outcome == ReviewOutcome.hard) ? item.repeatedToday + 1 : 0, // Reset counter on correct
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
