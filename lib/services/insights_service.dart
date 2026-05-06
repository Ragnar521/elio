import 'dart:math';

import 'package:flutter/material.dart';

import '../models/entry.dart';
import 'direction_service.dart';

enum InsightsPeriod { week, month }

class InsightItem {
  const InsightItem(this.icon, this.text);

  final IconData icon;
  final String text;
}

class InsightsData {
  InsightsData({
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.daysInPeriod,
    required this.entries,
    required this.checkInCount,
    required this.daysWithEntries,
    required this.streak,
    required this.mostFelt,
    required this.avgMood,
    required this.stdDev,
    required this.trendUp,
    required this.trendDown,
    required this.stable,
    required this.volatile,
    required this.weekendsBetter,
    required this.mondaysWorse,
    required this.betterThanLastMonth,
    required this.worseThanLastMonth,
    required this.insightText,
    // New fields
    required this.reflectionDays,
    required this.reflectionRate,
    required this.longestStreakAllTime,
    required this.longestStreakInPeriod,
    this.previousPeriodAvg,
    this.previousPeriodCheckIns,
    this.moodChangeVsPrevious,
    this.checkInChangeVsPrevious,
    required this.dayOfWeekAverages,
    this.bestDay,
    this.worstDay,
    required this.insights,
    required this.patternInsight,
    required this.mostFeltCount,
  });

  final InsightsPeriod period;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int daysInPeriod;
  final List<Entry> entries;
  final int checkInCount;
  final int daysWithEntries;
  final int streak;
  final String mostFelt;
  final int mostFeltCount;
  final double avgMood;
  final double stdDev;
  final bool trendUp;
  final bool trendDown;
  final bool stable;
  final bool volatile;
  final bool weekendsBetter;
  final bool mondaysWorse;
  final bool betterThanLastMonth;
  final bool worseThanLastMonth;
  final String insightText;

  // New fields
  final int reflectionDays;
  final double reflectionRate;
  final int longestStreakAllTime;
  final int longestStreakInPeriod;
  final double? previousPeriodAvg;
  final int? previousPeriodCheckIns;
  final double? moodChangeVsPrevious;
  final int? checkInChangeVsPrevious;
  final Map<int, double> dayOfWeekAverages;
  final int? bestDay;
  final int? worstDay;
  final List<InsightItem> insights;
  final String patternInsight;
}

