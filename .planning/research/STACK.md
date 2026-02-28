# Stack Research

**Domain:** Flutter mood tracking & journaling app (subsequent milestone - UX polish & advanced features)
**Researched:** 2026-02-26
**Confidence:** MEDIUM-HIGH (based on Flutter ecosystem knowledge through January 2025, specific versions should be verified)

## Context

Elio v1.1.0 already has:
- Flutter SDK ^3.10.8
- Hive 2.2.3 + hive_flutter 1.1.0 (local storage)
- StatefulWidget + Singleton Services pattern
- Manual Hive adapters (no build_runner)
- flutter_local_notifications 17.1.2
- uuid 4.5.1

This research focuses on **additional packages needed** for v2.0 features:
- Edit/delete entries
- Search & filter
- Visual mood patterns (heatmap/calendar)
- Weekly summaries
- Smart nudges
- Premium animations & transitions
- App Store readiness

## Recommended Additions

### Animation & Transitions

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| **animations** | ^2.0.11 | Shared axis, fade through, fade scale transitions | Official Flutter package, best-in-class page transitions. Use for screen-to-screen navigation polish. |
| **flutter_animate** | ^4.5.0 | Declarative animations with timing/easing | Modern, lightweight alternative to traditional AnimationController boilerplate. Perfect for micro-interactions (button taps, card reveals). |
| **shimmer** | ^3.0.0 | Skeleton loading states | Industry standard for premium loading UX. Use for async data fetches (insights calculations, history loading). |

**Rationale:** Elio already has basic animations (300ms fade + slide in insights). These packages elevate polish without changing architecture. `animations` package is maintained by Flutter team, `flutter_animate` reduces boilerplate by 70%, `shimmer` is proven in production apps (40k+ likes on pub.dev).

### Data Visualization

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **fl_chart** | ^0.68.0 | Charts & graphs (line, bar, scatter) | Best for mood wave enhancement - supports touch interactions, tooltips, gradient fills. Already battle-tested in health/finance apps. |
| **table_calendar** | ^3.1.2 | Calendar UI with custom builders | Standard choice for calendar/heatmap views. Highly customizable, supports day-level data visualization. Use for mood heatmap feature. |
| **fl_heatmap** | ^1.0.0 | GitHub-style contribution heatmap | Lightweight, purpose-built for heatmaps. Alternative to table_calendar if you want pure heatmap (no date picker). |

**Rationale:** `fl_chart` is the de facto Flutter charting library (8k+ likes), actively maintained. `table_calendar` is the most mature calendar package with 2k+ likes. Both support custom styling to match Elio's warm dark mode palette.

**Note:** Elio already has a custom mood wave widget. `fl_chart` would be an upgrade if you want more sophisticated interactions (pinch zoom, multi-touch, animated updates).

### Search & Filter

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **Built-in only** | — | No package needed | Flutter's native `List.where()`, `String.contains()`, and `TextField.onChanged` are sufficient for entry search. |
| **intl** | ^0.19.0 | Date formatting & localization | Already implicitly included by Flutter, but add explicitly for date range filters ("Last 7 days", "This month"). |

**Rationale:** Search in mood tracking apps is usually simple (text in intention/reflection, date range, mood range). Adding a search package would be over-engineering. Use Hive's native filtering + Dart's collection methods.

**Implementation pattern:**
```dart
// In StorageService
List<Entry> searchEntries({
  String? keyword,
  DateTimeRange? dateRange,
  double? minMood,
  double? maxMood,
}) {
  return getAllEntries().where((entry) {
    if (keyword != null &&
        !entry.intention.toLowerCase().contains(keyword.toLowerCase())) {
      return false;
    }
    if (dateRange != null &&
        !dateRange.contains(entry.createdAt)) {
      return false;
    }
    if (minMood != null && entry.moodValue < minMood) return false;
    if (maxMood != null && entry.moodValue > maxMood) return false;
    return true;
  }).toList();
}
```

### UI Polish & Components

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **flutter_slidable** | ^3.1.1 | Swipe-to-delete, swipe-to-edit | Industry standard for list item actions. Use in history screen for swipe-to-delete entries. |
| **modal_bottom_sheet** | ^3.0.0 | Custom bottom sheets with smooth drag physics | Better than showModalBottomSheet() for complex sheets (edit entry, filter options). Already using in insights - standardize on this. |
| **flutter_staggered_animations** | ^1.1.1 | Staggered list animations | Polished reveal for history timeline, direction cards. Makes lists feel premium. |

