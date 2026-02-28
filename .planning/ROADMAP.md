# Roadmap: Elio

## Milestones

- ✅ **v2.0 The Proper App** — Phases 1-6 (shipped 2026-02-27)
- 🚧 **v2.1 Demo Mode** — Phases 7-9 (in progress)

## Phases

<details>
<summary>✅ v2.0 The Proper App (Phases 1-6) — SHIPPED 2026-02-27</summary>

- [x] Phase 1: Entry Management (2/2 plans) — completed 2026-02-26
- [x] Phase 2: Search & Filter (2/2 plans) — completed 2026-02-26
- [x] Phase 3: Calendar Visualization (2/2 plans) — completed 2026-02-26
- [x] Phase 4: Weekly Summaries (2/2 plans) — completed 2026-02-26
- [x] Phase 5: Smart Nudges (2/2 plans) — completed 2026-02-27
- [x] Phase 6: UX Polish (3/3 plans) — completed 2026-02-27

</details>

### 🚧 v2.1 Demo Mode (In Progress)

**Milestone Goal:** Add demo/showcase mode with realistic sample data so the app can be demonstrated with a full, lived-in feel.

- [x] **Phase 7: Sample Data Engine** — Build realistic data generator covering all features
- [ ] **Phase 8: Launcher Screen** — Pre-onboarding choice between demo and fresh start
- [ ] **Phase 9: Reset Mechanism** — Triple-tap Home icon to wipe and return to launcher

## Phase Details

### Phase 7: Sample Data Engine
**Goal:** App has realistic sample data that showcases all features
**Depends on:** Phase 6 (completed)
**Requirements:** DATA-01, DATA-02, DATA-03, DATA-04, DATA-05
**Success Criteria** (what must be TRUE):
  1. Demo mode loads ~90 days of entries with realistic mood patterns (lower Mondays, higher weekends, occasional gaps)
  2. Sample data includes varied reflections across all 9 categories with natural language
  3. Sample data includes 3-4 active directions with realistic connections to entries
  4. Weekly summaries are pre-generated and display trends from sample entries
  5. Current streak and longest streak reflect realistic check-in patterns from sample data
**Plans:** 2 plans
- [x] 07-01-PLAN.md — Core sample data service (entries, reflections, directions, connections, streaks)
- [x] 07-02-PLAN.md — Weekly summaries + visual verification

### Phase 8: Launcher Screen
**Goal:** Users can choose between sample data demo and fresh start before onboarding
**Depends on:** Phase 7
**Requirements:** LAUNCH-01, LAUNCH-02, LAUNCH-03
**Success Criteria** (what must be TRUE):
  1. First app open shows launcher screen with clear "Use sample data" and "Start fresh" options
  2. Selecting "Start fresh" launches normal onboarding flow as before
  3. Selecting "Use sample data" skips onboarding, sets name to "Alex", loads demo data, and lands on main app (Home tab)
  4. App remembers user's choice and never shows launcher again unless reset
**Plans:** 1 plan
- [ ] 08-01-PLAN.md — Launcher screen UI + app gate wiring

### Phase 9: Reset Mechanism
**Goal:** Users can wipe all data and return to launcher for re-demonstration
**Depends on:** Phase 8
**Requirements:** RESET-01
**Success Criteria** (what must be TRUE):
  1. Triple-tapping the Home icon immediately wipes all data (entries, directions, summaries, settings)
  2. After wipe, app returns to launcher screen with fresh state
  3. User can choose demo or fresh start again after reset
**Plans:** TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Entry Management | v2.0 | 2/2 | Complete | 2026-02-26 |
| 2. Search & Filter | v2.0 | 2/2 | Complete | 2026-02-26 |
| 3. Calendar Visualization | v2.0 | 2/2 | Complete | 2026-02-26 |
| 4. Weekly Summaries | v2.0 | 2/2 | Complete | 2026-02-26 |
| 5. Smart Nudges | v2.0 | 2/2 | Complete | 2026-02-27 |
| 6. UX Polish | v2.0 | 3/3 | Complete | 2026-02-27 |
| 7. Sample Data Engine | v2.1 | 2/2 | Complete | 2026-02-28 |
| 8. Launcher Screen | v2.1 | 0/1 | Planned | — |
| 9. Reset Mechanism | v2.1 | 0/0 | Not started | — |

---
*Roadmap created: 2026-02-26*
*Last updated: 2026-02-28 after Phase 7 completion*
