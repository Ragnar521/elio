---
phase: 05-smart-nudges
plan: 01
subsystem: nudge-infrastructure
tags: [nudge-service, nudge-card, trigger-detection, cooldown-management]
dependency_graph:
  requires:
    - DirectionService.getDormantDirections()
    - StorageService.getCurrentStreak()
    - StorageService.getEntriesForPeriod()
    - Hive settings box
  provides:
    - NudgeService.checkOnAppOpen()
    - NudgeService.checkPostCheckIn()
    - NudgeService pending nudge mechanism
    - NudgeCard widget
  affects:
    - Future: Home screen (will consume pending nudges)
    - Future: Confirmation screen (will call checkPostCheckIn)
tech_stack:
  added:
    - lib/models/nudge.dart (NudgeType enum, Nudge data class)
    - lib/services/nudge_service.dart (singleton service)
    - lib/widgets/nudge_card.dart (reusable widget)
  patterns:
    - Hive settings box for cooldown persistence
    - Singleton service pattern
    - Pending nudge handoff mechanism
key_files:
  created:
    - lib/models/nudge.dart
    - lib/services/nudge_service.dart
    - lib/widgets/nudge_card.dart
  modified: []
decisions:
  - Cooldown periods: 7 days dormant, 30 days streak, 14 days pattern
  - Streak milestones: 3, 7, 14, 30, 60, 100 days
  - Mood pattern threshold: 15% above/below overall average
  - Minimum 7 entries required for mood pattern detection
  - NudgeCard uses softer accent border (0.6 opacity) to differentiate from WeeklySummaryCard
  - Concurrency guard prevents overlapping evaluations
metrics:
  duration: 2
  completed_date: "2026-02-27"
  tasks_completed: 2
  files_created: 3
  commits: 2
---

# Phase 05 Plan 01: Nudge Infrastructure Summary

**One-liner:** Smart nudge system with dormant direction, streak milestone, and mood pattern detection using Hive-based cooldown management and pending nudge handoff mechanism.

## Objective Achieved

Created complete nudge infrastructure with:
- Nudge data model and NudgeType enum
- NudgeService singleton with trigger detection for all three nudge types
- Cooldown management using Hive settings box
- Pending nudge mechanism for post-check-in → Home screen handoff
- NudgeCard widget matching existing design system

## Implementation Summary

### Task 1: Nudge Model and Service
**Files:** lib/models/nudge.dart, lib/services/nudge_service.dart
**Commit:** b6bd4b7

Created the core nudge infrastructure:

**Nudge Model:**
- Simple data class with id, type, message, actionText, directionId fields
- NudgeType enum with three variants: dormantDirection, moodPattern, streakCelebration
- No Hive adapter needed (nudges are transient)

**NudgeService:**
- Singleton pattern with instance getter
- `checkOnAppOpen()` - Detects dormant directions (7+ days without connections)
  - Calls DirectionService.getDormantDirections()
  - Returns nudge with direction emoji, title, and "Reconnect →" action
  - 7-day cooldown per direction
- `checkPostCheckIn(currentStreak)` - Detects streak milestones and mood patterns
  - Priority 1: Streak milestones (3, 7, 14, 30, 60, 100 days)
  - Priority 2: Mood patterns (best/worst day analysis)
  - Warm, brief messages without exclamation marks
  - 30-day cooldown for streaks, 14-day for patterns
- `setPendingNudge()` / `consumePendingNudge()` - Handoff mechanism for post-check-in nudges
- `dismissNudge(cooldownKey)` - Stores dismissal timestamp in Hive settings box
- Concurrency guard prevents overlapping evaluations

**Mood Pattern Detection:**
- Requires minimum 7 entries in 14-day period
- Calculates day-of-week averages
- 15% threshold for best/worst day identification
- Positive patterns show percentage increase
- Negative patterns use gentle, supportive language

### Task 2: NudgeCard Widget
**Files:** lib/widgets/nudge_card.dart
**Commit:** 44ed6e3

Created reusable dismissible card widget:

**Visual Design:**
- Matches WeeklySummaryCard style (surface color, 18px radius)
- Softer left accent border (0.6 opacity) to differentiate
- 16px padding, consistent spacing

**Layout:**
- Left: Type-specific icon (fire/explore/insights)
- Center: Message text + optional action text in accent color
- Right: Close button for dismissal

**Interactivity:**
- Optional onTap callback for card navigation
- onDismiss callback for close button
- InkWell ripple with matching border radius

## Verification Results

