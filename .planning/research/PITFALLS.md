# Pitfalls Research

**Domain:** Flutter Mood Tracking & Journaling Apps (App Store Polish)
**Researched:** 2026-02-26
**Confidence:** MEDIUM (based on Flutter/Hive patterns + wellness app domain knowledge)

## Critical Pitfalls

### Pitfall 1: Hive Data Migration Without Version Control

**What goes wrong:**
Adding/removing fields from Hive models causes crashes for existing users when they update the app. TypeAdapter reads expect exact field counts, leading to "Expected X fields but found Y" errors on app launch.

**Why it happens:**
Developers test with fresh installs during development. Existing users have data written with old schema. Hive's manual TypeAdapters don't handle schema evolution automatically.

**How to avoid:**
- Implement versioned TypeAdapters with migration logic before making schema changes
- Use field defaults for new optional fields in read() method
- Add version field to each model (e.g., `int schemaVersion = 1`)
- Test migrations with real user data copies before release

**Warning signs:**
- Adding fields to Entry, Direction, or ReflectionAnswer models
- Changing field types (e.g., `String` → `String?`)
- Removing deprecated fields

**Phase to address:**
Phase 1 (Foundation) — before adding edit/delete features that might require schema changes

---

### Pitfall 2: Unbounded List Rendering in History/Search

**What goes wrong:**
Loading all entries at once into ListView causes memory bloat and scroll jank when users have 100+ entries. App feels sluggish, scrolling stutters, and memory warnings appear on older devices.

**Why it happens:**
Simple `ListView(children: entries.map(...))` loads entire dataset into memory. Works fine with 10 entries during testing, fails with 200+ in production.

**How to avoid:**
- Use `ListView.builder()` with lazy loading for History screen
- Implement pagination for search results (show 20, load more on scroll)
- Consider `ListView.separated()` for better performance with date dividers
- Profile with 500+ dummy entries during development

**Warning signs:**
- History screen using `ListView(children: ...)` instead of `ListView.builder()`
- Search returning all entries without pagination
- Memory usage climbing linearly with entry count

**Phase to address:**
Phase 2 (Search & Filter) — implement before search feature to avoid refactoring later

---

### Pitfall 3: Missing Undo for Destructive Actions

**What goes wrong:**
Users accidentally delete entries or directions, lose data permanently, leave 1-star reviews saying "lost my entire journal history." No recovery mechanism exists.

**Why it happens:**
Developers focus on implementing delete functionality without considering error recovery. Confirmation dialogs feel sufficient during testing, but production usage reveals fat-finger taps and regret.

**How to avoid:**
- Implement soft delete with 30-day retention before permanent deletion
- Add "Undo" SnackBar for 5 seconds after delete action
- Store deleted items in separate Hive box (`deleted_entries`) with timestamp
- Add "Recently Deleted" screen accessible from Settings

**Warning signs:**
- Delete operations calling `box.delete(key)` immediately
- No grace period between user action and permanent data loss
- Confirmation dialog as only safeguard

**Phase to address:**
Phase 1 (Foundation) — implement with edit/delete features, not as an afterthought

---

### Pitfall 4: StatefulWidget Memory Leaks in Entry Flows

**What goes wrong:**
Navigation through mood entry → intention → reflection → confirmation creates orphaned listeners, timers, or animation controllers. Memory leaks accumulate across multiple check-ins, causing gradual performance degradation.

**Why it happens:**
`initState()` creates resources (controllers, listeners, streams) but `dispose()` doesn't clean them up properly. Multiple screen pushes create new instances without disposing old ones.

**How to avoid:**
- Always dispose TextEditingControllers, AnimationControllers, StreamControllers in `dispose()`
- Use `mounted` check before calling `setState()` after async operations
- Audit all StatefulWidgets with animation/input controllers
- Use Flutter DevTools memory profiler to verify no leaks

**Warning signs:**
- Controllers created in `initState()` without matching `dispose()`
- Timers/periodic tasks running after screen pop
- Memory usage climbing after multiple check-in flows

**Phase to address:**
Phase 3 (Animations) — review during animation polish pass, catches existing + new leaks

---

### Pitfall 5: No Offline Handling for Local-Only App

**What goes wrong:**
Despite being local-only, app assumes device services (notifications, date/time, file system) are always available. Crashes occur when permissions change, storage is full, or system services fail.

**Why it happens:**
Developers assume "local-only = no network error handling needed." Forget that local resources can also fail (disk full, permission revoked, service unavailable).

**How to avoid:**
- Wrap Hive operations in try-catch with graceful degradation
- Check storage availability before saving large datasets
- Handle notification permission denial gracefully
- Show meaningful error messages, not generic exceptions

**Warning signs:**
- Hive `.add()` or `.put()` operations without error handling
- No disk space checks before heavy write operations
- Assuming notification permissions persist after granted once

