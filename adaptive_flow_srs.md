How AdaptiveFlow SRS Works
1. Initial Learning Phase
When a new word or phrase is introduced:
The item goes through a "planting" phase with multiple exposures in different formats (like Memrise)
User must correctly answer the item in at least 3 different ways (typing, multiple choice, listening)
Initial exposures happen in a single session, with short intervals (30 seconds between attempts)
After successful initial learning, the item enters the review schedule
2. Review Schedule Base Intervals
AdaptiveFlow uses a hybrid approach with base intervals:
1 hour → 5 hours → 1 day → 3 days → 7 days → 14 days → 30 days → 60 days → 120 days
These base intervals serve as the foundation but are modified by personal performance factors.
3. Simplified Feedback System
Instead of complex ratings or binary right/wrong, AdaptiveFlow uses a three-button system:
Quick (answered easily and quickly)
Got It (answered correctly but with some effort)
Missed (answered incorrectly)
This captures the essence of Anki's granularity without overwhelming users with choices.
4. Personal Difficulty Factor (PDF)
Each item has a Personal Difficulty Factor that starts at 1.0 and adjusts based on performance:
Quick response: PDF decreases by 0.15 (making the item "easier")
Got It response: PDF remains unchanged
Missed response: PDF increases by 0.2 (making the item "harder")
PDF has a minimum value of 0.5 and a maximum of 2.0
5. Next Interval Calculation
The next review interval is calculated using:
Next Interval = Base Interval × Personal Difficulty Factor × Review Type Modifier
Where:
Base Interval is from the standard sequence
Personal Difficulty Factor reflects your history with this specific item
Review Type Modifier adjusts based on the type of review (explained below)
6. Review Type Modifiers
Different review types have different difficulty levels and receive appropriate modifiers:
Multiple choice: 0.9 (slightly shorter intervals as it's easier)
Typing full answer: 1.1 (slightly longer intervals as it demonstrates stronger recall)
Listening comprehension: 1.0 (standard interval)
This ensures that easier review types don't artificially inflate your perceived mastery.
7. Handling Missed Items
When an item is missed:
It doesn't completely restart (unlike DuoCards and Memrise)
Instead, it goes back 2 steps in the interval sequence
The Personal Difficulty Factor increases (making future intervals shorter)
A "priority flag" is added to ensure it appears early in the next review session
8. Streak Bonuses
To motivate consistent practice:
Items reviewed on schedule (not late) receive a small bonus (5% interval increase)
Consecutive "Quick" answers (3+) receive an additional bonus (10% interval increase)
These bonuses are capped to prevent intervals from growing too quickly
9. Maximum Interval Cap
Unlike Anki which can extend intervals indefinitely:
Maximum interval is capped at 120 days (4 months)
This ensures no item is forgotten completely, while still being efficient
10. Smart Review Mixing
During each review session:
Items are presented in a mix of different review types
Difficult items (higher PDF) are tested more often with typing (the most effective method)
Easy items (lower PDF) may be tested more often with multiple choice
This optimizes learning efficiency while maintaining engagement
11. Adaptive Session Length
The algorithm suggests optimal daily review session length based on your learning history
As your vocabulary grows, the system prioritizes items most at risk of being forgotten
This prevents overwhelming users with too many reviews as their collection grows
12. Implementation in Flutter
The algorithm is designed to be lightweight and efficient:
All calculations can be performed client-side without server requirements
Data storage needs are minimal (item ID, current interval, PDF, last review date, next review date)
The system can function offline and sync when connection is restored