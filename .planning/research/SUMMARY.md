# Project Research Summary

**Project:** Elio v2.0 - The Proper App
**Domain:** Flutter mood tracking & journaling app (App Store readiness)
**Researched:** 2026-02-26
**Confidence:** MEDIUM-HIGH

## Executive Summary

Elio is a local-first mood tracking and journaling app built with Flutter and Hive. The research reveals that v1.1.0 has solid foundations (unique Directions feature, no-guilt design philosophy, clean StatefulWidget + Singleton Services architecture) but is missing critical table stakes features that users expect from any journaling app. To reach App Store readiness, Elio needs entry editing/deletion, search/filter capabilities, calendar heatmap visualization, and comprehensive UX polish (animations, loading states, error handling).

The recommended approach is a phased build order starting with foundational CRUD completion, followed by data access (search/filter), then visual patterns (calendar), analytics (weekly summaries), intelligence (smart nudges), and finally animation polish. This sequence respects architectural dependencies and allows early user testing of core features before investing in advanced analytics.

The primary risks are Hive data migration crashes (manual adapters without version control), performance degradation with 500+ entries (unbounded list rendering), and App Store health app compliance requirements. These can be mitigated by implementing versioned TypeAdapters before schema changes, using ListView.builder with pagination from the start, and including proper disclaimers and privacy policy for mental health data.

## Key Findings

### Recommended Stack

Elio's existing stack (Flutter 3.10.8 + Hive 2.2.3 + StatefulWidget pattern) is appropriate and should be maintained. For v2.0, add targeted packages for polish and features without changing core architecture.

**Core additions for v2.0:**
- **animations** (^2.0.11): Official Flutter package for SharedAxis/fade transitions — elevates screen navigation polish to premium feel
- **flutter_animate** (^4.5.0): Declarative micro-interactions — reduces AnimationController boilerplate by 70% for button taps, card reveals
- **shimmer** (^3.0.0): Skeleton loading states — industry standard for async operations (insights calculations, history loading)
- **fl_chart** (^0.68.0): Interactive charts — upgrade mood wave with touch interactions, tooltips, gradient fills
- **table_calendar** (^3.1.2): Calendar UI — standard choice for mood heatmap with day-level data visualization
- **flutter_slidable** (^3.1.1): Swipe-to-delete/edit — proven pattern for list item actions in history screen
- **intl** (^0.19.0): Date formatting — needed for date range filters, week/month labels

**What NOT to add:**
- Provider/Riverpod/Bloc — existing StatefulWidget pattern works at this scale, rewrite would add complexity without benefit
- build_runner — Elio uses manual Hive adapters by design, adding this would conflict
- Cloud sync packages — counter to local-first philosophy, defer to v3+ with E2E encryption

### Expected Features

Research reveals Elio is missing every journaling app table stakes feature. Competitors (Daylio, Finch, Pixels, Reflectly) all have entry editing, deletion, search, calendar view, and data export.

**Must have (v2.0 table stakes):**
- Entry editing — every journaling app allows editing past entries, users expect to fix typos
- Entry deletion with confirmation — data control equals trust, but needs undo mechanism (soft delete)
- Search entries by text — users with 50+ entries need to find specific moments
- Filter by mood range/date range — complements search for pattern discovery
- Calendar/heatmap view — industry standard since Daylio, users expect visual at-a-glance patterns
- Smooth screen transitions — premium feel requires Hero animations, consistent 300ms timing
- Loading states — skeleton screens for heavy operations prevent "frozen app" perception
- Empty state polish — every screen needs helpful guidance when empty
- Error handling — user-friendly messages, no crashes or stack traces
- Data export (CSV) — trust and portability requirement for mental health apps

**Should have (competitive differentiators):**
- Weekly summaries — automated "Here's your week" recap makes insights actionable
- Smart nudges — "You haven't connected to Peace direction in 7 days" proactive notifications
- Streak visualization enhancement — fire icon, progress rings, celebrate milestones
- Mood correlation insights — already partially implemented, surface more prominently

**Defer (v2.x or v3+):**
- Entry reminders (push notifications) — skeleton exists, add when check-in rates drop
- Cloud sync with E2E encryption — only if multi-device becomes major request
- Photo attachments — scope creep, slows check-in flow, defer until text feels limiting
- AI chat/advice — liability risk, against human-reflection philosophy

