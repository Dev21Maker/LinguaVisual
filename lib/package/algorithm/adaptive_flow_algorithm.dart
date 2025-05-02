import 'dart:math';

class SrsItem {
  final String id;
  int? box; // Nullable indicates long-term
  double pdf;
  int baseIndex;
  int nextReview; // Epoch milliseconds
  double lastInterval; // Milliseconds
  int streakQuick;
  int timesSeenToday;
  String lastSeenDay; // YYYY-MM-DD UTC

  SrsItem({
    required this.id,
    this.box,
    required this.pdf,
    required this.baseIndex,
    required this.nextReview,
    required this.lastInterval,
    required this.streakQuick,
    required this.timesSeenToday,
    required this.lastSeenDay,
  });

  // Consider adding methods for serialization/deserialization if needed
  // e.g., toJson(), fromJson()
}


class SRS {
  Map<String, SrsItem> items = {};

  // ───── CONFIG (milliseconds) ─────
  final List<int> boxWait;
  final List<int> baseSteps;
  final int maxCap;
  final Map<String, double> typeMod;
  final int dailyLimit;
  final int coolHour; // UTC Hour
  final int loadWindow; // Milliseconds
  final int loadScale;
  final double loadSlope;

  SRS({
    List<int>? boxWait,
    List<int>? baseSteps,
    int? maxCap,
    Map<String, double>? typeMod,
    int? dailyLimit,
    int? coolHour,
    int? loadWindow,
    int? loadScale,
    double? loadSlope,
  }) : boxWait =
           boxWait ?? [30000, 120000, 600000, 3600000, 86400000, 259200000, 604800000], // 7 boxes
       baseSteps =
           baseSteps ??
           [
             3600000, // 1h
             28800000, // 8h
             86400000, // 1d
             172800000, // 2d
             345600000, // 4d
             604800000, // 7d
             1209600000, // 14d
             2592000000, // 30d
             5184000000, // 60d
             10368000000, // 120d
           ],
       maxCap = maxCap ?? 10368000000, // 120 d
       typeMod = typeMod ?? {'mc': 0.9, 'typing': 1.1, 'listening': 1.0},
       dailyLimit = dailyLimit ?? 7,
       coolHour = coolHour ?? 9, // 09:00 UTC next day
       loadWindow = loadWindow ?? 14400000, // 4 h
       loadScale = loadScale ?? 50, // cards
       loadSlope = loadSlope ?? 0.25 { // coefficient in log10 formula
    // Validate config if necessary
    assert(this.boxWait.isNotEmpty, "boxWait cannot be empty");
    assert(this.baseSteps.isNotEmpty, "baseSteps cannot be empty");
  }

  // ───────── utilities ─────────
  T clamp<T extends num>(T v, T minVal, T maxVal) =>
      max(minVal, min(maxVal, v));
      
  // Changed from seconds to milliseconds to match the rest of the application
  int now() => DateTime.now().millisecondsSinceEpoch; // Milliseconds
  
  String utcDateStr(int epochMilliseconds) => DateTime.fromMillisecondsSinceEpoch(
    epochMilliseconds,
    isUtc: true,
  ).toIso8601String().substring(0, 10); // YYYY-MM-DD

  // ───────── PUBLIC API ─────────
  SrsItem addItem(String id, {int? now}) {
    if (items.containsKey(id)) {
      throw ArgumentError("Item '$id' already exists");
    }
    final currentTime = now ?? this.now();
    final newItem = SrsItem(
      id: id,
      box: 0, // Start in the first Leitner box
      pdf: 1.0,
      baseIndex: 0, // Not used until graduation
      nextReview: currentTime + boxWait[0],
      lastInterval: boxWait[0].toDouble(),
      streakQuick: 0,
      timesSeenToday: 0,
      lastSeenDay: utcDateStr(currentTime),
    );
    items[id] = newItem;
    return newItem;
  }

  List<SrsItem> dueItems({int? now}) {
    final currentTime = now ?? this.now();
    return items.values.where((i) => i.nextReview <= currentTime).toList();
  }

  SrsItem? getItem(String id) {
    // Return a copy to prevent accidental modification? Dart objects are references.
    // For this app's structure it might be fine, but be aware.
    return items[id];
  }

  SrsItem processAnswer(
    String id,
    String resp, { // e.g., 'quick', 'got', 'missed'
    String reviewType = 'mc',
    int? now,
  }) {
    final itm = items[id];
    if (itm == null) {
      throw ArgumentError("Item '$id' not found");
    }
    final currentTime = now ?? this.now();

    // Process based on current stage (Leitner box or long-term)
    if (itm.box != null) {
      _handleLeitner(itm, resp, currentTime);
    } else {
      _handleLongTerm(itm, resp, reviewType, currentTime);
    }

    // Apply daily limit/cooldown AFTER scheduling the next review
    _updateDailyCount(itm, currentTime);
    _applyCoolDownIfNeeded(itm, currentTime);
    return itm;
  }

