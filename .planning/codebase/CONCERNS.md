# Codebase Concerns

**Analysis Date:** 2026-02-26

## Tech Debt

**Deprecated buildSnapshot method:**
- Issue: `lib/services/insights_service.dart` contains synchronous `buildSnapshot()` method that returns empty insights list as fallback
- Files: `lib/services/insights_service.dart:216-318`, `lib/screens/insights_screen.dart:100-106`
- Impact: Insights screen uses deprecated method, missing direction insights and proper async data loading
- Fix approach: Replace all `buildSnapshot()` calls with `getInsightsForPeriod()` and update screens to use async pattern. Remove deprecated method after migration complete.

**Manual Hive adapter pattern:**
- Issue: Manual Hive adapters instead of code generation (no `build_runner` used)
- Files: `lib/models/*.dart` (all model files with HiveType/HiveField annotations)
- Impact: More manual maintenance, prone to TypeId conflicts, harder to update models
- Fix approach: Migrate to `hive_generator` + `build_runner` workflow for automated adapter generation

**No error boundaries:**
- Issue: Most screens lack top-level error handling, relying on scattered try-catch blocks
- Files: `lib/screens/reflection_screen.dart:42-44`, `lib/screens/confirmation_screen.dart:143-149`, `lib/screens/onboarding/first_checkin_screen.dart:166`
- Impact: Crashes can propagate to widget tree, poor user experience when services fail
- Fix approach: Implement error boundary widgets or global error handling, add FutureBuilder/StreamBuilder error states

**Service initialization fragility:**
- Issue: Services throw StateError if not initialized, but no guards prevent UI from accessing uninitialized services
- Files: `lib/services/storage_service.dart:104,112`, `lib/services/direction_service.dart:42,50`, `lib/services/reflection_service.dart:458,466`
- Impact: Hot reload breaks initialization state, requires full app restart
- Fix approach: Add service ready state checks in main.dart, show loading screen until all services initialized, or use lazy initialization pattern

## Known Bugs

**iOS physical device crash (RESOLVED):**
- Symptoms: App crashes on launch with SIGSEGV(11) during Flutter scene creation
- Files: `IOS_CRASH_FIX.md` documents issue and resolution
- Trigger: Stale build artifacts from incremental builds
- Workaround: Clean rebuild (`flutter clean`, remove Pods, rebuild)
- **Status:** Documented with fix script available, diagnostic logging added to `ios/Runner/AppDelegate.swift`

**Test file references non-existent MyApp class:**
- Issue: `test/widget_test.dart` references `MyApp` class but main.dart exports `ElioApp`
- Files: `test/widget_test.dart:16`, `lib/main.dart:20`
- Trigger: Template test file not updated after app rename
- Workaround: Tests not critical for current development
- Fix approach: Rewrite test to use `ElioApp` or remove template test

**withOpacity deprecation warnings:**
- Issue: Widespread use of `.withOpacity()` method throughout UI code
- Files: 28 files (all screen and widget files - see `lib/screens/*.dart`, `lib/widgets/*.dart`, `lib/theme/*.dart`)
- Trigger: Compile time warnings in Flutter SDK
- Impact: Cosmetic only, no runtime issues, but clutters build output
- Fix approach: Migrate to `Color.withValues(alpha: x)` pattern or suppress warnings until Flutter LTS

## Security Considerations

**No data encryption:**
- Risk: Hive database stored unencrypted on device storage
- Files: All Hive box initialization in `lib/services/*.dart`
- Current mitigation: iOS/Android sandbox protections only
- Recommendations: Add Hive encryption for sensitive mood/reflection data, especially before adding cloud sync

**No input sanitization:**
- Risk: User input (intentions, custom questions, direction titles) stored without validation
- Files: `lib/services/storage_service.dart:35-56`, `lib/services/reflection_service.dart`, `lib/services/direction_service.dart:91-110`
- Current mitigation: Character limits enforced (100 chars intentions, 50 chars direction titles, 200 chars reflections)
- Recommendations: Add HTML/script sanitization if data ever displayed in webviews, validate UTF-8 encoding

**Service singletons accessible globally:**
- Risk: Any code can access and modify data without authorization checks
- Files: `StorageService.instance`, `ReflectionService.instance`, `DirectionService.instance`, `NotificationService.instance`
- Current mitigation: Single-user app, no multi-user access
- Recommendations: If adding user accounts or export features, implement access control layer

## Performance Bottlenecks

**getAllEntries() called frequently:**
- Problem: Loads and sorts entire entry list on every insights screen build
- Files: `lib/screens/insights_screen.dart:36-41`, `lib/services/insights_service.dart` (multiple calls)
- Cause: No caching, FutureBuilder rebuilds on every navigation
- Improvement path: Add in-memory cache with invalidation, use Stream for entry updates, lazy load insights data

**Streak calculation on every entry save:**
- Problem: `getCurrentStreak()` iterates all entries on each save operation
- Files: `lib/services/storage_service.dart:52-53`, `lib/services/storage_service.dart:77-95`
- Cause: No cached streak value, recalculates from scratch
- Improvement path: Cache current streak, update incrementally on new entries

**Direction correlation analysis is O(n*m):**
- Problem: `getDirectionsWithMoodCorrelation()` calculates average mood for each direction separately
- Files: `lib/services/direction_service.dart:380-394`
- Cause: Nested loops through directions and entries
- Improvement path: Single pass through entries, build correlation map in one iteration