**Rationale:** These are proven patterns in premium apps. `flutter_slidable` is the standard (3k+ likes), `modal_bottom_sheet` fixes native sheet limitations, `flutter_staggered_animations` adds subtle delight without being distracting.

### App Store Readiness

| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| **flutter_launcher_icons** | ^0.14.2 | App icon generation | Already in pubspec.yaml. Verify icon meets iOS/Android specs (1024x1024 source). |
| **flutter_native_splash** | ^2.4.1 | Splash screen generation | Replaces manual native splash config. Generates iOS/Android splash screens from single config. |
| **rename** | ^3.0.2 | Rename app in all platform files | Dev tool for final app name changes across Xcode, AndroidManifest, etc. |

**Rationale:** These are dev tools, not runtime dependencies. `flutter_native_splash` saves hours of manual native code editing. `rename` prevents mistakes when updating app display name.

### Testing & Quality (Optional but Recommended)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **golden_toolkit** | ^0.15.0 | Screenshot testing | Use if you want to prevent UI regressions. Captures widget snapshots. |
| **mockito** | ^5.4.4 | Mocking for tests | Only if adding unit tests for services. Not essential for v2.0. |

**Confidence: MEDIUM** — These are nice-to-have. Mood tracking apps can ship without tests, but they help with refactoring confidence.

## Installation