**Phase to address:**
Phase 4 (Polish) — comprehensive error handling pass before App Store submission

---

### Pitfall 6: Inconsistent Dark Mode Implementation

**What goes wrong:**
Some screens use theme colors correctly, others have hardcoded values. System dialogs, bottom sheets, or third-party widgets appear in light mode despite dark theme. Feels amateur and inconsistent.

**Why it happens:**
Initial screens use theme, new screens copy-paste hex codes for speed. Standard Material widgets default to light mode unless explicitly configured. Not tested across both themes systematically.

**How to avoid:**
- Ban hardcoded colors — enforce `Theme.of(context)` or `ElioColors` constants
- Configure Material app theme data for dialogs, bottom sheets, system UI
- Test every screen in both light and dark mode before completion
- Use `brightness: Brightness.dark` for system UI overlay style

**Warning signs:**
- Hex color codes in widget files instead of theme references
- System dialogs appearing in light mode
- Inconsistent surface colors between screens

**Phase to address:**
Phase 4 (Polish) — design consistency pass, verify all screens match theme system

---

### Pitfall 7: Apple App Store Health Data Compliance

**What goes wrong:**
App Store rejects app for "health data" usage without proper disclaimers, privacy policy, or HealthKit integration. Mood tracking = health data in Apple's eyes, even if not using HealthKit.

**Why it happens:**
Developers assume "no HealthKit = no health app." Apple's review guidelines classify mood/mental health tracking as health-related regardless of API usage. Requires specific disclosures.

**How to avoid:**
- Add prominent disclaimer: "Not medical advice, for awareness only"
- Include privacy policy even though data is local-only (explain data storage)
- Add "App Privacy" section in App Store Connect detailing data collection (even if none)
- Don't use medical terminology ("diagnosis", "treatment", "therapy")

**Warning signs:**
- Marketing copy or app description using medical claims
- No privacy policy linked in app or store listing
- Missing "Data Used to Track You" disclosures in App Store Connect

**Phase to address:**
Phase 5 (App Store) — prepare before submission to avoid rejection delays

---

### Pitfall 8: Search Performance with Full-Text Scanning

**What goes wrong:**
Search scans entire entry text, intention, and reflection answers on UI thread. With 500+ entries, search typing becomes laggy (200ms+ delay per keystroke). Users perceive app as "slow and unpolished."

**Why it happens:**
Simple implementation: `entries.where((e) => e.intention.contains(query))` runs synchronously. Works fine with 20 entries, unacceptable with 200+. No debouncing or async execution.

**How to avoid:**
- Implement debounced search (300ms delay after last keystroke)
- Run search in isolate for heavy operations (500+ entries)
- Index searchable text fields for faster lookup
- Show loading indicator for searches taking >100ms

**Warning signs:**
- Search using synchronous `where()` on large lists
- No debouncing on search TextField `onChanged`
- UI thread blocking during search (jank in DevTools timeline)

