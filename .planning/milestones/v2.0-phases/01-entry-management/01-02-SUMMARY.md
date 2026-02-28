---
phase: 01-entry-management
plan: 02
subsystem: ui-layer
tags: [entry-edit, entry-delete, undo-flow, stateful-widget]
dependency_graph:
  requires:
    - entry-soft-delete
    - entry-update
    - entry-restore
    - answer-update
  provides:
    - entry-edit-ui
    - entry-delete-ui
    - undo-snackbar
  affects:
    - lib/screens/entry_detail_screen.dart
    - lib/screens/history_screen.dart
tech_stack:
  added: []
  patterns:
    - stateful-widget-edit-mode
    - in-place-editing
    - confirmation-dialog
    - undo-with-snackbar
    - callback-refresh-pattern
key_files:
  created: []
  modified:
    - lib/screens/entry_detail_screen.dart
    - lib/screens/history_screen.dart
decisions:
  - Edit mode uses in-place toggle (no separate screen)
  - AppBar icons follow user decision (edit/delete in view, close/check in edit)
  - Delete requires confirmation dialog before soft delete
  - Undo snackbar shows for 5 seconds on history screen
  - History always refreshes on return from detail (handles all cases)
  - Mood slider uses same word mapping as mood entry flow
  - Reflection editing supports both modifying existing and adding new (up to 3 total)
metrics:
  duration_minutes: 4
  tasks_completed: 2
  files_modified: 2
  commits: 2
  completed_at: 2026-02-26
---

# Phase 01 Plan 02: Entry Detail Edit & Delete UI Summary

**One-liner:** Converted EntryDetailScreen to StatefulWidget with in-place edit mode toggle, mood slider, intention editing, reflection management (edit + add), delete confirmation dialog with 5-second undo snackbar, and auto-refreshing history.

## Objective

Convert EntryDetailScreen from StatelessWidget to StatefulWidget with view/edit toggle and delete-with-undo flow. Update HistoryScreen to refresh data when returning from detail.

## Tasks Completed

### Task 1: Convert EntryDetailScreen to StatefulWidget with edit mode and delete flow
**Commit:** 35d71b3
**Files:** lib/screens/entry_detail_screen.dart

Rewrote EntryDetailScreen from StatelessWidget to StatefulWidget with full edit/delete capabilities:

**State Management:**
- `_isEditMode` toggles between view and edit modes
- `_intentionController` for intention text editing
- `_editedMoodValue` and `_editedMoodWord` track mood changes
- `_reflectionAnswers` loaded from ReflectionService
- `_currentEntry` tracks latest entry state after saves
- `_hasChanges` signals history refresh on pop
- `_answerControllers` map manages TextEditingControllers for existing answers
- `_newAnswers` list tracks newly added reflections (not yet saved)

**AppBar (User-Locked Decisions):**
- View mode: back arrow, "Entry Details" title, edit pencil icon, delete trash icon
- Edit mode: back arrow, "Edit Entry" title, close icon (cancel), check icon (save)

**View Mode:**
- Displays mood card with color dot, mood word, intensity bar
- Shows intention text in card
- Lists all reflection Q&A pairs in cards
- Same visual design as before

**Edit Mode:**
- **Mood section:** Horizontal slider (0.0-1.0) with real-time mood word updates, color glow animation
- **Intention section:** TextField (max 100 chars, 3 lines) replacing static text
- **Reflections section:**
  - Each existing answer shown as editable TextField (max 200 chars, 3 lines)
  - Question text read-only and muted
  - Controllers stored in `_answerControllers` map
- **Add reflection button:** Shows if total reflections < 3
  - Fetches next available question from ReflectionService
  - Adds new answer card with autofocus
  - Tracked separately in `_newAnswers` list

