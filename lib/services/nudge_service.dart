import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/nudge.dart';
import '../models/entry.dart';
import 'direction_service.dart';
import 'storage_service.dart';

class NudgeService {
  static final NudgeService instance = NudgeService._();
  NudgeService._();

  final _uuid = const Uuid();
  Nudge? _pendingNudge;
  bool _isChecking = false;

  /// Check for dormant direction nudges on app open
  Future<Nudge?> checkOnAppOpen() async {
    if (_isChecking) return null;
    _isChecking = true;

    try {
      final dormantDirections = DirectionService.instance
          .getDormantDirections();

      if (dormantDirections.isEmpty) return null;

      // Check first dormant direction
      final direction = dormantDirections.first;
      final cooldownKey = 'dormant_${direction.id}';

      if (_isOnCooldown(cooldownKey)) return null;

      return Nudge(
        id: _uuid.v4(),
        type: NudgeType.dormantDirection,
        message:
            "It's been a while since you connected with ${direction.title}. Still on your mind?",
        actionText: "Reconnect →",
        directionId: direction.id,
      );
    } finally {
      _isChecking = false;
    }
  }

  /// Check for streak milestones and mood pattern nudges after check-in
  Future<Nudge?> checkPostCheckIn(int currentStreak) async {
    if (_isChecking) return null;
    _isChecking = true;

    try {
      // Priority 1: Streak milestones
      const milestones = [3, 7, 14, 30, 60, 100];

      if (milestones.contains(currentStreak)) {
        final cooldownKey = 'streak_$currentStreak';
        if (!_isOnCooldown(cooldownKey)) {
          final message = _streakMessage(currentStreak);
          return Nudge(
            id: _uuid.v4(),
            type: NudgeType.streakCelebration,
            message: message,
          );
        }
      }

      // Priority 2: Mood patterns
      final now = DateTime.now();
      final fourteenDaysAgo = now.subtract(const Duration(days: 14));
      final entries = await StorageService.instance.getEntriesForPeriod(
        fourteenDaysAgo,
        now,
      );

      // Need at least 7 entries to detect patterns
      if (entries.length < 7) return null;

      final cooldownKey = 'mood_pattern';
      if (_isOnCooldown(cooldownKey)) return null;

      // Calculate day-of-week pattern
      final dayPattern = _calculateDayOfWeekPattern(entries);
      if (dayPattern.isEmpty) return null;

      final overallAvg =
          entries.map((e) => e.moodValue).reduce((a, b) => a + b) /
          entries.length;
      final (bestDay, worstDay) = _findBestWorstDays(dayPattern, overallAvg);

      // Positive pattern (best day found)
      if (bestDay != null) {
        final bestAvg = dayPattern[bestDay]!;
        final percentDiff = ((bestAvg - overallAvg) / overallAvg * 100).round();
        final dayName = _dayName(bestDay);

        return Nudge(
          id: _uuid.v4(),
          type: NudgeType.moodPattern,
          message:
              "Your mood is $percentDiff% higher on ${dayName}s. What makes them work?",
        );
      }

      // Negative pattern (worst day found, no best)
      if (worstDay != null) {
        final dayName = _dayName(worstDay);

        return Nudge(
          id: _uuid.v4(),
          type: NudgeType.moodPattern,
          message:
              "${dayName}s seem harder lately. Consider planning something gentle.",
        );
      }

      return null;
    } finally {
      _isChecking = false;
    }
  }

  /// Store a nudge for Home screen to pick up
  void setPendingNudge(Nudge nudge) {
    _pendingNudge = nudge;
  }

  /// Returns and clears pending nudge
  Nudge? consumePendingNudge() {
    final nudge = _pendingNudge;
    _pendingNudge = null;
    return nudge;
  }

  /// Dismiss a nudge and store cooldown timestamp
  Future<void> dismissNudge(String cooldownKey) async {
    final settingsBox = Hive.box('settings');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await settingsBox.put('nudge_dismissed_$cooldownKey', timestamp);
  }

  /// Check if cooldown period has elapsed
  bool _isOnCooldown(String cooldownKey) {
    final settingsBox = Hive.box('settings');
    final timestamp = settingsBox.get('nudge_dismissed_$cooldownKey');

    if (timestamp == null) return false;

    final dismissedAt = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final now = DateTime.now();

    // Determine cooldown days based on key prefix
    final cooldownDays = cooldownKey.startsWith('dormant_')
        ? 7
        : cooldownKey.startsWith('streak_')
        ? 30
        : 14;

    final cooldownEnd = dismissedAt.add(Duration(days: cooldownDays));
    return now.isBefore(cooldownEnd);
  }

  /// Get streak milestone message
  String _streakMessage(int streak) {
    switch (streak) {
      case 3:
        return "3 days in a row. You're building something.";
      case 7:
        return "A full week. You showed up.";
      case 14:
        return "Two weeks of showing up. Consistency matters.";
      case 30:
        return "30 days. This is becoming a practice.";
      case 60:
        return "60 days of showing up. You're here.";
      case 100:
        return "100 days. You've built something real.";
      default:
        return "You showed up.";
    }
  }

  /// Calculate average mood per weekday
  Map<int, double> _calculateDayOfWeekPattern(List<Entry> entries) {
    final dayTotals = <int, double>{};
    final dayCounts = <int, int>{};

    for (final entry in entries) {
      final weekday = entry.createdAt.weekday; // 1=Mon to 7=Sun
      dayTotals[weekday] = (dayTotals[weekday] ?? 0.0) + entry.moodValue;
      dayCounts[weekday] = (dayCounts[weekday] ?? 0) + 1;
    }

    final pattern = <int, double>{};
    for (final weekday in dayTotals.keys) {
      pattern[weekday] = dayTotals[weekday]! / dayCounts[weekday]!;
    }

    return pattern;
  }

  /// Find best and worst days (15% threshold)
  (int?, int?) _findBestWorstDays(Map<int, double> pattern, double overallAvg) {
    if (pattern.isEmpty) return (null, null);

    final threshold = overallAvg * 0.15;

    int? bestDay;
    double bestAvg = 0.0;
    int? worstDay;
    double worstAvg = 1.0;

    for (final entry in pattern.entries) {
      final weekday = entry.key;
      final avg = entry.value;

      // Best day: highest avg, must be >= 15% above overall
      if (avg >= overallAvg + threshold && avg > bestAvg) {
        bestDay = weekday;
        bestAvg = avg;
      }

      // Worst day: lowest avg, must be >= 15% below overall
      if (avg <= overallAvg - threshold && avg < worstAvg) {
        worstDay = weekday;
        worstAvg = avg;
      }
    }

    return (bestDay, worstDay);
  }

  /// Convert weekday int to name
  String _dayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }
}
