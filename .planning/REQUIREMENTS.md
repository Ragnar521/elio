# Requirements: Elio v2.0

**Defined:** 2026-02-26
**Core Value:** Users can quickly check in with their mood and intentions, then understand what their data means through summaries, nudges, and visual patterns.

## v1 Requirements

Requirements for v2.0 release. Each maps to roadmap phases.

### Entry Management

- [x] **ENTRY-01**: User can edit mood value and mood word on an existing entry
- [x] **ENTRY-02**: User can edit intention text on an existing entry
- [x] **ENTRY-03**: User can edit or add reflection answers on an existing entry
- [x] **ENTRY-04**: User can delete an entry with confirmation dialog
- [x] **ENTRY-05**: User can undo a deletion within a short time window (soft delete)

### Search & Filter

- [x] **SRCH-01**: User can search entries by keyword matching intention or reflection text
- [x] **SRCH-02**: User can filter entries by mood range (e.g., low/mid/high)
- [x] **SRCH-03**: User can filter entries by date range
- [x] **SRCH-04**: User can filter entries by connected direction
- [x] **SRCH-05**: User can combine search and filter criteria

### Visual Patterns

- [x] **VISP-01**: User can view a calendar heatmap of mood entries color-coded by mood value
- [ ] **VISP-02**: User can tap a day on the calendar to see that day's entries
- [ ] **VISP-03**: User can navigate between months on the calendar view
- [x] **VISP-04**: User can see at a glance which days have entries and which don't

### Weekly Summaries

- [ ] **SUMM-01**: User sees a weekly summary recap after completing a full week of entries
- [ ] **SUMM-02**: Weekly summary shows mood trend, average, and highlights
- [ ] **SUMM-03**: Weekly summary surfaces top direction connections and patterns
- [ ] **SUMM-04**: Weekly summary includes actionable takeaway or encouragement

### Smart Nudges

- [ ] **NUDG-01**: User sees in-app nudge when a direction has no connections for 7+ days
- [ ] **NUDG-02**: User sees in-app nudge highlighting mood patterns (e.g., "Mornings are harder lately")
- [ ] **NUDG-03**: User sees in-app nudge celebrating streaks and consistency
- [ ] **NUDG-04**: Nudges are non-intrusive and dismissible (no-guilt design)

### UX Polish

- [ ] **UXPL-01**: All screen transitions use smooth, consistent animations
- [ ] **UXPL-02**: Loading states use shimmer placeholders instead of blank screens
- [ ] **UXPL-03**: Every screen has a meaningful empty state with guidance
- [ ] **UXPL-04**: Error states show user-friendly messages with recovery actions
- [ ] **UXPL-05**: Design consistency pass — all screens match design system (spacing, radius, colors, typography)
- [ ] **UXPL-06**: Micro-animations for interactive elements (buttons, cards, toggles)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Data Portability

- **EXPRT-01**: User can export all entries as CSV
- **EXPRT-02**: User can export all entries as JSON
- **EXPRT-03**: Export includes reflections and direction connections

### Notifications

- **NOTF-01**: User can set daily check-in reminder time
- **NOTF-02**: User receives local notification at scheduled time
- **NOTF-03**: User can enable/disable notifications from settings

### App Store

- **STORE-01**: Privacy policy page accessible from settings
- **STORE-02**: Health/wellness disclaimer in onboarding or about screen
- **STORE-03**: App Store metadata, screenshots, and description

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Cloud sync / accounts | Local-first privacy philosophy, adds complexity |
| Social sharing | Privacy risk for mental health data, against no-guilt design |
| Photo/voice attachments | Storage bloat, slows check-in flow, scope creep |
| AI therapist / chatbot | Liability risk, not a mental health professional |
| Multiple check-ins per day | Creates obsessive tracking, complicates insights |
| Complex mood scales | Analysis paralysis, keep simple 0.0-1.0 slider |
| Gamification (levels, achievements) | Extrinsic motivation conflicts with no-guilt philosophy |
| Light mode polish | Dark mode is primary, light can follow later |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ENTRY-01 | Phase 1 | Complete |
| ENTRY-02 | Phase 1 | Complete |
| ENTRY-03 | Phase 1 | Complete |
| ENTRY-04 | Phase 1 | Complete |
| ENTRY-05 | Phase 1 | Complete |
| SRCH-01 | Phase 2 | Complete |
| SRCH-02 | Phase 2 | Complete |
| SRCH-03 | Phase 2 | Complete |
| SRCH-04 | Phase 2 | Complete |
| SRCH-05 | Phase 2 | Complete |
| VISP-01 | Phase 3 | Complete |
| VISP-02 | Phase 3 | Pending |
| VISP-03 | Phase 3 | Pending |
| VISP-04 | Phase 3 | Complete |
| SUMM-01 | Phase 4 | Pending |
| SUMM-02 | Phase 4 | Pending |
| SUMM-03 | Phase 4 | Pending |
| SUMM-04 | Phase 4 | Pending |
| NUDG-01 | Phase 5 | Pending |
| NUDG-02 | Phase 5 | Pending |
| NUDG-03 | Phase 5 | Pending |
| NUDG-04 | Phase 5 | Pending |
| UXPL-01 | Phase 6 | Pending |
| UXPL-02 | Phase 6 | Pending |
| UXPL-03 | Phase 6 | Pending |
| UXPL-04 | Phase 6 | Pending |
| UXPL-05 | Phase 6 | Pending |
| UXPL-06 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 28 total
- Mapped to phases: 28
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-26*
*Last updated: 2026-02-26 after roadmap creation*
