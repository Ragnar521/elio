---
phase: 01-entry-management
plan: 01
subsystem: data-layer
tags: [entry-model, hive, soft-delete, crud]
dependency_graph:
  requires: []
  provides:
    - entry-soft-delete
    - entry-update
    - entry-restore
    - answer-update
    - answer-delete
  affects:
    - lib/models/entry.dart
    - lib/services/storage_service.dart
    - lib/services/reflection_service.dart
tech_stack:
  added: []
  patterns:
    - hive-schema-evolution
    - soft-delete-with-cleanup
    - backward-compatible-adapters
key_files:
  created: []
  modified:
    - lib/models/entry.dart
    - lib/services/storage_service.dart
    - lib/services/reflection_service.dart
decisions:
  - Use field indices 6-8 for new Entry fields (never change typeId)
  - 30-day retention for soft-deleted entries
  - Automatic cleanup on app init
  - updateEntry always sets updatedAt timestamp
  - getEntry does not filter by isDeleted (needed for restore flow)
metrics:
  duration_minutes: 2
  tasks_completed: 2
  files_modified: 3
  commits: 2
  completed_at: 2026-02-26
---

# Phase 01 Plan 01: Entry Model Soft Delete & CRUD Summary

**One-liner:** Entry model evolved with backward-compatible soft delete fields, StorageService and ReflectionService extended with full CRUD operations and 30-day cleanup logic.

## Objective

Add soft delete fields to the Entry model and implement update/delete/restore methods in StorageService and ReflectionService. This provides the data layer foundation for editing and deleting entries before the UI can be built.

## Tasks Completed

### Task 1: Evolve Entry model with soft delete fields and update EntryAdapter
**Commit:** 84adc16
**Files:** lib/models/entry.dart

Added three new fields to Entry class:
- `bool isDeleted` (default: false) — field index 6
- `DateTime? deletedAt` (default: null) — field index 7
- `DateTime? updatedAt` (default: null) — field index 8

Updated EntryAdapter:
- `read()` method uses ?? defaults for fields 6-8 to handle old entries
- `write()` method changed field count from 6 to 9
- TypeId unchanged (remains 0)
- Backward-compatible: existing entries load correctly

### Task 2: Add update, soft delete, restore, and cleanup methods to StorageService and ReflectionService
**Commit:** 8a6e6fd
**Files:** lib/services/storage_service.dart, lib/services/reflection_service.dart

**StorageService additions:**
- `updateEntry(Entry entry)` — updates entry with new updatedAt timestamp
- `softDeleteEntry(String entryId)` — marks entry as deleted with deletedAt
- `restoreEntry(String entryId)` — restores soft-deleted entry
- `getEntry(String id)` — retrieves entry by id (doesn't filter by isDeleted)
- `_permanentDeleteOldEntries()` — removes entries deleted >30 days ago, called during init()
- Updated `getAllEntries()`, `getEntriesForDate()`, `getEntriesForPeriod()` to filter out soft-deleted entries

**ReflectionService additions:**
- `updateAnswer({required String answerId, required String newAnswerText})` — edits answer text
- `deleteAnswer(String answerId)` — removes individual answer
- `deleteAnswersForEntry(String entryId)` — cleanup answers when entry is permanently deleted

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

All verification steps passed:
- `flutter analyze lib/models/entry.dart` — No issues found
- `flutter analyze lib/services/storage_service.dart lib/services/reflection_service.dart` — No issues found
- Entry model constructor accepts isDeleted, deletedAt, updatedAt with sensible defaults
- EntryAdapter reads entries without fields 6-8 without crashing (uses ?? defaults)
- getAllEntries filters out isDeleted entries
- softDeleteEntry + restoreEntry are inverse operations

## Technical Implementation Notes

### Hive Schema Evolution
The Entry model evolution follows Hive's best practices for backward compatibility:
1. New fields added with default values in constructor
2. EntryAdapter.read() uses null-aware operators (??) for new fields
3. EntryAdapter.write() increments field count and writes all fields
4. Existing entries (with only 6 fields) load correctly with defaults
5. TypeId never changed (critical for Hive compatibility)

### Soft Delete Pattern
- Entries marked as deleted (isDeleted=true, deletedAt set) remain in database
- All query methods (getAllEntries, getEntriesForDate, getEntriesForPeriod) filter them out
- getEntry() does NOT filter — needed for restore/undo flows
- After 30 days, permanent deletion removes entry + associated reflection answers
- Cleanup runs automatically on app init

### Data Integrity
- Permanent delete cleans up reflection answers via ReflectionService.deleteAnswersForEntry()
- updateEntry always sets updatedAt timestamp
- softDeleteEntry sets both deletedAt and updatedAt
- restoreEntry clears deletedAt and sets updatedAt

## Impact

**Enables:**
- Edit entry flow (Phase 1 Plan 2)
- Delete entry flow with undo (Phase 1 Plan 2)
- Reflection answer editing (Phase 1 Plan 2)

**Dependencies satisfied:**
- ENTRY-01: Edit mood entry
- ENTRY-02: Edit intention
- ENTRY-04: Delete entry with soft delete
- ENTRY-05: Edit reflection answers

**Next steps:**
- Build UI for edit entry screen
- Build UI for delete confirmation
- Add undo snackbar after delete
- Implement reflection answer editing in entry detail

## Self-Check

Verifying all claims in SUMMARY.md:

**Created files:** None expected, none created ✓

**Modified files:**
- lib/models/entry.dart ✓
- lib/services/storage_service.dart ✓
- lib/services/reflection_service.dart ✓

**Commits:**
- 84adc16: feat(01-01): add soft delete fields to Entry model ✓
- 8a6e6fd: feat(01-01): add CRUD operations to StorageService and ReflectionService ✓

**Field verification:**
- Entry has isDeleted field ✓
- Entry has deletedAt field ✓
- Entry has updatedAt field ✓
- StorageService has updateEntry method ✓
- StorageService has softDeleteEntry method ✓
- StorageService has restoreEntry method ✓
- StorageService has getEntry method ✓
- StorageService has _permanentDeleteOldEntries method ✓
- ReflectionService has updateAnswer method ✓
- ReflectionService has deleteAnswer method ✓
- ReflectionService has deleteAnswersForEntry method ✓

## Self-Check: PASSED

All files exist, all commits are in git log, all methods implemented as specified.
