# Coding Conventions

**Analysis Date:** 2026-02-26

## Naming Patterns

**Files:**
- `snake_case.dart` for all Dart files
- Screen files: `*_screen.dart` (e.g., `mood_entry_screen.dart`, `direction_detail_screen.dart`)
- Service files: `*_service.dart` (e.g., `storage_service.dart`, `insights_service.dart`)
- Widget files: `*_widget.dart` or descriptive name (e.g., `entry_card.dart`, `mood_wave.dart`)
- Model files: Plain noun (e.g., `entry.dart`, `direction.dart`)

**Functions:**
- `camelCase` for public methods
- `_leadingUnderscore` for private methods and helpers
- Getters use noun form: `userName`, `onboardingCompleted`, `moodEmoji`
- Boolean getters use `is` prefix when appropriate: `isArchived`, `isCustom`, `isFavorite`

**Variables:**
- `camelCase` for local variables and instance fields
- `_leadingUnderscore` for private instance fields
- Constants: `_camelCaseWithPrefix` for private constants (e.g., `_entriesBoxName`, `_userNameKey`)
- Static constants: `SCREAMING_SNAKE_CASE` not used; prefer `camelCase` even for static

**Types:**
- `PascalCase` for classes, enums, typedefs
- `PascalCase` for enum values (e.g., `DirectionType.career`, `InsightsPeriod.week`)

## Code Style

**Formatting:**
- Tool used: Dart formatter (built-in)
- No custom formatter config detected
- Line length: Default (80 characters, enforced by `dart format`)

**Linting:**
- Tool: `flutter_lints` package (version 6.0.0)
- Config: `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`
- No custom rules enabled or disabled
- Standard Flutter recommended lints apply

## Import Organization

**Order:**
1. Dart core libraries (e.g., `dart:io`, `dart:math`)
2. Flutter framework imports (`package:flutter/material.dart`, `package:flutter/services.dart`)
3. Third-party packages (`package:hive/hive.dart`, `package:uuid/uuid.dart`)
4. Local project imports (relative paths starting with `../`)

**Pattern observed in `lib/screens/mood_entry_screen.dart`:**
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/elio_colors.dart';
import '../services/storage_service.dart';
import 'intention_screen.dart';
```

**Path Aliases:**
- Relative imports only (e.g., `../models/entry.dart`, `../services/storage_service.dart`)
- No path aliases or barrel files detected

## Error Handling

**Patterns:**
- Try-catch blocks used sparingly, primarily around service initialization and async operations
- Errors logged with `debugPrint()` rather than `print()`
- No rethrowing or custom exception types observed
- Graceful degradation: errors caught and default values returned (e.g., returning 0 or empty list)

**Example from `lib/services/direction_service.dart`:**
```dart
Direction? getDirection(String id) {
  try {
    return _directions.values.firstWhere((d) => d.id == id);
  } catch (_) {
    return null;
  }
}
```

**Example from `lib/screens/confirmation_screen.dart`:**
```dart
try {
  _streakCount = await StorageService.instance.getCurrentStreak();
} catch (_) {}
```

## Logging

**Framework:** Built-in `debugPrint`

**Patterns:**
- Use `debugPrint('Error: $e')` for error logging
- Minimal logging in production code
- Only 2 instances found in entire codebase:
  - `lib/screens/confirmation_screen.dart:144`
  - `lib/screens/reflection_screen.dart:43`

**When to Log:**
- Only on caught exceptions during critical operations (entry saving, data loading)
- Not used for debugging or tracing

## Comments

**When to Comment:**
- Section dividers in service classes (e.g., `// ============ DIRECTIONS CRUD ============`)
- Complex calculations or non-obvious logic
- Documentation not observed in models or widgets
- Template test file has extensive comments (Flutter generated)

**JSDoc/DartDoc:**
- Not used in codebase
- No `///` documentation comments found
- Public APIs lack formal documentation

## Function Design

**Size:**
- Most methods under 30 lines
- Largest methods in `lib/services/insights_service.dart` (793 lines total, but well-factored)
- Complex operations broken into helper methods (e.g., `_calculateReflectionStats`, `_generateInsights`)

**Parameters:**
- Named parameters preferred: `required` keyword used extensively
- Optional parameters use `?` nullable syntax or default values
- Example: `createDirection({required String title, required DirectionType type, required bool reflectionEnabled})`

**Return Values:**
- Explicit return types always declared
- `Future<T>` for async operations
- Nullable return types (`T?`) for operations that may fail
- Records syntax used for multiple return values: `(String, int) _mostFelt(...)` returns tuple

## Module Design

**Exports:**
- No explicit exports; each file is self-contained
- No library-level exports or `part` directives

**Barrel Files:**
- Not used in this codebase
- Direct imports from individual files

## State Management

**Pattern:** StatefulWidget + Service Layer

**Singleton Services:**
```dart
class StorageService {
  StorageService._();  // Private constructor
  static final StorageService instance = StorageService._();

  Future<void> init() async { ... }
}
```

**Widget State:**
- StatefulWidget used for all screens requiring state
- `late` keyword for variables initialized in `initState()`
- `setState()` for local UI updates
- No Provider, Bloc, or Riverpod

## Constants and Configuration

**Pattern:**
- Private static constants in service classes: `static const _entriesBoxName = 'entries';`
- Theme constants in dedicated files: `lib/theme/elio_colors.dart`
- Magic numbers avoided; named constants preferred (e.g., `maxDirections = 5`)

## Widget Structure

**Standard Pattern:**
```dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key, required this.param});

  final String param;

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}
```

**Key Conventions:**
- `super.key` in constructor for widget keys
- `const` constructors wherever possible
- Private state class: `_MyScreenState`
- State class name matches widget with `State` suffix

## Hive (Database) Patterns

**Manual Adapters:**
- TypeAdapters written manually (no build_runner)
- TypeIds explicitly assigned: 0 (Entry), 1 (ReflectionQuestion), 2 (ReflectionAnswer), 4 (DirectionType), 5 (Direction), 6 (DirectionConnection)
- TypeId 3 reserved for future use

**Adapter Pattern:**
```dart
class EntryAdapter extends TypeAdapter<Entry> {
  @override
  final int typeId = 0;

  @override
  Entry read(BinaryReader reader) { ... }

  @override
  void write(BinaryWriter writer, Entry obj) { ... }
}
```

## Animation Patterns

**Controllers:**
- `AnimationController` with `vsync: this` (requires `SingleTickerProviderStateMixin`)
- Animations created with `Tween` and `CurvedAnimation`
- Disposed in `dispose()` method

**Example from `lib/screens/confirmation_screen.dart`:**
```dart
class _ConfirmationScreenState extends State<ConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _glowScale = Tween<double>(begin: 0.6, end: 1.1).animate(...);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Theme Usage

**Accessing Theme:**
- Use `Theme.of(context).textTheme.headlineSmall` for text styles
- Direct color references: `ElioColors.darkAccent`
- Opacity modifiers: `ElioColors.darkPrimaryText.withOpacity(0.6)`

**Border Radius Convention:**
- Cards: 16-24px
- Buttons: 18px
- Chips: 14px
- Defined inline, not as constants

---

*Convention analysis: 2026-02-26*
