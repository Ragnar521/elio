---
phase: 09-reset-mechanism
plan: 01
subsystem: reset-mechanism
tags: [reset, demo-mode, debug-tools, triple-tap]
dependency_graph:
  requires: [launcher-screen, storage-service, hive-boxes]
  provides: [full-data-wipe, reset-to-launcher]
  affects: [home-shell, all-hive-boxes]
tech_stack:
  added: []
  patterns: [triple-tap-gesture, full-data-wipe, navigation-reset]
key_files:
  created: []
  modified:
    - lib/services/storage_service.dart
    - lib/screens/home_shell.dart
decisions:
  - "Settings box cleared LAST to prevent partially-wiped state showing launcher before data is cleared"
  - "Navigation goes to OnboardingGate (not LauncherScreen directly) to leverage existing gate logic"
  - "Method renamed from _resetOnboarding to _resetApp to reflect expanded scope"
metrics:
  duration: 79s
  completed: 2026-02-28T13:35:55Z
  tasks: 2
  files: 2
  commits: 2
---

# Phase 09 Plan 01: Reset Mechanism Summary

**Expanded triple-tap Home icon reset to wipe ALL app data and return to launcher screen, enabling re-demonstration of demo mode or fresh start flow.**

## Objective Achievement

Implemented full data wipe mechanism that clears all 7 Hive boxes (entries, reflectionAnswers, reflectionQuestions, directions, direction_connections, weekly_summaries, settings) when user triple-taps the Home icon in debug mode, then navigates to the launcher screen where they can choose demo mode or fresh start again.

## Tasks Completed

### Task 1: Add wipeAllData method to StorageService
**Status:** ✅ Complete
**Commit:** 4885460
**Files:** lib/services/storage_service.dart

Added `wipeAllData()` method that:
- Opens and clears all 7 Hive boxes (entries, reflectionAnswers, reflectionQuestions, directions, direction_connections, weekly_summaries, settings)
- Clears settings box LAST to prevent partially-wiped state
- Uses `Hive.openBox` pattern (returns existing instance if already open, same as SampleDataService.loadDemoData)
- Added required imports for all model types used in typed box opens

**Key changes:**
- Added imports: Direction, DirectionConnection, ReflectionAnswer, ReflectionQuestion, WeeklySummary
- New method: `wipeAllData()` with proper documentation and order of operations
- Settings cleared last for safety (if wipe fails midway, app doesn't get stuck)

### Task 2: Update HomeShell triple-tap to wipe all data and return to launcher
**Status:** ✅ Complete
**Commit:** 6beeb08
**Files:** lib/screens/home_shell.dart

Updated triple-tap reset mechanism to:
- Call `wipeAllData()` instead of just resetting onboarding flags
- Navigate to `OnboardingGate` which detects `launcherCompleted=false` and shows LauncherScreen
- Renamed method from `_resetOnboarding` to `_resetApp` for clarity
- Updated call site in `_handleTap`

**Key changes:**
- Replaced `onboarding/onboarding_flow.dart` import with `../main.dart` (for OnboardingGate)
- Renamed `_resetOnboarding` → `_resetApp`
- Replaced flag-setting logic with single `wipeAllData()` call
- Navigation target changed from OnboardingFlow to OnboardingGate
- Removed redundant `setNotificationsEnabled(false)` (wipeAllData already clears settings)

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

✅ `flutter analyze lib/services/storage_service.dart lib/screens/home_shell.dart` — 1 pre-existing deprecation warning (documented in CLAUDE.md as known/cosmetic), no errors
✅ wipeAllData() method exists and clears all 7 boxes
✅ Triple-tap calls wipeAllData() and navigates to OnboardingGate
✅ OnboardingGate will show LauncherScreen when launcherCompleted=false
✅ Debug mode guard (kDebugMode) preserved
✅ No confirmation dialog (per requirement RESET-01)

**Manual testing required:**
- Triple-tap Home icon in debug mode → verify all data wiped → verify launcher screen shown
- From launcher, choose "Use sample data" → verify demo loads and shows HomeShell
- Triple-tap again → verify reset works multiple times
- From launcher, choose "Start fresh" → verify onboarding flow starts

## Architecture Impact

### Data Flow
```
User triple-taps Home icon (debug mode)
  → _resetApp() called
  → wipeAllData() clears all 7 Hive boxes
  → Navigator pushes OnboardingGate with removeUntil
  → OnboardingGate checks launcherCompleted (now false)
  → LauncherScreen shown
  → User can choose demo or fresh start
```

### Box Clear Order
1. entries
2. reflectionAnswers
3. reflectionQuestions
4. directions
5. direction_connections
6. weekly_summaries
7. settings (LAST - contains launcher_completed, onboarding_completed)

Clearing settings last ensures that if the wipe fails partway through, the app doesn't get stuck showing the launcher with partially-intact data.

## Success Criteria

✅ Triple-tapping the Home icon wipes all data from all Hive boxes (RESET-01)
✅ After wipe, app returns to launcher screen with fresh state (RESET-01)
✅ User can choose demo or fresh start again after reset (RESET-01)
✅ Reset only works in debug mode (kDebugMode guard preserved)
✅ All files pass flutter analyze with no errors (1 pre-existing cosmetic warning)

## Notes for Future Work

- Triple-tap mechanism is debug-only by design (kDebugMode guard)
- No confirmation dialog before wipe (per RESET-01 requirements)
- ReflectionService.init() will re-seed questions automatically on next app start
- This enables rapid re-demonstration of demo mode without app reinstall
- Future: Could add UI button in Settings (debug section) for easier reset access

## Self-Check: PASSED

**Files created:** None (summary file created separately)

**Files modified:**
- FOUND: /Users/radekmuzikant/Documents/elio/lib/services/storage_service.dart
- FOUND: /Users/radekmuzikant/Documents/elio/lib/screens/home_shell.dart

**Commits:**
- FOUND: 4885460 (Task 1: Add wipeAllData method)
- FOUND: 6beeb08 (Task 2: Update triple-tap reset)

All claims verified. Implementation complete and committed.