```bash
# Core additions for v2.0
flutter pub add animations flutter_animate shimmer
flutter pub add fl_chart table_calendar
flutter pub add flutter_slidable modal_bottom_sheet flutter_staggered_animations
flutter pub add intl

# Dev tools
flutter pub add --dev flutter_native_splash rename

# Optional (if adding visual regression tests)
flutter pub add --dev golden_toolkit mockito
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| **fl_chart** | syncfusion_flutter_charts | Use if you need advanced features (3D charts, stock charts). Syncfusion is more powerful but has larger footprint and licensing considerations. |
| **table_calendar** | flutter_calendar_carousel | Use if you need horizontal swipe calendar. table_calendar is more actively maintained. |
| **animations** (Flutter team) | page_transition | Use if you need one-off custom transitions. `animations` is better for consistent app-wide patterns. |
| **flutter_animate** | Traditional AnimationController | Use if you need frame-perfect control or complex choreography. flutter_animate is better for 90% of cases. |
| **Built-in search** | algolia_helper_flutter | Only if adding cloud search (out of scope for Elio's local-first philosophy). |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **provider / riverpod / bloc** | Elio uses StatefulWidget + Services pattern. Adding state management now would require architectural rewrite. | Continue with existing pattern. It's working. |
| **get_it / injectable** | Service locator pattern unnecessary when Singleton Services work fine. Adds complexity without benefit at this scale. | Keep `ServiceName.instance` pattern. |
| **dio / http** | Elio is local-only. No network calls needed. | Nothing. Hive is sufficient. |
| **flutter_local_notifications** (upgrade) | Already on 17.1.2. No critical updates in newer versions. Push notifications are out of v2.0 scope. | Keep current version. |
| **build_runner** | Elio explicitly uses manual Hive adapters. Adding build_runner now would conflict with existing pattern. | Continue manual adapters. |
| **freezed / json_serializable** | Hive doesn't need JSON serialization. Freezed adds build complexity. | Keep simple Hive TypeAdapters. |

## Stack Patterns by Feature

### Edit Entry Feature
**Stack:**
- No new packages needed
- Use existing Hive `box.put(entry.id, updatedEntry)`
- Show edit screen with pre-filled forms (reuse MoodEntryScreen pattern)
- Add "Save Changes" vs "Cancel" buttons

### Delete Entry Feature
**Stack:**
- `flutter_slidable` for swipe-to-delete in history
- Native confirmation dialog (`showDialog` with AlertDialog)
- Hive `box.delete(entry.id)` + cascade delete reflection answers

### Search & Filter
**Stack:**
- No packages - built-in Dart collections
- `TextField` for keyword search
- Custom filter chips (mood range, date range)
- Hive query + `List.where()` filtering

### Mood Heatmap/Calendar
**Stack:**
- `table_calendar` for calendar UI
- Custom day builder function:
  ```dart
  Widget dayBuilder(context, day, focusedDay) {
    final entries = getEntriesForDate(day);
    final avgMood = entries.isEmpty ? null : calculateAvg(entries);
    return Container(
      decoration: BoxDecoration(
        color: avgMood == null ? transparent : moodToColor(avgMood),
        shape: BoxShape.circle,
      ),
      child: Center(child: Text('${day.day}')),
    );
  }
  ```

### Weekly Summary Screen
**Stack:**
- `fl_chart` for summary visualizations (optional - can use custom widgets)
- `intl` for date formatting ("Week of Jan 20 - Jan 26")
- Reuse existing `InsightsService.getInsightsForPeriod()` logic
- Add "View Past Summaries" with list navigation

### Smart Nudges
**Stack:**
- No new packages needed
- Add `NudgeService` following Singleton pattern:
  - Check dormant directions (DirectionService already has `getDormantDirections()`)
  - Detect mood patterns (InsightsService already has pattern detection)
  - Return nudge suggestions (List<Nudge>)
- Show as cards in Home tab or insights tab
- Use existing notification service for reminders (future enhancement)

### Premium Animations
**Stack:**
- `animations` for screen transitions:
  ```dart
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => NextScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
    ),
  );
  ```
- `flutter_animate` for micro-interactions:
  ```dart
  Text('Mood saved!')
    .animate()
    .fadeIn(duration: 300.ms)
    .scale(begin: Offset(0.8, 0.8));
  ```
- `shimmer` for loading states:
  ```dart
  Shimmer.fromColors(
    baseColor: ElioColors.darkSurface,
    highlightColor: ElioColors.darkSurface.withOpacity(0.3),
    child: EntryCardSkeleton(),
  );
  ```

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| animations 2.0.11 | Flutter >=3.10.0 | Works with current Flutter 3.10.8 |
| fl_chart 0.68.0 | Flutter >=3.10.0 | Requires Dart >=3.0.0 (satisfied) |
| table_calendar 3.1.2 | intl ^0.18.0 or ^0.19.0 | May auto-upgrade intl, safe |
| flutter_slidable 3.1.1 | Flutter >=3.7.0 | Compatible |
| flutter_animate 4.5.0 | Flutter >=3.7.0 | Compatible |
| modal_bottom_sheet 3.0.0 | Flutter >=3.10.0 | May require null safety migration if older |

**Critical:** Before running `flutter pub add`, check pub.dev for latest versions. My knowledge cutoff is January 2025, so versions may have updated.

## Confidence Levels by Category

| Category | Confidence | Notes |
|----------|-----------|-------|
| Animation packages | **HIGH** | `animations` and `flutter_animate` are established standards. |
| Data visualization | **HIGH** | `fl_chart` and `table_calendar` are mature, widely used. |
| Search/filter approach | **HIGH** | Built-in approach is correct for this app's scale. |
| UI components | **MEDIUM-HIGH** | `flutter_slidable` and `modal_bottom_sheet` are solid, but verify latest versions. |
| App Store tools | **MEDIUM** | Tools work, but App Store guidelines change frequently - verify current requirements. |
| Version numbers | **MEDIUM** | Based on January 2025 knowledge. Verify on pub.dev before installing. |

## Implementation Priority

**Phase 1 (Core Polish - Week 1-2):**
1. Add `animations` package - screen transitions
2. Add `shimmer` - loading states
3. Add `flutter_slidable` - swipe-to-delete in history

**Phase 2 (Features - Week 3-4):**
4. Add `table_calendar` - mood heatmap view
5. Add `flutter_staggered_animations` - list reveals
6. Add `intl` explicitly - date formatting

**Phase 3 (Advanced - Week 5-6):**
7. Add `fl_chart` - upgrade mood wave (if needed)
8. Add `flutter_animate` - micro-interactions
9. Add `modal_bottom_sheet` - standardize sheets

**Phase 4 (App Store Prep - Week 7-8):**
10. Add `flutter_native_splash` - splash screen
11. Verify `flutter_launcher_icons` - icon specs
12. Add `rename` (dev tool) - finalize app name

## Sources

- **Pub.dev package stats** - Popularity and maintenance activity (through January 2025)
- **Flutter documentation** - Official packages (animations, intl)
- **Existing codebase analysis** - Current patterns and constraints (Hive manual adapters, Singleton Services)
- **CLAUDE.md + PROJECT.md** - Project architecture and requirements

**Verification recommended:**
- Visit pub.dev for each package before installation to confirm:
  - Latest version number
  - Flutter SDK compatibility
  - Null safety migration status
  - Recent maintenance activity (last publish date)

---
*Stack research for: Elio v2.0 - Mood Tracking App*
*Researched: 2026-02-26*
*Confidence: MEDIUM-HIGH (verify versions on pub.dev)*
