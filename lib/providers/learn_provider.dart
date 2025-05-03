import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingua_visual/models/flashcard.dart';
import 'package:lingua_visual/package/algorithm/adaptive_flow_algorithm.dart' show SrsItem;

/// Enum representing the different sides of a flashcard
enum CardSide {
  front,
  back,
}

/// Enum representing the different review types
enum ReviewType {
  quick('Quick'),
  gotIt('Got It'),
  missed('Missed');

  final String label;
  const ReviewType(this.label);

  String get apiValue {
    switch (this) {
      case ReviewType.quick:
        return 'quick';
      case ReviewType.gotIt:
        return 'got';
      case ReviewType.missed:
        return 'missed';
    }
  }
}

/// Provider for the current flashcard being displayed
final currentFlashcardProvider = StateProvider<Flashcard?>((ref) => null);

/// Provider for the current card side being displayed
final cardSideProvider = StateProvider<CardSide>((ref) => CardSide.front);

/// Provider for whether the translation is visible
final isTranslationVisibleProvider = StateProvider<bool>((ref) => false);

/// Provider for the list of SRS items due for review
final dueItemsProvider = StateProvider<List<SrsItem>>((ref) => []);

/// Provider for tracking reviewed cards in the current session
final reviewedCardsProvider = StateProvider<Map<String, (SrsItem, ReviewType)>>((ref) => {});

/// Provider for whether the session is complete
final isSessionCompleteProvider = StateProvider<bool>((ref) => false);

/// Provider for the selected stack ID
final selectedStackIdProvider = StateProvider<String?>((ref) => null);

/// Provider for whether reverse mode is active
final isReverseModeProvider = StateProvider<bool>((ref) => true);

