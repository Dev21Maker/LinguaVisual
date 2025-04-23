// import 'dart:math';
// import 'package:lingua_visual/models/flashcard.dart';

// import '../models/online_flashcard.dart';

// class SRSService {
//   // Default values for new cards
//   static const double defaultEaseFactor = 2.5;
//   static const double defaultInterval = 1.0;
//   static const double minimumEaseFactor = 1.3;

//   /// Calculates the next review parameters based on SM-2 algorithm
//   /// Returns a new Flashcard with updated SRS parameters
//   Flashcard calculateNextReview(Flashcard card, String rating) {
//     double newInterval;
//     double newEaseFactor = card.srsEaseFactor;
//     final now = DateTime.now();

//     switch (rating.toLowerCase()) {
//       case 'again':
//         // Failed recall - reset interval and decrease ease factor
//         newInterval = 1.0;
//         newEaseFactor = max(minimumEaseFactor, card.srsEaseFactor - 0.2);
//         break;
        
//       case 'hard':
//         // Difficult recall - slight increase in interval, decrease ease factor
//         newInterval = card.srsInterval * 1.2;
//         newEaseFactor = max(minimumEaseFactor, card.srsEaseFactor - 0.15);
//         break;
        
//       case 'good':
//         // Successful recall - normal interval increase
//         newInterval = card.srsInterval * card.srsEaseFactor;
//         break;
        
//       case 'easy':
//         // Easy recall - larger interval increase and increase ease factor
//         newInterval = card.srsInterval * card.srsEaseFactor * 1.3;
//         newEaseFactor = card.srsEaseFactor + 0.15;
//         break;
        
//       default:
//         throw ArgumentError('Invalid rating: $rating');
//     }

//     // Calculate next review date
//     final nextReviewDate = now.add(Duration(days: newInterval.round()));

//     // Return new Flashcard with updated SRS parameters
//     return card.copyWith(
//       srsInterval: newInterval,
//       srsEaseFactor: newEaseFactor,
//       srsNextReviewDate: nextReviewDate.millisecondsSinceEpoch,
//       srsLastReviewDate: now.millisecondsSinceEpoch,
//     );
//   }

//   // Initialize SRS parameters for a new card
//   Map<String, dynamic> initializeCard() {
//     final now = DateTime.now();
//     return {
//       'interval': defaultInterval,
//       'easeFactor': defaultEaseFactor,
//       'nextReviewDate': now.millisecondsSinceEpoch,
//       'lastReviewDate': null,
//     };
//   }

//   // Check if a card is due for review
//   bool isDue(int nextReviewDate) {
//     final now = DateTime.now().millisecondsSinceEpoch;
//     return nextReviewDate <= now;
//   }
// }