**Phase to address:**
Phase 2 (Search & Filter) — implement performant search from the start, avoid refactor later

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Using StatefulWidget instead of StatelessWidget with providers | Simpler initial code, matches existing pattern | setState rebuilds entire tree, poor performance with complex screens | Acceptable for this project (small scale, no complex state) |
| Manual Hive TypeAdapters instead of build_runner | No code generation step, simpler build | Schema changes require manual migration code, error-prone | Current approach OK, but add migration utilities |
| Storing full Entry objects in DirectionConnection | Faster reads, no joins needed | Data duplication, stale data if entry edited | Never — keep normalized schema, join on read |
| Loading entire entry list on app start | Simple caching, fast after first load | Memory bloat with 1000+ entries | Never — load on-demand with pagination |
| Hardcoded animation durations (300ms everywhere) | Consistent feel without config | Hard to tweak feel globally, no adaptive performance | Acceptable for small set of animations, centralize if expanding |
| No analytics/crash reporting (local-only) | Privacy-first, no third-party SDKs | Blind to production crashes and usage patterns | Acceptable if manual bug reports sufficient, add opt-in analytics for growth phase |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| flutter_local_notifications | Assuming notification permission persists after granted | Check permission before every schedule, handle denial gracefully |
| Hive Box operations | Not closing boxes, causing file locks | Use `await box.close()` in service disposal, open lazily |
| iOS App Store submission | Forgetting to increment build number in Xcode | Automate in CI/CD or add pre-submission checklist |
| Dark mode system UI | Using hardcoded status bar style | Sync `SystemChrome.setSystemUIOverlayStyle()` with theme changes |
| Flutter Navigator 2.0 | Mixing Navigator 1.0 and 2.0 patterns | Stick to simple push/pop (current approach), or fully migrate to declarative routing |
| iOS keyboard avoidance | Scaffold's resizeToAvoidBottomInset not working with complex layouts | Wrap in SingleChildScrollView with bottom padding, test on various screen sizes |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Rebuilding entire ListView on every setState | Scroll jank, poor responsiveness | Use `ListView.builder()`, const widgets, separate state | 50+ entries with frequent updates |
| Unoptimized AnimationController in entry flow | Dropped frames during transitions | Use `AnimationController` with `vsync`, dispose properly | Multiple concurrent animations |
| Synchronous Hive queries on UI thread | Stuttering during data operations | Use `await` properly, show loading states | 200+ entries in box |
| Large reflection answer text rendering | Slow scrolling in History when answers are long | Truncate text in list view, expand on tap | 10+ long-form answers visible |
| Day pattern chart recalculating on every build | Insights screen rebuild lag | Cache calculations, only recompute when data changes | 90+ days of entries in period |
| No widget keys in reorderable lists (future feature) | Incorrect animations, state loss | Add `Key` to list items | Any dynamic list reordering |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Not encrypting Hive database | Device theft exposes private mood/reflection data | Use `encryptionCipher` with user-derived key, biometric unlock option |
| Logging sensitive data to console | User reflections exposed in crash logs | Sanitize debug output, remove debugPrint before release |
| Screenshots containing personal data | Reflections visible in app switcher | Use `WidgetsBindingObserver` to blur sensitive screens on background |
| Storing encryption key in SharedPreferences | Defeats encryption purpose | Use flutter_secure_storage for key storage |
| No data export before uninstall | Users lose data permanently | Add export feature, warn before account deletion |
| Reflections visible in notification previews | Private thoughts shown on lock screen | Keep notification text generic ("Time to check in"), no content preview |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No empty states for new users | Blank screen confusion, "is it broken?" | Show helpful empty states with clear CTAs ("Create your first entry") |
| Hiding edit/delete behind long-press only | Discoverability issues, users don't find features | Add swipe actions + overflow menu for multiple entry points |
| No loading indicators for heavy operations | App appears frozen during Hive queries, chart generation | Show skeleton screens, progress indicators for >200ms operations |
| Mood slider too sensitive to input | Accidental mood changes, frustration | Add haptic feedback at mood boundaries, larger touch targets |
| No confirmation for irreversible actions | Accidental deletes, data loss anxiety | Require confirmation + implement undo for 5-10 seconds |
| Date pickers defaulting to today | Annoying when adding historical entries | Default to last entry date or selected date in history view |
| No keyboard shortcuts/gestures | Feels slow for power users | Add swipe to delete, pull-to-refresh, long-press shortcuts |
| Overwhelming onboarding flow | Users drop off before first entry | Keep onboarding minimal (name + first check-in), teach features gradually |
| No progress indication for streaks/goals | Users don't feel momentum | Celebrate milestones (7-day, 30-day streaks), show progress visually |
| Generic error messages ("Error occurred") | Users confused, can't self-resolve | Specific, actionable errors ("Storage full. Delete old entries to continue.") |

## "Looks Done But Isn't" Checklist

