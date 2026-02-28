---
phase: 02-search-filter
plan: 01
subsystem: search-filter
tags: [data-layer, filtering, search]
dependency_graph:
  requires: []
  provides:
    - EntryFilter model for filter criteria state
    - FilterService for in-memory entry filtering
    - MoodRange enum for mood categorization
  affects:
    - History screen (Plan 02 will consume these services)
tech_stack:
  added: []
  patterns:
    - Singleton service pattern
    - Immutable filter model
    - Answer cache for N+1 prevention
key_files:
  created:
    - lib/models/entry_filter.dart
    - lib/services/filter_service.dart
  modified: []
decisions:
  - title: "Synchronous filtering for performance"
    rationale: "In-memory filtering of <1000 entries is faster synchronous than async overhead"
    alternatives: ["Async filtering with FutureBuilder"]
  - title: "Pre-fetch direction connections"
    rationale: "Direction filter requires async lookup, caller pre-fetches and passes Set<String>"
    alternatives: ["Make entire filterEntries async", "Remove direction filter support"]
  - title: "Answer cache to prevent N+1"
    rationale: "Build Map<entryId, answers> once before loop instead of per-entry lookup"
    alternatives: ["Accept O(n) lookups", "Pre-load all answers in service init"]
metrics:
  duration_minutes: 3
  tasks_completed: 2
  files_created: 2
  commits: 2
  completed_at: "2026-02-26"
---

# Phase 02 Plan 01: Search & Filter Data Layer Summary

**One-liner:** Created EntryFilter model and FilterService with keyword search (intention + reflections), mood range filtering (low/mid/high OR logic), date range filtering (inclusive end), and direction filtering via pre-fetched IDs.

## What Was Built

This plan implemented the complete data layer for entry search and filtering, centralizing all filter logic in a testable, synchronous service.

**Key artifacts:**
1. **EntryFilter model** (`lib/models/entry_filter.dart`)
   - Immutable model for filter criteria
   - MoodRange enum with label getter and matches method
   - hasActiveFilters computed property
   - copyWith and cleared methods for state management

2. **FilterService** (`lib/services/filter_service.dart`)
   - Singleton service following project pattern
   - Synchronous filterEntries method for optimal performance
   - Keyword search across intention + reflection answers
   - Answer cache to prevent N+1 lookups
   - Mood range filter with OR logic (any selected range matches)
   - Date range filter with inclusive end date (adds Duration(days: 1))
   - Direction filter via pre-fetched entry ID set
   - Helper method getConnectedEntryIds for async direction lookup

## How It Works

**Filter flow:**
```
1. Caller loads all entries from StorageService
2. If direction filter needed, pre-fetch IDs via getConnectedEntryIds
3. Call filterEntries with EntryFilter criteria
4. Filters apply sequentially (AND logic):
   - Keyword search (if searchQuery set)
   - Mood range filter (if moodRanges not empty)
   - Date range filter (if dateRange set)
   - Direction filter (if directionId + connectedEntryIds provided)
5. Returns filtered list synchronously
```

**Performance optimizations:**
- Answer cache built once per filter operation (prevents N+1 queries)
- Synchronous execution (no async overhead for in-memory operations)
- Short-circuit on intention match (doesn't check reflections unnecessarily)

## Requirements Fulfilled

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| SRCH-01 | ✅ | Keyword search via _filterByKeyword with answer cache |
| SRCH-02 | ✅ | Mood range filter using MoodRange.matches with OR logic |
| SRCH-03 | ✅ | Date range filter with inclusive end (add Duration(days: 1)) |
| SRCH-04 | ✅ | Direction filter via pre-fetched connected entry ID set |
| SRCH-05 | ✅ | Combined filters with sequential AND logic |

## Deviations from Plan

None - plan executed exactly as written.

## Key Decisions

**1. Synchronous filtering for performance**
- **Context:** Research showed in-memory filtering of <1000 entries takes <5ms
- **Decision:** Made filterEntries synchronous, only getConnectedEntryIds is async
- **Impact:** Simpler code, better performance, easier testing

**2. Pre-fetch direction connections**
- **Context:** DirectionService.getConnectedEntries is async, but we want synchronous filtering
- **Decision:** Caller pre-fetches connected entry IDs and passes as Set<String>
- **Impact:** Keeps filterEntries synchronous, clear separation of concerns

**3. Answer cache to prevent N+1**
- **Context:** Calling getAnswersByIds in loop would be O(n) lookups
- **Decision:** Build Map<entryId, answers> once before filter loop
- **Impact:** Better performance for keyword search, especially with many reflections

## Testing Notes

**Manual verification:**
- ✅ dart analyze reports no errors for both files
- ✅ MoodRange enum has low/mid/high with correct boundaries (0.33, 0.66)
- ✅ EntryFilter has hasActiveFilters, copyWith, cleared methods
- ✅ FilterService uses answer cache (lines 72-76, 91-92)
- ✅ Date range filter adds Duration(days: 1) to end (line 50)
- ✅ Direction filter uses pre-fetched entry ID set (lines 15-17, 59-62)

**What to test in Plan 02 (HistoryScreen integration):**
- Keyword search matches intention text (case-insensitive)
- Keyword search matches reflection answer text
- Multiple mood ranges selected (OR logic works)
- Date range includes entries from end date (inclusive check)
- Direction filter shows only connected entries
- Combining all filters narrows results correctly (AND logic)

## Next Steps

Plan 02 will integrate this data layer into HistoryScreen by:
1. Adding search bar with debounce (300ms)
2. Adding filter chips for mood ranges and directions
3. Adding date range picker
4. Managing filter state in HistoryScreen
5. Calling FilterService.filterEntries on state changes
6. Displaying filtered results in existing ListView

## Self-Check: PASSED

**Files created:**
- ✅ lib/models/entry_filter.dart exists
- ✅ lib/services/filter_service.dart exists

**Commits exist:**
- ✅ 78d85c7: feat(02-search-filter): create EntryFilter model and MoodRange enum
- ✅ b54a675: feat(02-search-filter): create FilterService with all filter methods

**Functionality verified:**
- ✅ MoodRange enum has matches method and label getter
- ✅ EntryFilter has hasActiveFilters, copyWith, cleared
- ✅ FilterService singleton exists with filterEntries method
- ✅ Answer cache prevents N+1 lookups
- ✅ Date range filter is inclusive of end date
- ✅ Direction filter uses pre-fetched ID set
- ✅ No dart analyze errors
