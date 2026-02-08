# Elio — Insights Redesign (Complete Specification)

## ✅ STATUS: FULLY IMPLEMENTED (February 8, 2026)

All features from this specification have been successfully implemented and are live in the app.

## Overview

**Previous state:** Beautiful mood wave + 1 generic insight + 3 basic stats = decoration
**Current state:** Actionable patterns + context + direction + interactions = true clarity coach

The Insights screen should help users:
1. **Understand** — "Aha, that's why I feel this way"
2. **See direction** — "I'm doing better than last week"
3. **Take action** — "I should try a gentler Monday routine"

---

## Implementation Summary

### ✅ Completed Goals (All 8 + 2 Bonus Features)

1. ✅ **Make mood wave interactive** - Tap dot → tooltip with "View Entry →" button → EntryDetailScreen
2. ✅ **Add navigation hints** - Arrow buttons (‹ ›) + swipe gestures + visual feedback
3. ✅ **Show 2-3 insights** - Priority-based generation with emoji icons
4. ✅ **Add reflection statistics** - Rate + count displayed in stat cards
5. ✅ **Add comparison to previous period** - Percentage change shown below wave
6. ✅ **Track and display longest streak** - All-time best + backfill on first run
7. ✅ **Add day-of-week pattern visualization** - Horizontal bars with best/worst indicators
8. ✅ **Generate actionable pattern insights** - Contextual suggestions based on day patterns

### 🎁 Bonus Features Implemented

9. ✅ **Period transition animations** - 300ms fade + slide transitions (direction-aware)
10. ✅ **Tappable day pattern chart** - Tap any day → bottom sheet with filtered entries

---

## Screen Layout

```
┌─────────────────────────────────────┐
│ Insights                            │
├─────────────────────────────────────┤
│                                     │
│        [Week]  [Month]              │
│       ‹ Feb 3 - Feb 9 ›             │  ← tappable arrows
│                                     │
│   ╭───────────────────────────╮     │
│   │                           │     │
│   │      MOOD WAVE            │     │  ← tap dot → Entry Detail
│   │      (interactive)        │     │
│   │                           │     │
│   ╰───────────────────────────╯     │
│                                     │
│   This week: 0.65 avg  ↑12%         │  ← comparison line
│                                     │
│   ┌───────────────────────────┐     │
│   │ 📈 Your mood lifted as    │     │
│   │    the week went on.      │     │
│   │                           │     │
│   │ 🔥 5 days in a row.       │     │
│   │    You're building rhythm.│     │  ← 2-3 insights card
│   │                           │     │
│   │ 📝 Reflected 4 of 5 days. │     │
│   │    That's real commitment.│     │
│   └───────────────────────────┘     │
│                                     │
│   ┌─────┬─────┬─────┬─────┐         │
│   │  5  │  3  │ 80% │Calm │         │
│   │of 7 │days │4of5 │most │         │  ← 4 stat cards
│   │ ↑2  │best8│     │felt │         │
│   └─────┴─────┴─────┴─────┘         │
│                                     │
│   YOUR WEEK PATTERN                 │
│   ┌───────────────────────────┐     │
│   │ Mon ████░░░░░░  0.35  😔 │     │
│   │ Tue ██████░░░░  0.55     │     │
│   │ Wed ███████░░░  0.65     │     │
│   │ Thu ████████░░  0.75     │     │  ← day-of-week chart
│   │ Fri █████████░  0.85     │     │
│   │ Sat ██████████  0.95  😊 │     │
│   │ Sun █████████░  0.88     │     │
│   └───────────────────────────┘     │
│                                     │
│   💡 Saturdays are your best days.  │
│      Mondays tend to be tougher.    │  ← pattern insight
│                                     │
└─────────────────────────────────────┘
```

---

## Task 1: Mood Wave — Tap to Entry Detail

### Current Behavior
- Tap dot → shows tooltip with date, mood, intention
- Tooltip disappears on tap outside

### New Behavior
- Tap dot → shows enhanced tooltip with "View Entry" button
- Tap "View Entry" → navigates to EntryDetailScreen

### Tooltip Design

```
┌─────────────────────────┐
│ Mon, Feb 8 at 3:45 PM   │
│ 😌 Calm                 │
│ "Focus on the report"   │
│                         │
│     [View Entry →]      │  ← tappable, Warm Orange text
└─────────────────────────┘
```

### Implementation

In `mood_wave.dart`:

```dart
// When dot is tapped, show tooltip with entry data
void _showEntryTooltip(Entry entry, Offset position) {
  // Show overlay with:
  // - DateTime formatted
  // - Mood word with appropriate emoji
  // - Intention (truncated to 2 lines)
  // - "View Entry →" button
}

// On "View Entry" tap:
void _navigateToEntry(Entry entry) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EntryDetailScreen(entry: entry),
    ),
  );
}
```

---

## Task 2: Swipe Navigation Hints

### Current Behavior
- Swipe left/right to navigate periods (hidden, no visual hint)
- Users don't discover this feature

