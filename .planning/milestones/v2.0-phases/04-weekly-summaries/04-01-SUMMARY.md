---
phase: 04-weekly-summaries
plan: 01
subsystem: data-layer
tags: [backend, model, service, hive, analytics]
dependency_graph:
  requires:
    - lib/services/insights_service.dart (mood analytics)
    - lib/services/direction_service.dart (direction stats)
    - lib/services/reflection_service.dart (answer fetching)
    - lib/services/storage_service.dart (entry queries)
  provides:
    - lib/models/weekly_summary.dart (WeeklySummary model + adapter)
    - lib/services/weekly_summary_service.dart (summary generation + persistence)
  affects:
    - lib/main.dart (service initialization)
tech_stack:
  added:
    - intl: ^0.19.0 (date formatting for weekLabel)
  patterns:
    - Manual Hive TypeAdapter (typeId: 7, follows Entry pattern)
    - Singleton service pattern (instance getter)
    - Service orchestration (aggregates data from multiple services)
    - Denormalized snapshots (store direction/reflection data directly)
key_files:
  created:
    - lib/models/weekly_summary.dart (WeeklySummary model, 132 lines)
    - lib/services/weekly_summary_service.dart (service with generation logic, 393 lines)
  modified:
    - lib/main.dart (added WeeklySummaryService.instance.init())
    - pubspec.yaml (added intl package)
decisions:
  - key: Denormalized direction and reflection data in summaries
    rationale: Summaries are snapshots - storing titles and question text directly means the summary remains accurate even if directions are archived or entries edited later
    impact: Increases storage size slightly but ensures summary integrity over time
  - key: Reuse InsightsService.getInsightsForPeriod for mood analytics
    rationale: Avoids duplicating trend detection, average calculations, and day pattern logic
    impact: Summary generation leverages battle-tested analytics code, reduces maintenance
  - key: Calculate best mood day from entries, not from InsightsService
    rationale: InsightsService doesn't track individual entry peaks, only day-of-week averages
    impact: Requires direct entry scan but provides specific "Thursday when you felt Joyful" context
  - key: 13-template takeaway system with priority-based selection
    rationale: Ensures takeaway is always contextual and supportive, adapts to different week patterns
    impact: Scalable message generation without AI overhead, consistent warm tone
  - key: Reflection selection by length + category diversity
    rationale: Longer answers indicate thoughtfulness, different categories show breadth
    impact: Simple heuristic that surfaces meaningful reflections without sentiment analysis
metrics:
  duration_minutes: 14
  tasks_completed: 3
  files_created: 2
  files_modified: 2
  commits: 3
  lines_added: ~600
  completed_date: 2026-02-26
---

# Phase 04 Plan 01: Weekly Summary Data Layer

Built the complete data foundation for weekly summaries: WeeklySummary Hive model (typeId 7) and WeeklySummaryService that orchestrates summary generation from InsightsService, DirectionService, and ReflectionService. Summaries capture mood trends, direction patterns, standout reflections, and personalized takeaways for each completed week.

## Tasks Completed

### Task 1: Create WeeklySummary model with Hive adapter
- Created `lib/models/weekly_summary.dart` with all 17 fields
- Implemented manual Hive adapter (typeId: 7) following Entry pattern
- Added computed properties: `hasBeenViewed`, `weekLabel`, `hasDirections`, `hasReflections`
- Designed for denormalized snapshots: stores direction titles, emojis, and reflection text directly
- **Commit:** 365526a

### Task 2a: Create WeeklySummaryService skeleton with persistence and detection
- Created `lib/services/weekly_summary_service.dart` singleton following existing service pattern
- Implemented Hive box initialization and adapter registration
- Added `hasUnviewedSummary()` for Home screen card detection (checks previous week Monday)
- Added `getOrGenerateCurrentSummary()` with automatic generation for weeks with ≥1 entry
- Added `markAsViewed()` to track when user opens full summary
- Added `getAllSummaries()` for Insights history browsing (sorted descending by weekStart)
- Added `getSummaryForWeek()` for date-based lookup
- Created `_generateSummary()` stub with minimal implementation
- Initialized service in `lib/main.dart` after DirectionService
- **Commit:** 362c853

### Task 2b: Implement summary generation algorithms
- Completed `_generateSummary()` with full InsightsService integration:
  - Fetches week entries via `StorageService.getEntriesForPeriod()`
  - Calls `InsightsService.getInsightsForPeriod()` with offset -1 for previous week
  - Extracts mood stats: avgMood, checkInCount, daysWithEntries, moodTrend, mostFeltMood
- Calculates best mood day from entries:
  - Finds entry with highest moodValue
  - Stores weekday name ("Thursday"), mood value, and mood word
  - Enables specific moment references in takeaway
- Builds direction summaries:
  - Loops active directions, fetches `DirectionStats` for each
  - Calculates weekly connections for the specific week period (not generic "last 7 days")
  - Serializes to `Map<String, dynamic>`: directionId, title, emoji, weeklyConnections, avgMoodWhenConnected, moodDifference
  - Identifies top direction: highest positive moodDifference ≥ 0.1 threshold
- Implemented `_selectStandoutReflections()`:
  - Collects all reflection answer IDs from week entries
  - Batch-fetches answers via `ReflectionService.getAnswersByIds()`
  - Sorts by length descending (longer = more thoughtful)
  - Picks longest answer + different category/question for diversity
  - Denormalizes to {questionText, answer} maps (max 2 items)
  - Returns null if no reflections exist
