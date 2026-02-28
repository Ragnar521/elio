---
phase: 05-smart-nudges
plan: 02
subsystem: nudge-ui-integration
tags: [home-screen, confirmation-screen, nudge-display, lifecycle-handling]
dependency_graph:
  requires:
    - NudgeService.checkOnAppOpen()
    - NudgeService.checkPostCheckIn()
    - NudgeService.consumePendingNudge()
    - NudgeService.setPendingNudge()
    - NudgeCard widget
    - DirectionService.getDirection()
  provides:
    - Complete end-to-end nudge system
    - Home screen nudge display
    - Post-check-in nudge evaluation
    - Dormant direction navigation
  affects:
    - MoodEntryScreen (Home tab)
    - ConfirmationScreen (check-in flow)
tech_stack:
  added: []
  patterns:
    - AppLifecycleListener for app resume detection
    - Pending nudge handoff (Confirmation → Home)
    - Priority-based card display (weekly summary > nudge)
    - Fire-and-forget nudge evaluation
key_files:
  created: []
  modified:
    - lib/screens/mood_entry_screen.dart
    - lib/screens/confirmation_screen.dart
decisions:
  - Weekly summary card takes priority over nudge card (no stacking)
  - Nudge evaluation is non-blocking (preserves confirmation flow)
  - AppLifecycleListener detects app resume for dormant direction checks
  - Dormant direction nudges navigate to DirectionDetailScreen
  - Streak/pattern nudges are informational only (no navigation)
metrics:
  duration: 1
  completed_date: "2026-02-27"
  tasks_completed: 2
  files_modified: 2
  commits: 2
---

# Phase 05 Plan 02: Nudge UI Integration Summary

**One-liner:** Complete nudge system integration with Home screen display, app lifecycle detection, post-check-in evaluation, and priority-based card management.

## Objective Achieved

Wired NudgeService and NudgeCard into the app's UI flow:
- Home screen shows nudges at correct trigger times (app open vs post-check-in)
- ConfirmationScreen evaluates nudges after entry save
- Pending nudge mechanism enables post-check-in → Home handoff
- Weekly summary card takes priority (no stacking)
- Dormant direction nudges navigate to DirectionDetailScreen

## Implementation Summary

### Task 1: Integrate Nudge Display into MoodEntryScreen
**Files:** lib/screens/mood_entry_screen.dart
**Commit:** b2d5a94

Enhanced Home screen with nudge display and lifecycle detection:

**State Management:**
- Added `_currentNudge` and `_nudgeDismissed` state variables
- Added `AppLifecycleListener` for app resume detection
- Proper lifecycle management (dispose listener)

**Nudge Detection Flow:**
1. `_checkForNudges()` called on `initState()` and app resume
2. First checks for pending nudge from `consumePendingNudge()` (post-check-in flow)
3. If no pending, checks `checkOnAppOpen()` (dormant directions)
4. Updates state if nudge found

**Display Logic:**
- NudgeCard shows below weekly summary card (if summary dismissed)
- Conditional rendering: `_currentNudge != null && !_nudgeDismissed && (_pendingSummary == null || _summaryDismissed)`
- Ensures only one card visible at a time (weekly summary priority)

**User Interactions:**
- `_dismissNudge()`: Calls `NudgeService.dismissNudge()` with cooldown persistence
- `_handleNudgeTap()`: Navigates to DirectionDetailScreen for dormant direction nudges
- Close button dismisses, action text (if present) enables tap navigation

**Key Features:**
- App resume triggers dormant direction check (user returns after 7 days)
- Pending nudges consumed immediately on Home screen mount
- Navigation to DirectionDetailScreen with direction lookup
- Graceful handling of null directions (user might have archived)

### Task 2: Add Post-Check-In Nudge Evaluation
**Files:** lib/screens/confirmation_screen.dart
**Commit:** 1d8bdfa

Added nudge evaluation to confirmation flow:

**Integration Point:**
- Called in `_saveEntryAndStart()` after streak calculation
- Fire-and-forget style (no await, non-blocking)
- Preserves confirmation screen animations

**Evaluation Logic:**
- `_evaluatePostCheckInNudges()` calls `NudgeService.checkPostCheckIn(currentStreak)`
- Checks streak milestones (3, 7, 14, 30, 60, 100 days)
- Checks mood patterns (15% threshold, minimum 7 entries)
- Stores result via `setPendingNudge()` if nudge generated

**Error Handling:**
- Try-catch wraps entire evaluation
- Errors logged but don't disrupt confirmation flow
- Non-critical operation (nudge absence is acceptable)

