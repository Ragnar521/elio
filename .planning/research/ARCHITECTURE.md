# Architecture Research

**Domain:** Mood tracking & journaling mobile app (Flutter)
**Researched:** 2026-02-26
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Screens  │  │ Widgets  │  │ Dialogs  │  │ Sheets   │    │
│  │(Stateful)│  │(Reusable)│  │(Modals)  │  │(Bottom)  │    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘    │
│       │             │             │             │           │
├───────┴─────────────┴─────────────┴─────────────┴───────────┤
│                    BUSINESS LOGIC LAYER                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │        Singleton Services (No Provider/Bloc)        │    │
│  ├───────────┬────────────┬────────────┬───────────────┤    │
│  │ Storage   │Reflection  │ Direction  │   Insights    │    │
│  │ Service   │ Service    │ Service    │   Service     │    │
│  │           │            │            │               │    │
│  │ • CRUD    │• Questions │• CRUD      │• Analytics    │    │
│  │ • Settings│• Rotation  │• Links     │• Patterns     │    │
│  │ • Streaks │• Answers   │• Stats     │• Correlation  │    │
│  └───────────┴────────────┴────────────┴───────────────┘    │
│       │             │             │             │           │
├───────┴─────────────┴─────────────┴─────────────┴───────────┤
│                    DATA PERSISTENCE LAYER                    │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Hive (NoSQL, Local-Only)                │   │
│  ├──────────┬──────────┬──────────┬──────────┬──────────┤   │
│  │ Entries  │Reflection│Reflection│Directions│Direction │   │
│  │   Box    │Questions │ Answers  │   Box    │Connections│   │
│  │          │   Box    │   Box    │          │   Box    │   │
│  │ TypeId:0 │ TypeId:1 │ TypeId:2 │ TypeId:5 │ TypeId:6 │   │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Settings Box (Key-Value, Dynamic)            │   │
│  │   user_name | onboarding | notifications | etc.     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Communicates With |
|-----------|----------------|-------------------|
| **Screens** | UI layout, user interactions, state management via setState | Services (direct instance access) |
| **Widgets** | Reusable UI components, isolated logic, parameter-driven | Parent screens (props), minimal service access |
| **Services** | Business logic, data operations, calculations | Hive boxes (direct access), other services |
| **Hive Boxes** | Data persistence, type-safe storage | Services only (screens never access directly) |
| **Models** | Data structures with Hive adapters | Services and screens for data transfer |

### Existing Architecture Pattern

Elio uses a **StatefulWidget + Singleton Service** pattern:
- **No Provider/Bloc/Riverpod** — simplicity over abstraction
- **Direct service access** — `ServiceName.instance.method()`
- **Manual state management** — `setState()` in screens
- **Synchronous reads** — Hive boxes loaded in-memory
- **Async writes** — Futures for save operations

**Why this works for Elio:**
- Small-to-medium app scale (5 services, ~15 screens)
- Local-only data (no network sync complexity)
- Fast reads (Hive is in-memory)
- Simple testing (services are mockable singletons)

## Advanced Features Integration

### 1. Search & Filter System

**Component Boundary:**
```
SearchBar Widget
    ↓ (query changes)
FilterService (NEW)
    ↓ (filters entries)
StorageService.getAllEntries()
    ↓ (raw data)
FilteredResults → ListView
```

**Recommended Implementation:**
- **NEW: FilterService** — singleton for search/filter logic
  - `searchEntries(String query)` — search intention + reflection text
  - `filterByMoodRange(double min, double max)` — mood value filtering
  - `filterByDateRange(DateTime start, DateTime end)` — date filtering
  - `filterByDirection(String directionId)` — direction filtering
  - `applyMultipleFilters(FilterCriteria)` — combine filters

- **UI Pattern:** Debounced text input + filter chips
  - Use `StreamController<String>` for search input debouncing (300ms)
  - Filter chips for mood ranges (Low/Mid/High)
  - Date picker for custom ranges