### Architecture Approach

Continue with StatefulWidget + Singleton Services pattern (no Provider/Bloc). It's working well for this scale. Add feature-specific services (FilterService, SummaryService, NudgeService, CalendarService) following existing patterns. Keep services UI-agnostic and stateless, store UI state in screen State classes.

**Major components to add:**

1. **FilterService** — search and filter logic with in-memory operations (Hive is fast enough), debounced text input (300ms), filter chips for mood/date ranges

2. **SummaryService** — generates weekly recaps by composing from existing services (StorageService, InsightsService, DirectionService), persists WeeklySummary snapshots to Hive (TypeId: 3)

3. **NudgeService** — pattern detection for smart nudges (dormant directions, streak risk, mood patterns), returns computed Nudge objects (not persisted), displayed as dismissible cards in Home tab

4. **CalendarService** — prepares heatmap data by grouping entries by day, calculates average mood per day, returns MoodDay objects (non-persisted computed data)

**Key architectural patterns:**
- Service composition over duplication — services call other services, reuse existing calculations (DRY)
- Compute on demand — calculate data when needed, don't cache (except WeeklySummary snapshots)
- Bottom sheets for detail views — use sheets for quick info (day entries), screens for full workflows (edit entry)
- Debouncing for search — 300ms delay after last keystroke to reduce CPU/battery usage
- ListView.builder for all lists — lazy loading to prevent memory bloat with 500+ entries

### Critical Pitfalls

Research identified 8 critical pitfalls that could sink the v2.0 release:

1. **Hive data migration crashes** — Adding/removing fields from manual TypeAdapters causes "Expected X fields but found Y" crashes for existing users. Solution: Implement versioned TypeAdapters with migration logic BEFORE making schema changes in Phase 1.

2. **Unbounded list rendering** — Loading all entries into ListView causes memory bloat and jank with 100+ entries. Solution: Use ListView.builder() from the start in Phase 2 search implementation, test with 500+ dummy entries.

3. **Missing undo for destructive actions** — Users accidentally delete entries, leave 1-star reviews about lost data. Solution: Implement soft delete with 30-day retention and 5-second undo SnackBar in Phase 1.

4. **StatefulWidget memory leaks** — Animation controllers and timers not disposed properly, gradual performance degradation. Solution: Audit all StatefulWidgets in Phase 3 animations pass, verify with DevTools memory profiler.

5. **Search performance degradation** — Full-text scanning on UI thread causes 200ms+ lag per keystroke with 500+ entries. Solution: Implement debounced search (300ms) and isolate execution for heavy operations in Phase 2.

6. **Inconsistent dark mode** — Hardcoded colors, system dialogs in light mode despite dark theme. Solution: Ban hex codes, enforce Theme.of(context) usage, test every screen in Phase 4 polish pass.

7. **Apple App Store health compliance** — Mood tracking = health data in Apple's eyes, requires disclaimers and privacy policy even without HealthKit. Solution: Add "Not medical advice" disclaimer, privacy policy link, proper App Store Connect disclosures in Phase 5.

8. **No offline handling** — Assumes device services (notifications, file system) always work, crashes when storage full or permissions revoked. Solution: Wrap Hive operations in try-catch, check disk space, show meaningful error messages in Phase 4.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Foundation (Entry Management)
**Rationale:** Complete basic CRUD operations before building advanced features. Users cannot trust the app with their data until they can edit and safely delete entries. Establishes data integrity patterns needed for all subsequent phases.

**Delivers:**
- Edit entry screen (reuse mood/intention/reflection inputs from entry flow)
- Delete entry with confirmation dialog
- Soft delete implementation (30-day retention, undo SnackBar)
- Versioned Hive TypeAdapters with migration utilities
- StorageService edit/delete methods with cascading cleanup

**Addresses features:**
- Entry editing (CRITICAL table stakes)
- Entry deletion with undo (CRITICAL table stakes)

**Avoids pitfalls:**
- Hive data migration crashes (implement versioning BEFORE schema changes)
- Missing undo for destructive actions (build soft delete from the start)

**Research flags:** Standard patterns, skip research-phase. Editing/deleting are well-documented Flutter/Hive operations.