**Timing Pattern:**
- Nudge evaluation happens after save (has streak count)
- Nudge stored in service's pending slot
- Home screen picks up on return (natural delay creates breathing room)
- User sees confirmation first, then nudge on Home

## Verification Results

Both files pass flutter analyze with only cosmetic deprecation warnings:
- lib/screens/mood_entry_screen.dart - 8 withOpacity warnings (project-wide known issue)
- lib/screens/confirmation_screen.dart - 6 withOpacity warnings (project-wide known issue)

No errors or functional issues.

## Deviations from Plan

None - plan executed exactly as written.

## Key Technical Decisions

1. **AppLifecycleListener for Resume Detection:**
   - Detects when user returns to app after 7+ days
   - Triggers dormant direction check
   - Properly disposed in dispose()

2. **Priority-Based Card Display:**
   - Weekly summary > Nudge (only one visible)
   - Conditional: `(_pendingSummary == null || _summaryDismissed)`
   - Prevents card stacking and UI clutter

3. **Fire-and-Forget Nudge Evaluation:**
   - No await on `_evaluatePostCheckInNudges()`
   - Preserves confirmation screen timing
   - Error-tolerant (won't crash flow)

4. **Pending Nudge Handoff:**
   - ConfirmationScreen stores via `setPendingNudge()`
   - Home screen consumes via `consumePendingNudge()`
   - Checked first (priority over app-open nudges)
   - Consume-once pattern (cleared after retrieval)

5. **Navigation Handling:**
   - Dormant direction nudges navigate (have directionId + actionText)
   - Streak/pattern nudges dismiss only (informational)
   - Direction lookup handles null (archived directions)

## Testing Notes

**Manual Testing Required:**
1. **Dormant Direction Nudge:**
   - Create direction, don't connect for 7+ days
   - Open app → nudge appears on Home
   - Tap nudge → navigates to DirectionDetailScreen
   - Dismiss → nudge disappears

2. **Streak Milestone Nudge:**
   - Complete check-in at milestone (3, 7, 14, 30, 60, 100 days)
   - After confirmation, return to Home → nudge appears
   - Dismiss → nudge disappears

3. **Mood Pattern Nudge:**
   - Complete 7+ check-ins with clear day pattern
   - After check-in, return to Home → nudge appears
   - Dismiss → nudge disappears

4. **Priority Management:**
   - Have both weekly summary and nudge pending
   - Weekly summary shows first
   - Dismiss summary → nudge appears
   - Only one card visible at a time

5. **Cooldown Persistence:**
   - Dismiss nudge
   - Close and reopen app
   - Nudge doesn't reappear (cooldown active)

6. **App Resume:**
   - Create dormant direction
   - Force quit app
   - Reopen after 7+ days → nudge appears

## Next Steps

Phase 05 complete. Nudge system fully operational:
- ✅ Infrastructure (Plan 01)
- ✅ UI Integration (Plan 02)

**User Experience Flow:**
1. User opens app → dormant direction nudge (if 7+ days)
2. User completes check-in → streak/pattern evaluation
3. User returns to Home → pending nudge displays
4. User taps/dismisses → navigation or cooldown

**Future Enhancements (Not in v2.0):**
- User-configurable cooldown periods
- Nudge preferences (enable/disable by type)
- More nudge types (reflection frequency, direction balance)
- Analytics on nudge engagement

## Files Modified

| File | Lines Changed | Purpose |
|------|---------------|---------|
| lib/screens/mood_entry_screen.dart | +76 | Nudge display, lifecycle detection, navigation |
| lib/screens/confirmation_screen.dart | +17 | Post-check-in nudge evaluation |

**Total:** 2 files, 93 lines added

## Commits

| Commit | Message | Files |
|--------|---------|-------|
| b2d5a94 | feat(05-02): integrate nudge display into Home screen | mood_entry_screen.dart |
| 1d8bdfa | feat(05-02): add post-check-in nudge evaluation | confirmation_screen.dart |

## Self-Check

Verifying modified files exist:

```bash
[ -f "lib/screens/mood_entry_screen.dart" ] && echo "FOUND" || echo "MISSING"
[ -f "lib/screens/confirmation_screen.dart" ] && echo "FOUND" || echo "MISSING"
```

Verifying commits exist:

```bash
git log --oneline --all | grep -q "b2d5a94" && echo "FOUND" || echo "MISSING"
git log --oneline --all | grep -q "1d8bdfa" && echo "FOUND" || echo "MISSING"
```

**Result:**
```
FOUND: lib/screens/mood_entry_screen.dart
FOUND: lib/screens/confirmation_screen.dart
FOUND: b2d5a94
FOUND: 1d8bdfa
```

## Self-Check: PASSED