**Data Flow:**
```
User types "work" → (debounce 300ms) → FilterService.searchEntries("work")
    ↓
StorageService.getAllEntries() → Filter in-memory → Return matches
    ↓
Screen updates ListView (setState) → Show results
```

**Key Pattern:** Keep filtering in-memory (Hive is fast, no need for database queries)

---

### 2. Weekly Summary System

**Component Boundary:**
```
SummaryService (NEW)
    ↓ (aggregates week data)
StorageService + InsightsService + DirectionService
    ↓ (raw metrics)
WeeklySummaryScreen (NEW)
    ↓ (displays recap)
WeeklySummaryCard Widget (NEW)
```

**Recommended Implementation:**
- **NEW: SummaryService** — generates weekly recaps
  - `getWeeklySummary(DateTime weekStart)` → `WeeklySummary` model
  - `getAllSummaries()` — list of past summaries
  - `generateSummaryForLastWeek()` — called on demand or scheduled

- **WeeklySummary Model (TypeId: 3)** — Hive-persisted
  ```dart
  WeeklySummary {
    id: String (UUID)
    weekStart: DateTime
    weekEnd: DateTime
    checkInCount: int
    avgMood: double
    topDirection: String? (direction ID)
    keyInsight: String (generated text)
    moodTrend: String ("up", "down", "stable")
    highlightEntry: String? (entry ID for standout moment)
    createdAt: DateTime
  }
  ```

- **Generation Strategy:**
  - Triggered manually (button in Insights tab)
  - OR auto-generate Monday morning (via NotificationService)
  - Reuse InsightsService calculations (DRY principle)

**Data Flow:**
```
User taps "See Weekly Recap" → SummaryService.getWeeklySummary(lastWeek)
    ↓
Fetch entries for week → Calculate with InsightsService logic
    ↓
Format as narrative ("This week you checked in 5 times...")
    ↓
Save WeeklySummary to Hive → Display in card format
```

**Key Pattern:** Summaries are snapshots — pre-calculate and store, don't recompute on view

---

### 3. Smart Nudges System

**Component Boundary:**
```
NudgeService (NEW)
    ↓ (analyzes patterns)
DirectionService + InsightsService + StorageService
    ↓ (data sources)
NotificationService (existing, enhanced)
    ↓ (schedules notifications)
NudgeCard Widget (NEW)
    ↓ (in-app display)
```

**Recommended Implementation:**
- **NEW: NudgeService** — detects patterns & generates nudges
  - `getDormantDirectionNudges()` — directions with 0 connections in 7+ days
  - `getMoodPatternNudges()` — "Your Mondays are tough" type insights
  - `getStreakRiskNudge()` — "Don't break your 8-day streak!"
  - `getReflectionNudge()` — "You haven't reflected in 3 days"
  - `getAllActiveNudges()` — returns list of `Nudge` objects

- **Nudge Model (non-persisted, computed on-demand)**
  ```dart
  Nudge {
    id: String
    type: NudgeType (streak, dormantDirection, moodPattern, reflection)
    priority: int (1-3, 1 = highest)
    title: String
    description: String
    actionLabel: String? ("Check in now", "View pattern")
    actionRoute: String? (screen to navigate to)
    dismissible: bool
    createdAt: DateTime
  }
  ```

- **Display Strategy:**
  - In-app: Show 1-2 nudges at top of Home tab (dismissible cards)
  - Notifications: Optional push via NotificationService (defer to future)

**Data Flow:**
```
Home screen loads → NudgeService.getAllActiveNudges()
    ↓
Check dormant directions (DirectionService.getDormantDirections())
Check streak (StorageService.getCurrentStreak() + days since last entry)
Check mood patterns (InsightsService day-of-week data)
    ↓
Generate 1-3 nudges with priority ranking → Return sorted list
    ↓
Home screen displays top 2 as dismissible cards
```

**Key Pattern:** Nudges are ephemeral — computed on demand, not stored (reduces data complexity)

---

### 4. Visual Patterns (Heatmap/Calendar View)

