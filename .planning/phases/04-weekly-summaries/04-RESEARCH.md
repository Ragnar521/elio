# Phase 4: Weekly Summaries - Research

**Researched:** 2026-02-26
**Domain:** Flutter UI state management, Hive data aggregation, weekly analytics
**Confidence:** HIGH

## Summary

Phase 4 implements automated weekly recaps that appear on the Home screen after a week of check-ins. The implementation leverages Elio's existing architecture: StatefulWidget + Service Layer pattern, Hive local storage, and reusable widgets (MoodWave, StatCard, DirectionCard). The weekly summary system requires three new components: (1) a WeeklySummaryService to detect week completion and generate summary data, (2) a WeeklySummary data model to store generated summaries in Hive, and (3) UI components to display summaries on Home screen and in a browsable history within Insights tab.

The technical foundation is already in place through InsightsService's week-based calculations. The primary challenge is week completion detection (determining when Monday arrives after a full previous week) and conditional UI rendering (showing the summary card only when appropriate). All required data sources exist: mood trends via InsightsService, direction patterns via DirectionService, and reflection answers via ReflectionService.

**Primary recommendation:** Extend existing services rather than creating parallel calculation logic. Reuse InsightsService.getInsightsForPeriod() for mood data, DirectionService statistics methods for direction patterns, and build a new WeeklySummaryService to orchestrate generation and persistence.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Card appears on Home screen at the start of a new week (not a modal/overlay)
- Summary also persists in Insights tab for ongoing access
- Scrollable history of all past weekly summaries (not just the latest)
- Tapping the Home card opens the full summary screen
- 3-4 focused sections — not overwhelming but more than just numbers
- Mini mood wave (reuse existing MoodWave component) showing the week's mood trajectory
- 1-2 standout reflection answers surfaced from the week, giving a personal/journaling feel
- Sections: mood overview (wave + stats), direction patterns, reflection highlights, takeaway
- Reuse the existing MoodWave widget from Insights for consistency
- Shows each day's mood as dots connected by a line
- Mini cards for each active direction with mood correlation data
- Each card shows: emoji + title, weekly connection count, mood when connected vs overall
- Highlight the top mood-impact direction with a callout (e.g., "Peace days boosted your mood by 15%")
- If user has no directions: skip directions section and include gentle prompt to create one ("Add a direction to see how your mood connects to what matters")
- Always generate summaries regardless of check-in count (even 1 day gets a summary)
- Warm encouragement style — feels like a friend, not a coach
- Reference specific moments from the week (e.g., "Your best mood was Thursday when you felt Joyful")
- Supportive language, never guilt-inducing
- Tone adapts to the week's mood patterns (acknowledge tough weeks without forcing positivity)

### Claude's Discretion
- Home card persistence behavior (dismiss after viewed vs persist for the week)
- Headline stats selection and layout (differentiate from existing Insights stat cards)
- Number of takeaway messages per summary (1 vs 2-3)
- Tone for low/negative mood weeks (gentle acknowledgment vs subtle encouragement)
- Dormant directions display (show with gentle note vs hide)
- How to select "standout" reflection answers from the week
- Summary layout when data is sparse (1-2 check-ins in a week)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SUMM-01 | User sees a weekly summary recap after completing a full week of entries | Week completion detection via date calculations (Monday detection), conditional Home screen card rendering |
| SUMM-02 | Weekly summary shows mood trend, average, and highlights | Reuse InsightsService.getInsightsForPeriod() with InsightsPeriod.week, MoodWave widget, stat card layout |
| SUMM-03 | Weekly summary surfaces top direction connections and patterns | DirectionService.getStats(), mood correlation calculations (hasPositiveCorrelation, avgMoodWhenConnected) |
| SUMM-04 | Weekly summary includes actionable takeaway or encouragement | Text generation logic based on mood patterns, reflection presence, direction engagement |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter SDK | 3.10.8+ | UI framework | Already in use, matches existing codebase |
| Hive | 2.2.3 | Local NoSQL storage | Already integrated, all existing data models use it |
| uuid | 4.5.1 | ID generation | Already in use for all models |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| intl | Latest | Date formatting | For week range labels (e.g., "Jan 20-26") |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hive | SharedPreferences | SharedPreferences can't store complex objects, would require JSON serialization overhead |
| StatefulWidget | Provider/Bloc | Unnecessary complexity for this app's scale, existing pattern works |
| Custom week detection | DateTime utilities package | Built-in DateTime is sufficient for week calculations |

