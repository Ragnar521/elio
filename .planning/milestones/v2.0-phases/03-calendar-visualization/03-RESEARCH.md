# Phase 3: Calendar Visualization - Research

**Phase:** 03-calendar-visualization
**Researched:** 2026-02-26
**Requirements:** VISP-01, VISP-02, VISP-03, VISP-04

---

## Executive Summary

Phase 3 adds a **calendar heatmap** visualization to the Insights tab, showing mood patterns at a glance. Users will see a monthly grid where each day is color-coded by average mood value, tap days to view entries, and navigate between months. This phase requires NO new data models, NO new services, and NO external calendar libraries — built entirely with custom Flutter widgets matching Elio's design system.

**Key Decision:** Build custom calendar widget instead of using third-party packages to maintain full control over design consistency, avoid dependency bloat, and match the existing Elio aesthetic perfectly.

---

## Requirements Coverage

### VISP-01: Calendar heatmap with color-coded days
**Requirement:** User can view a calendar heatmap where each day is color-coded by average mood value

**Implementation approach:**
- Custom Flutter widget rendering a 7-column grid (Mon-Sun)
- Each day cell shows date number + background color based on average mood
- Use existing mood color gradient: `Color.lerp(Color(0xFF4B5A68), ElioColors.darkAccent, moodValue)`
- Days with multiple entries: calculate average mood across all entries
- Days with no entries: dimmed surface color (subtle visual treatment)
- Rounded square cells (BorderRadius.circular(8)) for modern feel

**Data source:**
- `StorageService.getAllEntries()` — filter entries by displayed month
- Group entries by date, calculate average mood per day
- No new service methods needed

---

### VISP-02: Tap days to see entries
**Requirement:** User can tap any day on the calendar to see all entries from that day

**Implementation approach:**
- Reuse existing `DayEntriesSheet` bottom sheet (from Day Pattern Chart)
- On day tap: call `StorageService.getEntriesForDate(date)` (already exists)
- Pass entries to bottom sheet widget
- Bottom sheet shows: date header, entry count, scrollable entry cards
- Entry cards tap through to `EntryDetailScreen` (already wired)
- Days with no entries: not tappable (no visual response on tap)

**Consistency win:**
- Same bottom sheet pattern as day-of-week chart
- Same entry card layout
- Same navigation flow to detail screen

---

### VISP-03: Navigate between months
**Requirement:** User can navigate between months to view historical mood patterns

**Implementation approach:**
- Arrow buttons (← →) flanking month/year label
- Swipe gestures (left/right) for quick navigation
- Month navigation synchronized with Insights period navigation (shared state)
- Animated transitions (300ms fade + slide, direction-aware)
- Boundaries:
  - **Past boundary:** Stop at month of first-ever entry (prevent empty months)
  - **Future boundary:** Cannot navigate past current month
- Calculate boundaries using `StorageService.getAllEntries()` to find earliest entry date