All files pass flutter analyze:
- lib/models/nudge.dart - No issues
- lib/services/nudge_service.dart - No issues
- lib/widgets/nudge_card.dart - Only cosmetic withOpacity deprecation warnings (known, project-wide)

## Deviations from Plan

None - plan executed exactly as written.

## Key Technical Decisions

1. **Cooldown Periods:**
   - Dormant directions: 7 days (allows weekly re-engagement)
   - Streak milestones: 30 days (each milestone independent)
   - Mood patterns: 14 days (bi-weekly pattern check)

2. **Mood Pattern Detection:**
   - Reimplemented day-of-week pattern logic (InsightsService methods are private)
   - 15% threshold matches InsightsService pattern
   - Requires 7+ entries to ensure statistical significance

3. **Streak Milestone Messages:**
   - No exclamation marks (maintains calm, mindful tone)
   - Focus on presence and consistency
   - Examples: "3 days in a row. You're building something." / "100 days. You've built something real."

4. **Concurrency Safety:**
   - `_isChecking` flag prevents overlapping evaluations
   - Both checkOnAppOpen and checkPostCheckIn protected
   - Returns null immediately if already checking

5. **Pending Nudge Mechanism:**
   - Simple instance variable storage
   - Allows post-check-in nudges to appear on Home screen
   - Consume-once pattern (cleared after retrieval)

## Dependencies

**Required Services:**
- DirectionService.getDormantDirections() - Returns directions with 7+ days no connections
- StorageService.getCurrentStreak() - Current consecutive check-in days
- StorageService.getEntriesForPeriod() - Entries for mood pattern analysis
- Hive settings box - Cooldown timestamp persistence

**Provides for Future Plans:**
- NudgeService.checkOnAppOpen() - Home screen app open trigger
- NudgeService.checkPostCheckIn() - Confirmation screen post-check-in trigger
- NudgeService pending nudge handoff - Confirmation → Home transition
- NudgeCard widget - Reusable nudge display

## Testing Notes

**Manual Testing Required (Plan 02):**
- Test dormant direction nudge appears on app open
- Test streak milestone nudges at 3, 7, 14, 30, 60, 100 days
- Test mood pattern nudges (positive and negative)
- Verify cooldown periods prevent spam
- Confirm pending nudge appears on Home after check-in
- Test dismiss functionality persists across app restarts

**Edge Cases Handled:**
- No dormant directions → checkOnAppOpen returns null
- Fewer than 7 entries → mood pattern detection skipped
- No best/worst day pattern → mood pattern returns null
- Concurrent check calls → second call returns null immediately
- Cooldown active → nudge suppressed

## Next Steps (Plan 02)

Integration with UI screens:
1. Home screen: Call checkOnAppOpen() on mount, display consumePendingNudge()
2. Confirmation screen: Call checkPostCheckIn() after save, setPendingNudge() if result
3. Wire NudgeCard onTap to navigation (dormant directions → DirectionDetailScreen)
4. Wire NudgeCard onDismiss to NudgeService.dismissNudge()

## Files Created

| File | Lines | Purpose |
|------|-------|---------|
| lib/models/nudge.dart | 17 | Nudge data class and NudgeType enum |
| lib/services/nudge_service.dart | 234 | Singleton service with trigger detection and cooldown |
| lib/widgets/nudge_card.dart | 93 | Reusable dismissible card widget |

**Total:** 3 files, 344 lines

## Commits

| Commit | Message | Files |
|--------|---------|-------|
| b6bd4b7 | feat(05-01): add nudge model and service with trigger detection | nudge.dart, nudge_service.dart |
| 44ed6e3 | feat(05-01): add NudgeCard widget with consistent design system | nudge_card.dart |

## Self-Check

Verifying created files exist:

```bash
[ -f "lib/models/nudge.dart" ] && echo "FOUND" || echo "MISSING"
[ -f "lib/services/nudge_service.dart" ] && echo "FOUND" || echo "MISSING"
[ -f "lib/widgets/nudge_card.dart" ] && echo "FOUND" || echo "MISSING"
```

Verifying commits exist:

```bash
git log --oneline --all | grep -q "b6bd4b7" && echo "FOUND" || echo "MISSING"
git log --oneline --all | grep -q "44ed6e3" && echo "FOUND" || echo "MISSING"
```

**Result:**
```
FOUND: lib/models/nudge.dart
FOUND: lib/services/nudge_service.dart
FOUND: lib/widgets/nudge_card.dart
FOUND: b6bd4b7
FOUND: 44ed6e3
```

## Self-Check: PASSED