class InsightsService {
  static Future<InsightsData> getInsightsForPeriod({
    required DateTime now,
    required List<Entry> allEntries,
    required InsightsPeriod period,
    required int offset,
    required int streak,
    required int longestStreakAllTime,
  }) async {
    final periodRange = _periodRange(now, period, offset);
    final periodEntries = _entriesInRange(allEntries, periodRange.start, periodRange.end);
    final daysInPeriod = periodRange.end.difference(periodRange.start).inDays;
    final daysWithEntries = _daysWithEntries(periodEntries);
    final checkInCount = periodEntries.length;
    final mostFeltResult = _mostFelt(periodEntries);
    final avgMood = _average(periodEntries.map((entry) => entry.moodValue).toList());
    final stdDev = _standardDeviation(periodEntries.map((entry) => entry.moodValue).toList());
    final trend = _trend(periodEntries, periodRange.start, daysInPeriod, period);
    final stable = stdDev > 0 && stdDev < 0.15;
    final volatile = stdDev > 0.3;
    final weekendsBetter = _weekendsBetter(periodEntries, avgMood);
    final mondaysWorse = _mondaysWorse(periodEntries, avgMood);
    final monthlyComparison = _monthlyComparison(
      allEntries,
      period,
      periodRange.start,
      avgMood,
    );

    // New calculations
    final reflectionStats = _calculateReflectionStats(periodEntries);
    final dayPattern = _calculateDayOfWeekPattern(periodEntries);
    final bestWorstDays = _findBestWorstDays(dayPattern);
    final longestInPeriod = _calculateLongestStreakInPeriod(periodEntries, periodRange.start, periodRange.end);

    // Comparison to previous period
    double? prevAvg;
    int? prevCheckIns;
    double? moodChange;
    int? checkInChange;

    final duration = periodRange.end.difference(periodRange.start);
    final prevStart = periodRange.start.subtract(duration).subtract(const Duration(days: 1));
    final prevEnd = periodRange.start.subtract(const Duration(days: 1));
    final prevEntries = _entriesInRange(allEntries, prevStart, prevEnd);

    if (prevEntries.isNotEmpty) {
      prevAvg = _average(prevEntries.map((entry) => entry.moodValue).toList());
      prevCheckIns = prevEntries.length;
      moodChange = prevAvg > 0 ? (avgMood - prevAvg) / prevAvg : null;
      checkInChange = checkInCount - prevEntries.length;
    }

    final insightText = _insightText(
      period: period,
      streak: streak,
      checkInCount: checkInCount,
      trendUp: trend.trendUp,
      trendDown: trend.trendDown,
      stable: stable,
      volatile: volatile,
      avgMood: avgMood,
      weekendsBetter: weekendsBetter,
      mondaysWorse: mondaysWorse,
      betterThanLastMonth: monthlyComparison.betterThanLast,
      worseThanLastMonth: monthlyComparison.worseThanLast,
    );

    // Generate 2-3 insights
    final insights = await _generateInsights(
      period: period,
      streak: streak,
      checkInCount: checkInCount,
      trendUp: trend.trendUp,
      trendDown: trend.trendDown,
      stable: stable,
      volatile: volatile,
      avgMood: avgMood,
      moodChangeVsPrevious: moodChange,
      reflectionDays: reflectionStats.$1,
      reflectionRate: reflectionStats.$2,
    );

    final patternInsight = _generatePatternInsight(bestWorstDays.$1, bestWorstDays.$2);

    return InsightsData(
      period: period,
      periodStart: periodRange.start,
      periodEnd: periodRange.end,
      daysInPeriod: daysInPeriod,
      entries: periodEntries,
      checkInCount: checkInCount,
      daysWithEntries: daysWithEntries,
      streak: streak,
      mostFelt: mostFeltResult.$1,
      mostFeltCount: mostFeltResult.$2,
      avgMood: avgMood,
      stdDev: stdDev,
      trendUp: trend.trendUp,
      trendDown: trend.trendDown,
      stable: stable,
      volatile: volatile,
      weekendsBetter: weekendsBetter,
      mondaysWorse: mondaysWorse,
      betterThanLastMonth: monthlyComparison.betterThanLast,
      worseThanLastMonth: monthlyComparison.worseThanLast,
      insightText: insightText,
      reflectionDays: reflectionStats.$1,
      reflectionRate: reflectionStats.$2,
      longestStreakAllTime: longestStreakAllTime,
      longestStreakInPeriod: longestInPeriod,
      previousPeriodAvg: prevAvg,
      previousPeriodCheckIns: prevCheckIns,
      moodChangeVsPrevious: moodChange,
      checkInChangeVsPrevious: checkInChange,
      dayOfWeekAverages: dayPattern,
      bestDay: bestWorstDays.$1,
      worstDay: bestWorstDays.$2,
      insights: insights,
      patternInsight: patternInsight,
    );
  }

