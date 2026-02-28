# Architecture

**Analysis Date:** 2026-02-26

## Pattern Overview

**Overall:** Service-Oriented MVC with Local-First Data Persistence

**Key Characteristics:**
- StatefulWidget-based UI layer with direct service calls (no BLoC/Provider)
- Singleton service pattern for business logic and data access
- Hive NoSQL database for local-only storage with manual type adapters
- Navigator 2.0 push/pop navigation without routing packages
- Bottom navigation shell with IndexedStack for tab preservation

## Layers

**Presentation Layer:**
- Purpose: UI screens and reusable widgets
- Location: `lib/screens/`, `lib/widgets/`
- Contains: StatefulWidget screens, UI components, theme definitions
- Depends on: Service layer, Models, Theme system
- Used by: Main entry point, Navigation flow

**Service Layer:**
- Purpose: Business logic, data operations, analytics calculations
- Location: `lib/services/`
- Contains: Singleton services (StorageService, ReflectionService, DirectionService, InsightsService, NotificationService)
- Depends on: Models, Hive database
- Used by: Screens, other services (cross-service dependencies exist)

**Data Model Layer:**
- Purpose: Domain objects with Hive serialization
- Location: `lib/models/`
- Contains: Data classes (Entry, Direction, ReflectionQuestion, etc.) and manual TypeAdapters
- Depends on: Hive package
- Used by: Services, Screens

**Theme Layer:**
- Purpose: Design system and visual styling
- Location: `lib/theme/`
- Contains: Color palette, text themes, ThemeData configurations
- Depends on: Flutter Material
- Used by: All UI components

## Data Flow

**Mood Entry Creation Flow:**

1. User opens `MoodEntryScreen` (Home tab via `HomeShell`)
2. User adjusts mood slider → state updates locally in StatefulWidget
3. User taps Continue → Navigator pushes to `IntentionScreen` with mood data
4. User enters intention → Navigator pushes to `ReflectionScreen` (if enabled)
5. `ReflectionService.getNextQuestion()` returns rotation-based question
6. User answers → Answer stored temporarily in screen state
7. User taps Continue → `ConfirmationScreen` receives all data
8. `StorageService.saveEntry()` persists Entry to Hive, auto-updates longest streak
9. `ReflectionService.saveAnswer()` persists each ReflectionAnswer to Hive
10. `DirectionService.connectEntry()` links entry to selected directions (if any)
11. Screen shows confirmation → Navigator pops back to HomeShell

**Insights Analytics Flow:**

1. `InsightsScreen` mounts → calls `StorageService.getAllEntries()`
2. Screen calls `InsightsService.getInsightsForPeriod()` with entries and period
3. Service calculates: mood averages, trends, streaks, reflection stats, day patterns
4. For week view: Service calls `DirectionService` for direction-based insights
5. Service generates 2-3 priority-based InsightItems
6. Screen renders: mood wave chart, stat cards, day pattern chart, insights
7. User taps day in pattern chart → Screen shows bottom sheet with filtered entries
8. User taps entry in sheet → Navigator pushes to `EntryDetailScreen`

**State Management:**
- Per-screen state in StatefulWidget `setState()`
- Persistent state in Hive boxes via singleton services
- Cross-tab state preserved with IndexedStack in `HomeShell`
- No global state management (Provider/BLoC)

## Key Abstractions

**Service Singleton Pattern:**
- Purpose: Single source of truth for each domain area
- Examples: `StorageService.instance`, `ReflectionService.instance`, `DirectionService.instance`
- Pattern: Private constructor, static `instance` getter, init() method for async setup
- Usage: Services initialized in `main()` before runApp(), accessed via `.instance` throughout app

**Hive TypeAdapter:**
- Purpose: Manual serialization for domain models
- Examples: `EntryAdapter` (typeId: 0), `DirectionAdapter` (typeId: 5), `DirectionConnectionAdapter` (typeId: 6)
- Pattern: Extend `TypeAdapter<T>`, implement `read()` and `write()` with field byte mapping
- Registration: Adapters registered in service `init()` methods before opening boxes

**Direction-Entry Connection:**
- Purpose: Many-to-many relationship between entries and life directions
- Examples: `DirectionConnection` model links directionId to entryId
- Pattern: Separate join table in Hive, queried via `DirectionService` helper methods
- Usage: `connectEntry()`, `disconnectEntry()`, `getConnectedEntries()`, `getDirectionsForEntry()`

**Question Rotation Logic:**
- Purpose: Deterministic daily reflection question selection
- Examples: `ReflectionService.getNextQuestion()`
- Pattern: Favorites first, then modulo-based rotation on day-of-year
- Formula: `dayOfYear % rotatingQuestions.length` ensures same question all day

**Insights Priority System:**
- Purpose: Generate 2-3 most relevant insights from 18 possible patterns
- Examples: Priority 1 (perfect streak) overrides Priority 7 (reflection rate)
- Pattern: Sequential evaluation, early exit when 3 insights reached
- Output: List of `InsightItem(icon, text)` tuples

## Entry Points

**main():**
- Location: `lib/main.dart`
- Triggers: App launch
- Responsibilities:
  - Initialize Flutter bindings
  - Initialize all services sequentially (Storage → Reflection → Direction → Notification)
  - Launch MaterialApp with OnboardingGate

**OnboardingGate:**
- Location: `lib/main.dart` (nested class)
- Triggers: MaterialApp home widget
- Responsibilities:
  - Check `StorageService.onboardingCompleted` flag
  - Route to `OnboardingFlow` if false, `HomeShell` if true
  - Provide callback to refresh gate after onboarding

**HomeShell:**
- Location: `lib/screens/home_shell.dart`
- Triggers: Post-onboarding or direct navigation
- Responsibilities:
  - Render 5-tab bottom navigation (Home, Insights, Directions, History, Settings)
  - Preserve tab state with IndexedStack
  - Handle debug triple-tap to reset onboarding

**OnboardingFlow:**
- Location: `lib/screens/onboarding/onboarding_flow.dart`
- Triggers: First launch or debug reset
- Responsibilities:
  - Manage PageController for 4-screen flow (Welcome → Name → FirstCheckin → Complete)
  - Persist user name to StorageService
  - Set onboarding completed flag
  - Callback to OnboardingGate to transition to main app

## Error Handling

**Strategy:** Defensive coding with fallbacks, minimal user-facing errors

**Patterns:**
- Service getters check null boxes and throw `StateError` if not initialized
- Database queries return empty lists/defaults instead of throwing
- Missing data (e.g., deleted questions) filtered with `whereType<T>()` and null coalescing
- Hot reload issues documented as "restart required" (service initialization state lost)
- No try-catch in UI layer - services expected to return safe defaults

## Cross-Cutting Concerns

**Logging:** Debug prints via `debugPrint()`, not production logging

**Validation:**
- Input length limits (intention: 100 chars, direction title: 50 chars)
- Business rules (max 5 active directions, max 2 favorite questions)
- Enforced in services before persistence

**Authentication:** Not applicable (local-only app)

**Analytics:**
- InsightsService calculates patterns from Entry data
- DirectionService provides mood correlation analysis
- No external analytics (privacy-first design)

**Persistence:**
- Hive boxes opened in service init(), remain open for app lifetime
- Automatic persistence on put/delete operations
- No explicit save/flush required
- Backfill logic for longest streak on first run

---

*Architecture analysis: 2026-02-26*