**Integration decision:**
- Calendar respects Week/Month toggle in Insights tab
- When Week view selected: calendar dims or hides (focus on weekly insights)
- When Month view selected: calendar becomes prominent visualization
- Alternative: Calendar always shows full month regardless of toggle (Claude's discretion)

---

### VISP-04: Visual distinction between days with/without entries
**Requirement:** User can instantly identify which days have entries (colored) versus no entries (empty)

**Implementation approach:**
- **Days with entries:** Full mood color (gradient from low = #4B5A68 to high = #FF6436)
- **Days without entries:** Dimmed surface color or subtle outline
  - Option A: `ElioColors.darkSurface.withOpacity(0.3)` — very subtle
  - Option B: Border only (`Border.all(color: darkPrimaryText.withOpacity(0.1))`) — outline style
  - Claude's discretion on final visual treatment
- **Today's date:** Accent-colored border ring (`Border.all(color: darkAccent, width: 2)`)
- **Selected day (tapped):** Highlighted with accent ring while bottom sheet is open

**Visual hierarchy:**
- Colored cells stand out immediately
- Empty cells recede visually
- Today marker provides orientation
- Selected state gives tap feedback

---

## Technical Implementation Details

### 1. Data Fetching & Aggregation

**Existing service methods (NO CHANGES NEEDED):**
```dart
// StorageService
Future<List<Entry>> getAllEntries()          // Get all entries
Future<List<Entry>> getEntriesForDate(DateTime date) // Get entries for specific day
DateTime _dateOnly(DateTime dateTime)        // Already exists for date normalization
```

**New helper logic (in widget state):**
```dart
// Group entries by date for the displayed month
Map<DateTime, List<Entry>> _groupEntriesByDate(List<Entry> entries, DateTime month) {
  final Map<DateTime, List<Entry>> grouped = {};
  final monthStart = DateTime(month.year, month.month, 1);
  final monthEnd = DateTime(month.year, month.month + 1, 0);

  for (final entry in entries) {
    final date = _dateOnly(entry.createdAt);
    if (date.isAfter(monthStart.subtract(Duration(days: 1))) &&
        date.isBefore(monthEnd.add(Duration(days: 1)))) {
      grouped.putIfAbsent(date, () => []).add(entry);
    }
  }
  return grouped;
}

// Calculate average mood for a day's entries
double _averageMood(List<Entry> entries) {
  if (entries.isEmpty) return 0.0;
  final sum = entries.fold(0.0, (sum, e) => sum + e.moodValue);
  return sum / entries.length;
}

// Mood color from value (matches existing gradient)
Color _moodColor(double value) {
  const low = Color(0xFF4B5A68);
  const high = ElioColors.darkAccent;
  return Color.lerp(low, high, value) ?? high;
}
```

---

### 2. Calendar Widget Structure

**New file:** `lib/widgets/calendar_heatmap.dart`

**Widget hierarchy:**
```
CalendarHeatmap (StatelessWidget)
├── Column
│   ├── Month/Year Header with arrows
│   ├── Weekday labels row (M T W T F S S)
│   └── Calendar Grid (7 columns × 5-6 rows)
│       └── Day cells (GestureDetector + Container)
```

**Props:**
```dart
class CalendarHeatmap extends StatelessWidget {
  const CalendarHeatmap({
    required this.month,              // DateTime representing the month
    required this.entriesByDate,      // Map<DateTime, List<Entry>>
    required this.onDayTap,           // Function(DateTime date)
    required this.onMonthChanged,     // Function(int offset) for arrow navigation
    this.selectedDate,                // DateTime? for highlight
    this.canNavigateBack,             // bool (based on first entry)
    this.canNavigateForward,          // bool (based on current month)
  });
}
```

**Layout calculation:**
```dart
// Calendar grid generation
List<DateTime?> _buildCalendarDays(DateTime month) {
  final firstDay = DateTime(month.year, month.month, 1);
  final lastDay = DateTime(month.year, month.month + 1, 0);
  final daysInMonth = lastDay.day;

  // Monday = 1, Sunday = 7
  final firstWeekday = firstDay.weekday;

  // Leading empty cells (before month start)
  final leadingEmptyCells = firstWeekday - 1;

  // Build day list
  final days = <DateTime?>[];
  for (var i = 0; i < leadingEmptyCells; i++) {
    days.add(null); // Empty cell
  }
  for (var day = 1; day <= daysInMonth; day++) {
    days.add(DateTime(month.year, month.month, day));
  }

  // Trailing empty cells (pad to full week)
  while (days.length % 7 != 0) {
    days.add(null);
  }

  return days;
}
```

---

### 3. Day Cell Design

**Visual specifications:**
- **Size:** 40x40 pixels (square)
- **Border radius:** 8px
- **Spacing:** 4px gap between cells
- **Typography:** Body small (14px) for day number

**Cell states:**
```dart
Widget _buildDayCell(DateTime? date, Map<DateTime, List<Entry>> entriesByDate) {
  if (date == null) {
    // Empty cell (leading/trailing)
    return SizedBox(width: 40, height: 40);
  }

  final entries = entriesByDate[_dateOnly(date)] ?? [];
  final hasEntries = entries.isNotEmpty;
  final avgMood = hasEntries ? _averageMood(entries) : 0.0;
  final isToday = _isSameDay(date, DateTime.now());
  final isSelected = selectedDate != null && _isSameDay(date, selectedDate!);

  // Background color
  final bgColor = hasEntries
    ? _moodColor(avgMood)
    : ElioColors.darkSurface.withOpacity(0.3);

  // Border (today marker or selected state)
  final border = isToday
    ? Border.all(color: ElioColors.darkAccent, width: 2)
    : (isSelected ? Border.all(color: ElioColors.darkAccent, width: 1.5) : null);

  return GestureDetector(
    onTap: hasEntries ? () => onDayTap(date) : null,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        border: border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '${date.day}',
          style: TextStyle(
            color: hasEntries ? ElioColors.darkPrimaryText : ElioColors.darkPrimaryText.withOpacity(0.4),
            fontSize: 14,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}
```

---

### 4. Month Navigation

**Navigation arrows:**
```dart
Row(
  children: [
    IconButton(
      icon: Icon(Icons.chevron_left),
      onPressed: canNavigateBack ? () => onMonthChanged(-1) : null,
      color: canNavigateBack ? ElioColors.darkPrimaryText : ElioColors.darkPrimaryText.withOpacity(0.3),
    ),
    Expanded(
      child: Text(
        _monthYearLabel(month), // e.g., "February 2026"
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ),
    IconButton(
      icon: Icon(Icons.chevron_right),
      onPressed: canNavigateForward ? () => onMonthChanged(1) : null,
      color: canNavigateForward ? ElioColors.darkPrimaryText : ElioColors.darkPrimaryText.withOpacity(0.3),
    ),
  ],
)
```

**Swipe gesture detection:**
```dart
GestureDetector(
  onHorizontalDragEnd: (details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return; // Ignore slow drags

    if (velocity < 0 && canNavigateForward) {
      onMonthChanged(1); // Swipe left = next month
    } else if (velocity > 0 && canNavigateBack) {
      onMonthChanged(-1); // Swipe right = previous month
    }
  },
  child: _calendarGrid,
)
```

**Month boundary calculation:**
```dart
// In parent widget (InsightsScreen or wrapper)
DateTime _calculateFirstEntryMonth(List<Entry> entries) {
  if (entries.isEmpty) return DateTime.now();
  final sorted = entries.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final firstEntry = sorted.first;
  return DateTime(firstEntry.createdAt.year, firstEntry.createdAt.month);
}

bool _canNavigateBack(DateTime currentMonth, DateTime firstEntryMonth) {
  return currentMonth.isAfter(firstEntryMonth);
}

bool _canNavigateForward(DateTime currentMonth) {
  final now = DateTime.now();
  final currentMonthDate = DateTime(now.year, now.month);
  return currentMonth.isBefore(currentMonthDate);
}
```

---

### 5. Integration with Insights Screen

**Location:** Add calendar section to `lib/screens/insights_screen.dart`

**Placement options (Claude's discretion):**
1. **Top of scroll view** (above mood wave) — immediate visibility
2. **Between mood wave and stats** — logical flow from line chart to calendar
3. **Below day pattern chart** — grouped with other pattern visualizations

**State management:**
```dart
class _InsightsScreenState extends State<InsightsScreen> {
  // Existing state
  InsightsPeriod _period = InsightsPeriod.week;
  int _offset = 0;

  // New calendar state
  DateTime? _selectedCalendarDate;

  void _onCalendarDayTap(DateTime date, List<Entry> entries) {
    setState(() {
      _selectedCalendarDate = date;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DayEntriesSheet(
        dayName: _dateLabel(date),
        entries: entries,
        averageMood: _averageMood(entries),
      ),
    ).then((_) {
      setState(() {
        _selectedCalendarDate = null; // Clear highlight when sheet closes
      });
    });
  }
}
```

**Syncing with period navigation:**
- When user changes Week/Month toggle → update calendar visibility
- When user navigates periods with arrows → calendar reflects current period's month
- When calendar arrows are used → update parent period state to keep in sync

---

### 6. Color Legend (Optional Enhancement)

**Compact gradient bar showing mood scale:**
```dart
Widget _buildColorLegend() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Low',
        style: TextStyle(fontSize: 12, color: ElioColors.darkPrimaryText.withOpacity(0.6)),
      ),
      SizedBox(width: 8),
      Container(
        width: 120,
        height: 8,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4B5A68), ElioColors.darkAccent],
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      SizedBox(width: 8),
      Text(
        'High',
        style: TextStyle(fontSize: 12, color: ElioColors.darkPrimaryText.withOpacity(0.6)),
      ),
    ],
  );
}
```

**Placement:** Below calendar grid, subtle and compact

---

## Library Research: Why NO External Calendar Package

### Evaluated Packages

**Research sources:**
- [table_calendar package](https://pub.dev/packages/table_calendar)
- [flutter_heatmap_calendar package](https://pub.dev/documentation/flutter_heatmap_calendar/latest/)
- [simple_heatmap_calendar package](https://pub.dev/packages/simple_heatmap_calendar)
- [Syncfusion Flutter Calendar](https://www.syncfusion.com/blogs/post/heat-map-calendar-using-flutter-event-calendar)

### Decision: Build Custom Widget

**Why NOT use external packages:**

1. **Design system mismatch:** All packages use their own styling — would require extensive overrides to match Elio's 18px border radius, #1C1C1E background, #F9DFC1 text, etc.

2. **Dependency bloat:** `table_calendar` is feature-rich (300+ lines) but includes event markers, multi-select, range selection, etc. — all unused. Adds ~50KB to app size.

3. **Over-engineering:** `simple_heatmap_calendar` designed for GitHub-style contribution charts with year-long views. Elio needs month-only view with mood gradient.

4. **Licensing/commercial:** Syncfusion requires commercial license for production apps (not open source).

5. **Control & maintenance:** Custom widget = full control over layout, animations, gestures. No breaking changes from third-party updates.

6. **Simplicity:** Calendar grid is ~150 lines of Dart code (see layout calculation above). No complex logic needed — just date math and grid rendering.

**What we gain by building custom:**
- Perfect match to Elio design system (colors, radius, spacing)
- Lightweight (no unused features)
- Swipe gestures tailored to app navigation patterns
- Easy integration with existing `DayEntriesSheet`
- No external dependency risk

**Estimated implementation time:** 2-3 hours (widget + integration + testing)

---

## Edge Cases & Considerations

### 1. Empty States
**Scenario:** User has no entries in a given month
**Handling:** Show full calendar with all days in dimmed state, no tap responses. Arrow navigation still works (can browse empty months).

### 2. Multiple Entries Per Day
**Scenario:** User creates 2+ entries on the same day
**Handling:** Calculate average mood across all entries. Bottom sheet shows all entries for the day (already supported by `DayEntriesSheet`).

### 3. Partial Months
**Scenario:** Current month is only partially complete (e.g., Feb 26, 2026)
**Handling:** Future days (27-28) shown in dimmed state. Today (26) gets accent border. Past days show mood data.

### 4. Very First Month
**Scenario:** User's first entry was this month
**Handling:** Back arrow disabled (grayed out). User cannot navigate to months before their first entry.

### 5. Leap Years & Month Boundaries
**Scenario:** February 2024 (29 days) vs February 2025 (28 days)
**Handling:** Dart's `DateTime` handles this natively. `DateTime(year, month + 1, 0).day` returns correct last day.

### 6. Time Zones
**Scenario:** User travels across time zones
**Handling:** All dates use device local time (same as rest of app). No UTC conversion needed since no cloud sync.

### 7. Animation Performance
**Scenario:** Rapid month navigation (user spam-taps arrows)
**Handling:** Debounce navigation or disable arrows during animation (300ms). Prevent stacked animations.

---

## Performance Considerations

### Data Volume Estimates
- **Typical user:** 365 entries/year (1 per day)
- **Power user:** 730 entries/year (2 per day)
- **Monthly view:** ~30-60 entries loaded at once
- **Grouping operation:** O(n) where n = entries in month — negligible for <100 entries

### Memory Footprint
- **Calendar grid:** 35-42 day cells × 40x40 pixels = minimal render cost
- **Entry data:** Already loaded in `InsightsScreen` via `getAllEntries()`
- **No caching needed:** Rebuilds on month change (fast enough for <1000 total entries)

### Render Optimization
- Use `const` constructors where possible
- GridView.builder NOT needed (only 35-42 cells, no scrolling)
- Simple Column + Wrap or Table widget for grid

---

## Testing Strategy

### Manual Testing Scenarios
1. **Month navigation:**
   - Navigate backwards to first entry month → arrow disables
   - Navigate forwards to current month → arrow disables
   - Swipe left/right to change months → smooth animation

2. **Day interactions:**
   - Tap day with entries → bottom sheet appears
   - Tap day without entries → no response
   - Tap today → accent border visible

3. **Mood colors:**
   - Low mood entry (0.0-0.33) → dark gray/blue cell
   - Mid mood entry (0.33-0.66) → transition color
   - High mood entry (0.66-1.0) → warm orange cell

4. **Edge cases:**
   - Empty month → all cells dimmed
   - Multiple entries per day → average mood displayed
   - Leap year February → 29 days shown correctly

### Visual Regression Checks
- Calendar matches design system (border radius, colors, spacing)
- Weekday labels aligned with columns
- Today marker visible and distinct
- Bottom sheet consistent with existing pattern

---

## Dependencies

**New dependencies:** NONE

**Existing dependencies used:**
- `flutter/material.dart` — UI framework
- `lib/models/entry.dart` — Entry model
- `lib/services/storage_service.dart` — Data fetching
- `lib/theme/elio_colors.dart` — Color constants
- `lib/widgets/day_entries_sheet.dart` — Bottom sheet (reused)

**New files created:**
- `lib/widgets/calendar_heatmap.dart` — Calendar widget (~200 lines)

**Modified files:**
- `lib/screens/insights_screen.dart` — Add calendar section (~50 lines added)

---

## Open Questions for Planning Phase

### 1. Calendar Visibility & Period Toggle
**Question:** Should the calendar respect the Week/Month toggle?
**Options:**
- A) Calendar always shows full month (regardless of toggle)
- B) Calendar hides when Week view selected, shows when Month selected
- C) Calendar always visible (toggle only affects stats/charts below)

**Recommendation:** Option B (calendar tied to Month view) — reinforces that calendar is a monthly visualization tool.

---

### 2. Empty Day Visual Treatment
**Question:** How should days without entries look?
**Options:**
- A) Dimmed surface (`ElioColors.darkSurface.withOpacity(0.3)`)
- B) Subtle outline only (`Border.all(color: darkPrimaryText.withOpacity(0.1))`)
- C) Slightly darker background than surface

**Recommendation:** Option A (dimmed surface) — provides subtle fill while still clearly distinguishing from colored days.

---

### 3. Calendar Positioning
**Question:** Where in the Insights tab should the calendar live?
**Options:**
- A) Top of scroll view (first thing users see)
- B) Between mood wave and stat cards
- C) Below day pattern chart (grouped with patterns)