**Installation:**
```bash
# intl may already be installed, check pubspec.yaml
flutter pub add intl  # Only if not present
```

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── models/
│   └── weekly_summary.dart        # New: WeeklySummary + Hive adapter (typeId: 7)
├── services/
│   └── weekly_summary_service.dart # New: Generate and persist summaries
├── screens/
│   ├── mood_entry_screen.dart      # Modified: Add summary card conditionally
│   ├── insights_screen.dart        # Modified: Add summary history tab/section
│   └── weekly_summary_screen.dart  # New: Full summary detail view
└── widgets/
    ├── weekly_summary_card.dart    # New: Compact card for Home screen
    └── reflection_highlight.dart   # New: Standout reflection display
```

### Pattern 1: Service Layer Data Orchestration
**What:** WeeklySummaryService coordinates data from multiple services (Insights, Direction, Reflection) to build a summary snapshot.

**When to use:** When a feature needs data from multiple domain services.

**Example:**
```dart
// lib/services/weekly_summary_service.dart
class WeeklySummaryService {
  static final WeeklySummaryService instance = WeeklySummaryService._();
  WeeklySummaryService._();

  static const _summariesBoxName = 'weekly_summaries';
  Box<WeeklySummary>? _summariesBox;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(WeeklySummaryAdapter().typeId)) {
      Hive.registerAdapter(WeeklySummaryAdapter());
    }
    _summariesBox = await Hive.openBox<WeeklySummary>(_summariesBoxName);
  }

  // Generate summary for a completed week
  Future<WeeklySummary> generateSummary(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));

    // Get all entries for the week
    final entries = await StorageService.instance.getEntriesForPeriod(
      weekStart,
      weekEnd,
    );

    // Reuse InsightsService for mood analytics
    final insights = await InsightsService.getInsightsForPeriod(
      now: weekEnd,
      allEntries: entries,
      period: InsightsPeriod.week,
      offset: -1, // Previous week
      streak: await StorageService.instance.getCurrentStreak(),
      longestStreakAllTime: await StorageService.instance.getLongestStreak(),
    );

    // Get direction patterns
    final directions = DirectionService.instance.getActiveDirections();
    final directionStats = <String, DirectionStats>{};
    for (final direction in directions) {
      directionStats[direction.id] = DirectionService.instance.getStats(direction.id);
    }

    // Select standout reflections (e.g., longest answers, varied topics)
    final standoutAnswers = await _selectStandoutReflections(entries);

    // Generate encouraging takeaway
    final takeaway = _generateTakeaway(insights, directionStats, entries);

    final summary = WeeklySummary(
      id: _uuid.v4(),
      weekStart: weekStart,
      weekEnd: weekEnd,
      avgMood: insights.avgMood,
      checkInCount: insights.checkInCount,
      moodTrend: insights.trendUp ? 'up' : insights.trendDown ? 'down' : 'stable',
      topDirectionId: _findTopDirection(directionStats),
      standoutReflectionIds: standoutAnswers.map((a) => a.id).toList(),
      takeaway: takeaway,
      createdAt: DateTime.now(),
    );

    await _summariesBox!.put(summary.id, summary);
    return summary;
  }
}
```

### Pattern 2: Week Completion Detection
**What:** Detect when a new week has started after a complete previous week.

**When to use:** On Home screen mount, determine if summary card should show.

**Example:**
```dart
// In MoodEntryScreen initState or build
Future<bool> shouldShowWeeklySummary() async {
  final now = DateTime.now();
  final mondayOfCurrentWeek = _startOfWeek(now);

  // Check if we're in a new week (Monday or later)
  if (now.weekday == DateTime.monday || now.isAfter(mondayOfCurrentWeek)) {
    // Check if summary already exists for previous week
    final previousWeekStart = mondayOfCurrentWeek.subtract(const Duration(days: 7));
    final existingSummary = await WeeklySummaryService.instance
        .getSummaryForWeek(previousWeekStart);

    if (existingSummary == null) {
      // Generate summary for previous week
      final entries = await StorageService.instance.getEntriesForPeriod(
        previousWeekStart,
        previousWeekStart.add(const Duration(days: 7)),
      );

      // Only generate if at least 1 entry in previous week
      if (entries.isNotEmpty) {
        await WeeklySummaryService.instance.generateSummary(previousWeekStart);
        return true;
      }
    } else if (!existingSummary.hasBeenViewed) {
      return true; // Summary exists but not viewed yet
    }
  }

  return false;
}