**Component Boundary:**
```
CalendarHeatmapWidget (NEW)
    ↓ (renders grid)
CalendarService (NEW)
    ↓ (prepares data)
StorageService.getAllEntries()
    ↓ (raw entries)
```

**Recommended Implementation:**
- **NEW: CalendarService** — prepares calendar data
  - `getMonthHeatmapData(DateTime month)` → `Map<DateTime, MoodDay>`
  - `getYearOverview()` → annual heatmap data
  - Helper: `_groupEntriesByDay(List<Entry>)` → aggregates

- **MoodDay Model (non-persisted, computed)**
  ```dart
  MoodDay {
    date: DateTime
    avgMood: double (0.0-1.0)
    entryCount: int
    color: Color (computed from avgMood)
  }
  ```

- **UI Pattern:**
  - Grid of 30-31 days (month view) or 365 days (year view)
  - Each cell colored by avgMood (gradient from low → high)
  - Tap cell → show day's entries in bottom sheet
  - Reuse existing `DayEntriesSheet` widget

**Data Flow:**
```
User navigates to Calendar tab (NEW) → CalendarService.getMonthHeatmapData(currentMonth)
    ↓
StorageService.getAllEntries() → Filter to month → Group by day
    ↓
Calculate avg mood per day → Map to color gradient
    ↓
CalendarHeatmapWidget renders grid → User taps cell
    ↓
Show DayEntriesSheet with filtered entries
```

**Key Pattern:** Use Flutter's `GridView.builder` for performance with large datasets (365 cells)

---

### 5. Premium Animations System

**Component Boundary:**
```
AnimationService (NEW, lightweight)
    ↓ (provides presets)
Screens/Widgets
    ↓ (use Animation/AnimatedWidget)
Built-in Flutter Animation APIs
```

**Recommended Implementation:**
- **NEW: AnimationService** (optional, for consistency)
  - Static constants for durations/curves
  - Helper methods for common patterns
  - Example: `AnimationService.standardDuration` (300ms)

- **Animation Patterns to Add:**
  1. **Hero Transitions** — entry cards → entry detail
  2. **Shared Element** — mood slider → confirmation screen
  3. **Page Transitions** — custom slide/fade between screens
  4. **Micro-interactions** — button press, card tap, swipe feedback
  5. **Loading States** — shimmer effects, skeleton screens
  6. **Success Animations** — checkmark, confetti on streak milestones

- **Implementation Strategy:**
  - Use Flutter's built-in `Hero`, `AnimatedContainer`, `AnimatedOpacity`
  - Add `PageRouteBuilder` for custom transitions
  - Use `AnimationController` for complex sequences
  - Keep animations < 400ms (feels responsive)

**Example: Hero Transition for Entry Detail**
```dart
// In EntryCard widget
Hero(
  tag: 'entry-${entry.id}',
  child: Container(...),
)

// In EntryDetailScreen
Hero(
  tag: 'entry-${widget.entry.id}',
  child: Container(...),
)
```

**Key Pattern:** Animations should enhance, not hinder — always skippable, never blocking

---

## Recommended Project Structure Extensions

```
lib/
├── services/                    # Business logic
│   ├── storage_service.dart    # (existing)
│   ├── reflection_service.dart # (existing)
│   ├── direction_service.dart  # (existing)
│   ├── insights_service.dart   # (existing)
│   ├── notification_service.dart # (existing)
│   ├── filter_service.dart     # NEW — search & filter
│   ├── summary_service.dart    # NEW — weekly recaps
│   ├── nudge_service.dart      # NEW — smart nudges
│   ├── calendar_service.dart   # NEW — heatmap data
│   └── animation_service.dart  # NEW (optional) — constants
├── screens/
│   ├── (existing screens...)
│   ├── search_screen.dart      # NEW — search/filter UI
│   ├── weekly_summary_screen.dart # NEW — recap display
│   ├── calendar_screen.dart    # NEW — heatmap view
│   └── edit_entry_screen.dart  # NEW — edit existing entries
├── widgets/
│   ├── (existing widgets...)
│   ├── search_bar.dart         # NEW — search input
│   ├── filter_chips.dart       # NEW — mood/date filters
│   ├── weekly_summary_card.dart # NEW — recap card
│   ├── nudge_card.dart         # NEW — smart nudge display
│   ├── calendar_heatmap.dart   # NEW — grid view
│   └── mood_day_cell.dart      # NEW — calendar cell
├── models/
│   ├── (existing models...)
│   ├── weekly_summary.dart     # NEW (TypeId: 3)
│   ├── nudge.dart              # NEW (non-persisted)
│   ├── mood_day.dart           # NEW (non-persisted)
│   └── filter_criteria.dart    # NEW (non-persisted)
└── utils/                       # NEW folder
    ├── debouncer.dart          # NEW — search debouncing
    ├── color_utils.dart        # NEW — mood → color mapping
    └── date_utils.dart         # NEW — week/month helpers
```