### New Behavior
- Show tappable arrows: `‹ Feb 3 - Feb 9 ›`
- Arrows are also tappable (not just swipe)
- Right arrow hidden/disabled when at current period
- Subtle animation when swiping

### Design

```
        ‹  Feb 3 - Feb 9  ›
        ↑                  ↑
    tap to go          tap to go
    backward           forward
```

### Implementation

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // Left arrow (always visible, goes to past)
    IconButton(
      icon: Icon(Icons.chevron_left, color: ElioTheme.softCream),
      onPressed: () => _navigatePeriod(-1),
    ),
    
    // Period label
    Text(
      _formatPeriodLabel(), // "Feb 3 - Feb 9" or "February 2026"
      style: TextStyle(color: ElioTheme.softCream, fontSize: 16),
    ),
    
    // Right arrow (hidden or disabled at current period)
    IconButton(
      icon: Icon(
        Icons.chevron_right,
        color: _isCurrentPeriod ? ElioTheme.softCream.withOpacity(0.3) : ElioTheme.softCream,
      ),
      onPressed: _isCurrentPeriod ? null : () => _navigatePeriod(1),
    ),
  ],
)
```

---

## Task 3: Multiple Insights (2-3)

### Current Behavior
- Shows only 1 insight text

### New Behavior
- Shows 2-3 insights based on data
- Each insight has emoji icon
- Displayed in a card with subtle background

### Insight Priority Rules

Generate insights in this priority order. Pick the **top 2-3** that apply:

| Priority | Condition | Icon | Insight Text |
|----------|-----------|------|--------------|
| 1 | streak ≥ 7 | 🔥 | "You've checked in every day this [week/month]. That's real commitment." |
| 2 | streak ≥ 3 | 🔥 | "[X] days in a row. You're building a rhythm." |
| 3 | trend up (> 0.05) | 📈 | "Your mood lifted as the [week/month] went on. Something's working." |
| 4 | trend down (< -0.05) | 📉 | "This [week/month] felt heavier toward the end. Be gentle with yourself." |
| 5 | vs previous ↑ (> 10%) | ✨ | "Your mood is up from last [week/month]. Nice progress." |
| 6 | vs previous ↓ (> 10%) | 💪 | "Tougher than last [week/month]. That's okay — you're still here." |
| 7 | reflection rate ≥ 80% | 📝 | "Reflected [X] of [Y] days. That's deep work." |
| 8 | reflection rate ≥ 50% | 📝 | "Reflection is becoming part of your routine." |
| 9 | stable mood (stdDev < 0.15) | ⚖️ | "A steady [week/month]. Consistency can be its own strength." |
| 10 | volatile mood (stdDev > 0.25) | 🌊 | "Some ups and downs this [week/month]. That's completely human." |
| 11 | avg mood > 0.7 | ☀️ | "A good [week/month] overall. Notice what made it work." |
| 12 | avg mood < 0.3 | 🌱 | "A tough [week/month]. You still showed up — that matters." |
| 13 | check-ins ≤ 2 | 👣 | "Just getting started. Every check-in counts." |
| 14 | fallback (always) | 👣 | "You're here. That's the first step." |

### Display Design

```
┌─────────────────────────────────────┐
│                                     │
│  📈  Your mood lifted as the week   │
│      went on. Something's working.  │
│                                     │
│  🔥  5 days in a row. You're        │
│      building a rhythm.             │
│                                     │
│  📝  Reflected 4 of 5 days.         │
│      That's deep work.              │
│                                     │
└─────────────────────────────────────┘
```

- Background: Soft Graphite (#313134)
- Border radius: 18px
- Padding: 16px
- Gap between insights: 12px
- Icon size: 20px
- Text: 15px, Soft Cream

### Implementation

```dart
class InsightItem {
  final String icon;
  final String text;
  
  InsightItem(this.icon, this.text);
}

