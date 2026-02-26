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

    // TODO: implement in Task 2b
    // For now, create a minimal summary so the service compiles
    final summary = WeeklySummary(
      id: _uuid.v4(),
      weekStart: weekStart,
      weekEnd: weekEnd,
      checkInCount: weekEntries.length,
      daysWithEntries: _calculateDaysWithEntries(weekEntries),
      avgMood: weekEntries.isEmpty ? 0.5 : _calculateAvgMood(weekEntries),
      moodTrend: 'stable',
      mostFeltMood: 'Calm',
      takeaway: 'Another week, another set of data points about you. Keep going.',
      createdAt: DateTime.now(),
    );

    await _summaries.put(summary.id, summary);
    return summary;
  }

  /// Calculate the start of the week (Monday) for a given date
  DateTime _startOfWeek(DateTime date) {
    final weekday = date.weekday;
    final mondayDate = date.subtract(Duration(days: weekday - 1));
    return DateTime(mondayDate.year, mondayDate.month, mondayDate.day);
  }

  /// Helper: Calculate days with entries
  int _calculateDaysWithEntries(List<Entry> entries) {
    final uniqueDays = <String>{};
    for (final entry in entries) {
      final dayKey = '${entry.createdAt.year}-${entry.createdAt.month}-${entry.createdAt.day}';
      uniqueDays.add(dayKey);
    }
    return uniqueDays.length;
  }

  /// Helper: Calculate average mood
  double _calculateAvgMood(List<Entry> entries) {
    if (entries.isEmpty) return 0.5;
    final sum = entries.fold<double>(0.0, (sum, entry) => sum + entry.moodValue);
    return sum / entries.length;
  }
}