**Recommendation:** Option C (below day pattern chart) — groups related visualizations, doesn't push primary insights (wave + stats) down.

---

### 4. Multi-Entry Day Color
**Question:** If user has 3 entries in one day with moods [0.2, 0.5, 0.8], what color?
**Options:**
- A) Average mood (0.5) — balanced representation
- B) Highest mood (0.8) — optimistic view
- C) Most recent mood (time-weighted) — current state

**Recommendation:** Option A (average mood) — most mathematically sound, aligns with how InsightsService calculates daily averages.

---

## Success Metrics (Post-Implementation)

**Functional completeness:**
- [ ] User can see calendar with color-coded days (VISP-01)
- [ ] User can tap days to see entries (VISP-02)
- [ ] User can navigate months with arrows + swipe (VISP-03)
- [ ] User can distinguish days with/without entries (VISP-04)

**Design consistency:**
- [ ] Calendar matches Elio design system (colors, spacing, radius)
- [ ] Animations feel smooth (300ms transitions)
- [ ] Bottom sheet reuses existing `DayEntriesSheet` component
- [ ] Today marker and selected state are visually distinct

**Performance:**
- [ ] Month transitions feel instant (no lag)
- [ ] No jank when opening bottom sheet
- [ ] Works smoothly with 500+ total entries