### Structure Rationale

- **Services:** Keep singleton pattern, add feature-specific services
- **Screens:** One screen per major feature (search, summary, calendar)
- **Widgets:** Extract reusable components (cards, inputs, visualizations)
- **Models:** Use Hive adapters only for persisted data, plain classes for computed data
- **Utils:** Non-stateful helpers (avoid service bloat)

---

## Architectural Patterns

### Pattern 1: Service Composition (Over Inheritance)

**What:** Services call other services for data, don't duplicate logic

**When to use:** When feature needs data from multiple sources

**Trade-offs:**
- ✅ DRY — reuse existing calculations
- ✅ Clear dependencies — easy to trace data flow
- ⚠️ Tight coupling — services depend on each other
- ⚠️ No dependency injection — harder to mock in tests

**Example:**
```dart
class NudgeService {
  static final NudgeService instance = NudgeService._();
  NudgeService._();

  Future<List<Nudge>> getAllActiveNudges() async {
    final nudges = <Nudge>[];

    // Compose from multiple services
    final dormantDirections = await DirectionService.instance.getDormantDirections();
    final streak = await StorageService.instance.getCurrentStreak();
    final lastEntryDate = await StorageService.instance.getLastEntryDate();

    // Generate nudges based on composed data
    if (dormantDirections.isNotEmpty) {
      nudges.add(_createDormantDirectionNudge(dormantDirections.first));
    }

    if (_isStreakAtRisk(streak, lastEntryDate)) {
      nudges.add(_createStreakNudge(streak));
    }

    return nudges..sort((a, b) => a.priority.compareTo(b.priority));
  }
}
```

### Pattern 2: Compute on Demand (Not Pre-Compute)

**What:** Calculate data when needed, don't store computed values (except summaries)

**When to use:** For dynamic data (nudges, filters, heatmaps)

**Trade-offs:**
- ✅ Always fresh data — no stale cached results
- ✅ Less storage — no extra Hive boxes
- ✅ Simpler data model — fewer entities to manage
- ⚠️ Recalculation cost — may be slower for complex queries
- ⚠️ Battery impact — more CPU usage

**When to pre-compute (exception):**
- Weekly summaries — snapshot in time, don't change
- Longest streak — updated on entry save, not every read

**Example:**
```dart
// ❌ Don't do this (storing computed data)
class FilterService {
  List<Entry>? _cachedSearchResults;

  Future<List<Entry>> searchEntries(String query) async {
    if (_cachedSearchResults != null) return _cachedSearchResults!;
    // ... search logic
  }
}

// ✅ Do this (compute on demand)
class FilterService {
  Future<List<Entry>> searchEntries(String query) async {
    final allEntries = await StorageService.instance.getAllEntries();
    return allEntries.where((entry) {
      return entry.intention.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
```

### Pattern 3: Bottom Sheets for Detail (Not New Screens)

**What:** Use bottom sheets for quick info, screens for full workflows

**When to use:**
- Bottom sheet: View day entries, quick filters, nudge details
- Screen: Edit entry, create direction, weekly summary