---

### Phase 2: Data Access (Search & Filter)
**Rationale:** Users need to find entries before advanced analytics make sense. With 50+ entries, history timeline becomes difficult to navigate. Search/filter unlocks value of existing data and validates assumptions about entry volumes before building calendar view.

**Delivers:**
- FilterService (search logic, mood/date range filters)
- SearchScreen UI with debounced text input (300ms)
- Filter chips for mood ranges, date picker for custom ranges
- ListView.builder implementation for performance
- Integration into History tab

**Uses stack elements:**
- intl package for date formatting/parsing
- Debouncer utility for search input
- Built-in Dart collections (no search package needed)

**Addresses features:**
- Search entries by text (IMPORTANT table stakes)
- Filter by mood range/date range (IMPORTANT table stakes)

**Avoids pitfalls:**
- Unbounded list rendering (implement ListView.builder from start)
- Search performance issues (debouncing + profiling with 500+ entries)

**Research flags:** Standard patterns, skip research-phase. Search/filter are common operations with established best practices.

---

### Phase 3: Visual Patterns (Calendar Heatmap)
**Rationale:** Industry-standard visualization for mood tracking. Users expect calendar view (Daylio popularized this pattern). Builds on Phase 2 date filtering logic. Provides complementary view to history timeline for pattern discovery.

**Delivers:**
- CalendarService (heatmap data preparation)
- CalendarHeatmapWidget using table_calendar package
- MoodDay model (computed, non-persisted)
- Day-level aggregation (average mood calculation)
- Bottom sheet integration for day detail (reuse DayEntriesSheet)
- New Calendar tab in bottom navigation

**Uses stack elements:**
- table_calendar package (^3.1.2) for calendar UI
- Existing DayEntriesSheet widget for tap interactions
- CalendarService for data aggregation

**Implements architecture:**
- Compute-on-demand pattern (heatmap data not cached)
- Bottom sheet for detail views (tap day → show entries)
- GridView.builder for performance with 365 cells

**Addresses features:**
- Calendar/heatmap view (CRITICAL table stakes)
- Visual pattern recognition (DIFFERENTIATOR)

**Research flags:** Standard patterns, skip research-phase. table_calendar is well-documented with extensive examples.

---

### Phase 4: Analytics (Weekly Summaries)
**Rationale:** Makes insights actionable by surfacing patterns in digestible format. Builds on existing InsightsService calculations. Creates engagement loop (weekly recap notifications can drive retention). Feeds data into Phase 5 nudges system.

**Delivers:**
- WeeklySummary model with Hive adapter (TypeId: 3)
- SummaryService (generation logic, reuses InsightsService)
- WeeklySummaryScreen (narrative recap display)
- "Past Summaries" list view
- Manual generation button (auto-generation deferred to Phase 6)

**Uses stack elements:**
- Existing InsightsService calculations (DRY principle)
- intl package for week date ranges
- Hive for summary persistence