/// LearnProvider class to handle the display logic for flashcards
class LearnProvider extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  
  LearnProvider(this.ref) : super(const AsyncValue.data(null));

  /// Toggles the card between front and back
  void toggleCardSide() {
    final currentSide = ref.read(cardSideProvider);
    ref.read(cardSideProvider.notifier).state = 
        currentSide == CardSide.front ? CardSide.back : CardSide.front;
    
    // Reset translation visibility when flipping back to front
    if (currentSide == CardSide.back) {
      ref.read(isTranslationVisibleProvider.notifier).state = false;
    }
  }

  /// Toggles the visibility of the translation on the back of the card
  void toggleTranslation() {
    final isVisible = ref.read(isTranslationVisibleProvider);
    ref.read(isTranslationVisibleProvider.notifier).state = !isVisible;
  }

  /// Resets the card state (flips to front, hides translation)
  void resetCardState() {
    ref.read(cardSideProvider.notifier).state = CardSide.front;
    ref.read(isTranslationVisibleProvider.notifier).state = false;
  }

  /// Sets the current flashcard
  void setCurrentFlashcard(Flashcard? flashcard) {
    ref.read(currentFlashcardProvider.notifier).state = flashcard;
    resetCardState();
  }

  /// Sets the due items for review
  void setDueItems(List<SrsItem> items) {
    ref.read(dueItemsProvider.notifier).state = items;
    
    // Reset session state when setting new due items
    ref.read(reviewedCardsProvider.notifier).state = {};
    ref.read(isSessionCompleteProvider.notifier).state = false;
    
    // Set the current flashcard if there are items
    if (items.isNotEmpty) {
      _loadCurrentFlashcard(items.first.id);
    } else {
      setCurrentFlashcard(null);
      ref.read(isSessionCompleteProvider.notifier).state = true;
    }
  }

  /// Loads a flashcard by its ID
  void _loadCurrentFlashcard(String flashcardId) {
    // This would typically involve fetching the flashcard from a repository
    // For now, we'll assume this is handled elsewhere and the flashcard is passed in
  }

  /// Records a review for the current flashcard
  void recordReview(ReviewType reviewType) {
    final flashcard = ref.read(currentFlashcardProvider);
    if (flashcard == null) return;
    
    // Get the current due items
    final dueItems = ref.read(dueItemsProvider);
    if (dueItems.isEmpty) return;
    
    // Find the current SRS item
    final currentItem = dueItems.firstWhere(
      (item) => item.id == flashcard.id,
      orElse: () => throw Exception('Current flashcard not found in due items'),
    );
    
    // Add to reviewed cards
    final reviewedCards = Map<String, (SrsItem, ReviewType)>.from(
      ref.read(reviewedCardsProvider),
    );
    reviewedCards[flashcard.id] = (currentItem, reviewType);
    ref.read(reviewedCardsProvider.notifier).state = reviewedCards;
    
    // Remove from due items
    final updatedDueItems = List<SrsItem>.from(dueItems);
    updatedDueItems.removeWhere((item) => item.id == flashcard.id);
    ref.read(dueItemsProvider.notifier).state = updatedDueItems;
    
    // Check if session is complete
    if (updatedDueItems.isEmpty) {
      ref.read(isSessionCompleteProvider.notifier).state = true;
      setCurrentFlashcard(null);
    } else {
      // Load the next flashcard and decide if reverse mode should be activated
      _loadCurrentFlashcard(updatedDueItems.first.id);
      _considerActivatingReverseMode(updatedDueItems.first);
    }
  }

  /// Decides whether to activate reverse mode based on the SRS item's interval
  void _considerActivatingReverseMode(SrsItem item) {
    // Only consider reverse mode for cards with high intervals
    // Define high interval as 7 days (604800000 milliseconds) or more
    const highIntervalThreshold = 604800000.0; // 7 days in milliseconds
    
    if (item.lastInterval >= highIntervalThreshold) {
      // 25% chance to activate reverse mode for eligible cards
      final random = Random();
      final shouldActivate = random.nextDouble() < 0.25; // 25% chance
      
      ref.read(isReverseModeProvider.notifier).state = shouldActivate;
    } else {
      // Ensure reverse mode is turned off for cards with lower intervals
      ref.read(isReverseModeProvider.notifier).state = false;
    }
  }

  /// Returns the content to display on the front of the card
  Widget buildFrontContent(Flashcard flashcard, {required Function onSpeakPressed}) {
    final isReverseMode = ref.read(isReverseModeProvider);
    
    // In reverse mode, show the back content as front
    if (isReverseMode) {
      return buildBackContent(
        flashcard,
        onSpeakPressed: onSpeakPressed,
        onImagePressed: () {}, // Simplified for reverse mode
        isTranslationVisible: true, // Always show translation in reverse mode
        onToggleTranslation: () {}, // Disable toggle in reverse mode
      );
    }
    
    // Normal mode - show regular front content
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          flashcard.word,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        IconButton(
          icon: const Icon(Icons.volume_up, color: Colors.white, size: 32),
          onPressed: () => onSpeakPressed(),
          tooltip: 'Listen to pronunciation',
        ),
      ],
    );
  }

  /// Returns the content to display on the back of the card
  Widget buildBackContent(
    Flashcard flashcard, {
    required Function onSpeakPressed,
    required Function onImagePressed,
    required bool isTranslationVisible,
    required Function onToggleTranslation,
  }) {
    final isReverseMode = ref.read(isReverseModeProvider);
    
    // In reverse mode, show the front content as back (and include review buttons)
    if (isReverseMode) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            flashcard.word,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.white, size: 32),
            onPressed: () => onSpeakPressed(),
            tooltip: 'Listen to pronunciation',
          ),
        ],
      );
    }
    
    // Normal mode - show regular back content
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Images (if available)
        if (flashcard.imageUrl != null)
          GestureDetector(
            onTap: () => onImagePressed(),
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: flashcard.cachedImagePath != null
                      ? FileImage(File(flashcard.cachedImagePath!)) as ImageProvider
                      : NetworkImage(flashcard.imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        
        // Translation toggle button
        ElevatedButton.icon(
          icon: Icon(
            isTranslationVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          label: Text(
            isTranslationVisible ? 'Hide Translation' : 'Show Translation',
            style: const TextStyle(color: Colors.white),
          ),
          onPressed: () => onToggleTranslation(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        const SizedBox(height: 16),
        
        // Translation (if visible)
        if (isTranslationVisible)
          Column(
            children: [
              Text(
                flashcard.translation,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (flashcard.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    flashcard.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// Returns the review buttons for the flashcard
  Widget buildReviewButtons({required Function(ReviewType) onReviewSelected}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildReviewButton(
              text: ReviewType.missed.label,
              color: Colors.red.shade400,
              onPressed: () => onReviewSelected(ReviewType.missed),
            ),
            const SizedBox(width: 25),
            _buildReviewButton(
              text: ReviewType.gotIt.label,
              color: Colors.blue.shade400,
              onPressed: () => onReviewSelected(ReviewType.gotIt),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildReviewButton(
          text: ReviewType.quick.label,
          color: Colors.green.shade400,
          onPressed: () => onReviewSelected(ReviewType.quick),
        ),
      ],
    );
  }

  /// Helper method to build a review button
  Widget _buildReviewButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Provider for the LearnProvider
final learnProvider = StateNotifierProvider<LearnProvider, AsyncValue<void>>((ref) {
  return LearnProvider(ref);
});