  // Keep old method for backward compatibility temporarily
  static InsightsData buildSnapshot({
    required DateTime now,
    required List<Entry> allEntries,
    required InsightsPeriod period,
    required int offset,
    required int streak,
  }) {
    // Synchronous wrapper - will be replaced
    final periodRange = _periodRange(now, period, offset);
    final periodEntries = _entriesInRange(allEntries, periodRange.start, periodRange.end);
    final daysInPeriod = periodRange.end.difference(periodRange.start).inDays;
    final daysWithEntries = _daysWithEntries(periodEntries);
    final checkInCount = periodEntries.length;
    final mostFeltResult = _mostFelt(periodEntries);
    final avgMood = _average(periodEntries.map((entry) => entry.moodValue).toList());
    final stdDev = _standardDeviation(periodEntries.map((entry) => entry.moodValue).toList());
    final trend = _trend(periodEntries, periodRange.start, daysInPeriod, period);
    final stable = stdDev > 0 && stdDev < 0.15;
    final volatile = stdDev > 0.3;
    final weekendsBetter = _weekendsBetter(periodEntries, avgMood);
    final mondaysWorse = _mondaysWorse(periodEntries, avgMood);
    final monthlyComparison = _monthlyComparison(allEntries, period, periodRange.start, avgMood);

    final reflectionStats = _calculateReflectionStats(periodEntries);
    final dayPattern = _calculateDayOfWeekPattern(periodEntries);
    final bestWorstDays = _findBestWorstDays(dayPattern);
    final longestInPeriod = _calculateLongestStreakInPeriod(periodEntries, periodRange.start, periodRange.end);

    double? prevAvg;
    int? prevCheckIns;
    double? moodChange;
    int? checkInChange;

    final duration = periodRange.end.difference(periodRange.start);
    final prevStart = periodRange.start.subtract(duration).subtract(const Duration(days: 1));
    final prevEnd = periodRange.start.subtract(const Duration(days: 1));
    final prevEntries = _entriesInRange(allEntries, prevStart, prevEnd);

    if (prevEntries.isNotEmpty) {
      prevAvg = _average(prevEntries.map((entry) => entry.moodValue).toList());
      prevCheckIns = prevEntries.length;
      moodChange = prevAvg > 0 ? (avgMood - prevAvg) / prevAvg : null;
      checkInChange = checkInCount - prevEntries.length;
    }

    final insightText = _insightText(
      period: period,
      streak: streak,
      checkInCount: checkInCount,
      trendUp: trend.trendUp,
      trendDown: trend.trendDown,
      stable: stable,
      volatile: volatile,
      avgMood: avgMood,
      weekendsBetter: weekendsBetter,
      mondaysWorse: mondaysWorse,
      betterThanLastMonth: monthlyComparison.betterThanLast,
      worseThanLastMonth: monthlyComparison.worseThanLast,
    );

    // For buildSnapshot (sync), use empty insights list as fallback
    // This method should be deprecated in favor of getInsightsForPeriod
    final insights = <InsightItem>[];

    final patternInsight = _generatePatternInsight(bestWorstDays.$1, bestWorstDays.$2);

    return InsightsData(
      period: period,
      periodStart: periodRange.start,
      periodEnd: periodRange.end,
      daysInPeriod: daysInPeriod,
      entries: periodEntries,
      checkInCount: checkInCount,
      daysWithEntries: daysWithEntries,
      streak: streak,
      mostFelt: mostFeltResult.$1,
      mostFeltCount: mostFeltResult.$2,
      avgMood: avgMood,
      stdDev: stdDev,
      trendUp: trend.trendUp,
      trendDown: trend.trendDown,
      stable: stable,
      volatile: volatile,
      weekendsBetter: weekendsBetter,
      mondaysWorse: mondaysWorse,
      betterThanLastMonth: monthlyComparison.betterThanLast,
      worseThanLastMonth: monthlyComparison.worseThanLast,
      insightText: insightText,
      reflectionDays: reflectionStats.$1,
      reflectionRate: reflectionStats.$2,
      longestStreakAllTime: 0, // Will be passed properly in screen
      longestStreakInPeriod: longestInPeriod,
      previousPeriodAvg: prevAvg,
      previousPeriodCheckIns: prevCheckIns,
      moodChangeVsPrevious: moodChange,
      checkInChangeVsPrevious: checkInChange,
      dayOfWeekAverages: dayPattern,
      bestDay: bestWorstDays.$1,
      worstDay: bestWorstDays.$2,
      insights: insights,
      patternInsight: patternInsight,
    );
  }

