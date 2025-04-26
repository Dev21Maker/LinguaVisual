import 'algorithm/adaptive_flow_algorithm.dart';
import 'models/flashcard_item.dart';
import 'models/review_outcome.dart';

/// Main manager class for the AdaptiveFlow spaced repetition system.
///
/// This class provides the core functionality for managing flashcard items
/// and scheduling reviews using the AdaptiveFlow algorithm.
class SRSManager {
  /// Internal list of flashcard items.
  final List<FlashcardItem> _items = [];
  
  /// The algorithm implementation used for spaced repetition calculations.
  final AdaptiveFlowAlgorithm _algorithm = AdaptiveFlowAlgorithm();

  /// Returns a list of all flashcard items.
  List<FlashcardItem> get items => List.unmodifiable(_items);

  /// Adds a new flashcard item to the system.
  ///
  /// If an item with the same ID already exists, it will be replaced.
  void addItem(FlashcardItem item) {
    // Check if an item with this ID already exists
    final existingIndex = _items.indexWhere((i) => i.id == item.id);
    
    if (existingIndex >= 0) {
      // Replace existing item
      _items[existingIndex] = item;
    } else {
      // Add new item
      _items.add(item);
    }
  }

  /// Records a review for the specified flashcard item.
  ///
  /// Updates the item's SRS fields based on the review outcome and type.
  ///
  /// Returns the updated flashcard item, or null if no item with the given ID was found.
  FlashcardItem? recordReview(String itemId, ReviewOutcome outcome, ReviewType reviewType) {
    // Find the item with the given ID
    final index = _items.indexWhere((item) => item.id == itemId);
    
    if (index < 0) {
      // Item not found
      return null;
    }
    
    // Get the current item
    final item = _items[index];
    
    // Process the review using the AdaptiveFlow algorithm
    final updatedItem = _algorithm.processReview(item, outcome, reviewType);
    
    // Update the item in the list
    _items[index] = updatedItem;
    
    return updatedItem;
  }

  /// Returns a list of flashcard items that are due for review.
  ///
  /// An item is considered due if its nextReviewDate is on or before the given date.
  /// If languageId is provided, only items for that language will be returned.
  /// Results are prioritized according to the AdaptiveFlow algorithm.
  List<FlashcardItem> getDueItems(DateTime currentDate, {String? languageId}) {
    final dueItems = _items.where((item) {
      // Check if the item is due
      final isDue = !item.nextReviewDate.isAfter(currentDate);
      
      // If languageId is provided, also check if the item belongs to that language
      final isCorrectLanguage = languageId == null || item.languageId == languageId;
      
      return isDue && isCorrectLanguage;
    }).toList();
    
    // Prioritize items according to the algorithm
    return _algorithm.prioritizeReviews(dueItems);
  }

  /// Removes a flashcard item from the system.
  ///
  /// Returns true if an item was removed, false if no item with the given ID was found.
  bool removeItem(String itemId) {
    final initialLength = _items.length;
    _items.removeWhere((item) => item.id == itemId);
    return _items.length < initialLength;
  }

  /// Updates an existing flashcard item.
  ///
  /// Returns the updated item, or null if no item with the given ID was found.
  FlashcardItem? updateItem(FlashcardItem updatedItem) {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    
    if (index < 0) {
      // Item not found
      return null;
    }
    
    // Update the item in the list
    _items[index] = updatedItem;
    
    return updatedItem;
  }

  /// Clears all flashcard items from the system.
  void clear() {
    _items.clear();
  }
  
  /// Suggests an optimal review type for a flashcard based on its difficulty.
  ///
  /// This helps implement the smart review mixing feature of AdaptiveFlow.
  ReviewType suggestReviewType(FlashcardItem item) {
    return _algorithm.getOptimalReviewType(item);
  }
  
  /// Suggests an optimal daily review session length based on due items.
  ///
  /// This helps implement the adaptive session length feature of AdaptiveFlow.
  int suggestSessionLength() {
    final dueItems = getDueItems(DateTime.now());
    return _algorithm.suggestSessionLength(dueItems);
  }
  
  /// Returns the number of items in the learning phase.
  int getLearningPhaseItemCount() {
    return _items.where((item) => item.isInLearningPhase).length;
  }
  
  /// Returns the number of priority items (items that were recently missed).
  int getPriorityItemCount() {
    return _items.where((item) => item.isPriority).length;
  }
  
  /// Returns the average personal difficulty factor across all items.
  ///
  /// This can be used as a measure of overall learning progress.
  double getAveragePersonalDifficultyFactor() {
    if (_items.isEmpty) return 1.0;
    
    double sum = _items.fold(0.0, (sum, item) => sum + item.personalDifficultyFactor);
    return sum / _items.length;
  }
}
