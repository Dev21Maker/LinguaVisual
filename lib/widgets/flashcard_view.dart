import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/flashcard.dart';

class FlashcardView extends StatefulWidget {
  final List<Flashcard> flashcards;
  final Function(String, Flashcard) onRatingSelected;

  const FlashcardView({
    super.key,
    required this.flashcards,
    required this.onRatingSelected,
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
      numberOfCardsDisplayed: 1, // We want to display 1 card at a time
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        return _buildFlashcard(widget.flashcards[index]);
      },
      onSwipe: (previousIndex, currentIndex, direction) {
        // Handle swipe if needed
        return true;
      },
      backCardOffset: const Offset(40, 40),
      padding: const EdgeInsets.all(24.0),
    );
  }

  Widget _buildFlashcard(Flashcard flashcard) {
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
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY((value * pi / 180)),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: double.infinity,  // Fill width
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
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                      transform: Matrix4.identity()
                        ..rotateY(value >= 90 ? pi : 0),
                      child: value >= 90 
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

  Widget _buildFrontContent(Flashcard flashcard) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (flashcard.imageUrl != null)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: flashcard.imageUrl!,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.error),
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          flex: 3,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  flashcard.word,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  flashcard.targetLanguageCode.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackContent(Flashcard flashcard) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!(translationVisible[flashcard.id] ?? false)) ...[
          ElevatedButton.icon(
            onPressed: () => setState(() => translationVisible[flashcard.id] = true),
            icon: const Icon(Icons.visibility, color: Colors.white),
            label: const Text(
              'Show Translation',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
        ] else ...[
          Text(
            flashcard.translation,
            style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            flashcard.nativeLanguageCode.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          if (!(hasCheckedAnswer[flashcard.id] ?? false)) ...[
            const Text(
              'Did you know it?',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnswerButton('Yes', Colors.green, flashcard),
                const SizedBox(width: 16),
                _buildAnswerButton('No', Colors.red, flashcard),
              ],
            ),
          ] else ...[
            const Text(
              'How well did you know it?',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
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
        ],
      ],
    );
  }

  Widget _buildAnswerButton(String label, Color color, Flashcard flashcard) {
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

  Widget _buildRatingButton(String label, Color color, Flashcard flashcard) {
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
        child: Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
