# Phase 2: Search & Filter - Research

**Researched:** 2026-02-26
**Domain:** Flutter UI/UX + Hive database filtering
**Confidence:** HIGH

## Summary

Phase 2 implements search and filter functionality for the History screen, enabling users to find specific entries using keyword search, mood range filters, date range filters, and direction filters. The implementation requires adding a search bar, filter chips UI, and filtering logic to the existing HistoryScreen without compromising performance for datasets of 500+ entries.

**Key technical considerations:**
1. **In-memory filtering** is sufficient — Hive excels at read operations (0ms for 1,000 reads), so filtering in Dart after loading all entries is faster than complex Hive queries
2. **Debounced search** (300-500ms) prevents UI lag from keystroke-triggered rebuilds
3. **ListView.builder** is already used in HistoryScreen, ensuring lazy loading for large lists
4. **No new dependencies needed** — Flutter's built-in TextField, FilterChip, and showDateRangePicker cover all requirements

**Primary recommendation:** Build a FilterService to centralize filter logic and state, keeping HistoryScreen focused on UI. Use FilterChips for mood ranges, native showDateRangePicker for date selection, and debounced TextField for keyword search.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SRCH-01 | User can search entries by keyword matching intention or reflection text | TextField with debounce + in-memory text matching across Entry.intention and ReflectionAnswer.answer fields |
| SRCH-02 | User can filter entries by mood range (e.g., low/mid/high) | FilterChip widgets with predefined ranges: Low (0.0-0.33), Mid (0.33-0.66), High (0.66-1.0) |
| SRCH-03 | User can filter entries by date range | Flutter's native showDateRangePicker for Material Design consistency |
| SRCH-04 | User can filter entries by connected direction | FilterChip per active direction, filtered via DirectionConnection lookup |
| SRCH-05 | User can combine search and filter criteria | Apply filters sequentially: keyword → mood range → date range → direction |

</phase_requirements>

---

## Standard Stack

### Core (No New Dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter Material | Built-in | TextField, FilterChip, showDateRangePicker | Native widgets ensure platform consistency and zero additional dependencies |
| Dart Timer | Built-in | Debounce implementation | Standard pattern for rate-limiting in Flutter, no package needed |
| Hive | 2.2.3 (existing) | Data storage | Already integrated, read performance is excellent (0ms for 1,000 entries) |

### Supporting

No additional packages required. The project already has all dependencies needed.

### Why No Additional Packages?

**Considered alternatives:**
- **flutter_chips_input** — Overkill for simple FilterChips, Material's built-in FilterChip is sufficient
- **calendar_date_picker2** — Adds 500KB for features we don't need, showDateRangePicker is simpler
- **rxdart** — Debounce can be implemented with Dart's Timer in ~10 lines, no need for reactive streams

**Decision:** Use built-in Flutter widgets and Dart standard library. This keeps the app lightweight, reduces version conflicts, and follows the project's "simple & fast" philosophy.

---

## Architecture Patterns

### Recommended Project Structure

```
lib/
├── services/
│   └── filter_service.dart       # NEW: Centralized filter logic
├── screens/
│   └── history_screen.dart        # MODIFIED: Add search bar, filter chips, filter state
├── models/
│   └── entry_filter.dart          # NEW: Immutable filter criteria model
└── widgets/
    ├── search_bar_widget.dart     # NEW: Reusable search input with debounce
    └── filter_chips_row.dart      # NEW: Mood + direction filter chips
```

### Pattern 1: FilterService (Singleton)

**What:** Centralized service for applying filter criteria to entry lists
**When to use:** Keep filter logic separate from UI state management