**Trade-offs:**
- ✅ Less navigation overhead — no back button needed
- ✅ Context preservation — main screen visible
- ✅ Gesture-friendly — swipe to dismiss
- ⚠️ Limited space — not for complex forms
- ⚠️ iOS vs Android differences — handle both

**Example:**
```dart
// For viewing entries (bottom sheet)
void _showDayEntries(BuildContext context, int dayOfWeek) {
  showModalBottomSheet(
    context: context,
    builder: (context) => DayEntriesSheet(dayOfWeek: dayOfWeek),
  );
}

// For editing entry (full screen)
void _editEntry(BuildContext context, Entry entry) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => EditEntryScreen(entry: entry),
    ),
  );
}
```

### Pattern 4: Debouncing for Search

**What:** Delay search execution until user stops typing

**When to use:** Any text input that triggers expensive operations (search, filter)

**Trade-offs:**
- ✅ Fewer operations — reduced CPU/battery usage
- ✅ Better UX — less UI flickering
- ✅ Less storage reads — Hive called less often
- ⚠️ Perceived latency — 300ms delay before results show

**Example:**
```dart
class _SearchScreenState extends State<SearchScreen> {
  Timer? _debounceTimer;

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _performSearch(query);
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
```

### Pattern 5: Hive TypeId Management

**What:** Reserve TypeIds, use manual adapters (no build_runner)

**Current allocation:**
- 0: Entry
- 1: ReflectionQuestion
- 2: ReflectionAnswer
- 3: **WeeklySummary (NEW)**
- 4: DirectionType (enum)
- 5: Direction
- 6: DirectionConnection
- 7-9: Reserved for future

**Trade-offs:**
- ✅ No build_runner dependency — simpler builds
- ✅ Full control — custom serialization logic
- ⚠️ Manual updates — must write adapters by hand
- ⚠️ Migration complexity — version changes require careful handling

**Pattern:** Always reserve next TypeId in documentation before using

---

## Data Flow

### Feature: Search Entries

```
User types "work" in SearchBar
    ↓
Debouncer (300ms wait)
    ↓
FilterService.searchEntries("work")
    ↓
StorageService.getAllEntries() → In-memory list
    ↓
Filter: intention.contains("work") || reflectionAnswers.contains("work")
    ↓
Return filtered list → Screen setState
    ↓
ListView.builder rebuilds with results
```

### Feature: Weekly Summary Generation

```
User taps "Generate Summary" button
    ↓
SummaryService.generateSummaryForLastWeek()
    ↓
Calculate weekStart/weekEnd dates
    ↓
Parallel data fetch:
  ├─ StorageService.getEntriesForPeriod(weekStart, weekEnd)
  ├─ InsightsService.getInsightsForPeriod(...) [reuse calculations]
  └─ DirectionService.getFrequentDirectionsThisWeek()
    ↓
Aggregate into WeeklySummary object
    ↓
Save to Hive (SummaryBox, TypeId: 3)
    ↓
Navigate to WeeklySummaryScreen
    ↓
Display narrative recap with stats
```

### Feature: Smart Nudge Display

```
HomeScreen initState() → Load nudges
    ↓
NudgeService.getAllActiveNudges()
    ↓
Parallel pattern checks:
  ├─ DirectionService.getDormantDirections() → Create nudge if any
  ├─ StorageService.getCurrentStreak() + lastEntryDate → Streak risk nudge
  ├─ ReflectionService.getDaysSinceLastReflection() → Reflection nudge
  └─ InsightsService.getDayOfWeekPattern() → Mood pattern nudge
    ↓
Combine into List<Nudge>, sort by priority
    ↓
Return top 2 nudges
    ↓
HomeScreen displays NudgeCards (dismissible)
```

### Feature: Calendar Heatmap

```
CalendarScreen loads month view
    ↓
CalendarService.getMonthHeatmapData(DateTime.now())
    ↓
StorageService.getAllEntries() → Filter to current month
    ↓
Group by day: Map<DateTime, List<Entry>>
    ↓
Calculate per-day: Map<DateTime, MoodDay>
  - avgMood = average of day's entries
  - color = colorFromMood(avgMood)
    ↓
Return Map<DateTime, MoodDay>
    ↓
GridView.builder renders 30-31 cells
    ↓
User taps cell → showModalBottomSheet(DayEntriesSheet)
```

