import 'algorithm/adaptive_flow_algorithm.dart';
import '../models/flashcard.dart';

/// Main manager class for the SRS (Spaced Repetition System).
///
/// This class provides an interface to the underlying SRS algorithm,
/// managing the state and scheduling of SrsItems.
class SRSManager {
  /// The core SRS algorithm implementation and state.
  final SRS _srs;

  /// Creates an SRSManager, optionally with custom SRS configuration.
  SRSManager({SRS? srs}) : _srs = srs ?? SRS();

  /// Adds a new item to the SRS system.
  ///
  /// Throws an ArgumentError if an item with the same ID already exists.
  /// Returns the newly created SrsItem.
  SrsItem addItem(Flashcard itemId, {int? now}) {

    print('Item Box: ${itemId.srsBaseIntervalIndex}');

    final srsItem = SrsItem(
      id: itemId.id,
      baseIndex: itemId.srsBaseIntervalIndex,
      nextReview: itemId.srsNextReviewDate,
      lastInterval: itemId.srsInterval,
      streakQuick: itemId.srsQuickStreak,
      timesSeenToday: 0,
      pdf: itemId.srsEaseFactor,
      // Prefer the actual box value if available, otherwise use base interval index if in learning phase
      box: itemId.srsIsInLearningPhase ? (itemId.srsBoxValue ?? itemId.srsBaseIntervalIndex) : null,
      lastSeenDay: itemId.srsLastReviewDate != null ? _srs.utcDateStr(itemId.srsLastReviewDate!) : _srs.utcDateStr(_srs.now()),
    );

    return _srs.addItem(srsItem, now: now);
  }

  /// Loads or updates an item in the SRS system based on Flashcard data.
  ///
  /// This is used to populate the manager with existing items and their progress.
  SrsItem loadOrUpdateItemFromFlashcard(Flashcard card) {
    final existingItem = _srs.items[card.id];

    // Create SrsItem state from Flashcard data
    final srsItem = SrsItem(
        id: card.id,
        // If Flashcard is in learning phase, use its box value if available, otherwise use baseIndex
        // Otherwise (graduated), box is null.
        box: card.srsIsInLearningPhase ? (card.srsBoxValue ?? card.srsBaseIntervalIndex) : null,
        pdf: card.srsEaseFactor, // Maps directly
        // BaseIndex in SrsItem tracks the long-term interval step.
        // Use the value from Flashcard directly.
        baseIndex: card.srsBaseIntervalIndex,
        nextReview: card.srsNextReviewDate, // Assumes epoch seconds
        lastInterval: card.srsInterval, // Assumes seconds
        streakQuick: card.srsQuickStreak, // Maps directly
        // Preserve session-specific state if item already exists in manager
        timesSeenToday: existingItem?.timesSeenToday ?? 0,
        // Use internal helper to get current date string if item is new this session
        lastSeenDay: existingItem?.lastSeenDay ?? _srs.utcDateStr(_srs.now()),
    );

    _srs.items[card.id] = srsItem; // Add or replace in the internal map
    return srsItem;
  }

  /// Records a review for the specified item.
  ///
  /// Updates the item's SRS state based on the response ('quick', 'got', 'missed')
  /// and the review type ('mc', 'typing', 'listening').
  ///
  /// Returns the updated SrsItem, or null if no item with the given ID was found.
  SrsItem? recordReview(String itemId, String response, {String reviewType = 'mc', int? now}) {
    try {
      // Basic validation for response string
      if (!['quick', 'got', 'missed'].contains(response)) {
        print("Warning: Invalid response '$response' passed to recordReview.");
        // Decide how to handle invalid input: return null, throw, or default?
        // For now, let's let the SRS class handle potential typeMod errors if reviewType is bad.
      }
      return _srs.processAnswer(itemId, response, reviewType: reviewType, now: now);
    } catch (e) {
      // Catch potential ArgumentError if item not found
      print("Error recording review for item '$itemId': $e");
      return null;
    }
  }

  /// Returns a list of SrsItems that are due for review as of the current time.
  ///
  /// Filtering by other criteria (like language) should happen outside this manager.
  List<SrsItem> getDueItems({int? now}) {
    return _srs.dueItems(now: now);
    // Note: Prioritization logic from the old algorithm is removed.
    // The new SRS class doesn't expose a separate prioritization method.
    // If prioritization is needed, it should be implemented here or in the calling code,
    // potentially based on SrsItem properties (e.g., nextReview, pdf).
  }

  /// Returns the SrsItem for the given ID, or null if not found.
  SrsItem? getItem(String itemId) {
    return _srs.getItem(itemId);
  }

  /// Returns a list of all SrsItems, sorted by their next review date (ascending).
  List<SrsItem> getAllItemsSortedByNextReview() {
    final sortedItems = List<SrsItem>.from(_srs.items.values);
    sortedItems.sort((a, b) => a.nextReview.compareTo(b.nextReview));
    return sortedItems;
  }

  /// Removes an item from the SRS system.
  ///
  /// Returns true if an item was removed, false if no item with the given ID was found.
  bool removeItem(String itemId) {
    return _srs.items.remove(itemId) != null;
  }

  /// Clears all items from the SRS system.
  void clear() {
    _srs.items.clear();
  }
}