- Implemented `_generateTakeaway()` with 13 prioritized templates:
  1. Perfect week (7 check-ins): "Seven for seven..."
  2. Improving trend + reflections: "Your reflections show real self-awareness..."
  3. Low mood + showed up: "Even on harder weeks, you kept checking in..."
  4. Low mood + reflections: "Tough weeks are worth reflecting on..."
  5. High mood + streak: "What a week! You showed up N days..."
  6. High mood + reflections: "Your reflections show real self-awareness..."
  7. Best day reference: "Your best mood was Thursday when you felt Joyful..."
  8. Direction engagement: "You connected N entries to your directions..."
  9. Reflection-heavy: "You reflected on N days this week..."
  10. Improving trend: "Your mood trended upward..."
  11. Stable mood: "Consistency is its own kind of strength..."
  12. One entry only: "One check-in is still a check-in..."
  13. Default: "Another week, another set of data points about you..."
  - Adapts tone to mood patterns: gentle acknowledgment for low mood, celebratory for high
  - References specific moments when available
- Added intl package (^0.19.0) for date formatting in `weekLabel`
- Removed unused helper methods (use InsightsService directly)
- **Commit:** 431a27f

## Deviations from Plan

None - plan executed exactly as written.

## Technical Implementation

### Data Model (WeeklySummary)
17 fields covering all summary aspects:
- **Identity:** id (UUID), weekStart/weekEnd (Monday-Sunday), createdAt, viewedAt
- **Mood metrics:** checkInCount, daysWithEntries, avgMood, moodTrend ('up'/'down'/'stable'), mostFeltMood
- **Best moment:** bestMoodDay (weekday name), bestMoodValue, bestMoodWord
- **Direction patterns:** directionSummaries (List<Map>), topDirectionId
- **Reflection highlights:** standoutReflectionAnswers (List<Map>)
- **Personalized message:** takeaway (String)

Computed properties for UI convenience: `hasBeenViewed`, `weekLabel`, `hasDirections`, `hasReflections`.

### Service Orchestration Pattern
`WeeklySummaryService._generateSummary()` coordinates data from 4 services:
1. **StorageService:** Entry queries (week period, all entries for context)
2. **InsightsService:** Mood analytics (avg, trend, most felt, reflection rate)
3. **DirectionService:** Direction stats (connections, mood correlations)
4. **ReflectionService:** Batch answer fetching for standout selection

This pattern avoids duplicate analytics logic while providing rich summary data.

### Denormalization Strategy
Summaries store direction titles, emojis, and reflection question text directly. This makes summaries self-contained snapshots that remain accurate even if:
- User archives a direction (summary still shows its old data)
- User edits/deletes an entry (summary preserves original reflection text)

Tradeoff: Slightly larger storage size (~200 bytes per summary) for guaranteed integrity.

### Takeaway Generation Algorithm
Priority-based template selection (first match wins):
- **High-priority patterns:** Perfect week, improving + reflections, low mood acknowledgment
- **Mid-priority patterns:** High mood celebration, best day reference, direction engagement
- **Fallback patterns:** Reflection rate, trend, stability, single entry
- **Default:** Generic encouraging message

Tone adaptation:
- avgMood < 0.35: Gentle, acknowledging ("Even on harder weeks...")
- avgMood ≥ 0.6: Celebratory, energizing ("What a week!")
- Otherwise: Neutral, supportive ("Consistency is its own kind of strength...")

### Week Boundary Logic
- Week start: Monday (matches InsightsService._startOfWeek pattern)
- Summary triggers: When app detects `now >= currentWeekMonday` AND no summary exists for previous week
- Generation condition: At least 1 entry in the previous week (no summaries for empty weeks)

## Verification

Automated checks passed:
```bash
$ flutter analyze lib/services/weekly_summary_service.dart lib/models/weekly_summary.dart
Analyzing 2 items...
No issues found! (ran in 0.6s)
```

Manual verification:
- `grep -n "class WeeklySummary"` → Found at line 4 (model), line 60 (adapter)
- `grep -n "typeId = 7"` → Confirmed typeId 7 for WeeklySummaryAdapter
- `grep -n "hasBeenViewed"` → Computed property at line 44
- `grep -n "WeeklySummaryService"` → Service initialized in main.dart
- `grep -n "_generateSummary"` → Full implementation at line 128
- `grep -n "_selectStandoutReflections"` → Implemented at line 257
- `grep -n "_generateTakeaway"` → Implemented at line 301
- `grep -n "bestMoodDay"` → Calculated from entries at line 153

All key methods present and functional.

## Next Steps

This plan provides the complete data foundation. Plan 02 will build the UI:
- Home screen weekly summary card (conditionally rendered)
- Full summary detail screen (MoodWave, direction cards, reflection highlights)
- Insights tab summary history section

The service is ready for UI integration - no additional data logic needed.

## Self-Check: PASSED

Created files verified:
```bash
$ [ -f "lib/models/weekly_summary.dart" ] && echo "FOUND: lib/models/weekly_summary.dart"
FOUND: lib/models/weekly_summary.dart
$ [ -f "lib/services/weekly_summary_service.dart" ] && echo "FOUND: lib/services/weekly_summary_service.dart"
FOUND: lib/services/weekly_summary_service.dart
```

Commits verified:
```bash
$ git log --oneline --all | grep -q "365526a" && echo "FOUND: 365526a"
FOUND: 365526a
$ git log --oneline --all | grep -q "362c853" && echo "FOUND: 362c853"
FOUND: 362c853
$ git log --oneline --all | grep -q "431a27f" && echo "FOUND: 431a27f"
FOUND: 431a27f
```

All artifacts created and committed successfully.
