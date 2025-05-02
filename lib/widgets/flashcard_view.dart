import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lingua_visual/models/flashcard.dart';

class FlashcardView extends StatefulWidget {
  final List<Flashcard> flashcards;
  final Function(String, Flashcard) onRatingSelected;
  final String? imageUrl;
  final bool showTranslation;

  const FlashcardView({
    super.key,
    required this.flashcards,
    required this.onRatingSelected,
    this.imageUrl,
    this.showTranslation = true,
  });

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> {
  final CardSwiperController controller = CardSwiperController();
  final Map<String, bool> flippedCards = {};
  bool isTranslationVisible = false;
  final Map<String, bool> hasCheckedAnswer = {};

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return const Center(child: Text('No cards available'));
    }

    return CardSwiper(
      controller: controller,
      cardsCount: widget.flashcards.length,
      numberOfCardsDisplayed: 1,
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        if (index >= widget.flashcards.length) {
          print("Index out of bounds: $index/${widget.flashcards.length}");
          return const SizedBox.shrink();
        }
        return FlashcardBuildItemView(
          controller: controller,
          onRatingSelected: widget.onRatingSelected,
          flashcard: widget.flashcards[index],
          imageUrl: widget.imageUrl,
        );
      },
      onSwipe: (previousIndex, currentIndex, direction) {
        if (currentIndex == null || currentIndex >= widget.flashcards.length) {
          print("Swipe resulted in invalid currentIndex: $currentIndex");
          return false;
        }
        return false;
      },
      backCardOffset: const Offset(40, 40),
      padding: const EdgeInsets.all(24.0),
    );
  }
}

class FlashcardBuildItemView extends StatefulWidget {
  const FlashcardBuildItemView({
    required this.flashcard,
    required this.imageUrl,
    required this.controller,
    required this.onRatingSelected,
    super.key,
  });

  final Flashcard flashcard;
  final String? imageUrl;
  final CardSwiperController controller;
  final Function(String, Flashcard) onRatingSelected;

  @override
  State<FlashcardBuildItemView> createState() => _FlashcardBuildItemViewState();
}

class _FlashcardBuildItemViewState extends State<FlashcardBuildItemView> {
  Flashcard get flashcard => widget.flashcard;

  bool isCardFlipped = false;
  bool isTranslationVisible = false;
  bool hasCheckedAnswer = false;

