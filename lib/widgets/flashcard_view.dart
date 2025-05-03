import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:lingua_visual/models/flashcard.dart';

class FlashcardView extends StatefulWidget {
  final List<Flashcard> flashcards;
  final Function(String, Flashcard) onRatingSelected;
  final bool showTranslation;

  const FlashcardView({
    super.key,
    required this.flashcards,
    required this.onRatingSelected,
  
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
    required this.controller,
    required this.onRatingSelected,
    super.key,
  });

  final Flashcard flashcard;
  final CardSwiperController controller;
  final Function(String, Flashcard) onRatingSelected;

  @override
  State<FlashcardBuildItemView> createState() => _FlashcardBuildItemViewState();
}

class _FlashcardBuildItemViewState extends State<FlashcardBuildItemView> {
  Flashcard get flashcard => widget.flashcard;

  bool isCardFlipped = false;
  bool isTranslationVisible = false; // Keep this state variable
  bool hasCheckedAnswer = false;

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, 
          insetPadding: const EdgeInsets.all(10), 
          child: GestureDetector( 
             onTap: () => Navigator.of(context).pop(),
             child: InteractiveViewer(
               panEnabled: true, 
               boundaryMargin: const EdgeInsets.all(20),
               minScale: 0.5,
               maxScale: 5, 
               child: Center( 
                  child: ClipRRect( 
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                       imageUrl,
                       fit: BoxFit.contain,
                       loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                         if (loadingProgress == null) return child;
                         return Container( 
                           width: MediaQuery.of(context).size.width * 0.8,
                           height: MediaQuery.of(context).size.height * 0.6,
                           alignment: Alignment.center,
                           child: const CircularProgressIndicator(),
                         );
                       },
                       errorBuilder: (context, error, stackTrace) => Container( 
                         width: MediaQuery.of(context).size.width * 0.8,
                         height: MediaQuery.of(context).size.height * 0.6,
                         color: Colors.grey[200],
                         child: const Center(child: Icon(Icons.error_outline, color: Colors.red, size: 50)),
                       ),
                     ),
                  ),
               ),
             ),
          ),
        );
      },
    );
  }

  Widget _buildResultButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), 
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0), 
        ),
        elevation: 4, 
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Image Display
            if (flashcard.imageUrl?.isNotEmpty ?? false)
              GestureDetector(
                onTap: () => _showImageDialog(context, flashcard.imageUrl!), 
                child: Container( 
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(16.0), 
                     // boxShadow removed for cleaner look, uncomment if desired
                     // boxShadow: [
                     //   BoxShadow(
                     //     color: Colors.black.withOpacity(0.2),
                     //     spreadRadius: 1,
                     //     blurRadius: 5,
                     //     offset: const Offset(0, 3),
                     //   ),
                     // ],
                   ),
                   child: ClipRRect(
                     borderRadius: BorderRadius.circular(16.0), 
                     child: Image.network(
                       flashcard.imageUrl!,
                       height: 280, 
                       width: 280,  
                       fit: BoxFit.cover, 
                       loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                         if (loadingProgress == null) return child;
                         return Container( 
                           height: 280,
                           width: 280,
                           color: Colors.grey[300],
                           child: Center(
                             child: CircularProgressIndicator(
                               value: loadingProgress.expectedTotalBytes != null
                                   ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                   : null,
                             ),
                           ),
                         );
                       },
                       errorBuilder: (context, error, stackTrace) => Container( 
                         height: 280,
                         width: 280,
                         decoration: BoxDecoration(
                           color: Colors.grey[300],
                           borderRadius: BorderRadius.circular(16.0),
                         ),
                         child: const Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey)),
                       ),
                     ),
                   ),
                ),
              )
            else // Placeholder when no image URL
              Container(
                height: 280,
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[50], 
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: Colors.blueGrey[100]!), 
                ),
                child: Center(child: Text('No Image Available', style: TextStyle(color: Colors.blueGrey[400]))),
              ),

            const SizedBox(height: 12), 

            // Translation Text (conditionally visible)
            if (isTranslationVisible)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0), // Add padding around text
                child: Text(
                  isReversedMode ? flashcard.word : flashcard.translation,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else // Show the button only when text is hidden
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.white, size: 30), // Use visibility icon
                onPressed: _toggleTranslation, // Call toggle function
                tooltip: 'Show Translation',
                padding: const EdgeInsets.all(12),
              ),

            const SizedBox(height: 25), 

            // Result Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: <Widget>[
                _buildResultButton( 
                  text: 'Missed',
                  color: Colors.red.shade400, 
                  onPressed: () {
                    // Add swipe and delay logic
                    widget.controller.swipe(CardSwiperDirection.left);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      widget.onRatingSelected('Missed', flashcard);
                    });
                    _resetCardState(); // Reset state
                  },
                ),
                const SizedBox(width: 25), 
                _buildResultButton( 
                  text: 'Got It',
                  color: Colors.blue.shade400, 
                  onPressed: () {
                    // Add swipe and delay logic
                    widget.controller.swipe(CardSwiperDirection.right);
                     Future.delayed(const Duration(milliseconds: 100), () {
                       widget.onRatingSelected('Got It', flashcard);
                     });
                    _resetCardState(); // Reset state
                  },
                ),
              ],
            ),
            const SizedBox(height: 18), 
            _buildResultButton( 
              text: 'Lucky Guess',
              color: Colors.green.shade400, 
              onPressed: () {
                // Add swipe and delay logic
                 widget.controller.swipe(CardSwiperDirection.right); // Or another direction if needed
                 Future.delayed(const Duration(milliseconds: 100), () {
                   widget.onRatingSelected('Lucky Guess', flashcard);
                 });
                _resetCardState(); // Reset state
              },
            ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: <Widget>[
                _buildResultButton( 
                  text: 'Missed',
                  color: Colors.red.shade400, 
                  onPressed: () {
                    // Add swipe and delay logic
                    widget.controller.swipe(CardSwiperDirection.left);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      widget.onRatingSelected('Missed', flashcard);
                    });
                    _resetCardState(); // Reset state
                  },
                ),
                const SizedBox(width: 25), 
                _buildResultButton( 
                  text: 'Got It',
                  color: Colors.blue.shade400, 
                  onPressed: () {
                    // Add swipe and delay logic
                    widget.controller.swipe(CardSwiperDirection.right);
                     Future.delayed(const Duration(milliseconds: 100), () {
                       widget.onRatingSelected('Got It', flashcard);
                     });
                    _resetCardState(); // Reset state
                  },
                ),
              ],
            ),
            const SizedBox(height: 18), 
            _buildResultButton( 
              text: 'Lucky Guess',
              color: Colors.green.shade400, 
              onPressed: () {
                // Add swipe and delay logic
                 widget.controller.swipe(CardSwiperDirection.right); // Or another direction if needed
                 Future.delayed(const Duration(milliseconds: 100), () {
                   widget.onRatingSelected('Lucky Guess', flashcard);
                 });
                _resetCardState(); // Reset state
              },
            ),
          },
        ],
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

  // Helper to reset card state after rating
  void _resetCardState() {
     if (mounted) { // Check if the widget is still in the tree
        setState(() {
          isCardFlipped = false;
          isTranslationVisible = false; // Reset translation visibility too
          hasCheckedAnswer = false;
        });
     }
  }
}
