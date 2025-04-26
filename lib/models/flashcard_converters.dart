import 'package:lingua_visual/models/flashcard.dart' show Flashcard;
import 'package:lingua_visual/models/offline_flashcard.dart';
import 'package:lingua_visual/package/models/flashcard_item.dart';
// import 'package:multi_language_srs/multi_language_srs.dart';
import 'online_flashcard.dart';

extension FlashcardToItem on Flashcard {
//   FlashcardItem toFlashcardItem() {
//     return FlashcardItem(
//       id: id,
//       question: word,
//       answer: translation,
//       languageId: targetLanguage.code,
//       interval: srsInterval,
//       easeFactor: srsEaseFactor,
//       nextReviewDate: DateTime.fromMillisecondsSinceEpoch(srsNextReviewDate),
//       lastReviewDate: srsLastReviewDate != null 
//           ? DateTime.fromMillisecondsSinceEpoch(srsLastReviewDate!)
//           : null,
//       metadata: {
//         'imageUrl': imageUrl,
//         'cachedImagePath': cachedImagePath,
//         'nativeLanguageCode': nativeLanguage.code,
//         'stackIds': stackIds,
//         'createdAt': createdAt?.toIso8601String(),
//         'updatedAt': updatedAt?.toIso8601String(),
//       },
//     );
//   }
// }

// extension FlashcardItemToCard on Flashcard {
//   FlashcardItem toFlashcard({
//     required Language targetLanguage,
//     required Language nativeLanguage,
//   }) {
//     return FlashcardItem(
//       id: id,
//       question: word,
//       answer: translation,
//       languageId: targetLanguage.code,
//       interval: srsInterval.toInt(),
//       easeFactor: srsEaseFactor,
//       nextReviewDate: DateTime.fromMillisecondsSinceEpoch(srsNextReviewDate),
//       reviews: 2, //TODO Increase or decrese by corectness
//     );
//   }
}

class FlashcardConverters {
//   static FlashcardItem onlineToFlashcardItem(OnlineFlashcard flashcard) {
//     return FlashcardItem(
//       id: flashcard.id,
//       question: flashcard.word,
//       answer: flashcard.translation,
//       languageId: flashcard.targetLanguage.code,
//       interval: flashcard.srsInterval.toInt(),
//       easeFactor: flashcard.srsEaseFactor,
//       nextReviewDate: DateTime.fromMillisecondsSinceEpoch(flashcard.srsNextReviewDate),
//       reviews: 2, // Increase or decrease by correctness
//     );
//   }

  static FlashcardItem offlineToFlashcardItem(OfflineFlashcard flashcard) {
    return FlashcardItem(
      id: flashcard.id,
      question: flashcard.word,
      answer: flashcard.translation,
      languageId: flashcard.targetLanguageCode,
      interval: flashcard.srsInterval.toInt(),
      personalDifficultyFactor: flashcard.srsEaseFactor,
      nextReviewDate: DateTime.fromMillisecondsSinceEpoch(flashcard.srsNextReviewDate),
      reviews: 2, // Increase or decrease by correctness
    );
  }

}
