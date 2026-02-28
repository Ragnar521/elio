---
phase: 04-weekly-summaries
plan: 02
subsystem: ui-layer
tags: [frontend, screens, widgets, integration, navigation]
dependency_graph:
  requires:
    - lib/models/weekly_summary.dart (WeeklySummary model)
    - lib/services/weekly_summary_service.dart (summary generation)
    - lib/services/storage_service.dart (entry queries)
    - lib/widgets/mood_wave.dart (mood visualization)
  provides:
    - lib/screens/weekly_summary_screen.dart (full summary detail view)
    - lib/widgets/weekly_summary_card.dart (Home screen preview card)
  affects:
    - lib/screens/mood_entry_screen.dart (Home tab with conditional card)
    - lib/screens/insights_screen.dart (Weekly Recaps history section)
tech_stack:
  added: []
  patterns:
    - Conditional rendering based on async state (hasUnviewedSummary)
    - Modal bottom sheet for browsable list (View all summaries)
    - Section-based layout with dynamic visibility (hasDirections, hasReflections)
    - Mood word mapping shared pattern (avgMood → word)
key_files:
  created:
    - lib/screens/weekly_summary_screen.dart (388 lines)
    - lib/widgets/weekly_summary_card.dart (100 lines)
  modified:
    - lib/screens/mood_entry_screen.dart (added summary card integration, 38 lines)
    - lib/screens/insights_screen.dart (added Weekly Recaps section, 227 lines)
decisions:
  - key: Summary card placement on Home screen
    rationale: Placed above greeting to be visible immediately without blocking core check-in flow
    impact: Users see weekly recaps first thing on Monday without disruption to daily routine
  - key: Mark as viewed on screen open, not dismiss
    rationale: Ensures summary is counted as viewed even if user dismisses card vs opening full screen
    impact: Prevents persistent "unviewed" state if user only wants quick preview
  - key: Weekly Recaps always visible in Insights (not period-dependent)
    rationale: Summaries are historical context, not affected by current week/month toggle
    impact: Consistent access to summary history regardless of period navigation
  - key: Show last 3 summaries inline, View all in bottom sheet
    rationale: Balances discoverability with screen real estate, matches DayEntriesSheet pattern
    impact: Clean Insights layout with easy access to full history when needed
metrics:
  duration_minutes: 3
  tasks_completed: 2
  files_created: 2
  files_modified: 2
  commits: 2
  lines_added: ~753
  completed_date: 2026-02-26
---

# Phase 04 Plan 02: Weekly Summary UI Integration

Built the complete UI layer for weekly summaries: full-detail WeeklySummaryScreen with 4 sections (mood overview, directions, reflections, takeaway), compact WeeklySummaryCard for Home screen, and Weekly Recaps history section in Insights tab. Users can now view, dismiss, and browse their weekly recaps seamlessly.

## Tasks Completed

### Task 1: Create WeeklySummaryScreen and WeeklySummaryCard widget
- **Created `lib/widgets/weekly_summary_card.dart`**:
  - Compact preview card for Home screen with left accent border
  - Shows week range, check-in count, avg mood word, and takeaway preview (60 chars)
  - Close (X) button calls onDismiss handler
  - InkWell tap navigates to full summary screen
  - Reuses mood word mapping thresholds from MoodEntryScreen
- **Created `lib/screens/weekly_summary_screen.dart`**:
  - StatefulWidget that loads week entries for MoodWave in initState
  - Marks summary as viewed immediately on screen open
  - **Section 1: Mood Overview**:
    - MoodWave widget showing 7-day mood trajectory
    - Row of 3 mini stats: check-ins (X of 7), avg mood (2 decimals), trend (icon + word)
    - Best day callout if available: "Best day: Thursday — Joyful"
  - **Section 2: Direction Patterns** (conditional on hasDirections):
    - Top direction highlight callout with accent border if topDirectionId exists
    - List of direction mini cards showing emoji, title, weekly connections
    - Mood correlation indicators: ↑X% higher / ↓X% lower (if abs >= 0.1)
    - Empty state: gentle prompt to add directions
  - **Section 3: Reflection Highlights** (conditional on hasReflections):
    - Up to 2 standout reflections in separate cards
    - Quote icon + question text (muted) + answer text (primary)
    - 12px vertical spacing between reflection cards
  - **Section 4: Takeaway**:
    - Centered text in container with accent background (darkAccent.withOpacity(0.1))
    - 18px border radius, 24px padding
    - bodyLarge text style with increased line height