---

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| **0-1k entries** | Current architecture perfect — in-memory filtering is instant |
| **1k-10k entries** | Add indexing in FilterService (cache entry.intention tokens), consider lazy loading in ListView |
| **10k+ entries** | Move to SQLite for complex queries, keep Hive for settings/config |

### Scaling Priorities

1. **First bottleneck (at ~2k entries):** Search/filter performance
   - **Fix:** Implement `compute()` for background filtering (isolate)
   - **Alternative:** Add full-text search with indexed tokens

2. **Second bottleneck (at ~5k entries):** Calendar heatmap rendering
   - **Fix:** Lazy-load months (don't compute all 365 days upfront)
   - **Alternative:** Use `CustomPainter` instead of GridView for year view

3. **Third bottleneck (at ~10k entries):** Insights calculation
   - **Fix:** Pre-compute weekly summaries (already planned)
   - **Alternative:** Move insights to background task (daily cron)

**Note:** Elio is a personal app, unlikely to exceed 1k entries (3 years of daily use). Current architecture is sufficient for 5+ years of heavy use.

---

## Anti-Patterns

### Anti-Pattern 1: Creating a Service for Every Screen

**What people do:** Create `SearchScreenService`, `CalendarScreenService`, etc.

**Why it's wrong:**
- Violates single responsibility — service tied to UI
- Hard to reuse logic across screens
- Services become UI controllers (not business logic)

**Do this instead:**
- Create feature-based services (`FilterService`, `CalendarService`)
- Services should be UI-agnostic (usable from any screen)
- If logic is screen-specific, keep it in the screen's State class

### Anti-Pattern 2: Storing UI State in Services

**What people do:**
```dart
class FilterService {
  String currentSearchQuery = "";
  List<String> selectedMoodFilters = [];
}
```

**Why it's wrong:**
- Services persist across screens (leads to stale state)
- Violates Flutter's reactive model (UI doesn't rebuild)
- Hard to reset state (when does query clear?)

**Do this instead:**
- Store UI state in screen's State class
- Pass state to service methods as parameters
- Services should be stateless (pure functions)

### Anti-Pattern 3: Deep Widget Trees with Prop Drilling

**What people do:** Pass data through 5+ levels of widgets

**Why it's wrong:**
- Refactoring nightmare (change one prop, update 5 widgets)
- Poor performance (unnecessary rebuilds)
- Hard to test (need to construct entire tree)