- [ ] **Edit Entry:** Often missing validation (can edit future entries?), undo logic, reflection answer updates — verify edits preserve data integrity
- [ ] **Delete Entry:** Often missing direction connection cleanup, reflection answer orphans — verify cascading deletes work
- [ ] **Search:** Often missing empty results state, loading indicators, special character handling — verify edge cases (empty query, no results, 1000+ matches)
- [ ] **Filters:** Often missing "clear all" option, filter persistence, multi-select logic — verify all combinations work (mood range + date + direction)
- [ ] **Weekly Summary:** Often missing empty data handling (1 entry week), timezone edge cases — verify calculations with minimal data
- [ ] **Smart Nudges:** Often missing permission denial handling, notification tap navigation, scheduling persistence across app updates — verify full lifecycle
- [ ] **Calendar Heatmap:** Often missing month boundaries, leap years, timezone handling — verify edge dates (Dec 31, Feb 29, DST transitions)
- [ ] **Animations:** Often missing interruption handling (user taps during animation), disposal on screen pop — verify rapid navigation doesn't crash
- [ ] **Dark Mode:** Often missing system dialog styling, splash screen, launch screen — verify every UI element respects theme
- [ ] **Data Export:** Often missing large dataset handling (OOM with 10k entries), progress indication, file write errors — verify with realistic data volumes

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Hive schema migration crash | HIGH | 1. Hotfix with try-catch fallback to previous schema, 2. Implement versioned migration, 3. Test with affected user data |
| Memory leak from undisposed controllers | MEDIUM | 1. Identify leaking widget with DevTools, 2. Add dispose() calls, 3. Audit all StatefulWidgets, 4. Release patch |
| Search performance degradation | MEDIUM | 1. Add debouncing to existing search, 2. Refactor to isolate in next update |
| App Store rejection for health claims | LOW | 1. Update app description/screenshots, 2. Add disclaimers to app, 3. Resubmit with privacy policy link |
| Data loss from missing undo | HIGH | 1. Add soft delete box, 2. Implement recovery screen, 3. Communicate feature to affected users |
| ListView performance issues | MEDIUM | 1. Convert to ListView.builder(), 2. Add pagination, 3. Profile improvements |
| Dark mode inconsistencies | LOW | 1. Audit screens for hardcoded colors, 2. Replace with theme references, 3. Test systematically |
| Missing encryption | HIGH | 1. Backup existing data, 2. Migrate to encrypted box, 3. Handle key management, 4. Test migration thoroughly |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Hive data migration crashes | Phase 1 (Foundation) | Load app with v1.1 data, verify no crashes after edit/delete schema changes |
| Unbounded list rendering | Phase 2 (Search & Filter) | Profile with 500+ entries, verify smooth 60fps scrolling |
| Missing undo for deletes | Phase 1 (Foundation) | Delete entry, verify undo appears, confirm recovery works |
| StatefulWidget memory leaks | Phase 3 (Animations) | DevTools memory timeline after 20 check-in flows, verify no accumulation |
| Offline handling gaps | Phase 4 (Polish) | Test with storage full, permissions denied, verify graceful errors |
| Dark mode inconsistencies | Phase 4 (Polish) | Screenshot test every screen in dark mode, compare to design system |
| App Store health compliance | Phase 5 (App Store) | Review submission checklist, verify disclaimers, privacy policy present |
| Search performance issues | Phase 2 (Search & Filter) | Type quickly in search with 500+ entries, verify <100ms response |
| No empty states | Phase 4 (Polish) | Fresh install, navigate to each screen, verify helpful empty states |
| Missing error handling | Phase 4 (Polish) | Error injection tests (disk full, permission denied), verify messages |

## Flutter-Specific Warnings

### Hot Reload vs. Full Restart
**Issue:** Service singletons lose state on hot reload, causing "Service not initialized" errors
**Solution:** Always test features with full restart (stop + run), document in onboarding for new contributors

### Build Context After Async
**Issue:** Using `context` after `await` without `mounted` check causes crashes
**Solution:** Check `if (!mounted) return;` before any `setState()` or `Navigator` call after async

### ListView vs. ListView.builder
**Issue:** Developer docs show `ListView(children: ...)` in examples, doesn't scale
**Solution:** Establish pattern: always use `.builder()` for dynamic lists, document in style guide

### Theme Access in Stateless Builds
**Issue:** Accessing `Theme.of(context)` in widget fields instead of build() causes stale values
**Solution:** Only access theme in build() method or initState(), never in widget fields

### Animation Controller Disposal
**Issue:** Forgetting `dispose()` causes memory leaks, but no compile-time warning
**Solution:** Code review checklist: every `AnimationController` creation must have matching `dispose()`

### iOS Simulator vs. Real Device
**Issue:** Performance looks fine on simulator, janky on real device (especially older models)
**Solution:** Test on real iPhone 8/SE for baseline performance, profile with DevTools on device

## App Store-Specific Warnings

### Privacy Nutrition Labels
**Required:** Even local-only apps must declare data practices
**Include:** Data storage location, retention policy, what's collected (mood, text, dates)

### Health App Classification
**Trigger:** Keywords like "mood", "mental health", "wellness" flag health review
**Requirement:** Disclaimers about not being medical advice, no treatment claims

### Screenshot Requirements
**iOS:** 6.5" and 5.5" displays (iPhone 14 Pro Max and iPhone 8 Plus)
**Content:** Must show actual app features, no mockups, avoid sensitive test data

### Version Increment
**iOS:** Both version (1.0.0) and build number (1) must increment
**Common mistake:** Forgetting to increment in Xcode `Info.plist` after `pubspec.yaml`

### TestFlight vs. Production
**Gotcha:** TestFlight allows longer review times, but production rejections delay launch
**Strategy:** Submit for production review 1 week before target launch date

## Sources

- Flutter performance best practices documentation
- Hive database documentation (manual adapters, migration patterns)
- iOS App Store Review Guidelines (Health & Medical category, 2026)
- Flutter memory profiling patterns from DevTools documentation
- Common mood tracking app UX patterns (industry knowledge)
- Flutter StatefulWidget lifecycle documentation

**Note:** This research is based on established Flutter/Hive development patterns and App Store requirements for wellness apps. Confidence level is MEDIUM due to lack of real-time web verification, but recommendations are grounded in documented technical constraints and domain-specific considerations for Elio's architecture (StatefulWidget + Hive + local-only storage).

---
*Pitfalls research for: Elio v2.0 — Flutter Mood Tracking & Journaling App*
*Researched: 2026-02-26*
