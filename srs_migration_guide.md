# AdaptiveFlow SRS Migration Guide

This document outlines the steps required to migrate the LinguaVisual application from its current Spaced Repetition System (SRS) to the new AdaptiveFlow SRS system, as defined in `adaptive_flow_srs.md`.

## 1. Understanding AdaptiveFlow

Before starting, ensure you understand the core concepts of the AdaptiveFlow system:

*   **Initial Learning:** New items require multiple successful interactions before entering the review schedule.
*   **Base Intervals:** A predefined sequence (1h, 5h, 1d, 3d, etc., up to 120d).
*   **Simplified Feedback:** Uses 'Quick', 'Got It', 'Missed' instead of complex ratings.
*   **Personal Difficulty Factor (PDF):** An item-specific multiplier (0.5-2.0) adjusted based on feedback.
*   **Next Interval Calculation:** `Next Interval = Base Interval × PDF × Review Type Modifier`.
*   **Review Type Modifiers:** Adjust intervals based on review difficulty (e.g., multiple choice vs. typing).
*   **Handling Missed Items:** Go back 2 steps in the interval sequence, increase PDF, add priority flag.
*   **Streak Bonuses:** Small interval increases for on-time reviews and consecutive 'Quick' answers.
*   **Max Interval Cap:** 120 days.
*   **Smart Review Mixing:** Prioritize review types based on PDF.
*   **Adaptive Session Length:** System suggests session length.

## 2. Changes Already Made

*   **`lib/screens/games/srs/learn_screen.dart`:**
    *   The `onRatingSelected` callback within `_buildBody` has been partially updated.
    *   It now conceptually maps the user's rating string ('Quick', 'Got It', 'Missed') to the existing `srs_model.ReviewOutcome` enum (`easy`, `good`, `missed`).
    *   **Note:** This is an intermediary step. The UI (`FlashcardView`) needs updating to provide these strings, and the `SRSManager` logic needs the core algorithm change.

## 3. Critical Next Steps

### 3.1. Update `SRSManager` (`lib/package/srs_manager.dart`)

This is the most significant change. The core SRS algorithm needs replacement.

*   **Replace `recordReview` Logic:** Implement the new interval calculation based on `Base Interval`, `PDF`, and `Review Type Modifier`.
*   **Implement PDF:** Add logic to calculate and update the `Personal Difficulty Factor` based on 'Quick', 'Got It', 'Missed' feedback.
*   **Implement Interval Sequence & Setbacks:** Modify how intervals progress and how 'Missed' feedback sets the interval back.
*   **Add Review Type Modifiers:** Incorporate the modifiers based on the `ReviewType` passed to `recordReview`.
*   **Implement Streak Bonuses:** Add logic to track and apply streak bonuses.
*   **Implement Max Interval Cap:** Ensure intervals do not exceed 120 days.
*   **Handle Initial Learning:** Decide how the initial 'planting' phase integrates or precedes the `SRSManager`'s tracking.
*   **(Optional) Smart Review Mixing & Adaptive Session Length:** These are more advanced features. Implement the core logic first, then consider these if time/priority allows.

### 3.2. Update Data Models (`lib/models/flashcard.dart`, `lib/package/models/flashcard_item.dart`)

*   Ensure the data models can store the necessary AdaptiveFlow fields:
    *   `personalDifficultyFactor` (PDF)
    *   `lastReviewDate`
    *   `nextReviewDate`
    *   Current `baseIntervalIndex` or similar to track progress in the sequence.
    *   (Optional) `priorityFlag` for missed items.
    *   (Optional) Fields for streak tracking.
*   Remove or deprecate unused fields from the old SRS system (e.g., `srsEaseFactor` if PDF replaces it entirely, `srsInterval` if the base interval sequence is used directly).
*   Update database schema and migration logic if necessary.

### 3.3. Update UI (`lib/widgets/flashcard_view.dart`)

*   Change the rating buttons/mechanism to provide the three feedback options: 'Quick', 'Got It', 'Missed'.
*   Ensure the `onRatingSelected` callback in `FlashcardView` passes these exact strings back to `learn_screen.dart`.

### 3.4. Update `learn_screen.dart` Further

*   **Pass `ReviewType`:** When calling `srsManager.recordReview`, determine the correct `ReviewType` (e.g., `typing`, `multiple_choice`) based on the current flashcard interaction type and pass it.
*   **Handle Initial Learning Phase:** Integrate logic to manage the initial 'planting' phase if not handled solely within `SRSManager`.
*   **Adjust Data Handling:** Ensure the screen correctly reads/writes the new AdaptiveFlow data fields from/to the flashcard models and providers.

### 3.5. Testing

*   Thoroughly test the new SRS logic with various scenarios:
    *   New card learning.
    *   Correct ('Quick', 'Got It') reviews at different interval stages.
    *   Incorrect ('Missed') reviews.
    *   Hitting the max interval.
    *   Streak bonuses.
    *   Different review types.
*   Test online and offline data synchronization.

## 4. Data Migration (Existing Users)

*   Plan how to migrate existing user data.
*   A possible approach: Initialize PDF to 1.0 for all existing cards. Map existing intervals/ease factors to the closest new base interval step. Set the `nextReviewDate` based on the old data.
*   This requires careful planning and potentially a one-time migration script/logic on app update.

This guide provides a roadmap. Each step, especially the `SRSManager` update, will require careful implementation and testing.
