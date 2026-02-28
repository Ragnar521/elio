---
phase: 08-launcher-screen
plan: 01
subsystem: launcher-flow
tags: [onboarding, demo-mode, first-launch]
dependency_graph:
  requires: [sample-data-service]
  provides: [launcher-screen, launcher-gate-logic]
  affects: [app-initialization, onboarding-flow]
tech_stack:
  added: []
  patterns: [gate-pattern, state-callback]
key_files:
  created:
    - lib/screens/launcher_screen.dart
  modified:
    - lib/services/storage_service.dart
    - lib/main.dart
decisions:
  - "Launcher appears only on first app open before any other screen"
  - "Demo mode sets both launcher_completed and onboarding_completed to skip onboarding"
  - "Fresh start only sets launcher_completed, allowing normal onboarding flow"
  - "Loading overlay shows during demo data load (takes several seconds)"
metrics:
  duration: 85s
  tasks: 2
  files_modified: 3
  commits: 2
  completed: 2026-02-28
---

# Phase 08 Plan 01: Launcher Screen Summary

**One-liner:** First-launch screen with demo mode (90 days sample data) and fresh start options using gate pattern with loading state.

## What Was Built

Created the launcher screen that appears on first app open, giving users the choice between exploring Elio with 90 days of pre-loaded sample data or starting their own fresh journey. The launcher integrates seamlessly into the app's gate logic and never appears again after the initial choice.

### Key Components

**1. LauncherScreen (lib/screens/launcher_screen.dart)**
- Full-screen centered layout with Elio branding
- Two tappable option cards with InkWell ripple effects
- Demo mode card: "Explore with sample data" with auto_awesome icon
- Fresh start card: "Start your own journey" with edit_note icon
- Loading overlay with CircularProgressIndicator during demo data load
- Error handling with SnackBar fallback
- Follows Elio design system (18px border radius, 24px padding, dark surface cards)

**2. StorageService Extension (lib/services/storage_service.dart)**
- Added `launcherCompleted` getter with `defaultValue: false`
- Added `setLauncherCompleted(bool)` setter
- New `_launcherCompletedKey` constant for Hive settings box
- Mirrors existing onboarding settings pattern

**3. App Gate Logic (lib/main.dart)**
- Updated OnboardingGate to three-state logic:
  1. `!launcherCompleted` → LauncherScreen
  2. `!onboardingCompleted` → OnboardingFlow
  3. Both complete → HomeShell
- `_handleLauncherFinished()` callback re-checks onboarding status (demo mode sets it)
- Demo mode path: launcher → loadDemoData → HomeShell (skips onboarding)
- Fresh start path: launcher → OnboardingFlow → HomeShell

### User Flows

**Demo Mode Flow:**
1. User taps "Explore with sample data"
2. Loading overlay appears: "Loading sample data..."
3. SampleDataService.loadDemoData() runs (~3-5 seconds)
4. Sets launcher_completed=true, onboarding_completed=true (via loadDemoData)
5. Gate re-checks settings, shows HomeShell with 90 days of data
6. User name is "Alex", 4 directions, ~78 entries, reflections, weekly summaries

**Fresh Start Flow:**
1. User taps "Start your own journey"
2. Sets launcher_completed=true immediately
3. Gate shows OnboardingFlow (name, first check-in, etc.)
4. After onboarding, shows HomeShell as normal

**Subsequent Launches:**
- launcher_completed=true → skips LauncherScreen entirely
- Goes straight to onboarding gate logic (or HomeShell if onboarding complete)

## Deviations from Plan

None — plan executed exactly as written.

## Testing & Verification

**Automated Checks:**
- `flutter analyze` passes for all modified files (8 cosmetic withOpacity deprecations, known issue)
- No compilation errors
- State management works correctly with StatefulWidget callbacks

**Manual Testing Required:**
- [ ] Fresh install shows LauncherScreen first
- [ ] Demo mode loads data and lands on Home tab
- [ ] Fresh start flows into onboarding
- [ ] Launcher never appears on second launch
- [ ] Loading indicator visible during demo data load
- [ ] Error handling works if loadDemoData fails

## Key Decisions

**1. Launcher as First Gate**
- **Decision:** Check launcher_completed before onboarding_completed
- **Rationale:** Ensures launcher is the very first thing users see, even before onboarding
- **Impact:** Clean separation of demo mode vs. real user paths

**2. Demo Mode Sets Onboarding Complete**
- **Decision:** SampleDataService.loadDemoData() sets onboarding_completed=true
- **Rationale:** Demo users should skip onboarding and see full app immediately
- **Impact:** Demo mode lands directly on HomeShell with all features visible

**3. Loading State with Overlay**
- **Decision:** Full-screen overlay with loading indicator during demo data load
- **Rationale:** LoadDemoData takes 3-5 seconds, user needs visual feedback
- **Impact:** Better UX, prevents double-taps, clear progress indication

**4. Error Handling with SnackBar**
- **Decision:** If loadDemoData() fails, show SnackBar and reset loading state
- **Rationale:** Graceful degradation, user can retry
- **Impact:** Resilient to Hive errors or data corruption edge cases

## Performance Metrics

- **Duration:** 85 seconds total
- **Tasks:** 2 of 2 completed
- **Files:** 3 modified (1 created, 2 updated)
- **Commits:** 2 (1 per task)
- **Lines Added:** ~220 lines (launcher screen + gate logic + settings)

## Files Changed

| File | Type | Lines | Purpose |
|------|------|-------|---------|
| lib/screens/launcher_screen.dart | Created | 200 | Launcher UI with two option cards |
| lib/services/storage_service.dart | Modified | +11 | launcher_completed getter/setter |
| lib/main.dart | Modified | +7 | Three-state gate logic |

## Integration Points

**Upstream Dependencies:**
- SampleDataService.loadDemoData() (Phase 07)
- StorageService.onboardingCompleted (existing)
- HomeShell, OnboardingFlow (existing)

**Downstream Impact:**
- App entry point behavior changed (launcher first)
- Demo mode becomes accessible to all users
- Onboarding flow unchanged (still works for fresh start users)

## Technical Notes

**State Management Pattern:**
- Uses StatefulWidget with VoidCallback pattern (matches OnboardingFlow)
- Parent gate (OnboardingGate) controls navigation via setState
- Child screen (LauncherScreen) calls onFinished callback
- Re-checks settings after callback to catch demo mode changes

**Design Consistency:**
- Uses ElioColors.darkBackground, darkSurface, darkAccent
- 18px border radius matches existing card style
- 24px padding matches other screens
- CircularProgressIndicator uses darkAccent color

**Error Resilience:**
- Try-catch wraps loadDemoData call
- SnackBar provides user feedback on failure
- Loading state resets on error
- User can retry without restarting app

## Self-Check

Verifying all claims in this summary:

**Files exist:**
```
✓ lib/screens/launcher_screen.dart
✓ lib/services/storage_service.dart (modified)
✓ lib/main.dart (modified)
```

**Commits exist:**
```
✓ 6d89981 - feat(08-01): add launcher screen and launcher_completed setting
✓ f3174b8 - feat(08-01): wire launcher into app gate logic
```

**Self-Check: PASSED**

All files created, all commits present, all functionality implemented as specified.

---

**Plan Status:** Complete
**Next Step:** Phase 08 complete — proceed to milestone v2.1 testing and release