List<InsightItem> generateInsights(InsightsData data, bool isWeekView) {
  final insights = <InsightItem>[];
  final period = isWeekView ? "week" : "month";
  
  // Priority 1: Perfect streak
  if (data.currentStreak >= 7) {
    insights.add(InsightItem("🔥", "You've checked in every day this $period. That's real commitment."));
  }
  // Priority 2: Good streak
  else if (data.currentStreak >= 3) {
    insights.add(InsightItem("🔥", "${data.currentStreak} days in a row. You're building a rhythm."));
  }
  
  // Priority 3-4: Trend
  if (data.moodTrend > 0.05) {
    insights.add(InsightItem("📈", "Your mood lifted as the $period went on. Something's working."));
  } else if (data.moodTrend < -0.05) {
    insights.add(InsightItem("📉", "This $period felt heavier toward the end. Be gentle with yourself."));
  }
  
  // Priority 5-6: Comparison to previous
  if (data.moodChangeVsPrevious != null) {
    if (data.moodChangeVsPrevious! > 0.1) {
      insights.add(InsightItem("✨", "Your mood is up from last $period. Nice progress."));
    } else if (data.moodChangeVsPrevious! < -0.1) {
      insights.add(InsightItem("💪", "Tougher than last $period. That's okay — you're still here."));
    }
  }
  
  // Priority 7-8: Reflection rate
  if (data.reflectionRate >= 0.8) {
    insights.add(InsightItem("📝", "Reflected ${data.reflectionDays} of ${data.checkInCount} days. That's deep work."));
  } else if (data.reflectionRate >= 0.5) {
    insights.add(InsightItem("📝", "Reflection is becoming part of your routine."));
  }
  
  // Continue with remaining priorities...
  // ...
  
  // Return top 3 (or 2 if only 2 available)
  return insights.take(3).toList();
}
```

---

## Task 4: Enhanced Stat Cards

### Current Behavior
- 3 cards: Check-ins, Streak, Most felt
- No context or comparison

### New Behavior
- 4 cards: Check-ins, Streak, Reflections, Most felt
- Each card shows comparison or context

### Weekly View Cards

| Card | Primary | Secondary | Tertiary |
|------|---------|-----------|----------|
| Check-ins | `5` | `of 7 days` | `↑2` (vs last week, green if positive) |
| Streak | `3` | `days` | `best: 8` |
| Reflections | `80%` | `4 of 5` | — |
| Most felt | `Calm` | — | — |

### Monthly View Cards

| Card | Primary | Secondary | Tertiary |
|------|---------|-----------|----------|
| Check-ins | `22` | `of 28 days` | `↑5` (vs last month) |
| Streak | `3` | `current` | `best: 12` |
| Reflections | `75%` | `17 of 22` | — |
| Most felt | `Calm` | `8 times` | — |

### Visual Design

```
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│    5     │ │    3     │ │   80%    │ │  Calm    │
│ of 7 days│ │   days   │ │  4 of 5  │ │          │
│    ↑2    │ │  best: 8 │ │          │ │          │
└──────────┘ └──────────┘ └──────────┘ └──────────┘
```

- Card background: Soft Graphite (#313134)
- Primary value: 24px, bold, Soft Cream
- Secondary label: 11px, Soft Cream 60% opacity
- Tertiary (comparison): 11px
  - Positive: Soft Green (#4CAF50)
  - Negative: Soft Cream 50% opacity (no red, no guilt)
  - Neutral: Soft Cream 50% opacity
- Gap between cards: 8px
- Card border radius: 12px
- Card padding: 12px

### Implementation

```dart
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String? comparison;
  final bool? isPositive; // true = green, false/null = neutral

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ElioTheme.softGraphite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: ElioTheme.softCream.withOpacity(0.6))),
          if (comparison != null) ...[
            SizedBox(height: 4),
            Text(
              comparison!,
              style: TextStyle(
                fontSize: 11,
                color: isPositive == true 
                  ? Color(0xFF4CAF50) 
                  : ElioTheme.softCream.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

---

## Task 5: Comparison to Previous Period

### New Data Required

```dart
// In InsightsService
Future<InsightsData> getInsights(DateTime start, DateTime end) async {
  final entries = await _getEntriesForPeriod(start, end);
  
  // Calculate previous period
  final duration = end.difference(start);
  final previousStart = start.subtract(duration);
  final previousEnd = start.subtract(Duration(days: 1));
  final previousEntries = await _getEntriesForPeriod(previousStart, previousEnd);
  
  // Current period stats
  final avgMood = _calculateAverage(entries);
  final checkInCount = entries.length;
  
  // Previous period stats
  final previousAvgMood = _calculateAverage(previousEntries);
  final previousCheckInCount = previousEntries.length;
  
  // Comparison
  final moodChangeVsPrevious = previousAvgMood > 0 
    ? (avgMood - previousAvgMood) / previousAvgMood 
    : null;
  final checkInChangeVsPrevious = previousCheckInCount > 0
    ? checkInCount - previousCheckInCount
    : null;
  
  return InsightsData(
    // ... existing fields
    previousPeriodAvg: previousAvgMood,
    previousPeriodCheckIns: previousCheckInCount,
    moodChangeVsPrevious: moodChangeVsPrevious,
    checkInChangeVsPrevious: checkInChangeVsPrevious,
  );
}
```

### Comparison Line Display

Below the mood wave, show a subtle comparison line:

```
This week: 0.65 avg  ↑12% vs last week
```

Or if no previous data:

```
This week: 0.65 avg
```

Design:
- Font size: 13px
- Color: Soft Cream 70% opacity
- Arrow color: Green for positive, neutral for negative
- Alignment: Center

---

## Task 6: Longest Streak Tracking

### Current Behavior
- Only tracks current streak
- No historical best

### New Behavior
- Track longest streak ever (all-time)
- Track longest streak in current period (week/month)
- Display in stat card: `best: 8`

### Storage

Add to StorageService or create streak tracking:

```dart
// In storage_service.dart or new streak_service.dart

Future<int> getLongestStreak() async {
  final box = Hive.box('settings');
  return box.get('longestStreak', defaultValue: 0);
}

Future<void> updateLongestStreak(int currentStreak) async {
  final box = Hive.box('settings');
  final longest = box.get('longestStreak', defaultValue: 0);
  if (currentStreak > longest) {
    await box.put('longestStreak', currentStreak);
  }
}

// Call this whenever a new entry is saved
Future<void> onEntrySaved() async {
  final currentStreak = await calculateCurrentStreak();
  await updateLongestStreak(currentStreak);
}
```

### In InsightsData

```dart
class InsightsData {
  // ... existing
  final int longestStreakAllTime;
  final int longestStreakInPeriod;
}
```

---

## Task 7: Day-of-Week Pattern Chart

### Purpose
Show users which days of the week tend to be better/worse for their mood.

### Data Calculation

```dart
Map<int, double> calculateDayOfWeekPattern(List<Entry> entries) {
  // Group entries by day of week (1=Monday, 7=Sunday)
  final Map<int, List<double>> grouped = {};
  
  for (final entry in entries) {
    final day = entry.createdAt.weekday; // 1-7
    grouped.putIfAbsent(day, () => []);
    grouped[day]!.add(entry.moodValue);
  }
  
  // Calculate average for each day
  final Map<int, double> averages = {};
  for (final day in grouped.keys) {
    final values = grouped[day]!;
    averages[day] = values.reduce((a, b) => a + b) / values.length;
  }
  
  return averages;
}

// Find best and worst days
(int? bestDay, int? worstDay) findBestWorstDays(Map<int, double> pattern) {
  if (pattern.isEmpty) return (null, null);
  
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
  
  // Only return if difference is meaningful (> 0.15)
  if (bestAvg - worstAvg < 0.15) return (null, null);
  
  return (bestDay, worstDay);
}
```

### Visual Design

```
YOUR WEEK PATTERN

Mon  ████░░░░░░  0.35  😔
Tue  ██████░░░░  0.55
Wed  ███████░░░  0.65
Thu  ████████░░  0.75
Fri  █████████░  0.85
Sat  ██████████  0.95  😊
Sun  █████████░  0.88
```

- Section header: "YOUR WEEK PATTERN" (uppercase, 12px, letter-spacing 1.2)
- Day labels: 14px, monospace or fixed width
- Bar: Warm Orange, width proportional to mood (0.0-1.0)
- Bar background: Soft Graphite
- Value: 13px, right-aligned
- Emoji: Only on highest (😊) and lowest (😔) days
- Row height: 32px
- Gap between rows: 4px

### Widget Implementation

```dart
class DayPatternChart extends StatelessWidget {
  final Map<int, double> pattern;
  final int? bestDay;
  final int? worstDay;
  
  static const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'YOUR WEEK PATTERN',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            color: ElioTheme.softCream.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 12),
        
        // Bars
        ...List.generate(7, (index) {
          final day = index + 1; // 1-7
          final value = pattern[day] ?? 0;
          final isBest = day == bestDay;
          final isWorst = day == worstDay;
          
          return _buildDayRow(
            dayNames[index],
            value,
            isBest ? '😊' : (isWorst ? '😔' : null),
          );
        }),
      ],
    );
  }
  
  Widget _buildDayRow(String day, double value, String? emoji) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Day label
          SizedBox(
            width: 36,
            child: Text(day, style: TextStyle(fontSize: 14)),
          ),
          
          // Bar
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: ElioTheme.softGraphite,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    color: ElioTheme.warmOrange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          
          // Value
          SizedBox(
            width: 40,
            child: Text(
              value.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13),
            ),
          ),
          
          // Emoji
          SizedBox(
            width: 24,
            child: Text(emoji ?? '', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
```

---

## Task 8: Pattern Insight

Below the day-of-week chart, show an actionable insight:

### Logic

```dart
String generatePatternInsight(int? bestDay, int? worstDay) {
  if (bestDay == null || worstDay == null) {
    return "💡 Your mood is fairly consistent across the week.";
  }
  
  final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final bestName = dayNames[bestDay];
  final worstName = dayNames[worstDay];
  
  // Generate contextual insight
  if (worstDay == 1) { // Monday
    return "💡 Mondays are your toughest day. Consider a gentler start to the week.";
  } else if (bestDay == 6 || bestDay == 7) { // Weekend
    return "💡 ${bestName}s are your best days. What makes them work?";
  } else {
    return "💡 ${bestName}s tend to be your best. ${worstName}s are tougher.";
  }
}
```

### Design

- Font size: 14px
- Color: Soft Cream 80% opacity
- Background: Soft Graphite with subtle border
- Padding: 12px
- Border radius: 12px
- Icon: 💡 inline with text

---

## Updated InsightsData Model

```dart
class InsightsData {
  // === EXISTING ===
  final List<Entry> entries;
  final double averageMood;
  final double moodTrend; // -1 to 1, positive = improving
  final int currentStreak;
  final String mostFeltMood;
  final int mostFeltCount;
  final bool isStable; // stdDev < 0.15
  final bool isVolatile; // stdDev > 0.25
  final double standardDeviation;
  
  // === NEW: Period Stats ===
  final int checkInCount;
  final int totalDaysInPeriod; // 7 for week, 28-31 for month
  
  // === NEW: Reflection Stats ===
  final int reflectionDays; // days with at least 1 reflection answer
  final double reflectionRate; // reflectionDays / checkInCount
  
  // === NEW: Streak ===
  final int longestStreakAllTime;
  final int longestStreakInPeriod;
  
  // === NEW: Comparison ===
  final double? previousPeriodAvg;
  final int? previousPeriodCheckIns;
  final double? moodChangeVsPrevious; // percentage: 0.12 = 12% improvement
  final int? checkInChangeVsPrevious; // absolute: +3 means 3 more check-ins
  
  // === NEW: Day of Week Pattern ===
  final Map<int, double> dayOfWeekAverages; // 1=Mon, 7=Sun
  final int? bestDay;
  final int? worstDay;
  
  InsightsData({
    required this.entries,
    required this.averageMood,
    required this.moodTrend,
    required this.currentStreak,
    required this.mostFeltMood,
    required this.mostFeltCount,
    required this.isStable,
    required this.isVolatile,
    required this.standardDeviation,
    required this.checkInCount,
    required this.totalDaysInPeriod,
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
  });
}
```

---

## Updated InsightsService Methods

```dart
class InsightsService {
  final StorageService _storage;
  
  InsightsService(this._storage);
  
  /// Main method to get all insights data for a period
  Future<InsightsData> getInsightsForPeriod(
    DateTime periodStart,
    DateTime periodEnd, {
    bool includeComparison = true,
  }) async {
    // Get entries for current period
    final entries = await _storage.getEntriesForPeriod(periodStart, periodEnd);
    
    // Basic calculations
    final avgMood = _calculateAverage(entries);
    final trend = _calculateTrend(entries);
    final stdDev = _calculateStdDev(entries, avgMood);
    final currentStreak = await _storage.getCurrentStreak();
    final (mostFelt, mostCount) = _findMostFeltMood(entries);
    
    // Period stats
    final totalDays = periodEnd.difference(periodStart).inDays + 1;
    
    // Reflection stats
    final (reflectionDays, reflectionRate) = _calculateReflectionStats(entries);
    
    // Streak history
    final longestAllTime = await _storage.getLongestStreak();
    final longestInPeriod = _calculateLongestStreakInPeriod(entries, periodStart, periodEnd);
    
    // Day of week pattern
    final dayPattern = _calculateDayOfWeekPattern(entries);
    final (bestDay, worstDay) = _findBestWorstDays(dayPattern);
    
    // Comparison (optional)
    double? prevAvg;
    int? prevCheckIns;
    double? moodChange;
    int? checkInChange;
    
    if (includeComparison) {
      final duration = periodEnd.difference(periodStart);
      final prevStart = periodStart.subtract(duration).subtract(Duration(days: 1));
      final prevEnd = periodStart.subtract(Duration(days: 1));
      final prevEntries = await _storage.getEntriesForPeriod(prevStart, prevEnd);
      
      if (prevEntries.isNotEmpty) {
        prevAvg = _calculateAverage(prevEntries);
        prevCheckIns = prevEntries.length;
        moodChange = prevAvg > 0 ? (avgMood - prevAvg) / prevAvg : null;
        checkInChange = entries.length - prevEntries.length;
      }
    }
    
    return InsightsData(
      entries: entries,
      averageMood: avgMood,
      moodTrend: trend,
      currentStreak: currentStreak,
      mostFeltMood: mostFelt,
      mostFeltCount: mostCount,
      isStable: stdDev < 0.15,
      isVolatile: stdDev > 0.25,
      standardDeviation: stdDev,
      checkInCount: entries.length,
      totalDaysInPeriod: totalDays,
      reflectionDays: reflectionDays,
      reflectionRate: reflectionRate,
      longestStreakAllTime: longestAllTime,
      longestStreakInPeriod: longestInPeriod,
      previousPeriodAvg: prevAvg,
      previousPeriodCheckIns: prevCheckIns,
      moodChangeVsPrevious: moodChange,
      checkInChangeVsPrevious: checkInChange,
      dayOfWeekAverages: dayPattern,
      bestDay: bestDay,
      worstDay: worstDay,
    );
  }
  
  /// Calculate reflection stats
  (int days, double rate) _calculateReflectionStats(List<Entry> entries) {
    int daysWithReflection = 0;
    
    for (final entry in entries) {
      if (entry.reflectionAnswerIds != null && entry.reflectionAnswerIds!.isNotEmpty) {
        daysWithReflection++;
      }
    }
    
    final rate = entries.isNotEmpty ? daysWithReflection / entries.length : 0.0;
    return (daysWithReflection, rate);
  }
  
  /// Calculate day-of-week pattern
  Map<int, double> _calculateDayOfWeekPattern(List<Entry> entries) {
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
  
  /// Find best and worst days
  (int?, int?) _findBestWorstDays(Map<int, double> pattern) {
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
  
  /// Generate 2-3 insight items
  List<InsightItem> generateInsights(InsightsData data, bool isWeekView) {
    final insights = <InsightItem>[];
    final period = isWeekView ? "week" : "month";
    
    // Priority 1: Perfect streak (7+ days)
    if (data.currentStreak >= 7) {
      insights.add(InsightItem("🔥", "You've checked in every day this $period. That's real commitment."));
    }
    // Priority 2: Good streak (3+ days)
    else if (data.currentStreak >= 3) {
      insights.add(InsightItem("🔥", "${data.currentStreak} days in a row. You're building a rhythm."));
    }
    
    // Priority 3: Trend up
    if (data.moodTrend > 0.05 && insights.length < 3) {
      insights.add(InsightItem("📈", "Your mood lifted as the $period went on. Something's working."));
    }
    // Priority 4: Trend down
    else if (data.moodTrend < -0.05 && insights.length < 3) {
      insights.add(InsightItem("📉", "This $period felt heavier toward the end. Be gentle with yourself."));
    }
    
    // Priority 5: Better than previous
    if (data.moodChangeVsPrevious != null && data.moodChangeVsPrevious! > 0.1 && insights.length < 3) {
      insights.add(InsightItem("✨", "Your mood is up from last $period. Nice progress."));
    }
    // Priority 6: Worse than previous
    else if (data.moodChangeVsPrevious != null && data.moodChangeVsPrevious! < -0.1 && insights.length < 3) {
      insights.add(InsightItem("💪", "Tougher than last $period. That's okay — you're still here."));
    }
    
    // Priority 7: High reflection rate
    if (data.reflectionRate >= 0.8 && insights.length < 3) {
      insights.add(InsightItem("📝", "Reflected ${data.reflectionDays} of ${data.checkInCount} days. That's deep work."));
    }
    // Priority 8: Medium reflection rate
    else if (data.reflectionRate >= 0.5 && insights.length < 3) {
      insights.add(InsightItem("📝", "Reflection is becoming part of your routine."));
    }
    
    // Priority 9: Stable
    if (data.isStable && insights.length < 3) {
      insights.add(InsightItem("⚖️", "A steady $period. Consistency can be its own strength."));
    }
    // Priority 10: Volatile
    else if (data.isVolatile && insights.length < 3) {
      insights.add(InsightItem("🌊", "Some ups and downs this $period. That's completely human."));
    }
    
    // Priority 11: High mood
    if (data.averageMood > 0.7 && insights.length < 3) {
      insights.add(InsightItem("☀️", "A good $period overall. Notice what made it work."));
    }
    // Priority 12: Low mood
    else if (data.averageMood < 0.3 && insights.length < 3) {
      insights.add(InsightItem("🌱", "A tough $period. You still showed up — that matters."));
    }
    
    // Priority 13: Few check-ins
    if (data.checkInCount <= 2 && insights.length < 3) {
      insights.add(InsightItem("👣", "Just getting started. Every check-in counts."));
    }
    
    // Priority 14: Fallback
    if (insights.isEmpty) {
      insights.add(InsightItem("👣", "You're here. That's the first step."));
    }
    
    return insights.take(3).toList();
  }
  
  /// Generate pattern insight text
  String generatePatternInsight(int? bestDay, int? worstDay) {
    if (bestDay == null || worstDay == null) {
      return "💡 Your mood is fairly consistent across the week.";
    }
    
    final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final bestName = dayNames[bestDay];
    final worstName = dayNames[worstDay];
    
    if (worstDay == 1) {
      return "💡 Mondays are your toughest day. Consider a gentler start to the week.";
    } else if (bestDay == 6 || bestDay == 7) {
      return "💡 ${bestName}s are your best days. What makes them work?";
    } else {
      return "💡 ${bestName}s tend to be your best. ${worstName}s are tougher.";
    }
  }
}

class InsightItem {
  final String icon;
  final String text;
  
  InsightItem(this.icon, this.text);
}
```

---

## File Structure

**Modified:**
- `lib/screens/insights_screen.dart` — complete redesign
- `lib/services/insights_service.dart` — new calculations
- `lib/services/storage_service.dart` — add getLongestStreak, getEntriesForPeriod
- `lib/widgets/mood_wave.dart` — tap to navigate

**New:**
- `lib/widgets/insights_card.dart` — multiple insights display
- `lib/widgets/stat_cards_row.dart` — 4 stat cards with comparison
- `lib/widgets/day_pattern_chart.dart` — day-of-week visualization

---

## Design Rules

**Colors:**
- Background: Warm Charcoal (#1C1C1E)
- Cards: Soft Graphite (#313134)
- Text: Soft Cream (#F9DFC1)
- Accent: Warm Orange (#FF6436)
- Positive: Soft Green (#4CAF50) — only for comparison arrows
- Negative: Soft Cream 50% opacity — no red, no guilt

**Spacing:**
- Section gap: 24px
- Card padding: 16px (large cards), 12px (stat cards)
- Border radius: 18px (large), 12px (small)

**Typography:**
- Section headers: 12px, uppercase, letter-spacing 1.2, 60% opacity
- Stat values: 24px, bold
- Stat labels: 11px, 60% opacity
- Insight text: 15px, regular
- Day labels: 14px, monospace

**Empty States:**
- < 3 entries: "Keep checking in. After a few entries, you'll start seeing patterns here."
- No entries in period: "No check-ins this [week/month] yet."
- Both include "Check In" CTA button

---

## Success Criteria

After this redesign, users should:

1. ✅ Tap any mood point → see full entry detail
2. ✅ Easily navigate between periods (arrows visible)
3. ✅ See 2-3 relevant insights, not just 1
4. ✅ Understand how this period compares to last
5. ✅ See their reflection completion rate
6. ✅ Know their best and worst days of the week
7. ✅ Get actionable suggestions based on patterns
8. ✅ Feel motivated, not judged

---

## Implementation Order

1. Update `InsightsData` model with new fields
2. Update `InsightsService` with new calculations
3. Update `StorageService` with helper methods
4. Create `DayPatternChart` widget
5. Create `InsightsCard` widget (multiple insights)
6. Update `StatCard` widget with comparison
7. Update `MoodWave` widget with navigation
8. Redesign `InsightsScreen` layout
9. Test with sample data
10. Test edge cases (empty states, missing data)

---

## 🎉 Implementation Complete

**Date Completed:** February 8, 2026
**Developer:** Claude Code (Sonnet 4.5)
**Branch:** `insights-redesign`

### Files Modified

#### Services Layer
- **`lib/services/storage_service.dart`**
  - Added `getLongestStreak()` - retrieve all-time longest streak from settings
  - Added `updateLongestStreak()` - update if current streak exceeds stored value
  - Added `getEntriesForPeriod()` - fetch entries within date range
  - Modified `saveEntry()` - auto-updates longest streak on each save
  - Added `_backfillLongestStreak()` - calculates longest streak from existing entries on first run
  - New setting key: `longest_streak`

- **`lib/services/insights_service.dart`**
  - Renamed `InsightsSnapshot` → `InsightsData` (breaking change, backward compatible wrapper kept)
  - Added `InsightItem` class for multiple insights with emoji icons
  - Extended `InsightsData` with 15+ new fields (reflections, streaks, comparisons, patterns)
  - Added `_calculateReflectionStats()` - counts days with reflections, calculates rate
  - Added `_calculateDayOfWeekPattern()` - groups entries by weekday, calculates averages
  - Added `_findBestWorstDays()` - identifies best/worst days (requires 15% difference)
  - Added `_calculateLongestStreakInPeriod()` - finds longest consecutive streak in period
  - Added `_generateInsights()` - priority-based generation (14 rules) with emojis
  - Added `_generatePatternInsight()` - contextual suggestions for day patterns
  - Updated `_mostFelt()` - now returns tuple (mood, count)
  - Added comparison to previous period logic

#### Widgets
- **`lib/widgets/stat_card.dart`**
  - Added `comparison` parameter for tertiary text
  - Added `isPositive` parameter for color coding (green for positive)
  - Added fixed height spacer when no comparison (maintains card height consistency)
  - Reduced horizontal padding (12px → 8px)
  - Added `maxLines` and `overflow` for better text handling

- **`lib/widgets/insight_card.dart`**
  - Updated to support `List<InsightItem>` for multiple insights
  - Displays 2-3 insights in single card
  - Each insight has own emoji icon
  - 12px spacing between insights
  - Backward compatible with single text parameter

- **`lib/widgets/mood_wave.dart`**
  - Added "View Entry →" button to tooltip
  - Added navigation to `EntryDetailScreen` on button tap
  - Added helper methods: `_timeLabel()`, `_dateLabel()`, `_weekdayFullName()`, `_moodColor()`
  - Tooltip auto-closes before navigation
  - Increased tooltip height to accommodate button

- **`lib/widgets/day_pattern_chart.dart`** (NEW)
  - Displays horizontal bars for Mon-Sun
  - Shows mood average per weekday
  - Adds 😊 emoji to best day, 😔 to worst day
  - **Interactive:** `onDayTap` callback parameter
  - Wrapped rows in `InkWell` for tap handling
  - Shows chevron icon when tappable (and no emoji)
  - Disables tap on days with no data (value == 0)
  - Material ripple feedback on tap

- **`lib/widgets/day_entries_sheet.dart`** (NEW)
  - Bottom sheet component for day entry filtering
  - Draggable with handle indicator
  - Header: day name + average mood badge
  - Entry count display
  - Scrollable entry list with cards
  - Each card: date, time, mood color dot, mood word, intention preview
  - Tap entry → navigate to `EntryDetailScreen`
  - Empty state: calendar icon + message
  - Uses `DraggableScrollableSheet` (40%-90% screen height)

#### Screens
- **`lib/screens/insights_screen.dart`**
  - **Navigation:** Added arrow buttons (‹ ›) with period label between them
  - **State:** Added `_NavigationDirection` enum (forward/backward)
  - **State:** Added `_lastDirection` tracking for animation direction
  - **Method:** Updated `_navigatePeriod()` to set direction state
  - **Method:** Added `_buildAnimatedTransition()` for custom slide+fade effect
  - **Method:** Added `_buildPeriodContent()` to wrap animated content with unique key
  - **Method:** Added `_buildPeriodNavigation()` for arrow navigation UI
  - **Method:** Added `_buildComparisonLine()` showing avg mood + % change vs previous
  - **Method:** Updated `_buildStatsRow()` for 4 equal-width cards with comparisons
  - **Method:** Added `_buildPatternInsight()` for actionable day pattern text
  - **Method:** Added `_showDayEntriesSheet()` to filter + display day entries
  - **UI:** Wrapped content in `AnimatedSwitcher` with 300ms transitions
  - **UI:** Added `GestureDetector` for swipe handling on animated content
  - **UI:** Added comparison line below mood wave
  - **UI:** Changed insight card to use multiple insights
  - **UI:** Added 4th stat card (Reflections)
  - **UI:** Added `DayPatternChart` with tap callback
  - **UI:** Added pattern insight text below chart
  - **Animation:** Fade + slide transitions (direction-aware)
  - **Animation:** 300ms duration with `Curves.easeInOutCubic`
  - **Animation:** 0.3 offset (30% of screen width)

### Technical Decisions

1. **Backward Compatibility:** Kept `buildSnapshot()` method alongside new `getInsightsForPeriod()` to avoid breaking changes
2. **Animation Performance:** Used `ValueKey` based on `period_offset` to trigger animations only when period changes
3. **Streak Backfill:** Runs once on first launch after update to calculate longest streak from existing data
4. **Day Filtering:** O(n) operation - filters entries in memory (efficient for typical data sizes)
5. **Equal Card Widths:** Used `Expanded(flex: 1)` + fixed height spacer for visual consistency
6. **Bottom Sheet:** `DraggableScrollableSheet` for native iOS/Android drag-to-dismiss UX

### Testing Performed

- ✅ Period navigation (arrows + swipe) with animations
- ✅ Week ↔ Month toggle
- ✅ Mood wave tap → tooltip → navigation
- ✅ All 4 stat cards display correctly (equal width/height)
- ✅ Comparison line shows correct percentage changes
- ✅ 2-3 insights generate based on priority rules
- ✅ Day pattern chart displays with best/worst indicators
- ✅ Tapping days shows filtered entries in bottom sheet
- ✅ Entry navigation from bottom sheet works
- ✅ Empty states (no data, no entries for day)
- ✅ Longest streak backfills from existing data
- ✅ Sample data toggle works with all features

### Known Limitations

- Uses deprecated `withOpacity()` - consistent with existing codebase, cosmetic warnings only
- Test file error (MyApp class) - pre-existing, not blocking
- Animations require full app restart after hot reload (service initialization)

### Future Enhancements (Not Implemented)

- Filter entries by mood range
- Export insights as image/PDF
- Customizable insight priorities
- Trend predictions (ML-based)
- Compare across multiple periods
- Custom date range selection

---

## For Future Development

If continuing work on Insights:

1. **Context is in:** `lib/services/insights_service.dart` - all calculation logic
2. **UI is in:** `lib/screens/insights_screen.dart` - layout and interactions
3. **Widgets are modular:** Each component can be updated independently
4. **Data model is extensible:** Add fields to `InsightsData` as needed
5. **Animations use:** `AnimatedSwitcher` + `ValueKey` pattern - can be adjusted
6. **Bottom sheets follow:** Material Design drag-to-dismiss pattern

### Code Patterns Used

**Service Layer:**
```dart
// Tuple returns for multiple values
(int days, double rate) _calculateReflectionStats(entries)

// Static helpers for calculations
static Map<int, double> _calculateDayOfWeekPattern(entries)
```

**Animations:**
```dart
AnimatedSwitcher(
  duration: Duration(milliseconds: 300),
  transitionBuilder: (child, animation) => SlideTransition(...),
  child: Widget(key: ValueKey('period_$offset')),
)
```

**Interactive Charts:**
```dart
InkWell(
  onTap: () => callback(data),
  child: ChartRow(...),
)
```

**Bottom Sheets:**
```dart
showModalBottomSheet(
  builder: (_) => DraggableScrollableSheet(
    initialChildSize: 0.6,
    builder: (_, controller) => Content(),
  ),
)
```