**Save Flow (`_saveChanges`):**
1. Creates updated Entry with edited mood value, mood word, intention
2. Calls `StorageService.instance.updateEntry(updatedEntry)`
3. For each existing answer that changed: calls `ReflectionService.instance.updateAnswer(...)`
4. For each new answer: calls `ReflectionService.instance.saveAnswer(...)`, adds returned ID to entry's reflectionAnswerIds
5. If new answers added, updates entry again with new IDs
6. Reloads reflection answers to show updated data
7. Sets `_isEditMode = false`, `_hasChanges = true`
8. Disposes new answer controllers, clears list
9. Rebuilds UI in view mode

**Cancel Flow (`_cancelEdit`):**
1. Resets `_intentionController.text` to `_currentEntry.intention`
2. Resets `_editedMoodValue` and `_editedMoodWord` to current values
3. Resets all reflection answer controllers to original values
4. Disposes and clears new answer controllers
5. Sets `_isEditMode = false`, rebuilds

**Delete Flow (`_showDeleteDialog`):**
1. Shows AlertDialog with "Delete entry?" title, confirmation text
2. Cancel button (pops dialog returning false)
3. Delete button in red/accent color (pops dialog returning true)
4. If confirmed and mounted:
   - Calls `StorageService.instance.softDeleteEntry(_currentEntry.id)`
   - Captures ScaffoldMessenger and Navigator references before popping
   - Pops detail screen with result `true`
   - Shows SnackBar on history screen's scaffold:
     - Content: "Entry deleted"
     - Duration: 5 seconds
     - Action: SnackBarAction "Undo" calls `restoreEntry()` + `widget.onUndoDelete?.call()`

**Mood Word Mapping:**
- Reuses exact same logic as `mood_entry_screen.dart`
- 8 mood words: Heavy, Tired, Flat, Okay, Calm, Good, Energized, Great
- Maps via `(value * 7).round()` to index into array

**Resource Management:**
- All TextEditingControllers properly disposed in `dispose()`
- PopScope (replaces WillPopScope) handles back button with `_hasChanges` signal

**Design System Compliance:**
- Cards: 18px border radius, ElioColors.darkSurface background
- Spacing: 24px between sections, 12px between elements
- Text: ElioColors.darkPrimaryText for main text, withOpacity(0.6) for labels
- Accent: ElioColors.darkAccent for interactive elements
- Mood glow: Color.lerp from low (0xFF4B5A68) to high (ElioColors.darkAccent)

### Task 2: Update HistoryScreen to refresh on return from detail and support undo restore
**Commit:** cff8446
**Files:** lib/screens/history_screen.dart

Updated HistoryScreen navigation to EntryDetailScreen to handle result and refresh data:

**Changes:**
1. Changed `Navigator.push()` to `await Navigator.push<bool>()`
2. Added `onUndoDelete` callback parameter to EntryDetailScreen constructor
3. Callback triggers `setState(() { _historyFuture = _loadData(); })` when undo tapped
4. Always reloads data after returning from detail screen (regardless of result)
5. Handles all cases: edit saves, delete with pop, and undo restore

**Flow:**
- User taps entry in history → navigates to EntryDetailScreen
- User edits entry and saves → returns to history, data reloads
- User deletes entry → confirms deletion, returns to history with snackbar, data reloads
- User taps Undo on snackbar → entry restored, callback triggers history reload

**Result:**
- History screen always shows latest data after any interaction
- No stale entries shown after edit
- Deleted entries disappear immediately
- Undone entries reappear immediately

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

All verification steps passed:
- `flutter analyze` shows only cosmetic deprecation warnings (withOpacity) consistent with existing codebase
- No errors or use_build_context_synchronously warnings (fixed with proper mounted checks and context capture)
- PopScope replaced WillPopScope (deprecated) for modern Android predictive back support
- Entry detail screen shows edit and delete icons in app bar (view mode)
- Edit mode shows close/cancel and save/checkmark icons
- Mood slider, intention TextField, and reflection editors functional in edit mode
- Save persists all changes via StorageService and ReflectionService
- Cancel restores original values without saving
- Delete shows confirmation dialog with Cancel and Delete buttons
- Confirming delete soft-deletes entry, pops to history, shows 5-second undo snackbar
- Undo restores entry and refreshes history via callback
- History screen shows updated entries after returning from detail

