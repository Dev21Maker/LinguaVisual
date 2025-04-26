import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lingua_visual/package/models/flashcard_item.dart';
// import 'package:multi_language_srs/multi_language_srs.dart';

class FlashcardView extends StatefulWidget {
  final List<FlashcardItem> flashcards;
  final Function(String, FlashcardItem) onRatingSelected;
  final String? imageUrl;
  final bool showTranslation; // Add this new parameter

  const FlashcardView({
    super.key,
    required this.flashcards,
    required this.onRatingSelected,
    this.imageUrl,
    this.showTranslation = true, // Default to true for backward compatibility
  });

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> {
  final CardSwiperController controller = CardSwiperController();
  final Map<String, bool> flippedCards = {};
  final Map<String, bool> translationVisible = {};
  final Map<String, bool> hasCheckedAnswer = {};

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _toggleCard(String cardId) {
    setState(() {
      flippedCards[cardId] = !(flippedCards[cardId] ?? false);
      if (!(flippedCards[cardId] ?? false)) {
        translationVisible[cardId] = false;
        hasCheckedAnswer[cardId] = false;
      }
    });
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
        // Add bounds check to prevent index out of range
        if (index >= widget.flashcards.length) {
          return const SizedBox.shrink(); // Return empty widget for invalid indices
        }
        return _buildFlashcard(widget.flashcards[index]);
      },
      onSwipe: (previousIndex, currentIndex, direction) {
        return true;
      },
      backCardOffset: const Offset(40, 40),
      padding: const EdgeInsets.all(24.0),
    );
  }

  Widget _buildFlashcard(FlashcardItem flashcard) {
    return GestureDetector(
      onTap: () => _toggleCard(flashcard.id),
      child: TweenAnimationBuilder(
        tween: Tween<double>(
          begin: 0,
          end: flippedCards[flashcard.id] ?? false ? 180 : 0,
        ),
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
                width: double.infinity, // Fill width
                height: double.infinity, // Fill height
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
                          value >= 90
                              ? _buildBackContent(flashcard)
                              : _buildFrontContent(flashcard),
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

  Widget _buildFrontContent(FlashcardItem flashcard) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            flashcard.question,
            style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBackContent(FlashcardItem flashcard) {
    if (widget.imageUrl != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 100, // Limit the maximum height
                  maxWidth: 100, // Limit the maximum width
                ),
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl!,
                  fit: BoxFit.contain,
                  placeholder:
                      (context, url) => Center(
                        child: CircularProgressIndicator(
                          strokeWidth:
                              2, // Make the loading indicator more subtle
                        ),
                      ),
                  errorWidget:
                      (context, url, error) =>
                          Center(child: const Icon(Icons.error, color: Colors.white)),
                ),
              ),
            ),
            _buildTranslationAndRatingButtons(flashcard),
          ],
        ),
      );
    }

    // Center everything if no image
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!(translationVisible[flashcard.id] ?? false))
              IconButton(
                onPressed:
                    () =>
                        setState(() => translationVisible[flashcard.id] = true),
                icon: const Icon(
                  Icons.visibility,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            if (translationVisible[flashcard.id] ?? false)
              Text(
                flashcard.answer,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildRatingButton('Again', Colors.red, flashcard),
                _buildRatingButton('Hard', Colors.orange, flashcard),
                _buildRatingButton('Good', Colors.green, flashcard),
                _buildRatingButton('Easy', Colors.blue, flashcard),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationAndRatingButtons(FlashcardItem flashcard) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!(translationVisible[flashcard.id] ?? false))
          IconButton(
            onPressed:
                () => setState(() => translationVisible[flashcard.id] = true),
            icon: const Icon(Icons.visibility, color: Colors.white, size: 28),
          ),
        if (translationVisible[flashcard.id] ?? false)
          Text(
            flashcard.answer,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildRatingButton('Again', Colors.red, flashcard),
            _buildRatingButton('Hard', Colors.orange, flashcard),
            _buildRatingButton('Good', Colors.green, flashcard),
            _buildRatingButton('Easy', Colors.blue, flashcard),
          ],
        ),
      ],
    );
  }

  Widget _buildAnswerButton(
    String label,
    Color color,
    FlashcardItem flashcard,
  ) {
    return ElevatedButton(
      onPressed: () {
        setState(() => hasCheckedAnswer[flashcard.id] = true);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.8),
        minimumSize: const Size(80, 36),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildRatingButton(
    String label,
    Color color,
    FlashcardItem flashcard,
  ) {
    return SizedBox(
      width: 80,
      child: ElevatedButton(
        onPressed: () {
          widget.onRatingSelected(label.toLowerCase(), flashcard);
          controller.swipe(CardSwiperDirection.left);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
