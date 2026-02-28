# Testing Patterns

**Analysis Date:** 2026-02-26

## Test Framework

**Runner:**
- `flutter_test` (SDK package, included by default)
- Config: No custom test configuration detected
- Coverage: No coverage tooling configured in `pubspec.yaml`

**Run Commands:**
```bash
flutter test                  # Run all tests
flutter test --watch         # Watch mode
flutter test --coverage      # Generate coverage (requires lcov)
```

## Test File Organization

**Location:**
- Tests in `test/` directory (Flutter convention)
- Only template test file exists: `test/widget_test.dart`

**Naming:**
- Pattern: `*_test.dart` for test files
- No custom tests written yet (only Flutter template)

**Structure:**
```
test/
└── widget_test.dart          # Flutter-generated template (non-functional)
```

## Test Structure

**Suite Organization:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:elio/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
```

**Patterns:**
- `testWidgets()` for widget tests
- `WidgetTester` parameter for widget interaction
- `async` test functions for pumping frames
- `expect()` for assertions
- `find.*` matchers for widget discovery

## Mocking

**Framework:** Not configured

**Patterns:**
- No mocking library in dependencies (`mockito`, `mocktail` not present)
- No mock implementations found in codebase
- Services use real Hive instances (in-memory would be needed for testing)

**What to Mock:**
- External dependencies (not yet implemented)
- Service layer (`StorageService`, `ReflectionService`, `DirectionService`)
- Platform-specific code (notifications, haptics)

**What NOT to Mock:**
- Simple data models (`Entry`, `Direction`)
- Theme and UI components
- Pure functions in `InsightsService`

## Fixtures and Factories

**Test Data:**
- No fixtures or factory patterns detected
- No test data generators

**Location:**
- Would conventionally go in `test/fixtures/` or `test/helpers/` (not present)

## Coverage

**Requirements:** None enforced

**View Coverage:**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Current State:**
- No coverage targets set
- No CI/CD integration for coverage
- Template test does not align with actual app structure

## Test Types

**Unit Tests:**
- Not implemented
- Would test service methods (`StorageService.getCurrentStreak()`, `InsightsService._average()`)
- Pure functions in `lib/services/insights_service.dart` are excellent candidates

**Integration Tests:**
- Not implemented
- Would test multi-service workflows (entry creation + reflection answers)
- Hive database interactions

**E2E Tests:**
- Framework: Not configured (would use `integration_test` package)
- No E2E tests present

## Common Patterns

**Async Testing:**
```dart
testWidgets('async widget test', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pump();  // Trigger one frame
  await tester.pumpAndSettle();  // Wait for all animations
});
```

**Error Testing:**
- Pattern not established (no examples in codebase)
- Would use `expect(() => ..., throwsA(...))` for exception testing

## Current Test Coverage

**Status:** Minimal

**Files with Tests:**
- `test/widget_test.dart` - Template test that references non-existent `MyApp` class (fails to run)

**Files without Tests:**
- All production code (0% coverage)
- Services: `lib/services/*.dart` (5 files)
- Models: `lib/models/*.dart` (6 files)
- Screens: `lib/screens/**/*.dart` (23 files)
- Widgets: `lib/widgets/*.dart` (8 files)

## Test Gaps

**Critical Untested Areas:**

**Services (High Priority):**
- `lib/services/storage_service.dart` - Entry CRUD, streak calculations
- `lib/services/direction_service.dart` - Direction CRUD, connections, statistics
- `lib/services/insights_service.dart` - Complex analytics calculations
- `lib/services/reflection_service.dart` - Question rotation logic

**Models (Medium Priority):**
- `lib/models/entry.dart` - Hive adapter serialization
- `lib/models/direction.dart` - Extension methods, copyWith
- `lib/models/direction_stats.dart` - Computed properties

**Widgets (Low Priority):**
- `lib/widgets/*.dart` - Widget rendering and interactions

## Recommended Testing Strategy

**Phase 1: Service Unit Tests**
- Test `InsightsService` pure functions: `_average()`, `_standardDeviation()`, `_calculateDayOfWeekPattern()`
- Test `StorageService` CRUD operations (with in-memory Hive)
- Test `DirectionService` connection logic

**Phase 2: Model Tests**
- Test Hive adapter serialization round-trips
- Test `DirectionStats` calculations
- Test extension methods (e.g., `EntryExtension.moodEmoji`)

**Phase 3: Widget Tests**
- Test key user flows: mood entry, intention input, reflection screen
- Test empty states and error states
- Test navigation between screens

**Phase 4: Integration Tests**
- Test complete check-in flow (mood → intention → reflection → save)
- Test direction creation and entry connection
- Test insights calculation with real data

## Setup Required for Testing

**Dependencies to Add:**
```yaml
dev_dependencies:
  mockito: ^5.4.0              # For mocking services
  build_runner: ^2.4.0         # For generating mocks
  hive_test: ^1.0.0            # In-memory Hive for tests
```

**Configuration Needed:**
- Mock generation config for services
- Test helper utilities for creating fixtures
- Hive initialization in `setUp()` blocks
- Cleanup in `tearDown()` blocks

---

*Testing analysis: 2026-02-26*