**Daily averages calculated multiple times:**
- Problem: Insights service recalculates daily patterns for same period on each render
- Files: `lib/services/insights_service.dart:405-426` (`_dailyAverages` called by multiple functions)
- Cause: Pure functions with no memoization
- Improvement path: Cache period calculations, only invalidate when entries change

## Fragile Areas

**Mood entry flow state management:**
- Files: `lib/screens/mood_entry_screen.dart`, `lib/screens/intention_screen.dart`, `lib/screens/reflection_screen.dart`, `lib/screens/confirmation_screen.dart`
- Why fragile: Flow passes moodValue/moodWord/intention through 4 screen constructors, easy to pass wrong values
- Test coverage: None
- Safe modification: Always trace data flow from mood_entry → intention → reflection → confirmation. Add integration test for full flow.

**Hive TypeId management:**
- Files: `lib/models/*.dart` (TypeIds: 0=Entry, 1=ReflectionQuestion, 2=ReflectionAnswer, 4=DirectionType, 5=Direction, 6=DirectionConnection)
- Why fragile: TypeId 3 reserved but unused, manual tracking in comments, no compile-time validation
- Test coverage: None
- Safe modification: Never reuse or change TypeIds. Add new models with TypeIds 7+. Document in CLAUDE.md before adding.

**Reflection question rotation logic:**
- Files: `lib/services/reflection_service.dart:313-335` (getNextQuestion method)
- Why fragile: Rotation based on `dayOfYear % rotatingQuestions.length`, breaks if pool changes mid-day
- Test coverage: None
- Safe modification: Don't modify rotation algorithm without testing multi-day consistency. Consider seeded random instead.

**InsightsData class with 22 fields:**
- Files: `lib/services/insights_service.dart:15-90` (InsightsData class)
- Why fragile: Large number of required named parameters, easy to miss fields when constructing
- Test coverage: None
- Safe modification: Use copyWith pattern when modifying. Consider splitting into smaller data classes (MoodStats, StreakStats, PatternStats).

## Scaling Limits

**Hive box loading all entries into memory:**
- Current capacity: ~1000 entries performs acceptably
- Limit: 10,000+ entries will cause noticeable lag on app startup and insights calculation
- Scaling path: Implement pagination, lazy-load boxes, archive old entries, or migrate to SQLite with indexed queries

**Insights calculations block UI thread:**
- Current capacity: Week/month calculations acceptable with ~100 entries
- Limit: Synchronous calculations will cause jank with 500+ entries
- Scaling path: Move calculations to isolates, use compute() for heavy analytics, implement progress indicators

**No data archiving:**
- Current capacity: Indefinite entry storage
- Limit: Multi-year usage will accumulate thousands of entries
- Scaling path: Add archive/export feature, auto-archive entries older than 1 year, implement data retention policy

## Dependencies at Risk

**flutter_local_notifications v17.1.2:**
- Risk: Notification service initialized but not used (future feature)
- Impact: Dead dependency increasing bundle size
- Migration plan: Remove dependency until notification feature implemented, or implement basic reminders

**hive v2.2.3 (NoSQL local storage):**
- Risk: Hive is no longer actively maintained (last update 2023)
- Impact: Security patches, Flutter SDK compatibility issues in future
- Migration plan: Monitor for Isar (successor) maturity, plan migration to SQLite + drift for long-term support

## Missing Critical Features

**No data backup/export:**
- Problem: Users cannot export or backup their mood data
- Blocks: User trust, data portability, GDPR compliance
- Priority: High - critical for user trust

**No entry editing:**
- Problem: Users cannot fix mistakes in mood entries or reflections
- Blocks: User satisfaction, data accuracy
- Priority: Medium - listed in CLAUDE.md future enhancements

**No delete functionality:**
- Problem: Users cannot remove unwanted entries
- Blocks: Privacy control, data hygiene
- Priority: Medium - privacy concern

**No error recovery:**
- Problem: Failed entry saves are silently lost (confirmation screen catches but doesn't retry)
- Blocks: Data integrity
- Priority: Medium - add save retry or queue mechanism

## Test Coverage Gaps

**No service integration tests:**
- What's not tested: StorageService, ReflectionService, DirectionService, InsightsService
- Files: All `lib/services/*.dart`
- Risk: Breaking changes in Hive, UUID, or service logic go undetected
- Priority: High

**No onboarding flow tests:**
- What's not tested: Complete onboarding sequence, state transitions
- Files: `lib/screens/onboarding/*.dart`, `lib/main.dart:35-63`
- Risk: Onboarding breaks could block all new users
- Priority: High

**No insights calculation tests:**
- What's not tested: Mood averages, trend detection, day patterns, correlation logic
- Files: `lib/services/insights_service.dart` (all calculation methods)
- Risk: Math errors, edge cases (empty data, single entry, etc.) not validated
- Priority: Medium

**No widget tests:**
- What's not tested: Any UI components, user interactions, navigation flows
- Files: All `lib/screens/*.dart`, `lib/widgets/*.dart`
- Risk: UI regressions, broken navigation, accessibility issues
- Priority: Medium

**No direction feature tests:**
- What's not tested: Direction CRUD, connections, mood correlation calculations
- Files: `lib/services/direction_service.dart`, `lib/screens/*direction*.dart`
- Risk: New feature (v1.1.0) completely untested, correlation math unvalidated
- Priority: Medium

---

*Concerns audit: 2026-02-26*