  @override
  Widget build(BuildContext context) {
    // Determine if this card should be shown reversed (back first)
    // When card is in box 3+ (higher learning stage), show back first
    final bool shouldShowReversed =
        flashcard.srsIsInLearningPhase && flashcard.srsBaseIntervalIndex >= 3;

    // Store whether the card is in reversed mode
    // This is used by _buildBackContent to modify its behavior
    final bool isReversedMode = shouldShowReversed && !(isCardFlipped);

    return GestureDetector(
      onTap: () => _toggleCard(flashcard.id),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: isCardFlipped ? 180 : 0),
        duration: const Duration(milliseconds: 300),
        builder: (context, double value, child) {
          return Transform(
            alignment: Alignment.center,
            transform:
                Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY((value * pi / 180)),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      Theme.of(context).colorScheme.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Icon(
                        Icons.flip,
                        color: Colors.white.withOpacity(0.3),
                        size: 24,
                      ),
                    ),
                    Transform(
                      alignment: Alignment.center,
                      transform:
                          Matrix4.identity()..rotateY(value >= 90 ? pi : 0),
                      child:
                          shouldShowReversed
                              ? (value >= 90
                                  ? _buildFrontContent(
                                    flashcard,
                                    isReversedMode,
                                  ) // If flipped, show front
                                  : _buildBackContent(
                                    flashcard,
                                    isReversedMode,
                                  )) // Initially show back
                              : (value >= 90
                                  ? _buildBackContent(
                                    flashcard,
                                    isReversedMode,
                                  ) // Normal: If flipped, show back
                                  : _buildFrontContent(
                                    flashcard,
                                    isReversedMode,
                                  )), // Normal: Initially show front
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackContent(Flashcard flashcard, bool isReversedMode) {
    if (widget.imageUrl != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 100,
                  maxWidth: 100,
                ),
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl!,
                  fit: BoxFit.contain,
                  placeholder:
                      (context, url) => Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  errorWidget:
                      (context, url, error) => const Center(
                        child: Icon(Icons.error, color: Colors.white),
                      ),
                ),
              ),
            ),

            // Translation visibility control
            if (!isTranslationVisible)
              IconButton(
                onPressed: _toggleTranslation,
                icon: const Icon(
                  Icons.visibility,
                  color: Colors.white,
                  size: 28,
                ),
                tooltip: 'Show translation',
              ),

            // Show translation based on visibility state
            if (isTranslationVisible)
              Text(
                flashcard.translation,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 32),

            // Always show rating buttons on back side
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildRatingButton('Missed', Colors.red.shade400, flashcard),
                _buildRatingButton(
                  'Got It',
                  Colors.blue.shade400,
                  flashcard,
                  direction: CardSwiperDirection.right,
                ),
                _buildRatingButton(
                  'Lucky Guess',
                  Colors.green.shade400,
                  flashcard,
                  direction: CardSwiperDirection.right,
                  isLonger: true,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Translation visibility control for normal mode
            if (!isTranslationVisible)
              IconButton(
                onPressed: _toggleTranslation,
                icon: const Icon(
                  Icons.visibility,
                  color: Colors.white,
                  size: 28,
                ),
                tooltip: 'Show translation',
              ),

            if (isTranslationVisible)
              Text(
                flashcard.translation,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 32),

            // Always show rating buttons on back side
            if (!isReversedMode) ...{
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildRatingButton('Missed', Colors.red.shade400, flashcard),
                  _buildRatingButton(
                    'Got It',
                    Colors.blue.shade400,
                    flashcard,
                    direction: CardSwiperDirection.right,
                  ),
                  _buildRatingButton(
                    'Lucky Guess',
                    Colors.green.shade400,
                    flashcard,
                    direction: CardSwiperDirection.right,
                    isLonger: true,
                  ),
                ],
              ),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildFrontContent(Flashcard flashcard, bool isReversedMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            flashcard.word,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (isReversedMode) ...{
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildRatingButton('Missed', Colors.red.shade400, flashcard),
                _buildRatingButton(
                  'Got It',
                  Colors.blue.shade400,
                  flashcard,
                  direction: CardSwiperDirection.right,
                ),
                _buildRatingButton(
                  'Lucky Guess',
                  Colors.green.shade400,
                  flashcard,
                  direction: CardSwiperDirection.right,
                  isLonger: true,
                ),
              ],
            ),
          },
        ],
      ),
    );
  }

  Widget _buildRatingButton(
    String label,
    Color color,
    Flashcard flashcard, {
    CardSwiperDirection direction = CardSwiperDirection.left,
    bool isLonger = false,
  }) {
    return SizedBox(
      width: isLonger ? 100 : 90,
      child: ElevatedButton(
        onPressed: () {
          // First trigger the swipe animation - do this before modifying the list
          widget.controller.swipe(direction);

          print('Flashcard word: ${flashcard.word} N: ${DateTime.fromMillisecondsSinceEpoch(flashcard.srsNextReviewDate).toIso8601String()} I: ${flashcard.srsInterval} E: ${flashcard.srsEaseFactor} P: ${flashcard.srsIsPriority} L: ${flashcard.srsIsInLearningPhase} B: ${flashcard.srsBaseIntervalIndex} Q: ${flashcard.srsQuickStreak}');
          // Small delay to allow animation to start before modifying the list
          Future.delayed(const Duration(milliseconds: 100), () {
            // Then notify parent about the rating (which will update SRS and modify the list)
            widget.onRatingSelected(label, flashcard);
          });

          print('@: Flashcard word: ${flashcard.word} N: ${DateTime.fromMillisecondsSinceEpoch(flashcard.srsNextReviewDate).toIso8601String()} I: ${flashcard.srsInterval} E: ${flashcard.srsEaseFactor} P: ${flashcard.srsIsPriority} L: ${flashcard.srsIsInLearningPhase} B: ${flashcard.srsBaseIntervalIndex} Q: ${flashcard.srsQuickStreak}');

          // Reset card state
          setState(() {
            isCardFlipped = false;
            isTranslationVisible = false;
            hasCheckedAnswer = false;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void _toggleTranslation() {
    setState(() {
      isTranslationVisible = !isTranslationVisible;
    });
  }

  void _toggleCard(String cardId) {
    setState(() {
      isCardFlipped = !isCardFlipped;
      if (!isCardFlipped) {
        isTranslationVisible = false;
        hasCheckedAnswer = false;
      }
    });
  }
}
