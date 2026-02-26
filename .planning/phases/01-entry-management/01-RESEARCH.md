# Phase 1: Entry Management - Research

**Researched:** 2026-02-26
**Domain:** Flutter in-place editing, Hive schema evolution, soft delete patterns
**Confidence:** HIGH

## Summary

Phase 1 enables users to edit and delete existing mood entries through in-place editing on the entry detail screen. The implementation requires careful handling of Hive schema evolution to avoid breaking existing data, proper StatefulWidget state management for edit/view mode toggling, and a soft delete system with 30-day retention and undo capability.

The key technical challenges are: (1) making Entry model mutable while maintaining Hive backward compatibility, (2) managing TextEditingControllers and form state without memory leaks, (3) implementing soft delete that preserves direction connections, and (4) providing a smooth undo experience via SnackBar.

**Primary recommendation:** Use manual Hive TypeAdapter field versioning with default values, implement edit mode as StatefulWidget state toggle with TextEditingController disposal, use ScaffoldMessenger for undo SnackBar with 5-second duration, and add `isDeleted` and `deletedAt` fields to Entry model for soft delete.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Edit entry flow:**
- Edit happens directly on the entry detail screen — tap edit, fields become editable in place
- Same screen, two modes: view mode and edit mode
- Mood editing uses the same vertical slider widget from the check-in flow
- Reflections: user can edit existing answers AND add new ones (up to 3 total)
- No "edited" indicator on modified entries — they look the same as originals
- Save button (checkmark) replaces edit icon in app bar when in edit mode; Cancel button also appears

**Delete & undo behavior:**
- Delete triggered via dialog popup confirmation ("Are you sure?" with Cancel/Delete buttons)
- After deletion: bottom snackbar with "Entry deleted — Undo" for ~5 seconds
- 30-day soft delete runs silently in background — no UI for browsing deleted entries
- Direction connections are preserved on soft-deleted entries (restoring brings everything back)

**Entry detail actions:**
- Edit (pencil icon) and delete (trash icon) in the top app bar
- Edit toggles the detail screen into edit mode (in-place editing, not a separate screen)
- Save/Cancel buttons appear in app bar during edit mode

### Claude's Discretion

- Whether to add long-press context menu on history list cards for quick edit/delete access
- Edit mode transition animations
- How the mood slider integrates visually into the detail screen layout
- Snackbar styling and positioning
- How reflection editing UI works (inline expand vs modal)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ENTRY-01 | User can edit mood value and mood word on an existing entry | Flutter StatefulWidget edit mode pattern, mood slider widget reuse, Hive Entry model mutation |
| ENTRY-02 | User can edit intention text on an existing entry | TextEditingController pattern, Form validation, TextField in-place editing |
| ENTRY-03 | User can edit or add reflection answers on an existing entry | ReflectionAnswer CRUD methods, managing answer list state, max 3 total constraint |
| ENTRY-04 | User can delete an entry with confirmation dialog | AlertDialog pattern, soft delete field addition to Entry model |
| ENTRY-05 | User can undo a deletion within a short time window (soft delete) | ScaffoldMessenger SnackBar with action, 30-day retention background cleanup |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_sdk | ^3.10.8 | UI framework | Already in use, matches project |
| hive | ^2.2.3 | Local NoSQL database | Already in use for all data storage |
| hive_flutter | ^1.1.0 | Hive Flutter extensions | Already in use, provides Hive.initFlutter() |
| uuid | ^4.5.1 | UUID generation | Already in use for all model IDs |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_test | sdk | Widget testing | For testing edit/delete flows |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual Hive adapters | build_runner with @HiveType annotations | Project explicitly uses manual adapters (see CLAUDE.md), more control over migration |
| StatefulWidget state | Provider/Bloc | Project pattern is StatefulWidget + Services (see CLAUDE.md Technical Architecture) |
| Soft delete | Hard delete + backup | User requirement specifies 30-day retention for undo safety |

**Installation:**
No new dependencies required — all necessary packages already in pubspec.yaml.

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── models/
│   └── entry.dart              # ADD: isDeleted, deletedAt, updatedAt fields
├── services/
│   └── storage_service.dart    # ADD: updateEntry(), softDeleteEntry(), restoreEntry(), permanentDeleteOldEntries()
├── screens/
│   └── entry_detail_screen.dart # CONVERT: StatelessWidget → StatefulWidget with edit mode
└── widgets/
    └── (optional) mood_slider_widget.dart # EXTRACT: reusable slider from mood_entry_screen.dart
