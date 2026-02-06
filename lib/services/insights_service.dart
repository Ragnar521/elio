import 'dart:math';

import '../models/entry.dart';

enum InsightsPeriod { week, month }

class InsightsSnapshot {
  InsightsSnapshot({
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
}

class InsightsService {
  static InsightsSnapshot buildSnapshot({
    required DateTime now,
    required List<Entry> allEntries,
    required InsightsPeriod period,
    required int offset,
    required int streak,
  }) {
    final periodRange = _periodRange(now, period, offset);
    final periodEntries = _entriesInRange(allEntries, periodRange.start, periodRange.end);
    final daysInPeriod = periodRange.end.difference(periodRange.start).inDays;
    final daysWithEntries = _daysWithEntries(periodEntries);
    final checkInCount = periodEntries.length;
    final mostFelt = _mostFelt(periodEntries);
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

    return InsightsSnapshot(
      period: period,
      periodStart: periodRange.start,
      periodEnd: periodRange.end,
      daysInPeriod: daysInPeriod,
      entries: periodEntries,
      checkInCount: checkInCount,
      daysWithEntries: daysWithEntries,
      streak: streak,
      mostFelt: mostFelt,
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

  static String _mostFelt(List<Entry> entries) {
    if (entries.isEmpty) return '—';
    final counts = <String, int>{};
    for (final entry in entries) {
      counts.update(entry.moodWord, (value) => value + 1, ifAbsent: () => 1);
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
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