  static _PeriodRange _periodRange(DateTime now, InsightsPeriod period, int offset) {
    final date = DateTime(now.year, now.month, now.day);
    if (period == InsightsPeriod.week) {
      final start = _startOfWeek(date).add(Duration(days: offset * 7));
      return _PeriodRange(start, start.add(const Duration(days: 7)));
    }

    final start = DateTime(date.year, date.month + offset, 1);
    final next = DateTime(start.year, start.month + 1, 1);
    return _PeriodRange(start, next);
  }

  static DateTime _startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  static List<Entry> _entriesInRange(List<Entry> entries, DateTime start, DateTime end) {
    final results = entries.where((entry) {
      return !entry.createdAt.isBefore(start) && entry.createdAt.isBefore(end);
    }).toList();
    results.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return results;
  }

  static int _daysWithEntries(List<Entry> entries) {
    final days = <DateTime>{};
    for (final entry in entries) {
      days.add(_dateOnly(entry.createdAt));
    }
    return days.length;
  }

  static (String, int) _mostFelt(List<Entry> entries) {
    if (entries.isEmpty) return ('—', 0);
    final counts = <String, int>{};
    for (final entry in entries) {
      counts.update(entry.moodWord, (value) => value + 1, ifAbsent: () => 1);
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return (sorted.first.key, sorted.first.value);
  }

  static double _average(List<double> values) {
    if (values.isEmpty) return 0;
    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }

  static double _standardDeviation(List<double> values) {
    if (values.length < 2) return 0;
    final mean = _average(values);
    var total = 0.0;
    for (final value in values) {
      total += pow(value - mean, 2).toDouble();
    }
    return sqrt(total / values.length);
  }

  static _TrendResult _trend(
    List<Entry> entries,
    DateTime periodStart,
    int daysInPeriod,
    InsightsPeriod period,
  ) {
    final daily = _dailyAverages(entries, periodStart, daysInPeriod);
    final filtered = daily.whereType<double>().toList();
    if (filtered.length < 4) {
      return const _TrendResult(trendUp: false, trendDown: false);
    }
    final segment = period == InsightsPeriod.week ? 3 : 4;
    if (filtered.length < segment * 2) {
      return const _TrendResult(trendUp: false, trendDown: false);
    }
    final first = filtered.take(segment).toList();
    final last = filtered.skip(filtered.length - segment).toList();
    final firstAvg = _average(first);
    final lastAvg = _average(last);
    return _TrendResult(
      trendUp: lastAvg > firstAvg + 0.05,
      trendDown: lastAvg < firstAvg - 0.05,
    );
  }

  static List<double?> _dailyAverages(
    List<Entry> entries,
    DateTime periodStart,
    int daysInPeriod,
  ) {
    final map = <DateTime, List<double>>{};
    for (final entry in entries) {
      final day = _dateOnly(entry.createdAt);
      map.putIfAbsent(day, () => []).add(entry.moodValue);
    }
    final averages = <double?>[];
    for (var i = 0; i < daysInPeriod; i += 1) {
      final day = periodStart.add(Duration(days: i));
      final values = map[day];
      if (values == null || values.isEmpty) {
        averages.add(null);
      } else {
        averages.add(_average(values));
      }
    }
    return averages;
  }

  static bool _weekendsBetter(List<Entry> entries, double overall) {
    if (entries.isEmpty) return false;
    final weekend = <double>[];
    final weekday = <double>[];
    for (final entry in entries) {
      final day = entry.createdAt.weekday;
      if (day == DateTime.saturday || day == DateTime.sunday) {
        weekend.add(entry.moodValue);
      } else {
        weekday.add(entry.moodValue);
      }
    }
    if (weekend.length < 2 || weekday.length < 2) return false;
    return _average(weekend) > _average(weekday) + 0.05 && _average(weekend) > overall;
  }

  static bool _mondaysWorse(List<Entry> entries, double overall) {
    if (entries.isEmpty) return false;
    final monday = <double>[];
    for (final entry in entries) {
      if (entry.createdAt.weekday == DateTime.monday) {
        monday.add(entry.moodValue);
      }
    }
    if (monday.isEmpty) return false;
    return _average(monday) < overall - 0.05;
  }

  static _MonthComparison _monthlyComparison(
    List<Entry> entries,
    InsightsPeriod period,
    DateTime periodStart,
    double currentAvg,
  ) {
    if (period != InsightsPeriod.month) {
      return const _MonthComparison(false, false);
    }
    final previousStart = DateTime(periodStart.year, periodStart.month - 1, 1);
    final previousEnd = DateTime(periodStart.year, periodStart.month, 1);
    final previousEntries = _entriesInRange(entries, previousStart, previousEnd);
    if (previousEntries.isEmpty) {
      return const _MonthComparison(false, false);
    }
    final previousAvg = _average(previousEntries.map((entry) => entry.moodValue).toList());
    return _MonthComparison(
      currentAvg > previousAvg + 0.05,
      currentAvg < previousAvg - 0.05,
    );
  }

  static String _insightText({
    required InsightsPeriod period,
    required int streak,
    required int checkInCount,
    required bool trendUp,
    required bool trendDown,
    required bool stable,
    required bool volatile,
    required double avgMood,
    required bool weekendsBetter,
    required bool mondaysWorse,
    required bool betterThanLastMonth,
    required bool worseThanLastMonth,
  }) {
    if (period == InsightsPeriod.week) {
      if (streak >= 7) {
        return "You've checked in every day this week. That's real commitment.";
      }
      if (streak >= 3) {
        return '$streak days in a row. You\'re building a rhythm.';
      }
      if (trendUp) {
        return "Your mood lifted as the week went on. Something's working.";
      }
      if (trendDown) {
        return 'This week felt heavier toward the end. Be gentle with yourself.';
      }
      if (stable) {
        return 'A steady week. Consistency can be its own kind of strength.';
      }
      if (volatile) {
        return "Some ups and downs this week. That's completely human.";
      }
      if (avgMood > 0.7) {
        return 'A good week overall. Notice what made it work.';
      }
      if (avgMood > 0 && avgMood < 0.3) {
        return 'A tough week. You still showed up — that matters.';
      }
      if (checkInCount <= 2) {
        return 'Just a couple of check-ins this week. Every one counts.';
      }
      return "You're here. That's the first step.";
    }

    if (checkInCount >= 20) {
      return 'You checked in $checkInCount times this month. That\'s a habit forming.';
    }
    if (weekendsBetter) {
      return 'Weekends brought some lightness. Worth noticing.';
    }
    if (mondaysWorse) {
      return 'Mondays tend to feel heavier. You\'re not alone in that.';
    }
    if (betterThanLastMonth) {
      return 'This month felt better than last. Progress isn\'t always obvious.';
    }
    if (worseThanLastMonth) {
      return 'A harder month. But you kept checking in.';
    }
    if (streak >= 3) {
      return '$streak days in a row. You\'re building a rhythm.';
    }
    return "You're here. That's the first step.";
  }

  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  static (int, double) _calculateReflectionStats(List<Entry> entries) {
    int daysWithReflection = 0;

    for (final entry in entries) {
      if (entry.reflectionAnswerIds != null && entry.reflectionAnswerIds!.isNotEmpty) {
        daysWithReflection++;
      }
    }

    final rate = entries.isNotEmpty ? daysWithReflection / entries.length : 0.0;
    return (daysWithReflection, rate);
  }

  static Map<int, double> _calculateDayOfWeekPattern(List<Entry> entries) {
    final Map<int, List<double>> grouped = {};

    for (final entry in entries) {
      final day = entry.createdAt.weekday;
      grouped.putIfAbsent(day, () => []);
      grouped[day]!.add(entry.moodValue);
    }

    final Map<int, double> averages = {};
    for (final day in grouped.keys) {
      final values = grouped[day]!;
      averages[day] = values.reduce((a, b) => a + b) / values.length;
    }

    return averages;
  }

  static (int?, int?) _findBestWorstDays(Map<int, double> pattern) {
    if (pattern.length < 2) return (null, null);

    int? bestDay;
    int? worstDay;
    double bestAvg = 0;
    double worstAvg = 1;

    for (final entry in pattern.entries) {
      if (entry.value > bestAvg) {
        bestAvg = entry.value;
        bestDay = entry.key;
      }
      if (entry.value < worstAvg) {
        worstAvg = entry.value;
        worstDay = entry.key;
      }
    }

    // Only significant if difference > 0.15
    if (bestAvg - worstAvg < 0.15) return (null, null);

    return (bestDay, worstDay);
  }

  static int _calculateLongestStreakInPeriod(List<Entry> entries, DateTime start, DateTime end) {
    if (entries.isEmpty) return 0;

    final daysWithEntries = <DateTime>{};
    for (final entry in entries) {
      daysWithEntries.add(_dateOnly(entry.createdAt));
    }

    final sortedDays = daysWithEntries.toList()..sort();
    var longestStreak = 0;
    var currentStreak = 1;

    for (var i = 1; i < sortedDays.length; i++) {
      final diff = sortedDays[i].difference(sortedDays[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
      } else {
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
        currentStreak = 1;
      }
    }

    // Check final streak
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    return longestStreak;
  }

  static Future<List<InsightItem>> _generateInsights({
    required InsightsPeriod period,
    required int streak,
    required int checkInCount,
    required bool trendUp,
    required bool trendDown,
    required bool stable,
    required bool volatile,
    required double avgMood,
    required double? moodChangeVsPrevious,
    required int reflectionDays,
    required double reflectionRate,
  }) async {
    final insights = <InsightItem>[];
    final periodName = period == InsightsPeriod.week ? "week" : "month";

    // Priority 1: Perfect streak (7+ days)
    if (streak >= 7) {
      insights.add(InsightItem(Icons.local_fire_department_outlined, "You've checked in every day this $periodName. That's real commitment."));
    }
    // Priority 2: Good streak (3+ days)
    else if (streak >= 3) {
      insights.add(InsightItem(Icons.local_fire_department_outlined, "$streak days in a row. You're building a rhythm."));
    }

    // Priority 3: Trend up
    if (trendUp && insights.length < 3) {
      insights.add(InsightItem(Icons.trending_up, "Your mood lifted as the $periodName went on. Something's working."));
    }
    // Priority 4: Trend down
    else if (trendDown && insights.length < 3) {
      insights.add(InsightItem(Icons.trending_down, "This $periodName felt heavier toward the end. Be gentle with yourself."));
    }

    // Priority 5: Better than previous
    if (moodChangeVsPrevious != null && moodChangeVsPrevious > 0.1 && insights.length < 3) {
      insights.add(InsightItem(Icons.auto_awesome, "Your mood is up from last $periodName. Nice progress."));
    }
    // Priority 6: Worse than previous
    else if (moodChangeVsPrevious != null && moodChangeVsPrevious < -0.1 && insights.length < 3) {
      insights.add(InsightItem(Icons.fitness_center, "Tougher than last $periodName. That's okay — you're still here."));
    }

    // Priority 7: High reflection rate
    if (reflectionRate >= 0.8 && insights.length < 3) {
      insights.add(InsightItem(Icons.edit_note, "Reflected $reflectionDays of $checkInCount days. That's deep work."));
    }
    // Priority 8: Medium reflection rate
    else if (reflectionRate >= 0.5 && insights.length < 3) {
      insights.add(InsightItem(Icons.edit_note, "Reflection is becoming part of your routine."));
    }

    // Priority 9: Stable
    if (stable && insights.length < 3) {
      insights.add(InsightItem(Icons.balance, "A steady $periodName. Consistency can be its own strength."));
    }
    // Priority 10: Volatile
    else if (volatile && insights.length < 3) {
      insights.add(InsightItem(Icons.waves, "Some ups and downs this $periodName. That's completely human."));
    }

    // Priority 11: High mood
    if (avgMood > 0.7 && insights.length < 3) {
      insights.add(InsightItem(Icons.light_mode_outlined, "A good $periodName overall. Notice what made it work."));
    }
    // Priority 12: Low mood
    else if (avgMood < 0.3 && insights.length < 3) {
      insights.add(InsightItem(Icons.spa_outlined, "A tough $periodName. You still showed up — that matters."));
    }

    // Priority 13: Few check-ins
    if (checkInCount <= 2 && insights.length < 3) {
      insights.add(InsightItem(Icons.directions_walk, "Just getting started. Every check-in counts."));
    }

    // Priority 14: Fallback
    if (insights.isEmpty) {
      insights.add(InsightItem(Icons.directions_walk, "You're here. That's the first step."));
    }

    // Direction insights (only for week view to keep it relevant)
    if (period == InsightsPeriod.week && insights.length < 3) {
      // Priority 15: Direction connected 5+ times this week
      final frequentDirections = await DirectionService.instance.getFrequentDirectionsThisWeek();
      for (final direction in frequentDirections) {
        if (insights.length >= 3) break;
        final count = DirectionService.instance.getWeeklyConnectionCount(direction.id);
        insights.add(InsightItem(Icons.explore_outlined, "'${direction.title}' showed up $count times this week. It's clearly important to you."));
      }

      // Priority 16: High mood correlation (≥0.15 difference)
      if (insights.length < 3) {
        final correlations = await DirectionService.instance.getDirectionsWithMoodCorrelation();
        for (final entry in correlations.where((e) => e.value >= 0.15)) {
          if (insights.length >= 3) break;
          insights.add(InsightItem(Icons.auto_awesome, "Your mood is higher when '${entry.key.title}' is part of your day."));
        }
      }

      // Priority 17: Low mood correlation (≤-0.1 difference)
      if (insights.length < 3) {
        final correlations = await DirectionService.instance.getDirectionsWithMoodCorrelation();
        for (final entry in correlations.where((e) => e.value <= -0.1)) {
          if (insights.length >= 3) break;
          insights.add(InsightItem(Icons.forum_outlined, "'${entry.key.title}' often comes up on tougher days. Worth reflecting on."));
        }
      }

      // Priority 18: Direction not connected in 7+ days
      if (insights.length < 3) {
        final dormantDirections = DirectionService.instance.getDormantDirections();
        for (final direction in dormantDirections) {
          if (insights.length >= 3) break;
          insights.add(InsightItem(Icons.spa_outlined, "Haven't connected to '${direction.title}' lately. Still matters?"));
        }
      }
    }

    return insights.take(3).toList();
  }

  static String _generatePatternInsight(int? bestDay, int? worstDay) {
    if (bestDay == null || worstDay == null) {
      return "Your mood is fairly consistent across the week.";
    }

    const dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final bestName = dayNames[bestDay];
    final worstName = dayNames[worstDay];

    if (worstDay == 1) {
      return "Mondays are your toughest day. Consider a gentler start to the week.";
    } else if (bestDay == 6 || bestDay == 7) {
      return "${bestName}s are your best days. What makes them work?";
    } else {
      return "${bestName}s tend to be your best. ${worstName}s are tougher.";
    }
  }
}

class _PeriodRange {
  const _PeriodRange(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

class _TrendResult {
  const _TrendResult({required this.trendUp, required this.trendDown});

  final bool trendUp;
  final bool trendDown;
}

class _MonthComparison {
  const _MonthComparison(this.betterThanLast, this.worseThanLast);

  final bool betterThanLast;
  final bool worseThanLast;
}