**Edge cases handled:**
- [ ] Empty months show gracefully
- [ ] First entry month boundary prevents over-navigation
- [ ] Current month boundary prevents future navigation
- [ ] Leap years render correctly

---

## Next Steps → Planning

**Planning phase should define:**
1. **Final calendar positioning** in Insights tab layout
2. **Empty day visual treatment** (dimmed vs outline)
3. **Period toggle behavior** (hide on week view vs always visible)
4. **Multi-entry color calculation** (average vs highest vs recent)
5. **Animation timing** (300ms fade + slide, spring curve?)
6. **Color legend inclusion** (yes/no, placement)

**Task breakdown estimate:**
1. Create `CalendarHeatmap` widget (core grid + styling) — 2 hours
2. Add month navigation (arrows + swipe) — 1 hour
3. Integrate day tap → `DayEntriesSheet` — 30 minutes
4. Integrate into `InsightsScreen` + state sync — 1 hour
5. Polish animations, boundaries, edge cases — 1.5 hours
6. Testing (manual + visual regression) — 1 hour

**Total:** ~7 hours implementation time

---

**Research complete.** Ready for planning phase.

---

*Sources:*
- [table_calendar package](https://pub.dev/packages/table_calendar)
- [simple_heatmap_calendar package](https://pub.dev/packages/simple_heatmap_calendar)
- [flutter_heatmap_calendar API docs](https://pub.dev/documentation/flutter_heatmap_calendar/latest/)
- [Syncfusion Flutter Calendar heatmap tutorial](https://www.syncfusion.com/blogs/post/heat-map-calendar-using-flutter-event-calendar)
