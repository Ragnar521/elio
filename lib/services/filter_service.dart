import '../models/entry.dart';
import '../models/entry_filter.dart';
import '../services/reflection_service.dart';
import '../services/direction_service.dart';

/// Service for filtering entry lists based on search and filter criteria
/// Designed for synchronous, in-memory filtering for optimal performance
class FilterService {
  FilterService._();

  static final FilterService instance = FilterService._();

  /// Pre-fetch connected entry IDs for a direction filter
  /// Call this before filterEntries if you need direction filtering
  Future<Set<String>> getConnectedEntryIds(String directionId) async {
    final entries = await DirectionService.instance.getConnectedEntries(directionId);
    return entries.map((e) => e.id).toSet();
  }

  /// Apply all filter criteria to entries. Synchronous for performance.
  /// Filters apply sequentially: keyword -> mood range -> date range -> direction.
  ///
  /// [entries] - The full list of entries to filter
  /// [filter] - The filter criteria to apply
  /// [connectedEntryIds] - Optional pre-fetched set of entry IDs connected to a direction
  ///                       Use getConnectedEntryIds to fetch this if filter.directionId is set
  List<Entry> filterEntries({
    required List<Entry> entries,
    required EntryFilter filter,
    Set<String>? connectedEntryIds,
  }) {
    var filtered = entries;

    // 1. Keyword search (intention + reflections)
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase().trim();
      filtered = _filterByKeyword(filtered, query);
    }

    // 2. Mood range filter (OR logic: match any selected range)
    if (filter.moodRanges.isNotEmpty) {
      filtered = filtered.where((entry) {
        return filter.moodRanges.any((range) => range.matches(entry.moodValue));
      }).toList();
    }

    // 3. Date range filter (inclusive of both start and end dates)
    if (filter.dateRange != null) {
      final start = filter.dateRange!.start;
      final endInclusive = filter.dateRange!.end.add(const Duration(days: 1));

      filtered = filtered.where((entry) {
        return !entry.createdAt.isBefore(start) &&
            entry.createdAt.isBefore(endInclusive);
      }).toList();
    }

    // 4. Direction filter (using pre-fetched connected entry IDs)
    if (filter.directionId != null && connectedEntryIds != null) {
      filtered = filtered.where((entry) {
        return connectedEntryIds.contains(entry.id);
      }).toList();
    }

    return filtered;
  }

  /// Filter entries by keyword search across intention and reflection answers
  /// Uses answer cache to avoid N+1 lookups (performance optimization)
  List<Entry> _filterByKeyword(List<Entry> entries, String query) {
    // Pre-load all reflection answers into a cache to avoid N+1 queries
    final answerCache = <String, List<dynamic>>{};

    for (final entry in entries) {
      if (entry.reflectionAnswerIds != null && entry.reflectionAnswerIds!.isNotEmpty) {
        answerCache[entry.id] = ReflectionService.instance.getAnswersByIds(entry.reflectionAnswerIds!);
      }
    }

    // Filter entries based on keyword match
    final results = <Entry>[];

    for (final entry in entries) {
      // Check intention first
      if (entry.intention.toLowerCase().contains(query)) {
        results.add(entry);
        continue;
      }

      // Check reflection answers if intention didn't match
      if (answerCache.containsKey(entry.id)) {
        final answers = answerCache[entry.id]!;
        if (answers.any((a) => a.answer.toLowerCase().contains(query))) {
          results.add(entry);
        }
      }
    }

    return results;
  }
}