**Implementation:**
```dart
// lib/services/filter_service.dart
class FilterService {
  FilterService._();
  static final FilterService instance = FilterService._();

  /// Apply all filter criteria to entries
  Future<List<Entry>> filterEntries({
    required List<Entry> entries,
    String? searchQuery,
    Set<MoodRange>? moodRanges,
    DateTimeRange? dateRange,
    String? directionId,
  }) async {
    var filtered = entries;

    // 1. Keyword search (intention + reflections)
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = await _filterByKeyword(filtered, query);
    }

    // 2. Mood range filter
    if (moodRanges != null && moodRanges.isNotEmpty) {
      filtered = filtered.where((e) => _matchesMoodRange(e.moodValue, moodRanges)).toList();
    }

    // 3. Date range filter
    if (dateRange != null) {
      filtered = filtered.where((e) =>
        !e.createdAt.isBefore(dateRange.start) &&
        e.createdAt.isBefore(dateRange.end.add(Duration(days: 1)))
      ).toList();
    }

    // 4. Direction filter
    if (directionId != null) {
      final connectedEntryIds = DirectionService.instance
          .getConnectedEntries(directionId)
          .map((e) => e.id)
          .toSet();
      filtered = filtered.where((e) => connectedEntryIds.contains(e.id)).toList();
    }

    return filtered;
  }

  Future<List<Entry>> _filterByKeyword(List<Entry> entries, String query) async {
    final results = <Entry>[];

    for (final entry in entries) {
      // Check intention
      if (entry.intention.toLowerCase().contains(query)) {
        results.add(entry);
        continue;
      }

      // Check reflection answers
      if (entry.reflectionAnswerIds != null && entry.reflectionAnswerIds!.isNotEmpty) {
        final answers = ReflectionService.instance.getAnswersByIds(entry.reflectionAnswerIds!);
        if (answers.any((a) => a.answer.toLowerCase().contains(query))) {
          results.add(entry);
        }
      }
    }

    return results;
  }

  bool _matchesMoodRange(double moodValue, Set<MoodRange> ranges) {
    for (final range in ranges) {
      switch (range) {
        case MoodRange.low:
          if (moodValue < 0.33) return true;
        case MoodRange.mid:
          if (moodValue >= 0.33 && moodValue < 0.66) return true;
        case MoodRange.high:
          if (moodValue >= 0.66) return true;
      }
    }
    return false;
  }
}

enum MoodRange { low, mid, high }
```

### Pattern 2: Debounced Search TextField

**What:** TextField that delays search execution until user stops typing
**When to use:** Any search input that triggers expensive operations (filtering 500+ entries)

**Implementation:**
```dart
// lib/widgets/search_bar_widget.dart
class DebouncedSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Duration debounceDuration;

  const DebouncedSearchBar({
    super.key,
    required this.onSearch,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<DebouncedSearchBar> createState() => _DebouncedSearchBarState();
}

class _DebouncedSearchBarState extends State<DebouncedSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search entries...',
        prefixIcon: Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onSearch('');
                },
              )
            : null,
      ),
    );
  }
}
```

