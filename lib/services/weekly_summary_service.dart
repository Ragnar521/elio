import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/weekly_summary.dart';
import '../models/entry.dart';
import 'storage_service.dart';
import 'insights_service.dart';
import 'direction_service.dart';
import 'reflection_service.dart';

class WeeklySummaryService {
  WeeklySummaryService._();

  static final WeeklySummaryService instance = WeeklySummaryService._();

  static const _boxName = 'weekly_summaries';
  Box<WeeklySummary>? _box;
  final _uuid = const Uuid();

  /// Initialize service - register adapter and open Hive box
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(WeeklySummaryAdapter().typeId)) {
      Hive.registerAdapter(WeeklySummaryAdapter());
    }
    _box = await Hive.openBox<WeeklySummary>(_boxName);
  }

  Box<WeeklySummary> get _summaries {
    final box = _box;
    if (box == null) {
      throw StateError('WeeklySummaryService not initialized. Call init() first.');
    }
    return box;
  }

  /// Check if there's an unviewed summary for the previous completed week
  Future<bool> hasUnviewedSummary() async {
    final now = DateTime.now();
    final currentWeekStart = _startOfWeek(now);
    final previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));

    // Look for existing summary for previous week
    final summary = getSummaryForWeek(previousWeekStart);
    return summary != null && !summary.hasBeenViewed;
  }

  /// Get or generate summary for the most recent completed week
  Future<WeeklySummary?> getOrGenerateCurrentSummary() async {
    final now = DateTime.now();
    final currentWeekStart = _startOfWeek(now);
    final previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));

    // Check if summary already exists
    final existingSummary = getSummaryForWeek(previousWeekStart);
    if (existingSummary != null) {
      return existingSummary;
    }

    // Check if there are entries in that week
    final previousWeekEnd = previousWeekStart.add(const Duration(days: 7));
    final entries = await StorageService.instance.getEntriesForPeriod(
      previousWeekStart,
      previousWeekEnd,
    );

    // Only generate if at least 1 entry exists
    if (entries.isEmpty) {
      return null;
    }

    // Generate new summary
    return await _generateSummary(previousWeekStart);
  }

  /// Mark a summary as viewed
  Future<void> markAsViewed(String summaryId) async {
    final summary = _summaries.get(summaryId);
    if (summary != null) {
      final updated = WeeklySummary(
        id: summary.id,
        weekStart: summary.weekStart,
        weekEnd: summary.weekEnd,
        checkInCount: summary.checkInCount,
        daysWithEntries: summary.daysWithEntries,
        avgMood: summary.avgMood,
        moodTrend: summary.moodTrend,
        mostFeltMood: summary.mostFeltMood,
        bestMoodDay: summary.bestMoodDay,
        bestMoodValue: summary.bestMoodValue,
        bestMoodWord: summary.bestMoodWord,
        directionSummaries: summary.directionSummaries,
        topDirectionId: summary.topDirectionId,
        standoutReflectionAnswers: summary.standoutReflectionAnswers,
        takeaway: summary.takeaway,
        createdAt: summary.createdAt,
        viewedAt: DateTime.now(),
      );
      await _summaries.put(summaryId, updated);
    }
  }

  /// Get all summaries sorted by most recent first
  List<WeeklySummary> getAllSummaries() {
    final summaries = _summaries.values.toList();
    summaries.sort((a, b) => b.weekStart.compareTo(a.weekStart));
    return summaries;
  }

  /// Get summary for a specific week by weekStart date
  WeeklySummary? getSummaryForWeek(DateTime weekStart) {
    // Strip time component for comparison
    final targetDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    try {
      return _summaries.values.firstWhere((summary) {
        final summaryDate = DateTime(
          summary.weekStart.year,
          summary.weekStart.month,
          summary.weekStart.day,
        );
        return summaryDate == targetDate;
      });
    } catch (_) {
      return null;
    }
  }

  /// Generate summary for a specific week (internal method)
  Future<WeeklySummary> _generateSummary(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));

    // Get entries for the week
    final weekEntries = await StorageService.instance.getEntriesForPeriod(
      weekStart,
      weekEnd,
    );

    // Get all entries for InsightsService context
    final allEntries = await StorageService.instance.getAllEntries();
    final streak = await StorageService.instance.getCurrentStreak();
    final longestStreak = await StorageService.instance.getLongestStreak();

    // Get insights for the week
    final insights = await InsightsService.getInsightsForPeriod(
      now: weekEnd,
      allEntries: allEntries,
      period: InsightsPeriod.week,
      offset: -1,
      streak: streak,
      longestStreakAllTime: longestStreak,
    );

    // Calculate best mood day from week entries
    String? bestMoodDay;
    double? bestMoodValue;
    String? bestMoodWord;
    if (weekEntries.isNotEmpty) {
      final bestEntry = weekEntries.reduce((a, b) => a.moodValue > b.moodValue ? a : b);
      bestMoodValue = bestEntry.moodValue;
      bestMoodWord = bestEntry.moodWord;

      // Get weekday name
      final weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      bestMoodDay = weekdayNames[bestEntry.createdAt.weekday - 1];
    }

    // Build direction summaries
    List<Map<String, dynamic>>? directionSummaries;
    String? topDirectionId;
    final directions = DirectionService.instance.getActiveDirections();

    if (directions.isNotEmpty) {
      directionSummaries = [];
      double highestMoodDifference = -999.0;

      for (final direction in directions) {
        // Calculate weekly connections for this specific week
        final weeklyConnections = await _countWeeklyConnections(direction.id, weekStart, weekEnd);

        // Get mood correlation stats
        final stats = await DirectionService.instance.getStats(direction.id);

        // Build serialized direction data
        directionSummaries.add({
          'directionId': direction.id,
          'title': direction.title,
          'iconAsset': direction.iconAsset,
          'weeklyConnections': weeklyConnections,
          'avgMoodWhenConnected': stats.avgMoodWhenConnected,
          'moodDifference': stats.moodDifference,
        });

        // Track top direction (highest positive correlation >= 0.1)
        if (stats.moodDifference >= 0.1 && stats.moodDifference > highestMoodDifference) {
          highestMoodDifference = stats.moodDifference;
          topDirectionId = direction.id;
        }
      }
    }

    // Get standout reflections
    final standoutReflections = await _selectStandoutReflections(weekEntries);

    // Generate takeaway
    final takeaway = _generateTakeaway(
      insights,
      weekEntries,
      directionSummaries,
      bestMoodDay,
      bestMoodWord,
    );

    // Determine mood trend
    String moodTrend = 'stable';
    if (insights.trendUp) {
      moodTrend = 'up';
    } else if (insights.trendDown) {
      moodTrend = 'down';
    }

    final summary = WeeklySummary(
      id: _uuid.v4(),
      weekStart: weekStart,
      weekEnd: weekEnd,
      checkInCount: insights.checkInCount,
      daysWithEntries: insights.daysWithEntries,
      avgMood: insights.avgMood,
      moodTrend: moodTrend,
      mostFeltMood: insights.mostFelt,
      bestMoodDay: bestMoodDay,
      bestMoodValue: bestMoodValue,
      bestMoodWord: bestMoodWord,
      directionSummaries: directionSummaries,
      topDirectionId: topDirectionId,
      standoutReflectionAnswers: standoutReflections,
      takeaway: takeaway,
      createdAt: DateTime.now(),
    );

    await _summaries.put(summary.id, summary);
    return summary;
  }

  /// Count connections for a specific week period (not the generic "last 7 days from now")
  Future<int> _countWeeklyConnections(String directionId, DateTime weekStart, DateTime weekEnd) async {
    // Get all connected entries for this direction
    final connectedEntries = await DirectionService.instance.getConnectedEntries(directionId);

    // Filter to only entries within the week range
    final weekConnections = connectedEntries.where((entry) =>
        !entry.createdAt.isBefore(weekStart) &&
        entry.createdAt.isBefore(weekEnd));

    return weekConnections.length;
  }

  /// Select 1-2 standout reflection answers from the week
  Future<List<Map<String, dynamic>>?> _selectStandoutReflections(List<Entry> entries) async {
    // Collect all reflection answer IDs
    final allAnswerIds = <String>[];
    for (final entry in entries) {
      if (entry.reflectionAnswerIds != null) {
        allAnswerIds.addAll(entry.reflectionAnswerIds!);
      }
    }

    if (allAnswerIds.isEmpty) return null;

    // Fetch all answers
    final answers = ReflectionService.instance.getAnswersByIds(allAnswerIds);
    if (answers.isEmpty) return null;

    // Sort by length (longer = more thoughtful)
    answers.sort((a, b) => b.answer.length.compareTo(a.answer.length));

    // Select standouts
    final standouts = <Map<String, dynamic>>[];

    // First standout: longest answer
    standouts.add({
      'questionText': answers.first.questionText,
      'answer': answers.first.answer,
    });

    // Second standout: different question than first, if available
    if (answers.length > 1) {
      for (var i = 1; i < answers.length; i++) {
        if (answers[i].questionText != answers.first.questionText) {
          standouts.add({
            'questionText': answers[i].questionText,
            'answer': answers[i].answer,
          });
          break;
        }
      }
    }

    return standouts;
  }

  /// Generate encouraging takeaway message based on week data
  String _generateTakeaway(
    InsightsData insights,
    List<Entry> entries,
    List<Map<String, dynamic>>? dirSummaries,
    String? bestMoodDay,
    String? bestMoodWord,
  ) {
    final checkIns = insights.checkInCount;
    final avgMood = insights.avgMood;
    final reflectionRate = insights.reflectionRate;
    final hasDirections = dirSummaries != null && dirSummaries.isNotEmpty;

    // Count total direction connections
    int totalDirConnections = 0;
    if (hasDirections) {
      for (final dir in dirSummaries) {
        totalDirConnections += dir['weeklyConnections'] as int;
      }
    }

    // Priority-based template selection

    // 1. Perfect week (7 check-ins)
    if (checkIns == 7) {
      return 'Seven for seven. You didn\'t miss a day. That\'s dedication.';
    }

    // 2. Improving trend + reflections
    if (insights.trendUp && reflectionRate > 0.5) {
      return 'Your reflections this week show real self-awareness. That\'s powerful.';
    }

    // 3. Low mood + showed up (avgMood < 0.35, checkIns >= 3)
    if (avgMood < 0.35 && checkIns >= 3) {
      return 'Even on harder weeks, you kept checking in. That takes courage.';
    }

    // 4. Low mood + reflections (avgMood < 0.35)
    if (avgMood < 0.35 && reflectionRate > 0) {
      return 'Tough weeks are worth reflecting on. You did that — and that matters.';
    }

    // 5. High mood + streak (avgMood >= 0.6, checkIns >= 5)
    if (avgMood >= 0.6 && checkIns >= 5) {
      return 'What a week! You showed up $checkIns days and your mood was on the rise. Keep that momentum going.';
    }

    // 6. High mood + reflections (avgMood >= 0.6)
    if (avgMood >= 0.6 && reflectionRate > 0.5) {
      return 'Your reflections this week show real self-awareness. That\'s powerful.';
    }

    // 7. Best day reference (bestMoodDay != null)
    if (bestMoodDay != null && bestMoodWord != null) {
      return 'Your best mood was $bestMoodDay when you felt $bestMoodWord. What made that day special?';
    }

    // 8. Direction engagement (dirSummaries not empty)
    if (hasDirections && totalDirConnections > 0) {
      return 'You connected $totalDirConnections entries to your directions this week. That\'s intentional living.';
    }

    // 9. Reflection-heavy (reflection rate > 0.7)
    if (reflectionRate > 0.7) {
      final reflectionDays = insights.reflectionDays;
      return 'You reflected on $reflectionDays days this week. Self-awareness is a superpower.';
    }

    // 10. Improving trend
    if (insights.trendUp) {
      return 'Your mood trended upward this week. Something\'s working — trust it.';
    }

    // 11. Stable mood
    if (insights.stable) {
      return 'Consistency is its own kind of strength. You showed up $checkIns times this week.';
    }

    // 12. One entry only
    if (checkIns == 1) {
      return 'One check-in is still a check-in. You showed up, and that counts.';
    }

    // 13. Default
    return 'Another week, another set of data points about you. Keep going.';
  }

  /// Calculate the start of the week (Monday) for a given date
  DateTime _startOfWeek(DateTime date) {
    final weekday = date.weekday;
    final mondayDate = date.subtract(Duration(days: weekday - 1));
    return DateTime(mondayDate.year, mondayDate.month, mondayDate.day);
  }
}
