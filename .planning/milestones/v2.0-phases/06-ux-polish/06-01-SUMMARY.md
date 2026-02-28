---
phase: 06-ux-polish
plan: 01
subsystem: foundation-ux
tags: [widgets, micro-interactions, empty-states, error-handling]
dependency_graph:
  requires: []
  provides:
    - AnimatedTap wrapper widget
    - EmptyStateView component
    - SVG empty state assets
    - Global error handler
  affects:
    - All future screens using empty states
    - All interactive elements using tap animations
tech_stack:
  added:
    - flutter_svg: ^2.0.10
  patterns:
    - Reusable animation wrapper pattern
    - Centralized empty state design
    - Global error boundary pattern
key_files:
  created:
    - lib/widgets/animated_tap.dart
    - lib/widgets/empty_state_view.dart
    - assets/empty_states/history_empty.svg
    - assets/empty_states/insights_empty.svg
    - assets/empty_states/directions_empty.svg
  modified:
    - lib/main.dart
    - pubspec.yaml
decisions:
  - Use AnimatedScale with 150ms duration for press feedback
  - Haptic feedback optional (platform safety wrapped in try-catch)
  - SVG colorFilter applies warm cream tone for brand consistency
  - Error handler shows exception only in kDebugMode
  - Empty state CTA button only shown when both label and callback provided
metrics:
  duration: 2
  tasks_completed: 2
  files_created: 5
  files_modified: 2
  completed_at: "2026-02-27T18:06:18Z"
---

# Phase 06 Plan 01: Foundation Widgets & Infrastructure Summary

**One-liner:** Created reusable AnimatedTap wrapper, EmptyStateView component, 3 SVG line art assets, and global error handler for UX polish foundation.

## What Was Built

### AnimatedTap Widget
A configurable wrapper that adds subtle scale animation with optional haptic feedback to any child widget. Provides press-and-release micro-interaction with:
- Configurable pressScale (0.97 for buttons, 0.98 for cards)
- 150ms AnimatedScale with Curves.easeInOut
- Optional haptic feedback (HapticFeedback.lightImpact) with platform safety
- Press state tracking via GestureDetector (onTapDown/onTapUp/onTapCancel)

### EmptyStateView Widget
Standard empty state layout component with:
- SVG illustration with ColorFilter applying warm cream tone (#F9DFC1 at 0.6 opacity)
- Title using headlineSmall from theme
- Description using bodyMedium at 0.7 opacity
- Optional FilledButton CTA with Elio accent styling
- Consistent spacing (24px after SVG, 12px after title, 24px before CTA)

### SVG Line Art Assets
Created 3 minimal Notion-style line art illustrations:
- **history_empty.svg:** Open journal with pen representing the journey starting
- **insights_empty.svg:** Simple line chart with upward trend representing data patterns
- **directions_empty.svg:** Compass rose representing life direction

All SVGs use:
- viewBox="0 0 120 120" for consistent sizing
- stroke="#F9DFC1" (warm cream) with varying opacity for depth
- stroke-width="2" for primary elements
- stroke-linecap="round" and stroke-linejoin="round" for smooth lines

### Global Error Handler
ErrorWidget.builder override in main.dart that:
- Replaces red Flutter error screen with user-friendly fallback
- Shows error icon, title ("Something went wrong"), recovery guidance
- Uses Elio design system colors (darkBackground, darkAccent, darkPrimaryText)
- Displays exception details in monospace font only when kDebugMode is true
- Set before service initialization to catch startup errors

## Task Breakdown

### Task 1: Create AnimatedTap widget, EmptyStateView widget, and SVG assets
- Added flutter_svg: ^2.0.10 dependency to pubspec.yaml
- Configured assets/empty_states/ directory in flutter assets
- Created AnimatedTap widget with press state management
- Created EmptyStateView widget with SVG rendering
- Designed and created 3 SVG line art illustrations
- Ran flutter pub get successfully
- **Commit:** 95b9c8f

### Task 2: Add global error handler to main.dart
- Imported flutter/foundation.dart for kDebugMode
- Imported theme/elio_colors.dart for design system colors
- Added ErrorWidget.builder after WidgetsFlutterBinding.ensureInitialized()
- Implemented user-friendly error UI with conditional debug info
- Verified with dart analyze (only cosmetic deprecation warnings)
- **Commit:** 3b2f820

## Deviations from Plan

None - plan executed exactly as written.

## Technical Decisions

1. **AnimatedScale over manual Transform:** Used Flutter's AnimatedScale widget for cleaner implementation and automatic animation handling.

2. **Try-catch for haptic feedback:** Wrapped HapticFeedback.lightImpact() in try-catch per research guidance to prevent platform-specific crashes.

3. **ColorFilter on SVG:** Applied ColorFilter.mode with BlendMode.srcIn to tint SVGs with warm cream color, ensuring brand consistency while maintaining vector scalability.

4. **Debug-only exception display:** Used kDebugMode guard to show exception details, preventing technical error exposure in production while aiding development.

5. **Optional CTA pattern:** CTA button only renders when both ctaLabel and onCtaPressed are non-null, allowing flexible empty state usage without CTA.

## Verification Results

All automated verifications passed:
- `flutter pub get` resolved flutter_svg successfully
- `dart analyze lib/widgets/animated_tap.dart lib/widgets/empty_state_view.dart` - no errors (3 cosmetic withOpacity deprecation warnings consistent with codebase)
- `dart analyze lib/main.dart` - no errors (3 cosmetic withOpacity deprecation warnings)
- All 3 SVG assets created in assets/empty_states/
- pubspec.yaml correctly declares flutter_svg dependency and asset directory

## Impact

### Immediate
- Foundation widgets ready for integration in Plan 02 and Plan 03
- Consistent empty state design across all screens
- Improved error experience replacing red error screen
- SVG assets optimized for performance (vector-based, lightweight)

### Future
- AnimatedTap can be applied to all interactive elements (buttons, cards, chips)
- EmptyStateView prevents empty state design drift
- Global error handler improves user experience during crashes
- SVG pattern established for future illustration needs

## Next Steps

Plan 02 will integrate these foundation widgets into existing screens:
- Apply AnimatedTap to buttons, cards, and navigation elements
- Replace existing empty states with EmptyStateView
- Add loading skeletons and optimistic UI patterns

## Self-Check: PASSED

### Created Files Verification
```bash
[ -f "lib/widgets/animated_tap.dart" ] && echo "FOUND: lib/widgets/animated_tap.dart"
[ -f "lib/widgets/empty_state_view.dart" ] && echo "FOUND: lib/widgets/empty_state_view.dart"
[ -f "assets/empty_states/history_empty.svg" ] && echo "FOUND: assets/empty_states/history_empty.svg"
[ -f "assets/empty_states/insights_empty.svg" ] && echo "FOUND: assets/empty_states/insights_empty.svg"
[ -f "assets/empty_states/directions_empty.svg" ] && echo "FOUND: assets/empty_states/directions_empty.svg"
```
**Result:** All files exist

### Commits Verification
```bash
git log --oneline --all | grep -q "95b9c8f" && echo "FOUND: 95b9c8f"
git log --oneline --all | grep -q "3b2f820" && echo "FOUND: 3b2f820"
```
**Result:** Both commits exist in git history