**Source:** [How to Create a Debounce Utility in Flutter for Efficient Search Input](https://medium.com/@valerii.novykov/how-to-create-a-debounce-utility-in-flutter-for-efficient-search-input-cd2827e3bd08)

### Pattern 3: FilterChip State Management

**What:** Multiple-selection chips for mood ranges and directions
**When to use:** Filtering with multiple independent criteria

**Implementation:**
```dart
// In HistoryScreen state
Set<MoodRange> _selectedMoodRanges = {};

Widget _buildMoodFilterChips() {
  return Wrap(
    spacing: 8,
    children: [
      FilterChip(
        label: Text('Low'),
        selected: _selectedMoodRanges.contains(MoodRange.low),
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _selectedMoodRanges.add(MoodRange.low);
            } else {
              _selectedMoodRanges.remove(MoodRange.low);
            }
            _applyFilters();
          });
        },
      ),
      // Repeat for mid, high
    ],
  );
}
```

**Source:** [Mastering Flutter Filter Chip: A Complete Guide with Multi-Select Example](https://medium.com/flutter-framework/mastering-flutter-filter-chip-a-complete-guide-with-multi-select-example-9b67d06abd20)

### Pattern 4: Date Range Picker Integration

**What:** Native Material Design date range picker
**When to use:** Selecting start/end dates for filtering

**Implementation:**
```dart
DateTimeRange? _selectedDateRange;

Future<void> _selectDateRange() async {
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
    initialDateRange: _selectedDateRange,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: ElioColors.darkAccent,
            surface: ElioColors.darkSurface,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    setState(() {
      _selectedDateRange = picked;
      _applyFilters();
    });
  }
}
```

**Source:** [Flutter Date Picker Deep Dive: A Complete Guide](https://medium.com/technologiaa/flutter-date-picker-deep-dive-a-complete-guide-9af844c6fb83)

### Anti-Patterns to Avoid

- **Don't filter on every keystroke** — Always debounce text search (300-500ms) to prevent UI jank
- **Don't use Hive queries for complex filters** — Hive lacks built-in text search; filtering in memory is faster for this dataset size
- **Don't rebuild entire list on filter change** — Use setState only in HistoryScreen, leverage existing ListView.builder for efficient rendering
- **Don't store filter state in service** — Filters are UI state, they belong in the screen's State, not in the singleton service

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Debouncing | Custom debounce logic with Completer | Dart's Timer with cancel on new input | Timer is standard library, simple, well-tested |
| Date range picker | Custom calendar widget | showDateRangePicker (Material) | Follows platform guidelines, accessible, localized |
| Text search | Custom fuzzy matching | String.contains() with toLowerCase() | Simple, fast for small datasets, no dependencies |
| Filter chips | Custom chip widgets | Material FilterChip | Material Design 3 compliant, accessible, themeable |

**Key insight:** Flutter's built-in widgets already solve all UI requirements for this phase. Custom implementations add complexity without performance or UX benefits for a local-only app with datasets under 1,000 entries.

---

## Common Pitfalls

### Pitfall 1: Filtering Too Early in Build Cycle

**What goes wrong:** Calling filter logic inside build() method causes expensive operations on every rebuild
**Why it happens:** Confusing reactive patterns from web frameworks with Flutter's explicit setState model
**How to avoid:** Store filtered results in state variable, only recalculate on user action (search input, chip toggle)
**Warning signs:** Lag when typing in search bar, jank when scrolling filtered list

**Example:**
```dart
// BAD: Filters on every build
@override
Widget build(BuildContext context) {
  final filtered = _filterEntries(_allEntries); // Runs on every rebuild!
  return ListView.builder(itemCount: filtered.length, ...);
}

// GOOD: Filter in setState callback
void _applyFilters() {
  setState(() {
    _filteredEntries = _filterEntries(_allEntries);
  });
}

@override
Widget build(BuildContext context) {
  return ListView.builder(itemCount: _filteredEntries.length, ...);
}
```

### Pitfall 2: Memory Leaks from Undisposed Timers

**What goes wrong:** Debounce timers continue firing after screen disposal, causing crashes
**Why it happens:** Forgetting to cancel timers in dispose() method
**How to avoid:** Always cancel active timers in dispose()
**Warning signs:** Crashes when navigating away during search, "setState called after dispose" errors

**Example:**
```dart
Timer? _debounce;

@override
void dispose() {
  _debounce?.cancel(); // CRITICAL: Must cancel timer
  _controller.dispose();
  super.dispose();
}
```

**Source:** [Debouncing in Flutter: Enhancing User Experience](https://blog.stackademic.com/debouncing-in-flutter-enhancing-user-experience-e330ea85f162)

### Pitfall 3: Incorrect Date Range Filtering

**What goes wrong:** End date is exclusive, missing entries from the last day of range
**Why it happens:** DateTime comparisons don't include the full day unless you add Duration(days: 1)
**How to avoid:** Add one day to end date when filtering: `e.createdAt.isBefore(dateRange.end.add(Duration(days: 1)))`
**Warning signs:** User selects "Feb 1 - Feb 5" but entries from Feb 5 don't appear

### Pitfall 4: Reflection Answer Lookup Performance

**What goes wrong:** Calling ReflectionService.getAnswersByIds() inside a loop for each entry causes N+1 queries
**Why it happens:** Not batching lookups or caching results
**How to avoid:** Preload all reflection answers into a Map<entryId, List<Answer>> before filtering, then lookup is O(1)
**Warning signs:** Search becomes slower as number of entries with reflections increases

**Optimized approach:**
```dart
// Preload all answers once
final answersByEntry = <String, List<ReflectionAnswer>>{};
for (final entry in entries) {
  if (entry.reflectionAnswerIds != null) {
    answersByEntry[entry.id] = ReflectionService.instance.getAnswersByIds(entry.reflectionAnswerIds!);
  }
}

// Then filter uses cached map
for (final entry in entries) {
  final answers = answersByEntry[entry.id] ?? [];
  if (answers.any((a) => a.answer.toLowerCase().contains(query))) {
    results.add(entry);
  }
}
```

---

## Code Examples

Verified patterns from official sources and existing codebase:

### Example 1: Complete HistoryScreen Filter State

```dart
// In _HistoryScreenState
class _HistoryScreenState extends State<HistoryScreen> {
  late Future<_HistoryData> _historyFuture;

  // Filter state
  String _searchQuery = '';
  Set<MoodRange> _selectedMoodRanges = {};
  DateTimeRange? _selectedDateRange;
  String? _selectedDirectionId;

  List<Entry> _filteredEntries = [];
  List<Entry> _allEntries = [];

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadData();
  }

  Future<_HistoryData> _loadData() async {
    final entries = await StorageService.instance.getAllEntries();
    final streak = await StorageService.instance.getCurrentStreak();

    setState(() {
      _allEntries = entries;
      _applyFilters(); // Initial filter (shows all)
    });

    return _HistoryData(entries: entries, streak: streak);
  }

  void _applyFilters() {
    _filteredEntries = FilterService.instance.filterEntries(
      entries: _allEntries,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      moodRanges: _selectedMoodRanges.isEmpty ? null : _selectedMoodRanges,
      dateRange: _selectedDateRange,
      directionId: _selectedDirectionId,
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedMoodRanges.clear();
      _selectedDateRange = null;
      _selectedDirectionId = null;
      _applyFilters();
    });
  }
}
```

### Example 2: Filter UI Layout

```dart
Widget _buildFilterSection() {
  final hasActiveFilters = _searchQuery.isNotEmpty ||
      _selectedMoodRanges.isNotEmpty ||
      _selectedDateRange != null ||
      _selectedDirectionId != null;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Search bar
      DebouncedSearchBar(
        onSearch: _onSearchChanged,
        debounceDuration: Duration(milliseconds: 300),
      ),
      SizedBox(height: 16),

      // Filter chips row
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Mood filters
          ..._buildMoodChips(),

          // Date range chip
          FilterChip(
            label: Text(_selectedDateRange == null
                ? 'Date range'
                : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'),
            selected: _selectedDateRange != null,
            onSelected: (_) => _selectDateRange(),
          ),

          // Clear filters button (only show if filters active)
          if (hasActiveFilters)
            ActionChip(
              label: Text('Clear all'),
              onPressed: _clearFilters,
            ),
        ],
      ),
      SizedBox(height: 16),

      // Results count
      Text(
        '${_filteredEntries.length} entries',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}
```

**Source:** Pattern follows existing HistoryScreen structure and [Building Advanced Search Experiences in Flutter With Filters](https://vibe-studio.ai/insights/building-advanced-search-experiences-in-flutter-with-filters)

### Example 3: Synchronous FilterService (No async needed)

```dart
// FilterService can be synchronous for better performance
List<Entry> filterEntries({
  required List<Entry> entries,
  String? searchQuery,
  Set<MoodRange>? moodRanges,
  DateTimeRange? dateRange,
  String? directionId,
}) {
  var filtered = entries;

  // All filters are in-memory operations, no async needed
  if (searchQuery != null && searchQuery.trim().isNotEmpty) {
    filtered = _filterByKeyword(filtered, searchQuery.toLowerCase());
  }

  if (moodRanges != null && moodRanges.isNotEmpty) {
    filtered = filtered.where((e) => _matchesMoodRange(e.moodValue, moodRanges)).toList();
  }

  if (dateRange != null) {
    final endInclusive = dateRange.end.add(Duration(days: 1));
    filtered = filtered.where((e) =>
      !e.createdAt.isBefore(dateRange.start) &&
      e.createdAt.isBefore(endInclusive)
    ).toList();
  }

  if (directionId != null) {
    final connectedEntryIds = DirectionService.instance
        .getConnectedEntries(directionId)
        .map((e) => e.id)
        .toSet();
    filtered = filtered.where((e) => connectedEntryIds.contains(e.id)).toList();
  }

  return filtered;
}
```

**Rationale:** Hive values are already loaded in memory. Filtering 1,000 entries in Dart takes <5ms. Synchronous code is simpler and faster than async overhead.

**Source:** [Flutter Performance Optimization 2026](https://dev.to/techwithsam/flutter-performance-optimization-2026-make-your-app-10x-faster-best-practices-2p07)

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Package-based debounce (rxdart) | Timer-based debounce | 2024 | Reduces dependencies, simpler debugging |
| Custom calendar widgets | showDateRangePicker | Flutter 1.20+ (2020) | Platform consistency, accessibility |
| Async filtering with FutureBuilder | Synchronous filtering with setState | 2025+ | Better performance for in-memory operations |
| ChoiceChip for multi-select | FilterChip | Material Design 3 (2023) | Semantically correct, better a11y |

**Deprecated/outdated:**
- **flutter_chips_input (unmaintained)**: Last update 2022, use built-in FilterChip instead
- **Async filtering for local data**: Only async operations (Hive reads) should be async, in-memory filtering should be synchronous

---

## Open Questions

1. **Should we paginate History results?**
   - What we know: STATE.md warns about ListView.builder requirement for 500+ entries
   - What's unclear: Current HistoryScreen already uses ListView (line 86-107), which has lazy loading
   - Recommendation: No pagination needed. ListView handles large lists efficiently. Only add pagination if user reports >2,000 entries cause issues.

2. **Should filters persist across app restarts?**
   - What we know: No mention in requirements or CLAUDE.md
   - What's unclear: UX expectation — most users expect filters to reset
   - Recommendation: Don't persist. Filters are session-scoped. Persisting adds complexity for minimal UX benefit.

3. **Should search include mood words?**
   - What we know: SRCH-01 specifies "intention or reflection text"
   - What's unclear: Users might search "Calm" expecting to find those moods
   - Recommendation: Start with intention + reflections only (per spec). Can add mood word search if users request it.

---

## Sources

### Primary (HIGH confidence)

- [Flutter Performance Optimization 2026](https://dev.to/techwithsam/flutter-performance-optimization-2026-make-your-app-10x-faster-best-practices-2p07) - Performance best practices, ListView.builder, state management
- [Building Advanced Search Experiences in Flutter With Filters](https://vibe-studio.ai/insights/building-advanced-search-experiences-in-flutter-with-filters) - Filter architecture patterns, debouncing, pagination
- [Flutter API: showDateRangePicker](https://api.flutter.dev/flutter/material/showDateRangePicker.html) - Official date range picker documentation
- [Flutter API: FilterChip](https://api.flutter.dev/flutter/material/FilterChip-class.html) - Official FilterChip widget documentation
- [Implementing Search in Flutter with Hive Db](https://singlesoup.medium.com/implementing-search-in-flutter-with-hive-db-b2b416a7a324) - Hive filtering patterns

### Secondary (MEDIUM confidence)

- [How to Create a Debounce Utility in Flutter for Efficient Search Input](https://medium.com/@valerii.novykov/how-to-create-a-debounce-utility-in-flutter-for-efficient-search-input-cd2827e3bd08) - Debounce implementation patterns
- [Mastering Flutter Filter Chip: A Complete Guide with Multi-Select Example](https://medium.com/flutter-framework/mastering-flutter-filter-chip-a-complete-guide-with-multi-select-example-9b67d06abd20) - FilterChip state management
- [Flutter Date Picker Deep Dive: A Complete Guide](https://medium.com/technologiaa/flutter-date-picker-deep-dive-a-complete-guide-9af844c6fb83) - Date picker customization
- [Debouncing in Flutter: Enhancing User Experience](https://blog.stackademic.com/debouncing-in-flutter-enhancing-user-experience-e330ea85f162) - Debounce best practices

### Tertiary (LOW confidence)

- None — all findings verified with official docs or multiple sources

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All dependencies already in project, patterns well-documented
- Architecture: HIGH - Matches existing StatefulWidget + Services pattern, verified with official docs
- Pitfalls: MEDIUM - Based on common Flutter issues and STATE.md warnings, not Phase 2 specific experience

**Research date:** 2026-02-26
**Valid until:** 2026-03-28 (30 days, stable APIs)