```

### Pattern 1: In-Place Edit Mode Toggle

**What:** Single screen with two modes (view/edit) controlled by boolean state variable

**When to use:** User wants to edit where they can see it (per CONTEXT.md decisions)

**Example:**
```dart
class _EntryDetailScreenState extends State<EntryDetailScreen> {
  bool _isEditMode = false;

  late TextEditingController _intentionController;
  late double _editedMoodValue;
  late String _editedMoodWord;

  @override
  void initState() {
    super.initState();
    _intentionController = TextEditingController(text: widget.entry.intention);
    _editedMoodValue = widget.entry.moodValue;
    _editedMoodWord = widget.entry.moodWord;
  }

  @override
  void dispose() {
    _intentionController.dispose(); // CRITICAL: prevent memory leak
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() => _isEditMode = !_isEditMode);
  }

  Future<void> _saveChanges() async {
    final updatedEntry = Entry(
      id: widget.entry.id,
      moodValue: _editedMoodValue,
      moodWord: _editedMoodWord,
      intention: _intentionController.text,
      createdAt: widget.entry.createdAt,
      reflectionAnswerIds: widget.entry.reflectionAnswerIds,
    );

    await StorageService.instance.updateEntry(updatedEntry);
    setState(() => _isEditMode = false);
  }

  void _cancelEdit() {
    // Reset to original values
    _intentionController.text = widget.entry.intention;
    _editedMoodValue = widget.entry.moodValue;
    _editedMoodWord = widget.entry.moodWord;
    setState(() => _isEditMode = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: _isEditMode
          ? [
              IconButton(icon: Icon(Icons.close), onPressed: _cancelEdit),
              IconButton(icon: Icon(Icons.check), onPressed: _saveChanges),
            ]
          : [
              IconButton(icon: Icon(Icons.edit), onPressed: _toggleEditMode),
              IconButton(icon: Icon(Icons.delete), onPressed: _showDeleteDialog),
            ],
      ),
      body: _isEditMode ? _buildEditMode() : _buildViewMode(),
    );
  }
}
```

**Source:** [Flutter StatefulWidget documentation](https://docs.flutter.dev/learn/pathway/tutorial/stateful-widget) - official Flutter docs, last updated 2026-02-05

### Pattern 2: Hive Schema Evolution with Field Versioning

**What:** Add new fields to existing Hive models without breaking existing data by using default values

**When to use:** Entry model needs `isDeleted`, `deletedAt`, `updatedAt` fields added

**Example:**
```dart
// BEFORE (current entry.dart)
class Entry {
  final String id;
  final double moodValue;
  final String moodWord;
  final String intention;
  final DateTime createdAt;
  final List<String>? reflectionAnswerIds;
}

class EntryAdapter extends TypeAdapter<Entry> {
  @override
  final int typeId = 0;

  @override
  Entry read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return Entry(
      id: fields[0] as String,
      moodValue: fields[1] as double,
      moodWord: fields[2] as String,
      intention: fields[3] as String,
      createdAt: fields[4] as DateTime,
      reflectionAnswerIds: fields[5] as List<String>?,
    );
  }

  @override
  void write(BinaryWriter writer, Entry obj) {
    writer
      ..writeByte(6) // field count
      ..writeByte(0) ..write(obj.id)
      ..writeByte(1) ..write(obj.moodValue)
      ..writeByte(2) ..write(obj.moodWord)
      ..writeByte(3) ..write(obj.intention)
      ..writeByte(4) ..write(obj.createdAt)
      ..writeByte(5) ..write(obj.reflectionAnswerIds);
  }
}

// AFTER (with soft delete fields)
class Entry {
  final String id;
  final double moodValue;
  final String moodWord;
  final String intention;
  final DateTime createdAt;
  final List<String>? reflectionAnswerIds;
  final bool isDeleted;           // NEW field 6
  final DateTime? deletedAt;      // NEW field 7
  final DateTime? updatedAt;      // NEW field 8
}

class EntryAdapter extends TypeAdapter<Entry> {
  @override
  final int typeId = 0; // NEVER CHANGE