## Technical Implementation Notes

### StatefulWidget Pattern
- Follows existing codebase pattern (no Provider/Bloc)
- State variables track edit mode, edited values, original values
- Controllers properly initialized in initState, disposed in dispose
- Uses setState for UI updates after state changes

### Edit Mode Toggle
- Single boolean `_isEditMode` controls entire UI
- AppBar actions change based on mode (edit/delete vs close/check)
- Body sections conditionally render view or edit widgets
- Cancel button restores original values without database interaction
- Save button persists all changes atomically

### Reflection Editing
- Existing answers: stored in `_reflectionAnswers` list, controllers in `_answerControllers` map
- New answers: tracked separately in `_newAnswers` list (not yet saved to DB)
- Add reflection button fetches next available question from rotation
- Save flow handles both `updateAnswer()` for existing and `saveAnswer()` for new
- Max 3 total reflections enforced (existing + new)

### Delete with Undo Pattern
- Soft delete preserves entry in database with `isDeleted=true`
- ScaffoldMessenger and Navigator captured before async pop (avoids use_build_context_synchronously)
- SnackBar shown on history screen's scaffold after pop
- SnackBar action calls `restoreEntry()` then triggers refresh via callback
- 5-second duration gives user time to undo

### History Refresh Pattern
- Simple callback pattern: parent passes `onUndoDelete` to child
- Child calls callback when undo happens
- Parent always reloads data on return from detail (covers all cases)
- No complex state management needed

### Mood Word Consistency
- Exact same `_moodWords` array as MoodEntryScreen
- Same formula: `(value * (_moodWords.length - 1)).round()`
- Ensures edited mood words match check-in flow words
- Color glow uses same Color.lerp logic

## Impact

**Enables:**
- Users can edit existing entries (mood, intention, reflections)
- Users can delete entries with undo safety net
- Users can add new reflections to existing entries (up to 3 total)
- History screen stays in sync with all changes

**Dependencies satisfied:**
- ENTRY-01: Edit mood entry ✓
- ENTRY-02: Edit intention ✓
- ENTRY-03: View entry history (already existed, now with edit/delete) ✓
- ENTRY-04: Delete entry with soft delete ✓
- ENTRY-05: Edit reflection answers ✓

**UX improvements:**
- In-place editing (no separate screen) feels lightweight
- Confirmation dialog prevents accidental deletes
- 5-second undo window provides safety net
- Visual feedback (mood color glow) during editing
- Autofocus on new reflection answer TextField

**Next steps:**
- Phase 1 complete! Entry management fully functional
- Move to Phase 2: Search & Filter (if in roadmap)
- Consider adding edit history timestamp display in entry detail
- Consider adding "last edited" indicator in history cards

## Self-Check

Verifying all claims in SUMMARY.md:

**Created files:** None expected, none created ✓

**Modified files:**
- lib/screens/entry_detail_screen.dart ✓
- lib/screens/history_screen.dart ✓

**Commits:**
- 35d71b3: feat(01-02): add edit mode and delete with undo to EntryDetailScreen ✓
- cff8446: feat(01-02): update HistoryScreen to refresh on return from detail ✓

**Feature verification:**
- EntryDetailScreen is StatefulWidget ✓
- View/edit mode toggle functional ✓
- Edit mode shows mood slider ✓
- Edit mode shows intention TextField ✓
- Edit mode shows reflection answer TextFields ✓
- Add reflection button appears when < 3 reflections ✓
- Save button persists changes ✓
- Cancel button restores original values ✓
- Delete button shows confirmation dialog ✓
- Delete soft-deletes entry and pops ✓
- Undo snackbar shows for 5 seconds ✓
- Undo restores entry and refreshes history ✓
- History always reloads on return from detail ✓
- All TextEditingControllers disposed ✓
- PopScope signals refresh when changes made ✓

## Self-Check: PASSED

All files exist, all commits are in git log, all features implemented as specified.
