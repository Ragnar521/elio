# Codebase Structure

**Analysis Date:** 2026-02-26

## Directory Layout

```
elio/
├── lib/
│   ├── main.dart                           # App entry + service initialization
│   ├── models/                             # Data models with Hive adapters
│   ├── screens/                            # UI screens
│   │   └── onboarding/                     # First-time user flow
│   ├── services/                           # Business logic singletons
│   ├── theme/                              # Design system
│   └── widgets/                            # Reusable components
├── android/                                # Android platform code
├── ios/                                    # iOS platform code
├── test/                                   # Unit/widget tests
├── pubspec.yaml                            # Dependencies manifest
└── README.md                               # Project overview
```

## Directory Purposes

**lib/models/**
- Purpose: Domain models with Hive serialization logic
- Contains: Data classes (Entry, Direction, ReflectionQuestion, ReflectionAnswer, DirectionConnection, DirectionCheckIn, DirectionStats)
- Key files:
  - `entry.dart`: Mood entry model (typeId: 0) + moodEmoji extension
  - `direction.dart`: Life direction model (typeId: 5) + DirectionType enum (typeId: 4)
  - `direction_connection.dart`: Entry-Direction join table (typeId: 6)
  - `direction_check_in.dart`: Per-entry direction presence/progress/blocker record (typeId: 8)
  - `direction_stats.dart`: Analytics model (not persisted, computed on-demand)
  - `reflection_question.dart`: Question model (typeId: 1) with category/favorite flags
  - `reflection_answer.dart`: Answer model (typeId: 2) with snapshot of question text

**lib/screens/**
- Purpose: Full-screen UI components
- Contains: StatefulWidget screens for each app section
- Key files:
  - `home_shell.dart`: Bottom navigation wrapper (5 tabs)
  - `mood_entry_screen.dart`: Mood slider entry (Home tab)
  - `intention_screen.dart`: Intention text input
  - `direction_check_in_screen.dart`: Multi-goal selection and optional per-goal detail before reflection
  - `reflection_screen.dart`: Reflection Q&A flow (up to 3 questions)
  - `confirmation_screen.dart`: Save entry + show streak
  - `insights_screen.dart`: Analytics dashboard (week/month view)
  - `directions_screen.dart`: Life directions list (Directions tab)
  - `create_direction_screen.dart`: Direction creation form
  - `direction_detail_screen.dart`: Direction stats + settings
  - `connect_entries_screen.dart`: Multi-select entry-to-direction linking
  - `history_screen.dart`: Entry timeline (History tab)
  - `entry_detail_screen.dart`: Full entry view with reflections
  - `settings_screen.dart`: App settings (Settings tab)
  - `reflection_settings_screen.dart`: Manage reflection questions
  - `question_library_screen.dart`: Browse 27 library questions
  - `custom_question_screen.dart`: Create custom user question

**lib/screens/onboarding/**
- Purpose: First-launch user setup flow
- Contains: PageView-based onboarding screens
- Key files:
  - `onboarding_flow.dart`: PageController coordinator for 4-screen flow
  - `welcome_screen.dart`: Welcome message (screen 1)
  - `name_screen.dart`: Name input with skip option (screen 2)
  - `first_checkin_screen.dart`: First mood entry (screen 3)
  - `onboarding_complete_screen.dart`: Completion celebration (screen 4)

**lib/services/**
- Purpose: Business logic layer and data access
- Contains: Singleton services with init() methods
- Key files:
  - `storage_service.dart`: Entry CRUD, settings persistence, streak calculation
  - `reflection_service.dart`: Question library, rotation logic, answer storage
  - `direction_service.dart`: Direction CRUD, connections, check-ins, stats, insights integration
  - `insights_service.dart`: Analytics calculations, pattern detection, insight generation
  - `notification_service.dart`: Local notifications (future feature, minimal implementation)

**lib/theme/**
- Purpose: Design system and visual styling
- Contains: Color palette, typography, ThemeData
- Key files:
  - `elio_colors.dart`: Color constants (dark/light modes)
  - `elio_text_theme.dart`: Typography scale
  - `elio_theme.dart`: ThemeData factory methods

**lib/widgets/**
- Purpose: Reusable UI components
- Contains: Custom widgets used across multiple screens
- Key files:
  - `entry_card.dart`: Entry preview card (history list item)
  - `mood_wave.dart`: Interactive mood chart with tap-to-view tooltips
  - `stat_card.dart`: Stat display with comparison indicator
  - `insight_card.dart`: Multiple insights display
  - `day_pattern_chart.dart`: Tappable day-of-week bar chart
  - `day_entries_sheet.dart`: Bottom sheet showing filtered entries
  - `direction_card.dart`: Direction preview with stats + progress
  - `answered_question_chip.dart`: Collapsed reflection answer display

## Key File Locations

**Entry Points:**
- `lib/main.dart`: App initialization + OnboardingGate router

**Configuration:**
- `pubspec.yaml`: Dependencies (hive, uuid, flutter_local_notifications)
- `android/app/build.gradle`: Android build config
- `ios/Runner.xcodeproj/`: iOS project config

**Core Logic:**
- `lib/services/storage_service.dart`: Entry persistence, settings
- `lib/services/reflection_service.dart`: Question seeding + rotation
- `lib/services/direction_service.dart`: Direction management + connections + check-ins
- `lib/services/insights_service.dart`: Analytics engine

**Testing:**
- `test/widget_test.dart`: Template test file (not actively used)

## Naming Conventions

**Files:**
- `snake_case.dart` for all files
- Screens: `*_screen.dart`
- Services: `*_service.dart`
- Models: singular noun (e.g., `entry.dart`, `direction.dart`)
- Widgets: descriptive noun (e.g., `mood_wave.dart`, `entry_card.dart`)

**Directories:**
- `lowercase` for directories
- Nested subdirectories for logical grouping (e.g., `screens/onboarding/`)

**Classes:**
- `PascalCase` for all classes
- Screen classes: `*Screen` (e.g., `MoodEntryScreen`)
- Service classes: `*Service` (e.g., `StorageService`)
- State classes: `_*State` (e.g., `_MoodEntryScreenState`)
- Private classes: `_PascalCase` prefix (e.g., `_PeriodRange`)

**Variables/Methods:**
- `camelCase` for public variables/methods
- `_camelCase` for private variables/methods
- Constants: `_camelCase` or `SCREAMING_SNAKE_CASE` for static const

## Where to Add New Code

**New Feature Screen:**
- Primary code: `lib/screens/feature_name_screen.dart`
- Tests: `test/screens/feature_name_screen_test.dart` (not yet implemented)
- Navigation: Add route in calling screen with `Navigator.of(context).push()`

**New Data Model:**
- Implementation: `lib/models/model_name.dart`
- Include: Model class + manual TypeAdapter extending `TypeAdapter<T>`
- Register: Add adapter registration in relevant service's `init()` method
- Assign unique typeId (0-6 used, 3 reserved, 7+ available)

**New Service:**
- Implementation: `lib/services/service_name_service.dart`
- Pattern: Private constructor, static `instance` getter, `init()` method
- Initialize: Call `await ServiceNameService.instance.init()` in `main.dart`
- Dependencies: Can reference other services via `.instance`

**New Widget:**
- Shared component: `lib/widgets/widget_name.dart`
- Pattern: Stateless or StatefulWidget, accept data via constructor
- Usage: Import and instantiate in screens

**New Utility/Helper:**
- For model extensions: Add to existing model file (e.g., `EntryExtension` in `entry.dart`)
- For service helpers: Add private methods to relevant service
- For standalone utils: Create `lib/utils/` directory (not yet exists)

**New Analytics Insight:**
- Logic: Add calculation method to `lib/services/insights_service.dart`
- Priority: Add to `_generateInsights()` method with priority number (18+ for new)
- Display: Will auto-render in `InsightsScreen` via `insight_card.dart`

**New Direction Type:**
- Add enum value to `DirectionType` in `lib/models/direction.dart`
- Add icon, color, example prompts, reflection questions to extension
- Update Hive adapter write/read methods to handle new enum value

## Special Directories

**android/**
- Purpose: Android platform-specific code
- Generated: Partially (gradle wrapper, build configs)
- Committed: Yes

**ios/**
- Purpose: iOS platform-specific code
- Generated: Partially (Xcode project, build configs)
- Committed: Yes

**build/**
- Purpose: Build artifacts
- Generated: Yes (via `flutter build`)
- Committed: No (in .gitignore)

**.dart_tool/**
- Purpose: Dart analyzer and build caches
- Generated: Yes
- Committed: No (in .gitignore)

**test/**
- Purpose: Unit and widget tests
- Generated: Template file exists
- Committed: Yes
- Status: Minimal test coverage (template only)

**.planning/**
- Purpose: GSD codebase mapping documents
- Generated: By `/gsd:map-codebase` command
- Committed: Not yet (new directory)
- Contains: ARCHITECTURE.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md, STACK.md, INTEGRATIONS.md, CONCERNS.md

## Navigation Patterns

**Push new screen:**
```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => NewScreen(param: value)),
);
```

**Replace current screen:**
```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => NewScreen()),
);
```

**Pop to root (back to HomeShell):**
```dart
Navigator.of(context).popUntil((route) => route.isFirst);
```

**Push and remove all previous routes:**
```dart
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => HomeShell(initialIndex: 1)),
  (route) => false,
);
```

## Import Patterns

**Relative imports for project code:**
```dart
import '../models/entry.dart';
import '../services/storage_service.dart';
import '../../theme/elio_colors.dart';
```

**Package imports:**
```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
```

**No path aliases configured** - all imports use relative paths from file location

## File Organization Guidelines

**Screen file structure:**
1. Imports (Flutter → packages → project)
2. StatefulWidget class
3. State class with lifecycle methods (initState, dispose, build)
4. Private helper methods
5. Private constants (if needed)

**Service file structure:**
1. Imports
2. Class definition with private constructor
3. Static instance getter
4. Private fields (boxes, constants)
5. Public init() method
6. Public API methods (grouped by feature)
7. Private helper methods
8. Private getters for boxes with null checks

**Model file structure:**
1. Imports
2. Model class with final fields
3. Extensions on model (if any)
4. TypeAdapter class with read/write methods

---

*Structure analysis: 2026-02-26*