  @override
  Entry read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return Entry(
      id: fields[0] as String,
      moodValue: fields[1] as double,
      moodWord: fields[2] as String,
      intention: fields[3] as String,
      createdAt: fields[4] as DateTime,
      reflectionAnswerIds: fields[5] as List<String>?,
      isDeleted: fields[6] as bool? ?? false,           // DEFAULT: false for old entries
      deletedAt: fields[7] as DateTime?,                 // DEFAULT: null for old entries
      updatedAt: fields[8] as DateTime?,                 // DEFAULT: null for old entries
    );
  }

  @override
  void write(BinaryWriter writer, Entry obj) {
    writer
      ..writeByte(9) // NEW field count (was 6, now 9)
      ..writeByte(0) ..write(obj.id)
      ..writeByte(1) ..write(obj.moodValue)
      ..writeByte(2) ..write(obj.moodWord)
      ..writeByte(3) ..write(obj.intention)
      ..writeByte(4) ..write(obj.createdAt)
      ..writeByte(5) ..write(obj.reflectionAnswerIds)
      ..writeByte(6) ..write(obj.isDeleted)      // NEW
      ..writeByte(7) ..write(obj.deletedAt)      // NEW
      ..writeByte(8) ..write(obj.updatedAt);     // NEW
  }
}
```

**Key points:**
- NEVER change existing field numbers (0-5)
- Assign new field numbers sequentially (6, 7, 8)
- Use null-aware operators (??) to provide defaults when reading old data
- Update field count in write() from 6 → 9
- TypeId (0) must NEVER change

**Sources:**
- [Hive TypeAdapter documentation](https://pub.dev/documentation/hive/latest/hive/TypeAdapter-class.html)
- [GitHub: Adding new field to Hive Object results in error from Adapter #781](https://github.com/isar/hive/issues/781)
- [GitHub: Hive field default values discussion #125](https://github.com/isar/hive/issues/125)

### Pattern 3: Soft Delete with Undo via SnackBar

**What:** Mark entry as deleted, show SnackBar with undo action, permanently delete after 30 days

**When to use:** User requirement for deletion safety (per CONTEXT.md and ENTRY-05)

**Example:**
```dart
Future<void> _showDeleteDialog() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete entry?'),
      content: Text('Are you sure you want to delete this entry?'),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(
          child: Text('Delete'),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  // Soft delete the entry
  await StorageService.instance.softDeleteEntry(widget.entry.id);

  // Show undo SnackBar (5 seconds per CONTEXT.md)
  final snackBar = SnackBar(
    content: Text('Entry deleted'),
    duration: Duration(seconds: 5),
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () async {
        await StorageService.instance.restoreEntry(widget.entry.id);
      },
    ),
  );

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(snackBar);

  // Navigate back to history
  Navigator.of(context).pop();
}
```

**Background cleanup (runs on app start):**
```dart
// In StorageService.init()
Future<void> init() async {
  // ... existing init code ...

  // Clean up entries deleted >30 days ago
  await _permanentDeleteOldEntries();
}

Future<void> _permanentDeleteOldEntries() async {
  final now = DateTime.now();
  final cutoff = now.subtract(Duration(days: 30));

  final entriesToDelete = _box.values.where((entry) {
    return entry.isDeleted &&
           entry.deletedAt != null &&
           entry.deletedAt!.isBefore(cutoff);
  }).toList();

  for (final entry in entriesToDelete) {
    await _box.delete(entry.id);
  }
}
```

**Sources:**
- [Flutter SnackBar documentation](https://docs.flutter.dev/cookbook/design/snackbars)
- [Flutter ScaffoldMessenger migration guide](https://docs.flutter.dev/release/breaking-changes/scaffold-messenger)
- [ScaffoldMessenger API reference](https://api.flutter.dev/flutter/material/ScaffoldMessenger-class.html)

### Pattern 4: TextEditingController Memory Management

**What:** Properly initialize and dispose TextEditingControllers to prevent memory leaks

**When to use:** Every StatefulWidget with TextFields (intention editing, reflection editing)

**Example:**
```dart
class _EntryDetailScreenState extends State<EntryDetailScreen> {
  late TextEditingController _intentionController;

  @override
  void initState() {
    super.initState();
    _intentionController = TextEditingController(text: widget.entry.intention);
  }