DateTime _startOfWeek(DateTime date) {
  final weekday = date.weekday;
  return DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: weekday - 1));
}
```

### Pattern 3: Reusing MoodWave for Summary
**What:** MoodWave widget already exists and accepts entries + period configuration.

**When to use:** Display mood trajectory in summary without rebuilding visualization logic.

**Example:**
```dart
// In weekly_summary_screen.dart
MoodWave(
  entries: weekEntries,
  periodStart: summary.weekStart,
  daysInPeriod: 7,
  height: 160, // Slightly smaller than Insights version
)
```

### Pattern 4: Direction Mini Cards
**What:** Compact version of DirectionCard widget showing weekly stats and mood correlation.

**When to use:** Display direction patterns in weekly summary.

**Example:**
```dart
// New widget: direction_summary_card.dart
class DirectionSummaryCard extends StatelessWidget {
  final Direction direction;
  final DirectionStats stats;
  final int weeklyConnections;
  final bool isTopImpact;

  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ElioColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: isTopImpact
            ? Border.all(color: ElioColors.darkAccent, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(direction.emoji, style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  direction.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '$weeklyConnections connections this week',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (stats.hasPositiveCorrelation || stats.hasNegativeCorrelation) ...[
            SizedBox(height: 4),
            Text(
              stats.hasPositiveCorrelation
                  ? '↑ ${(stats.moodDifference * 100).toStringAsFixed(0)}% higher mood'
                  : '↓ ${(stats.moodDifference.abs() * 100).toStringAsFixed(0)}% lower mood',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: stats.hasPositiveCorrelation
                    ? Color(0xFF4CAF50)
                    : ElioColors.darkAccent.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

### Pattern 5: Reflection Highlights Selection
**What:** Choose 1-2 standout reflection answers based on length, variety, or user favorites.

**When to use:** Surface meaningful reflections without overwhelming the summary.

**Example:**
```dart
Future<List<ReflectionAnswer>> _selectStandoutReflections(
  List<Entry> weekEntries,
) async {
  final allAnswerIds = weekEntries
      .expand((e) => e.reflectionAnswerIds ?? [])
      .toList();

  if (allAnswerIds.isEmpty) return [];

  final answers = await ReflectionService.instance.getAnswersByIds(allAnswerIds);

  // Strategy: Pick longest answer + most diverse category
  answers.sort((a, b) => b.answer.length.compareTo(a.answer.length));

  final standouts = <ReflectionAnswer>[];
  standouts.add(answers.first); // Longest

  // Find different category
  if (answers.length > 1) {
    final firstQuestion = await ReflectionService.instance
        .getQuestionById(answers.first.questionId);

    for (var i = 1; i < answers.length; i++) {
      final question = await ReflectionService.instance
          .getQuestionById(answers[i].questionId);
      if (question.category != firstQuestion.category) {
        standouts.add(answers[i]);
        break;
      }
    }
  }

  return standouts.take(2).toList();
}
```

### Anti-Patterns to Avoid

- **Duplicate calculations:** Don't re-implement mood averaging, trend detection, or day-of-week patterns. Reuse InsightsService.
- **Generating summaries on every app launch:** Only generate once per week, check for existing summary first.
- **Blocking UI on summary generation:** Generate summaries asynchronously in background, show loading state.
- **Ignoring week boundaries:** Always use Monday as week start (matching InsightsService._startOfWeek).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Week boundary calculation | Custom week detection logic | InsightsService._startOfWeek() + Duration math | Already tested, handles edge cases (year boundaries) |
| Mood trend analysis | New trend calculation | InsightsService.getInsightsForPeriod() | Returns trendUp, trendDown, avgMood, stdDev already calculated |
| Direction statistics | Loop through connections manually | DirectionService.getStats() | Returns avgMoodWhenConnected, moodDifference, hasPositiveCorrelation |
| Date range queries | Filter entries manually | StorageService.getEntriesForPeriod() | Efficient Hive query, already implemented |
| Mood visualization | Custom chart widget | MoodWave widget | Interactive, tested, matches Insights design |

**Key insight:** Elio's service layer already contains all analytics primitives. Weekly summaries are a presentation layer feature, not a new analytics capability. The challenge is orchestration and persistence, not calculation.

## Common Pitfalls

### Pitfall 1: Generating Summaries for Incomplete Weeks
**What goes wrong:** App generates a summary for the current week (Monday-Sunday) before Sunday completes.

**Why it happens:** Confusion between "current week" (in progress) and "previous week" (completed).

**How to avoid:** Always generate summaries for `previousWeekStart` (7 days before current Monday). Only generate when `now >= Monday of current week`.

**Warning signs:** Summary shows "0 of 7 days" or incomplete data.

### Pitfall 2: Week Start Date Ambiguity
**What goes wrong:** Different services calculate week boundaries differently (Sunday vs Monday start).

**Why it happens:** InsightsService uses Monday as week start, but developer might use Sunday (common in US).

**How to avoid:** Always use `_startOfWeek()` from InsightsService pattern (Monday = day 1).

**Warning signs:** Summary data doesn't match Insights tab for the same week.

### Pitfall 3: Not Handling Zero Directions
**What goes wrong:** App crashes or shows empty direction section when user has no directions.

**Why it happens:** Assuming directions always exist, not checking `getActiveDirections().isEmpty`.

**How to avoid:** Add conditional rendering: if no directions, show gentle prompt to create one.

**Warning signs:** Null pointer exceptions in direction rendering logic.

### Pitfall 4: Reflection Answer N+1 Problem
**What goes wrong:** Loading reflection answers one-by-one causes slow summary generation.

**Why it happens:** Calling `getAnswerById()` in a loop instead of batch fetch.

**How to avoid:** Use `ReflectionService.getAnswersByIds(List<String> ids)` for batch fetching.

**Warning signs:** Summary generation takes >500ms for weeks with many reflections.

### Pitfall 5: Stale Summary Data
**What goes wrong:** User sees old summary after editing entries from previous week.

**Why it happens:** Summary is generated once and never updated when source data changes.

**How to avoid:** Document that summaries are snapshots (not live data). Consider adding regeneration option if needed.

**Warning signs:** Summary shows different numbers than Insights tab for same week.

### Pitfall 6: Monday Detection Edge Case
**What goes wrong:** Summary doesn't appear on Monday if user opens app early in the day.

**Why it happens:** Using `now.weekday == DateTime.monday` without checking if summary already generated.

**How to avoid:** Check `now.weekday >= DateTime.monday || now.isAfter(currentWeekStart)` and verify no existing summary.

**Warning signs:** Summary only appears on Tuesday or later.

## Code Examples

Verified patterns from existing codebase:

### Week Range Calculation (from InsightsService)
```dart
// Source: lib/services/insights_service.dart:320-335
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
```

### Fetching Entries for Period (from StorageService)
```dart
// Source: lib/services/storage_service.dart (inferred from usage)
Future<List<Entry>> getEntriesForPeriod(DateTime start, DateTime end) async {
  final entries = _box.values.where((entry) {
    return !entry.isDeleted &&
           !entry.createdAt.isBefore(start) &&
           entry.createdAt.isBefore(end);
  }).toList();
  entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return entries;
}
```

### Direction Statistics with Mood Correlation
```dart
// Source: lib/services/direction_service.dart (pattern)
DirectionStats getStats(String directionId) {
  final connections = getConnectionCount(directionId);
  final avgWhenConnected = getAverageMoodWhenConnected(directionId);
  final overallAvg = getOverallAverageMood();

  return DirectionStats(
    totalConnections: connections,
    avgMoodWhenConnected: avgWhenConnected,
    overallAvgMood: overallAvg,
    moodDifference: avgWhenConnected - overallAvg,
    hasPositiveCorrelation: (avgWhenConnected - overallAvg) >= 0.1,
    hasNegativeCorrelation: (avgWhenConnected - overallAvg) <= -0.1,
    // ... other fields
  );
}
```

### Reusing MoodWave Widget
```dart
// Source: lib/screens/insights_screen.dart (pattern)
MoodWave(
  entries: periodEntries,
  periodStart: weekStart,
  daysInPeriod: 7,
  height: 180,
)
```

### Hive Model with Adapter (Pattern for WeeklySummary)
```dart
// Source: lib/models/entry.dart (pattern)
class WeeklySummary {
  WeeklySummary({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.avgMood,
    required this.checkInCount,
    required this.moodTrend,
    this.topDirectionId,
    this.standoutReflectionIds,
    required this.takeaway,
    required this.createdAt,
    this.viewedAt,
  });

  final String id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final double avgMood;
  final int checkInCount;
  final String moodTrend; // 'up', 'down', 'stable'
  final String? topDirectionId;
  final List<String>? standoutReflectionIds;
  final String takeaway;
  final DateTime createdAt;
  final DateTime? viewedAt;

  bool get hasBeenViewed => viewedAt != null;
}

class WeeklySummaryAdapter extends TypeAdapter<WeeklySummary> {
  @override
  final int typeId = 7; // Next available typeId

  @override
  WeeklySummary read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return WeeklySummary(
      id: fields[0] as String,
      weekStart: fields[1] as DateTime,
      weekEnd: fields[2] as DateTime,
      avgMood: fields[3] as double,
      checkInCount: fields[4] as int,
      moodTrend: fields[5] as String,
      topDirectionId: fields[6] as String?,
      standoutReflectionIds: (fields[7] as List?)?.cast<String>(),
      takeaway: fields[8] as String,
      createdAt: fields[9] as DateTime,
      viewedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklySummary obj) {
    writer
      ..writeByte(11) // field count
      ..writeByte(0) ..write(obj.id)
      ..writeByte(1) ..write(obj.weekStart)
      ..writeByte(2) ..write(obj.weekEnd)
      ..writeByte(3) ..write(obj.avgMood)
      ..writeByte(4) ..write(obj.checkInCount)
      ..writeByte(5) ..write(obj.moodTrend)
      ..writeByte(6) ..write(obj.topDirectionId)
      ..writeByte(7) ..write(obj.standoutReflectionIds)
      ..writeByte(8) ..write(obj.takeaway)
      ..writeByte(9) ..write(obj.createdAt)
      ..writeByte(10) ..write(obj.viewedAt);
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual week tracking | DateTime-based week boundaries | Flutter 3.0+ | Standardized across all date calculations |
| Separate analytics per feature | Centralized InsightsService | Phase 3 (Feb 2026) | Single source of truth for mood patterns |
| Individual stat cards | InsightItem list with priorities | Phase 3 (Feb 2026) | Flexible, extensible insight generation |
| Provider/Bloc state management | StatefulWidget + Services | Project start | Simpler for small-scale apps |

**Deprecated/outdated:**
- None identified. Elio is a new project (v1.1.0) with modern Flutter practices.

## Open Questions

1. **Summary Persistence Strategy**
   - What we know: Summaries are snapshots, not live data
   - What's unclear: Should summaries update if user edits entries from previous week?
   - Recommendation: Keep as snapshots (simpler), add note "Summary reflects data as of [date]"

2. **Standout Reflection Selection Algorithm**
   - What we know: Need 1-2 reflections that feel meaningful
   - What's unclear: What makes a reflection "standout"? (length, category diversity, sentiment?)
   - Recommendation: Start with longest answer + different category. Iterate based on user feedback.

3. **Takeaway Message Generation**
   - What we know: Should reference specific moments, adapt tone to mood patterns
   - What's unclear: How many variations needed? Should it be templated or AI-generated?
   - Recommendation: Start with 10-15 templates based on patterns (high mood + streak, low mood + reflections, etc.). Can add variety later.

4. **Home Card Dismissal Behavior**
   - What we know: User wants summary card on Home screen
   - What's unclear: Persist all week or dismiss after viewing?
   - Recommendation: Dismiss after viewing (set `viewedAt`). User can access history in Insights tab.

## Validation Architecture

> Validation is enabled (workflow.nyquist_validation: true in config.json)

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Flutter test framework (built-in) |
| Config file | None — standard Flutter test setup |
| Quick run command | `flutter test test/weekly_summary_service_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SUMM-01 | Week completion detection triggers summary generation | unit | `flutter test test/weekly_summary_service_test.dart::test_week_completion_detection -x` | ❌ Wave 0 |
| SUMM-01 | Summary card appears on Home screen after week completes | widget | `flutter test test/screens/mood_entry_screen_test.dart::test_summary_card_renders -x` | ❌ Wave 0 |
| SUMM-02 | Summary shows mood trend using MoodWave widget | widget | `flutter test test/screens/weekly_summary_screen_test.dart::test_mood_wave_renders -x` | ❌ Wave 0 |
| SUMM-02 | Summary shows average mood and highlights | unit | `flutter test test/services/weekly_summary_service_test.dart::test_mood_stats_calculation -x` | ❌ Wave 0 |
| SUMM-03 | Direction patterns calculated with mood correlations | unit | `flutter test test/services/weekly_summary_service_test.dart::test_direction_patterns -x` | ❌ Wave 0 |
| SUMM-03 | Top direction highlighted when mood impact ≥15% | unit | `flutter test test/services/weekly_summary_service_test.dart::test_top_direction_detection -x` | ❌ Wave 0 |
| SUMM-04 | Takeaway message generated based on week data | unit | `flutter test test/services/weekly_summary_service_test.dart::test_takeaway_generation -x` | ❌ Wave 0 |
| SUMM-04 | Takeaway tone adapts to mood patterns | unit | `flutter test test/services/weekly_summary_service_test.dart::test_takeaway_tone_adaptation -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/weekly_summary_service_test.dart -x` (fast feedback on service logic)
- **Per wave merge:** `flutter test` (full suite including widget tests)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/services/weekly_summary_service_test.dart` — covers SUMM-01, SUMM-02, SUMM-03, SUMM-04 service logic
- [ ] `test/screens/weekly_summary_screen_test.dart` — covers SUMM-02 UI rendering
- [ ] `test/screens/mood_entry_screen_test.dart` — covers SUMM-01 card rendering
- [ ] `test/models/weekly_summary_test.dart` — covers WeeklySummary model and Hive adapter

## Sources

### Primary (HIGH confidence)
- Elio codebase: `lib/services/insights_service.dart`, `lib/services/direction_service.dart`, `lib/services/storage_service.dart` — existing patterns for data aggregation and week calculations
- Elio codebase: `lib/widgets/mood_wave.dart`, `lib/widgets/stat_card.dart`, `lib/widgets/direction_card.dart` — reusable UI components
- Flutter official docs: [Card class](https://api.flutter.dev/flutter/material/Card-class.html) — Material Design Card widget
- Flutter official docs: [Material component widgets](https://docs.flutter.dev/ui/widgets/material) — standard UI components

### Secondary (MEDIUM confidence)
- [Building a card widget in Flutter - LogRocket Blog](https://blog.logrocket.com/building-a-card-widget-in-flutter/) — card layout best practices
- [Handling local data persistence in Flutter with Hive - LogRocket Blog](https://blog.logrocket.com/handling-local-data-persistence-flutter-hive/) — Hive storage patterns
- [Happio mood tracker GitHub](https://github.com/jccb15/happio) — open source mood tracker using Hive + Flutter

### Tertiary (LOW confidence)
- [Top 7 Mood Tracker Apps for 2026 - Clustox](https://www.clustox.com/blog/mood-tracker-apps/) — UX patterns for weekly summaries (general industry trends)
- [Best Mood Tracking Apps for 2026 - LifeStance Health](https://lifestance.com/blog/best-mood-tracking-apps-therapists-top-choices-2026/) — weekly summary features in commercial apps

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All dependencies already in use, no new libraries needed
- Architecture: HIGH - Patterns match existing codebase (StatefulWidget + Services, Hive models)
- Pitfalls: HIGH - Week boundary calculations are well-documented in InsightsService, edge cases understood
- Weekly summaries UX: MEDIUM - User decisions clear, but implementation details (e.g., takeaway generation) need iteration

**Research date:** 2026-02-26
**Valid until:** 2026-03-26 (30 days - stable stack, mature patterns)