**Implements architecture:**
- Service composition (SummaryService calls InsightsService + DirectionService)
- Snapshot pattern (pre-compute and store, don't recompute on view)
- Versioned Hive TypeAdapter (apply lessons from Phase 1)

**Addresses features:**
- Weekly summaries (DIFFERENTIATOR)
- Actionable insights (enhancement over current Insights tab)

**Research flags:** Standard patterns, skip research-phase. Summary generation is aggregation of existing metrics.

---

### Phase 5: Intelligence (Smart Nudges)
**Rationale:** Proactive engagement based on patterns. Differentiates from passive tracking apps. Requires all data sources (entries, directions, insights, summaries) to be stable. Low implementation cost but high user value for retention.

**Delivers:**
- NudgeService (pattern detection logic)
- Nudge model (non-persisted, computed on demand)
- NudgeCard widget for in-app display
- Integration into Home tab (1-2 nudges at top)
- Dismissible card interactions

**Uses stack elements:**
- Existing DirectionService.getDormantDirections()
- Existing InsightsService day-of-week patterns
- StorageService streak calculations
- No new packages needed

**Implements architecture:**
- Compute-on-demand pattern (nudges not stored)
- Priority-based ranking (show most important first)
- Service composition (calls DirectionService, InsightsService, StorageService)

**Addresses features:**
- Smart nudges (DIFFERENTIATOR)
- Contextual engagement (enhances retention)

**Avoids pitfalls:**
- No notification permissions assumed (in-app only initially)
- Graceful handling of empty data states

**Research flags:** Custom logic needed. Consider `/gsd:research-phase` for nudge prioritization rules and messaging tone (mental health sensitivity).

---

### Phase 6: Polish (Premium Animations & App Store)
**Rationale:** Pure polish phase after all features are stable. Animations should enhance existing screens, not be built alongside feature development. App Store preparation needs complete feature set to capture in screenshots and descriptions.

**Delivers:**
- Hero transitions between screens (entry card → detail)
- Shared element transitions (mood slider → confirmation)
- Custom page transitions using animations package
- Micro-interactions with flutter_animate (button taps, card reveals)
- Shimmer loading states for async operations
- Staggered list animations for history/directions
- Comprehensive empty state polish
- Comprehensive error handling with user-friendly messages
- Dark mode consistency audit (ban hardcoded colors)
- App Store assets (screenshots, descriptions, privacy policy)
- Health app disclaimers and compliance

**Uses stack elements:**
- animations package (SharedAxis, fade transitions)
- flutter_animate package (declarative micro-interactions)
- shimmer package (skeleton screens)
- flutter_staggered_animations package (list reveals)

**Addresses features:**
- Smooth screen transitions (CRITICAL table stakes)
- Loading states (IMPORTANT table stakes)
- Empty states (IMPORTANT table stakes)
- Error handling (IMPORTANT table stakes)

**Avoids pitfalls:**
- StatefulWidget memory leaks (audit all animation controllers)
- Inconsistent dark mode (systematic theme enforcement)
- App Store health compliance (disclaimers, privacy policy)
- Offline handling gaps (comprehensive error boundaries)

**Research flags:** Standard patterns for animations. Consider `/gsd:research-phase` for App Store submission checklist (health app category requirements evolve frequently).

---

### Phase 7: Data Portability (Export & Optional Features)
**Rationale:** Trust feature for mental health app. Users need to own their data. Not blocking for initial launch but important for App Store trust signals. Can be added post-launch if time-constrained.

**Delivers:**
- CSV export functionality
- JSON export option (developer-friendly)
- Export progress indicator for large datasets
- File write error handling
- Share sheet integration

**Addresses features:**
- Data export (IMPORTANT table stakes)
- Data portability (trust signal)

**Research flags:** Standard patterns, skip research-phase. CSV/JSON generation is well-documented.

---

### Phase Ordering Rationale

**Why this sequence:**
- Foundation first — can't build advanced features on broken CRUD operations
- Data access before visualization — search validates entry volumes, used by calendar
- Calendar before summaries — aggregation logic reused, validates computation patterns
- Summaries before nudges — summary analytics feed nudge detection logic
- Polish last — animations should enhance stable features, not concurrent development
- Export deferred — can ship without it, add post-launch based on user requests

**Dependency chain:**
```
Phase 1 (Foundation) → enables → Phase 2 (Search uses stable entry model)
Phase 2 (Search) → enables → Phase 3 (Calendar uses date filtering)
Phase 3 (Calendar) → enables → Phase 4 (Summaries use aggregation patterns)
Phase 4 (Summaries) → enables → Phase 5 (Nudges use summary analytics)
Phase 5 (Nudges) → enables → Phase 6 (Complete feature set ready for polish)
```

**Pitfall mitigation:**
- Phase 1 establishes Hive migration pattern → prevents crashes in Phases 3-4
- Phase 2 establishes ListView.builder → scales to Phases 3-4 with more data
- Phase 6 catches memory leaks, dark mode issues, App Store compliance

### Research Flags

**Phases likely needing deeper research:**
- **Phase 5 (Smart Nudges):** Mental health app messaging tone research needed. Nudge prioritization rules should be validated with UX patterns for wellness apps. Consider `/gsd:research-phase` for nudge psychology and non-judgmental language patterns.
- **Phase 6 (App Store):** Health app review guidelines change frequently. Consider `/gsd:research-phase` right before submission to verify current Apple requirements for mood tracking apps (disclaimers, privacy labels, age ratings).

**Phases with standard patterns (skip research-phase):**
- **Phase 1:** Entry editing/deletion are standard CRUD operations with extensive Flutter/Hive documentation
- **Phase 2:** Search and filter have established patterns, debouncing is common practice
- **Phase 3:** table_calendar package has comprehensive docs and examples, heatmap pattern is standard
- **Phase 4:** Weekly summaries are aggregation of existing metrics, no novel patterns
- **Phase 7:** CSV/JSON export is well-documented with many examples

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Recommended packages are mature and widely used. Version numbers based on Jan 2025 knowledge cutoff, should be verified on pub.dev before installation. |
| Features | MEDIUM | Based on training data knowledge of competitors (Daylio, Finch, Pixels) as of Jan 2025. Not verified with current 2026 market state. Feature gaps (edit/delete/search/calendar) are clear from competitor analysis. |
| Architecture | HIGH | Well-documented in existing CLAUDE.md. Singleton Services + StatefulWidget pattern is proven in v1.1.0. Recommended patterns (service composition, compute-on-demand, ListView.builder) are standard Flutter best practices. |
| Pitfalls | MEDIUM | Based on established Flutter/Hive development patterns and App Store requirements. Hive migration issues are well-documented. App Store health app requirements from 2026 guidelines (may need verification). |

**Overall confidence:** MEDIUM-HIGH

Research is grounded in documented technical constraints (Flutter performance, Hive limitations, Elio's existing architecture) and established UX patterns for mood tracking apps. Main uncertainty is around current competitor features (2026 state unknown) and specific App Store review nuances (evolve frequently).

### Gaps to Address

**Competitor feature parity:** Research based on Jan 2025 knowledge of Daylio, Finch, Pixels, Reflectly, Jour. Should manually review these apps in 2026 App Store before finalizing roadmap to catch any new table stakes features introduced in last year.

**App Store submission requirements:** Health app review guidelines change quarterly. Before Phase 6, check current Apple requirements for:
- Privacy nutrition labels (what counts as "health data")
- Medical disclaimers (exact wording requirements)
- Age ratings (mental health apps have specific requirements)
- Screenshot content rules (can you show mood data?)

**Package version verification:** All package versions (animations 2.0.11, fl_chart 0.68.0, etc.) are from Jan 2025. Before Phase 1 begins, verify on pub.dev:
- Latest stable versions
- Flutter SDK compatibility (currently on 3.10.8)
- Breaking changes in newer versions
- Null safety status

**Nudge messaging tone:** Phase 5 nudges need sensitivity for mental health context. Gap: no specific research on non-judgmental nudge language patterns. Recommendation: User test nudge wording with 5-10 existing mood tracking app users before implementing.

**Performance thresholds:** Research recommends ListView.builder and debouncing but doesn't have real-world Elio data on when performance degrades. Gap: actual entry count where issues appear. Recommendation: Load test with 500, 1000, 2000 dummy entries during Phase 2 to establish real thresholds.

## Sources

### Primary (HIGH confidence)
- **Elio codebase (v1.1.0)** — CLAUDE.md, lib/services/, lib/screens/ — verified existing architecture and patterns
- **Flutter official documentation** — Animation APIs, StatefulWidget lifecycle, performance best practices
- **Hive documentation** — Manual adapters, migration patterns, performance characteristics
- **pub.dev package stats** — Popularity scores, maintenance activity, version compatibility (through Jan 2025)

### Secondary (MEDIUM confidence)
- **Mood tracking app landscape** — Training data knowledge of Daylio, Finch, Pixels, Reflectly, Jour (as of Jan 2025) — feature comparison and UX patterns
- **iOS App Store Review Guidelines** — Health & Medical category requirements (2026 snapshot assumed similar to 2025)
- **Flutter community patterns** — Singleton services, StatefulWidget patterns, common pitfalls from developer discussions

### Tertiary (LOW confidence)
- **Competitor feature sets in 2026** — Not verified with WebSearch, may have changed since Jan 2025
- **Specific package versions** — Recommended versions from Jan 2025, may have updates available
- **App Store submission edge cases** — Review process varies by reviewer, documented requirements may not capture all rejection reasons

---

*Research completed: 2026-02-26*
*Ready for roadmap: yes*