  // ───────── private: 7‑box Leitner ─────────
  void _handleLeitner(SrsItem itm, String resp, int now) {
    final bool correct = (resp == 'quick' || resp == 'got');

    if (correct) {
      final int hop = (resp == 'quick') ? 2 : 1; // quick ⇒ double promotion
      // Use clamp to ensure box stays within bounds and calculate in a single step
      itm.box = clamp(itm.box! + hop, 0, boxWait.length - 1);

      // Graduation check - only graduate when in the last box (not when exceeding it)
      if (itm.box == boxWait.length - 1) {
        itm.box = null; // Switch to long-term
        itm.baseIndex = 0; // Start at the first base step
        final double interval = baseSteps[0] * itm.pdf; // Initial long-term interval
        itm.lastInterval = interval;
        itm.nextReview = now + interval.round();
        itm.streakQuick = 0; // Reset streak on graduation
        return; // Don't schedule Leitner wait
      }
    } else {
      // Miss ⇒ demote once (not below 0)
      itm.box = clamp(itm.box! - 1, 0, boxWait.length - 1);
    }

    // Schedule next wait inside session using the current box index
    final int wait = boxWait[itm.box!];
    itm.lastInterval = wait.toDouble(); // Store the Leitner wait as last interval
    itm.nextReview = now + wait;
  }


  // ───────── private: AdaptiveFlow long‑term ─────────
  void _handleLongTerm(SrsItem itm, String resp, String reviewType, int now) {
    final double typeM = typeMod[reviewType] ?? 1.0;
    final bool correct = (resp == 'quick' || resp == 'got');

    // 1️⃣ PDF adjust
    if (resp == 'quick') {
      itm.pdf = clamp(itm.pdf + 0.15, 0.5, 2.0);
      itm.streakQuick += 1;
    } else if (resp == 'missed') {
      itm.pdf = clamp(itm.pdf - 0.20, 0.5, 2.0);
      itm.streakQuick = 0; // Reset streak on miss
    } else { // 'got'
      // PDF doesn't change explicitly for 'got', but streak resets
      itm.streakQuick = 0;
    }

    // 2️⃣ Ladder index movement
    if (correct) {
      itm.baseIndex = clamp(itm.baseIndex + 1, 0, baseSteps.length - 1);
    } else { // missed
      itm.baseIndex = clamp(itm.baseIndex - 2, 0, baseSteps.length - 1); // Go back 2 steps, floor 0
    }

    // 3️⃣ Compute raw interval
    double interval = baseSteps[itm.baseIndex] * itm.pdf * typeM;

    // 4️⃣ Apply bonuses/modifiers

    // On-time bonus (allow lateness up to lastInterval)
    // Only apply if it was actually due (now >= itm.nextReview)
    if (now >= itm.nextReview && (now - itm.nextReview <= itm.lastInterval)) {
        interval *= 1.05;
    }

    // Streak bonus (apply *after* on-time bonus, only if correct)
    // Apply every 3 *consecutive* quick answers
    if (correct && itm.streakQuick > 0 && itm.streakQuick % 3 == 0) {
        interval *= 1.10;
    }


    // 5️⃣ Load‑aware stretch
    interval *= _loadFactor(now);

    // 6️⃣ Caps - Use the combined approach from srs_web_app for better results
    // Apply both soft cap and hard cap in a single operation
    interval = min(interval, min(itm.lastInterval * 2.5, maxCap.toDouble()));

    // Ensure minimum interval (e.g., prevent 0 or negative interval after penalties)
    interval = max(interval, 3600000.0); // Minimum 1 hour interval

    itm.lastInterval = interval;
    itm.nextReview = now + interval.round();
  }

  // ───────── private: load factor ─────────
  double _loadFactor(int now) {
    // Consider only items in the long-term phase for load calculation?
    // Or all items? Let's stick to all items for now as in the original code.
    final int dueNow = items.values.where((i) => i.nextReview <= now).length;
    final int dueSoon = items.values.where(
      (i) => i.nextReview > now && i.nextReview <= now + loadWindow,
    ).length;
    final int load = dueNow + dueSoon;

    // Avoid log(0) or negative results if load is very small
    if (load <= 0) return 1.0;

    // Calculate factor: 1 + slope * log10(1 + load / scale)
    // dart:math log is natural log (ln), so use log(x) / ln10 for log10(x)
    double factor = 1 + loadSlope * (log(1 + load / loadScale) / ln10);

    // Clamp factor to prevent excessive stretching (e.g., max 2x stretch)
    return clamp(factor, 1.0, 2.0);
  }

   // ───────── private: daily cap / cool‑down ─────────

  // Separated steps for clarity: update count, then apply cool-down if needed.
  void _updateDailyCount(SrsItem itm, int now) {
    final String today = utcDateStr(now);
    if (itm.lastSeenDay != today) {
      itm.lastSeenDay = today;
      itm.timesSeenToday = 0; // Reset count for the new day
    }
    itm.timesSeenToday++; // Increment count for this interaction
  }

  void _applyCoolDownIfNeeded(SrsItem itm, int now) {
    if (itm.timesSeenToday >= dailyLimit) {
      // Calculate the start of the *next* UTC day at coolHour
      final currentUtc = DateTime.fromMillisecondsSinceEpoch(now, isUtc: true);
      // Create tomorrow at coolHour using .add(Duration) instead of manually setting day+1
      final tomorrow = currentUtc.add(const Duration(days: 1));
      final tomorrowUtc = DateTime.utc(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          coolHour, // Set to the cool-down hour
          0, 0, 0  // Zero out minutes, seconds, ms
      );
      final int targetEpoch = tomorrowUtc.millisecondsSinceEpoch;

      // Push the review time to at least the cool-down time tomorrow.
      // If the calculated nextReview was already later, keep the later time.
      itm.nextReview = max(itm.nextReview, targetEpoch);
    }
  }

}
