import 'package:flutter/material.dart';

/// Mood range categories for filtering entries
enum MoodRange {
  low,
  mid,
  high;

  /// User-friendly label for the mood range
  String get label {
    switch (this) {
      case MoodRange.low:
        return 'Low';
      case MoodRange.mid:
        return 'Mid';
      case MoodRange.high:
        return 'High';
    }
  }

  /// Check if a mood value falls within this range
  /// Low: 0.0 to <0.33
  /// Mid: 0.33 to <0.66
  /// High: 0.66 to 1.0
  bool matches(double moodValue) {
    switch (this) {
      case MoodRange.low:
        return moodValue < 0.33;
      case MoodRange.mid:
        return moodValue >= 0.33 && moodValue < 0.66;
      case MoodRange.high:
        return moodValue >= 0.66;
    }
  }
}

/// Immutable filter criteria for entry filtering
/// NOT a Hive model - used for in-memory filter state only
class EntryFilter {
  final String? searchQuery;
  final Set<MoodRange> moodRanges;
  final DateTimeRange? dateRange;
  final String? directionId;

  const EntryFilter({
    this.searchQuery,
    this.moodRanges = const {},
    this.dateRange,
    this.directionId,
  });

  /// Check if any filter criteria are active
  bool get hasActiveFilters =>
      (searchQuery != null && searchQuery!.trim().isNotEmpty) ||
      moodRanges.isNotEmpty ||
      dateRange != null ||
      directionId != null;

  /// Create a copy with modified fields
  EntryFilter copyWith({
    String? searchQuery,
    Set<MoodRange>? moodRanges,
    DateTimeRange? dateRange,
    String? directionId,
  }) {
    return EntryFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      moodRanges: moodRanges ?? this.moodRanges,
      dateRange: dateRange ?? this.dateRange,
      directionId: directionId ?? this.directionId,
    );
  }

  /// Create an empty filter (all criteria cleared)
  EntryFilter cleared() {
    return const EntryFilter(
      searchQuery: null,
      moodRanges: {},
      dateRange: null,
      directionId: null,
    );
  }
}
