import 'entry.dart';

/// Statistics for a direction
class DirectionStats {
  final int totalConnections;
  final int monthlyConnections;
  final int monthlyTarget; // always 10 for progress bar
  final double avgMoodWhenConnected;
  final double overallAvgMood;
  final List<Entry> recentEntries; // last 5 connected entries

  DirectionStats({
    required this.totalConnections,
    required this.monthlyConnections,
    this.monthlyTarget = 10,
    required this.avgMoodWhenConnected,
    required this.overallAvgMood,
    required this.recentEntries,
  });

  /// Mood difference (positive = better mood when connected)
  double get moodDifference => avgMoodWhenConnected - overallAvgMood;

  /// Progress percentage for monthly bar (0.0 - 1.0)
  double get monthlyProgress =>
      (monthlyConnections / monthlyTarget).clamp(0.0, 1.0);

  /// Whether this direction correlates with higher mood
  bool get hasPositiveCorrelation => moodDifference >= 0.1;

  /// Whether this direction correlates with lower mood
  bool get hasNegativeCorrelation => moodDifference <= -0.1;
}