  @override
  void dispose() {
    _intentionController.dispose(); // CRITICAL: Always dispose!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _intentionController,
      maxLength: 100,
    );
  }
}
```

**Sources:**
- [Flutter memory leak prevention guide](https://devharshmittal.medium.com/flutter-memory-leaks-causes-prevention-and-best-practices-with-code-examples-df089566736e)
- [Mastering the dispose() method in Flutter](https://mailharshkhatri.medium.com/mastering-the-dispose-method-in-flutter-a-deep-dive-c71331550e3b)
- [Flutter Performance Optimization 2026](https://dev.to/techwithsam/flutter-performance-optimization-2026-make-your-app-10x-faster-best-practices-2p07)

### Anti-Patterns to Avoid

- **Hard deleting entries without confirmation:** Causes permanent data loss, violates user requirements
- **Using build_runner for Hive adapters:** Project uses manual adapters (see CLAUDE.md Development Notes)
- **Forgetting TextEditingController.dispose():** Primary cause of memory leaks in Flutter forms
- **Changing existing Hive field numbers:** Breaks backward compatibility, crashes app for existing users
- **Using Scaffold.of(context).showSnackBar:** Deprecated, use ScaffoldMessenger instead

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema migration | Custom migration logic | Hive field versioning with defaults | Hive handles missing fields automatically, custom logic is error-prone |
| TextEditingController lifecycle | Manual controller tracking | StatefulWidget initState/dispose | Flutter manages widget lifecycle, manual tracking causes leaks |
| Entry update logic | Separate update methods per field | Single updateEntry() with full Entry object | Maintains data consistency, simpler to test |
| Soft delete cleanup | UI for browsing deleted items | Background cleanup on init() | User requirement: silent 30-day retention, no UI needed |

**Key insight:** Flutter and Hive provide robust lifecycle and persistence patterns — custom solutions introduce complexity without benefit.

## Common Pitfalls

### Pitfall 1: Breaking Hive Backward Compatibility

**What goes wrong:** Changing field numbers or not providing defaults causes crashes when reading old data

**Why it happens:** Developer adds new field, forgets that existing users have data without it

**How to avoid:**
1. NEVER change existing field numbers
2. Always use `??` operator with sensible defaults when reading new fields
3. Update field count in write() to match total fields
4. Test with existing Hive database before deploying

**Warning signs:**
- Error: "RangeError (index): Invalid value: Not in inclusive range 0..5"
- Error: "type 'Null' is not a subtype of type 'bool'"
- App crashes on entry detail screen for old entries

### Pitfall 2: TextEditingController Memory Leaks

**What goes wrong:** Creating TextEditingController without disposing causes memory to accumulate

**Why it happens:** Controllers allocate resources that Dart's GC doesn't automatically clean up

**How to avoid:**
1. Always create controllers in initState()
2. Always dispose controllers in dispose()
3. Dispose before calling super.dispose()
4. Use DCM lint rule `dispose-fields` to detect missing disposals

**Warning signs:**
- App memory usage grows over time
- Performance degrades after many edit operations
- Flutter DevTools shows leaked controller instances

### Pitfall 3: Losing Edit Changes on Widget Rebuild

**What goes wrong:** User makes edits, screen rebuilds, edits disappear

**Why it happens:** Not using TextEditingController, or creating new controller on rebuild

**How to avoid:**
1. Create controllers in initState(), not build()
2. Use `late` keyword for controller fields
3. Store non-TextField state (mood value) in State variables
4. Only update state on save, not during editing

**Warning signs:**
- TextField loses focus randomly
- Typed text disappears when screen updates
- Mood slider resets to original value

### Pitfall 4: SnackBar Dismissed Before User Can Undo

**What goes wrong:** User deletes entry, SnackBar disappears too fast, can't undo

**Why it happens:** Default SnackBar duration is 4 seconds, user may not react in time

**How to avoid:**
1. Set duration to 5 seconds (per CONTEXT.md requirement)
2. Show SnackBar AFTER navigating back to history (not before)
3. Use ScaffoldMessenger, not Scaffold.of(context)
4. Test undo flow on real device, not just simulator

**Warning signs:**
- User feedback: "I accidentally deleted and couldn't undo"
- SnackBar appears briefly on entry detail screen before navigation

### Pitfall 5: Reflection Answers Orphaned on Entry Delete

**What goes wrong:** Entry soft-deleted, but reflection answers remain, causing data bloat

**Why it happens:** ReflectionAnswer has entryId but no cascade delete logic

**How to avoid:**
1. Soft delete preserves answers (per CONTEXT.md: "Direction connections preserved")
2. Permanent delete (30 days) must also delete associated ReflectionAnswers
3. Query answers by entryId, delete all matches
4. Add method: `deleteAnswersForEntry(String entryId)` to ReflectionService

**Warning signs:**
- Hive database grows even when entries deleted
- Orphaned answers visible in Hive browser tools

## Code Examples

Verified patterns from official sources:

### Common Operation 1: Update Entry in Hive

```dart
// In StorageService
Future<void> updateEntry(Entry entry) async {
  // Create new Entry with updatedAt timestamp
  final updated = Entry(
    id: entry.id,
    moodValue: entry.moodValue,
    moodWord: entry.moodWord,
    intention: entry.intention,
    createdAt: entry.createdAt,
    reflectionAnswerIds: entry.reflectionAnswerIds,
    isDeleted: entry.isDeleted,
    deletedAt: entry.deletedAt,
    updatedAt: DateTime.now(),
  );

  // Hive put() overwrites existing key
  await _box.put(entry.id, updated);
}
```

**Source:** Hive documentation - put() method overwrites existing keys

### Common Operation 2: Soft Delete with Restore

```dart
// In StorageService
Future<void> softDeleteEntry(String entryId) async {
  final entry = _box.get(entryId);
  if (entry == null) return;

  final deleted = Entry(
    id: entry.id,
    moodValue: entry.moodValue,
    moodWord: entry.moodWord,
    intention: entry.intention,
    createdAt: entry.createdAt,
    reflectionAnswerIds: entry.reflectionAnswerIds,
    isDeleted: true,
    deletedAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  await _box.put(entryId, deleted);
}

Future<void> restoreEntry(String entryId) async {
  final entry = _box.get(entryId);
  if (entry == null || !entry.isDeleted) return;

  final restored = Entry(
    id: entry.id,
    moodValue: entry.moodValue,
    moodWord: entry.moodWord,
    intention: entry.intention,
    createdAt: entry.createdAt,
    reflectionAnswerIds: entry.reflectionAnswerIds,
    isDeleted: false,
    deletedAt: null,
    updatedAt: DateTime.now(),
  );

  await _box.put(entryId, restored);
}
```

### Common Operation 3: Filter Out Soft-Deleted Entries

```dart
// In StorageService - update getAllEntries()
Future<List<Entry>> getAllEntries() async {
  final entries = _box.values
      .where((entry) => !entry.isDeleted) // FILTER soft-deleted
      .toList();
  entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return entries;
}

// Same for getEntriesForDate, getEntriesForPeriod
```

### Common Operation 4: Edit Reflection Answers

```dart
// In ReflectionService
Future<void> updateAnswer({
  required String answerId,
  required String newAnswerText,
}) async {
  final answer = _answers.get(answerId);
  if (answer == null) return;

  final updated = ReflectionAnswer(
    id: answer.id,
    entryId: answer.entryId,
    questionId: answer.questionId,
    questionText: answer.questionText,
    answer: newAnswerText,
    createdAt: answer.createdAt,
  );

  await _answers.put(answerId, updated);
}

Future<void> deleteAnswer(String answerId) async {
  await _answers.delete(answerId);
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Scaffold.of(context).showSnackBar | ScaffoldMessenger.of(context).showSnackBar | Flutter 2.0 (2021) | SnackBars now persist across routes |
| @HiveType annotations | Manual TypeAdapters | Project decision | More control over migration, matches CLAUDE.md pattern |
| Hard delete only | Soft delete with retention | User requirement | Safer UX, allows undo window |
| Separate update methods | Single updateEntry() | Best practice | Maintains consistency, simpler API |

**Deprecated/outdated:**
- `Scaffold.of(context).showSnackBar()`: Use ScaffoldMessenger instead
- Changing Hive typeId after deployment: Never allowed, causes data corruption

## Open Questions

1. **Should we add long-press context menu on history cards?**
   - What we know: User marked this as "Claude's discretion" in CONTEXT.md
   - What's unclear: Whether users prefer quick access vs. preventing accidental taps
   - Recommendation: Start without it (simpler), add if user feedback requests it

2. **How should reflection editing UI work?**
   - What we know: User can edit existing answers AND add new ones (up to 3 total)
   - What's unclear: Inline expand in entry detail vs. modal sheet vs. separate screen
   - Recommendation: Modal bottom sheet with list of answers + "Add new" button (matches app pattern)

3. **Should mood slider be extracted to reusable widget?**
   - What we know: Needs to be reused in entry detail edit mode
   - What's unclear: Whether to extract now or wait for more reuse cases
   - Recommendation: Extract now to `lib/widgets/mood_slider_widget.dart` — prevents duplication

## Validation Architecture

> Note: workflow.nyquist_validation is false in config.json — validation section included for completeness

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (sdk) |
| Config file | none (Flutter default test setup) |
| Quick run command | `flutter test test/entry_management_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ENTRY-01 | Edit mood value updates entry in Hive | unit | `flutter test test/entry_management_test.dart --name "edit mood"` | ❌ Wave 0 |
| ENTRY-02 | Edit intention updates entry in Hive | unit | `flutter test test/entry_management_test.dart --name "edit intention"` | ❌ Wave 0 |
| ENTRY-03 | Edit/add reflection answers (max 3) | unit | `flutter test test/entry_management_test.dart --name "edit reflections"` | ❌ Wave 0 |
| ENTRY-04 | Delete shows dialog, soft-deletes on confirm | widget | `flutter test test/entry_detail_test.dart --name "delete confirmation"` | ❌ Wave 0 |
| ENTRY-05 | Undo restores soft-deleted entry within 5s | integration | `flutter test test/soft_delete_test.dart --name "undo"` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/entry_management_test.dart` (unit tests only)
- **Per wave merge:** `flutter test` (full suite)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/entry_management_test.dart` — covers ENTRY-01, ENTRY-02, ENTRY-03 (service layer)
- [ ] `test/entry_detail_test.dart` — covers ENTRY-04 (widget interaction)
- [ ] `test/soft_delete_test.dart` — covers ENTRY-05 (undo flow)
- [ ] `test/test_helpers.dart` — Hive test setup, mock data generators

## Sources

### Primary (HIGH confidence)

- [Flutter StatefulWidget documentation](https://docs.flutter.dev/learn/pathway/tutorial/stateful-widget) - Official Flutter docs, updated 2026-02-05
- [Flutter SnackBar cookbook](https://docs.flutter.dev/cookbook/design/snackbars) - Official Flutter cookbook
- [Flutter ScaffoldMessenger migration](https://docs.flutter.dev/release/breaking-changes/scaffold-messenger) - Official breaking change guide
- [Hive TypeAdapter API](https://pub.dev/documentation/hive/latest/hive/TypeAdapter-class.html) - Official Hive documentation
- [ScaffoldMessenger API reference](https://api.flutter.dev/flutter/material/ScaffoldMessenger-class.html) - Official Flutter API docs

### Secondary (MEDIUM confidence)

- [GitHub: Hive versioning discussion #887](https://github.com/isar/hive/issues/887) - Community issue with versioning patterns
- [GitHub: Adding new field to Hive Object #781](https://github.com/isar/hive/issues/781) - Backward compatibility examples
- [GitHub: Hive field default values #125](https://github.com/isar/hive/issues/125) - Default value support discussion
- [Flutter memory leak prevention guide](https://devharshmittal.medium.com/flutter-memory-leaks-causes-prevention-and-best-practices-with-code-examples-df089566736e) - Community best practices
- [Mastering dispose() in Flutter](https://mailharshkhatri.medium.com/mastering-the-dispose-method-in-flutter-a-deep-dive-c71331550e3b) - Deep dive on lifecycle
- [Flutter Performance Optimization 2026](https://dev.to/techwithsam/flutter-performance-optimization-2026-make-your-app-10x-faster-best-practices-2p07) - Recent performance guide
- [Custom Hive Adapters guide](https://dev.to/dinko7/beyond-code-generation-crafting-custom-hive-adapters-1p33) - Manual adapter patterns
- [Flutter TextField validation guide](https://codewithandrea.com/articles/flutter-text-field-form-validation/) - Form patterns

### Tertiary (LOW confidence)

- None — all findings verified with official documentation or multiple community sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All packages already in project, versions confirmed in pubspec.yaml
- Architecture: HIGH - Patterns align with existing codebase (StatefulWidget + Services per CLAUDE.md)
- Pitfalls: HIGH - All based on official docs and verified community experiences
- Hive migration: MEDIUM - Community-driven patterns, official docs limited on versioning
- Testing: MEDIUM - Flutter test framework confirmed, but no existing test suite to reference

**Research date:** 2026-02-26
**Valid until:** 2026-03-26 (30 days for stable Flutter/Hive ecosystem)
