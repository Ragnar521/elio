# Roadmap: Elio v2.0

## Overview

Elio v2.0 transforms a functional mood tracking prototype into a polished, App Store-ready product. Starting with foundational CRUD operations (edit/delete entries), we build data access layers (search/filter), add visual pattern recognition (calendar heatmap), create actionable analytics (weekly summaries), implement intelligent engagement (smart nudges), and finish with comprehensive UX polish (animations, loading states, error handling). Each phase builds on the previous, ensuring stable foundations before adding advanced features.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3, 4, 5, 6): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Entry Management** - Complete CRUD operations with edit and safe delete
- [x] **Phase 2: Search & Filter** - Data access layer for finding entries by text, mood, date, direction
- [x] **Phase 3: Calendar Visualization** - Heatmap view with day-level mood patterns (completed 2026-02-26)
- [x] **Phase 4: Weekly Summaries** - Automated recaps with trends and actionable takeaways (completed 2026-02-26)
- [ ] **Phase 5: Smart Nudges** - Intelligent in-app nudges based on patterns and dormant directions
- [ ] **Phase 6: UX Polish** - Premium animations, loading states, error handling, App Store readiness

## Phase Details

### Phase 1: Entry Management
**Goal**: Users can safely edit and delete their mood entries
**Depends on**: Nothing (first phase)
**Requirements**: ENTRY-01, ENTRY-02, ENTRY-03, ENTRY-04, ENTRY-05
**Success Criteria** (what must be TRUE):
  1. User can edit mood value and mood word on any existing entry
  2. User can edit intention text on any existing entry
  3. User can edit or add reflection answers on any existing entry
  4. User can delete an entry with confirmation dialog and sees undo option
  5. Deleted entries can be recovered within 30-day soft delete window
**Plans**: 2 plans

Plans:
- [x] 01-01-PLAN.md — Data layer: Entry model schema evolution + StorageService/ReflectionService CRUD methods
- [x] 01-02-PLAN.md — UI layer: EntryDetailScreen edit/delete modes + HistoryScreen refresh

### Phase 2: Search & Filter
**Goal**: Users can find specific entries using text search and filter criteria
**Depends on**: Phase 1
**Requirements**: SRCH-01, SRCH-02, SRCH-03, SRCH-04, SRCH-05
**Success Criteria** (what must be TRUE):
  1. User can search entries by typing keywords that match intention or reflection text
  2. User can filter entries to show only low, mid, or high mood ranges
  3. User can filter entries to show only those within a custom date range
  4. User can filter entries to show only those connected to a specific direction
  5. User can combine multiple filters (e.g., high mood entries from last month with "work" keyword)
**Plans**: 2 plans

Plans:
- [x] 02-01-PLAN.md — Data layer: EntryFilter model + FilterService with keyword, mood, date, direction filtering
- [x] 02-02-PLAN.md — UI layer: DebouncedSearchBar widget + HistoryScreen search/filter integration

### Phase 3: Calendar Visualization
**Goal**: Users can see mood patterns at a glance via calendar heatmap
**Depends on**: Phase 2
**Requirements**: VISP-01, VISP-02, VISP-03, VISP-04
**Success Criteria** (what must be TRUE):
  1. User can view a calendar heatmap where each day is color-coded by average mood value
  2. User can tap any day on the calendar to see all entries from that day
  3. User can navigate between months to view historical mood patterns
  4. User can instantly identify which days have entries (colored) versus no entries (empty)
**Plans**: 2 plans

Plans:
- [ ] 03-01-PLAN.md — Widget layer: CalendarHeatmap custom widget with mood-colored grid, navigation, and color legend
- [ ] 03-02-PLAN.md — Integration layer: InsightsScreen calendar state, DayEntriesSheet wiring, period sync

### Phase 4: Weekly Summaries
**Goal**: Users receive automated weekly recaps that make their data actionable
**Depends on**: Phase 3
**Requirements**: SUMM-01, SUMM-02, SUMM-03, SUMM-04
**Success Criteria** (what must be TRUE):
  1. User sees a weekly summary recap automatically after completing a full week of check-ins
  2. Weekly summary displays mood trend graph, average mood, and highlights from the week
  3. Weekly summary surfaces which directions received most attention and any correlation patterns
  4. Weekly summary includes at least one actionable takeaway or encouraging message
**Plans**: 2 plans

Plans:
- [x] 04-01-PLAN.md — Data layer: WeeklySummary model (typeId 7) + WeeklySummaryService with generation, detection, and persistence
- [x] 04-02-PLAN.md — UI layer: WeeklySummaryScreen, Home screen card, Insights tab history

### Phase 5: Smart Nudges
**Goal**: Users receive helpful, non-intrusive nudges based on their patterns
**Depends on**: Phase 4
**Requirements**: NUDG-01, NUDG-02, NUDG-03, NUDG-04
**Success Criteria** (what must be TRUE):
  1. User sees an in-app nudge when any direction has zero connections for 7 or more days
  2. User sees an in-app nudge highlighting actionable mood patterns (e.g., "Mornings trending lower this week")
  3. User sees an in-app nudge celebrating streak milestones and check-in consistency
  4. All nudges are dismissible with one tap and never guilt-inducing (supportive tone only)
**Plans**: TBD

Plans:
- [ ] TBD

### Phase 6: UX Polish
**Goal**: Every screen feels premium with smooth animations, helpful states, and App Store compliance
**Depends on**: Phase 5
**Requirements**: UXPL-01, UXPL-02, UXPL-03, UXPL-04, UXPL-05, UXPL-06
**Success Criteria** (what must be TRUE):
  1. All screen transitions use smooth, consistent animations (300ms timing with appropriate curves)
  2. Loading operations show shimmer placeholders instead of blank screens or spinners
  3. Every screen displays a meaningful empty state with clear guidance when no data exists
  4. Error conditions show user-friendly messages with recovery actions (no stack traces or crashes)
  5. All screens adhere to design system (correct spacing, border radius, colors, typography)
  6. Interactive elements (buttons, cards, toggles) have micro-animations that provide tactile feedback
**Plans**: TBD

Plans:
- [ ] TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Entry Management | 2/2 | Complete | 2026-02-26 |
| 2. Search & Filter | 2/2 | Complete | 2026-02-26 |
| 3. Calendar Visualization | 2/2 | Complete   | 2026-02-26 |
| 4. Weekly Summaries | 0/TBD | Not started | - |
| 5. Smart Nudges | 0/TBD | Not started | - |
| 6. UX Polish | 0/TBD | Not started | - |

---
*Roadmap created: 2026-02-26*
*Last updated: 2026-02-26 after Phase 2 completion*