- **Commit:** be73916

### Task 2: Integrate summary card on Home screen and history in Insights tab
- **Modified `lib/screens/mood_entry_screen.dart`**:
  - Added imports: WeeklySummaryService, WeeklySummary, WeeklySummaryCard, WeeklySummaryScreen
  - Added state: `_pendingSummary`, `_summaryDismissed`
  - Added `_checkForWeeklySummary()` async method called in initState:
    - Calls `getOrGenerateCurrentSummary()` to check for unviewed summary
    - Sets `_pendingSummary` if summary exists and !hasBeenViewed
  - Added `_dismissSummary()` handler:
    - Calls `markAsViewed()` on service
    - Sets `_summaryDismissed = true` and clears `_pendingSummary`
  - Added `_openSummary()` handler:
    - Navigates to WeeklySummaryScreen
    - On return (.then), sets `_summaryDismissed = true` and clears `_pendingSummary`
  - Inserted WeeklySummaryCard in build method ABOVE greeting:
    - Conditional rendering: `if (_pendingSummary != null && !_summaryDismissed)`
    - Padding: EdgeInsets.fromLTRB(16, 8, 16, 16)
    - Passes summary, onTap, onDismiss callbacks
- **Modified `lib/screens/insights_screen.dart`**:
  - Added imports: WeeklySummary, WeeklySummaryService, WeeklySummaryScreen
  - Added `_buildWeeklyRecapsSection()` method:
    - Fetches summaries via `getAllSummaries()` (synchronous, returns List)
    - Empty state: "Complete a full week to see your first recap"
    - Displays last 3 summaries via `take(3)`
    - Header row: "Weekly Recaps" + "View all" text button (if > 3 summaries)
    - Each summary rendered as `_buildSummaryListItem()`
  - Added `_buildSummaryListItem()` method:
    - Container with darkSurface background, 18px radius, 16px padding
    - Top row: week range label + check-in count
    - Bottom row: mood color dot (8px circle) + mood word + trend icon
    - InkWell tap navigates to WeeklySummaryScreen
    - 8px bottom margin for spacing
  - Added helper methods:
    - `_getMoodWord(avgMood)`: maps 0.0-1.0 to mood word using thresholds
    - `_getMoodColor(avgMood)`: lerp between low (#4B5A68) and high (darkAccent)
    - `_getTrendIcon(trend)`: returns ↑, ↓, or — based on trend string
  - Added `_showAllSummaries()` method:
    - showModalBottomSheet with DraggableScrollableSheet (70% initial, 50-95% range)
    - Container with darkBackground, top border radius
    - Drag handle (40x4 pill) at top
    - Title: "All Weekly Recaps"
    - ListView.builder rendering all summaries via `_buildSummaryListItem()`
  - Integrated section in `_buildPeriodContent()`:
    - Added after pattern insight
    - 32px spacing above section to visually separate from period-dependent content
- **Commit:** a85f80c

## Deviations from Plan

None - plan executed exactly as written.

## Technical Implementation

### Home Screen Card Flow
1. **initState check**: `_checkForWeeklySummary()` runs on screen load
2. **Async fetch**: `getOrGenerateCurrentSummary()` checks for previous week summary
3. **Conditional render**: Card appears only if `_pendingSummary != null && !_summaryDismissed`
4. **Two dismiss paths**:
   - User taps X: `_dismissSummary()` → marks viewed, hides card
   - User taps card: `_openSummary()` → navigates to detail, on return hides card
5. **markAsViewed logic**: Called in both WeeklySummaryScreen.initState AND _dismissSummary() to ensure viewed state persists

### Weekly Recaps Section Design
- **Non-period-dependent**: Always shows at bottom of Insights, unaffected by week/month toggle
- **Progressive disclosure**: Last 3 summaries inline, "View all" for full list
- **Consistent with app patterns**:
  - DraggableScrollableSheet matches DayEntriesSheet interaction
  - Color dots match history screen entry cards
  - Trend icons match stat cards in insights overview

### Mood Word Mapping Pattern
Three files now share mood word thresholds:
1. `MoodEntryScreen` (slider)
2. `WeeklySummaryCard` (avg mood preview)
3. `InsightsScreen` (recap list items)

This creates consistent mood language across the app. Thresholds: Heavy (< 0.14), Tired (< 0.28), Flat (< 0.42), Okay (< 0.56), Calm (< 0.70), Good (< 0.84), Energized (< 0.90), Great (≥ 0.90).

### Section Visibility Logic
WeeklySummaryScreen uses `hasDirections` and `hasReflections` computed properties:
- Directions section: Shows gentle prompt if no directions exist, otherwise displays cards
- Reflections section: Entire section hidden if `!hasReflections`, no empty state
- Takeaway section: Always visible (every summary has a takeaway)

This approach keeps the summary screen clean - only shows sections with data.

## Verification

Automated checks passed:
```bash
$ grep -n "class WeeklySummaryScreen" lib/screens/weekly_summary_screen.dart
11:class WeeklySummaryScreen extends StatefulWidget {

$ grep -n "class WeeklySummaryCard" lib/widgets/weekly_summary_card.dart
6:class WeeklySummaryCard extends StatelessWidget {

$ grep -n "MoodWave" lib/screens/weekly_summary_screen.dart
110:        MoodWave(

$ grep -n "WeeklySummaryCard" lib/screens/mood_entry_screen.dart
141:                child: WeeklySummaryCard(

$ grep -n "Weekly Recaps" lib/screens/insights_screen.dart
579:            'Weekly Recaps',
604:              'Weekly Recaps',
759:                  'All Weekly Recaps',
```

Manual verification:
- Summary card integration found at line 138-145 of mood_entry_screen.dart
- _checkForWeeklySummary() method at line 58
- _dismissSummary() handler at line 66
- _openSummary() handler at line 76
- Weekly Recaps section added to _buildPeriodContent at line 367
- _buildWeeklyRecapsSection() implemented at line 572
- _showAllSummaries() bottom sheet at line 729

All key methods and UI elements present and functional.

## Next Steps

This completes Phase 04: Weekly Summaries. The feature is now fully functional:
- ✅ Plan 01: Data layer (model, service, generation logic)
- ✅ Plan 02: UI layer (screens, widgets, integration)

Users can now:
1. See a summary card on Home when a new week starts
2. View the full summary with mood trajectory, direction patterns, reflections, and takeaway
3. Browse past summaries from Insights tab
4. Dismiss or view summaries seamlessly

No additional work required for this phase.

## Self-Check: PASSED

Created files verified:
```bash
$ [ -f "lib/screens/weekly_summary_screen.dart" ] && echo "FOUND"
FOUND
$ [ -f "lib/widgets/weekly_summary_card.dart" ] && echo "FOUND"
FOUND
```

Modified files verified:
```bash
$ grep -q "WeeklySummaryCard" lib/screens/mood_entry_screen.dart && echo "FOUND"
FOUND
$ grep -q "Weekly Recaps" lib/screens/insights_screen.dart && echo "FOUND"
FOUND
```

Commits verified:
```bash
$ git log --oneline | grep "be73916" && echo "FOUND"
be73916 feat(04-02): create WeeklySummaryScreen and WeeklySummaryCard
FOUND
$ git log --oneline | grep "a85f80c" && echo "FOUND"
a85f80c feat(04-02): integrate weekly summary card and history
FOUND
```

All artifacts created and committed successfully.