**Do this instead:**
- For 1-2 levels: Prop drilling is fine
- For 3+ levels: Access service directly from child widget
- For global state: InheritedWidget (only if needed, Elio doesn't need it yet)

### Anti-Pattern 4: Premature Abstraction

**What people do:** Create `BaseService`, `BaseModel`, `BaseScreen` with shared logic

**Why it's wrong:**
- Over-engineering for small apps
- Harder to understand (indirection)
- Limits flexibility (concrete > abstract for evolving requirements)

**Do this instead:**
- Start with concrete implementations
- Extract abstractions only after duplication (Rule of 3)
- Prefer composition over inheritance (services calling services)

### Anti-Pattern 5: Ignoring Flutter's Async Patterns

**What people do:** Use callbacks instead of Futures/Streams

```dart
// ❌ Don't
void fetchData(Function(Data) onComplete) {
  // ... async work
  onComplete(data);
}

// ✅ Do
Future<Data> fetchData() async {
  // ... async work
  return data;
}
```

**Why it's wrong:**
- Callback hell (nested callbacks)
- No error handling (try/catch doesn't work)
- Can't use FutureBuilder/StreamBuilder

**Do this instead:**
- Use `Future` for single async results
- Use `Stream` for continuous data (not needed in Elio yet)
- Leverage Flutter's FutureBuilder/StreamBuilder widgets

---

## Integration Points

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| **Screens ↔ Services** | Direct instance access (`Service.instance`) | Screens never access Hive directly |
| **Widgets ↔ Services** | Direct access OK if needed, prefer props from parent | Reusable widgets should be stateless |
| **Services ↔ Services** | Direct calls (tight coupling is acceptable) | Document dependencies in service init |
| **Services ↔ Hive** | Services own boxes, exclusive access | Each box accessed by 1 service only |

### External Services (None Yet)

Elio is fully local (no network calls). Future integrations might include:

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| **Cloud Backup** (future) | Export service → JSON → User's iCloud/Google Drive | Manual export, not auto-sync |
| **Analytics** (future) | Anonymous usage tracking (opt-in) | Privacy-first, aggregated only |
| **Notifications** (existing but unused) | Local notifications via flutter_local_notifications | No push, all on-device |

---

## Build Order for New Features

### Phase 1: Entry Management (Foundation)
**Dependencies:** None
**Components:**
1. Edit entry screen (reuse mood/intention/reflection inputs)
2. Delete entry confirmation dialog
3. Update StorageService with edit/delete methods

**Why first:** Basic CRUD completion, unblocks user testing

### Phase 2: Search & Filter (Data Access)
**Dependencies:** Phase 1 (need stable entry model)
**Components:**
1. FilterService (search/filter logic)
2. SearchScreen (UI for search)
3. Filter widgets (chips, date picker)

**Why second:** Users need to find entries before advanced features make sense

### Phase 3: Visual Patterns (Data Visualization)
**Dependencies:** Phase 2 (reuse filter logic for date ranges)
**Components:**
1. CalendarService (heatmap data)
2. CalendarHeatmapWidget
3. CalendarScreen (tab integration)

**Why third:** Requires stable data access layer from Phase 2

### Phase 4: Weekly Summaries (Analytics)
**Dependencies:** Phase 3 (reuse calendar aggregation logic)
**Components:**
1. WeeklySummary model + Hive adapter (TypeId: 3)
2. SummaryService (generation logic)
3. WeeklySummaryScreen (display)

**Why fourth:** Builds on existing InsightsService patterns

### Phase 5: Smart Nudges (Intelligence)
**Dependencies:** Phase 4 (reuse summary analytics)
**Components:**
1. NudgeService (pattern detection)
2. NudgeCard widget
3. Integration into Home screen

**Why fifth:** Requires all other data sources to be stable

### Phase 6: Premium Animations (Polish)
**Dependencies:** All previous phases (animates existing screens)
**Components:**
1. AnimationService (optional constants)
2. Hero transitions between screens
3. Page transitions (custom routes)
4. Micro-interactions (buttons, cards)

**Why last:** Pure polish, doesn't affect data model or business logic

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| **Existing patterns** | HIGH | Well-documented in CLAUDE.md, proven in v1.1.0 |
| **Service composition** | HIGH | Singleton pattern is standard Flutter for small apps |
| **Search/filter** | HIGH | In-memory filtering is straightforward with Hive |
| **Heatmap rendering** | MEDIUM | GridView performance may need tuning at scale |
| **Animation integration** | HIGH | Flutter's animation APIs are mature and documented |
| **Smart nudges logic** | MEDIUM | Pattern detection rules need user testing/refinement |

---

## Sources

- **Flutter Official Docs:** https://docs.flutter.dev (Animation, State Management)
- **Hive Documentation:** https://docs.hivedb.dev (Performance characteristics, best practices)
- **Existing Elio Codebase:** CLAUDE.md, lib/services/, lib/screens/ (v1.1.0 patterns)
- **Flutter Community Patterns:** Training data (2024-2025) on singleton services, StatefulWidget patterns
- **Confidence:** HIGH on existing architecture (verified in code), MEDIUM on new features (based on standard Flutter patterns, not domain-specific research)

---

*Architecture research for: Elio v2.0 — Mood Tracking & Journaling App*
*Researched: 2026-02-26*
