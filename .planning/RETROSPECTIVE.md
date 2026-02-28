# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v2.0 — The Proper App

**Shipped:** 2026-02-27
**Phases:** 6 | **Plans:** 13 | **Tasks:** 21

### What Was Built
- Full CRUD operations — edit mood/intention/reflections, soft delete with 30-day undo
- Keyword search and multi-criteria filtering (mood range, date, direction, combinable)
- Calendar heatmap visualization with mood-colored grid and day-tap interaction
- Automated weekly summary recaps with mood trends, direction patterns, actionable takeaways
- Smart in-app nudges for dormant directions, mood patterns, and streak celebrations
- Premium UX polish — custom transitions, staggered animations, shimmer loading, empty states, micro-interactions

### What Worked
- Phase-by-phase execution with data layer → UI layer split kept each plan focused and manageable
- Synchronous in-memory filtering was the right call — instant response, no async complexity
- Denormalizing data in weekly summaries prevented stale reference bugs
- AnimatedTap + EmptyStateView as foundation widgets in Phase 6-01 made 6-02 and 6-03 much faster
- Audit before milestone completion caught no gaps — phases were well-verified throughout

### What Was Inefficient
- SUMMARY.md frontmatter `requirements_completed` arrays left empty in most plans — documentation gap that didn't affect functionality but made auditing harder
- ROADMAP.md progress table not updated after phases 4-6 (showed "Not started" for completed work)
- Some phase directories have inconsistent naming (01-entry-management vs 02-search-filter naming convention)

### Patterns Established
- Manual Hive TypeAdapters with explicit field indices (never change typeId, use new indices for schema evolution)
- Singleton service pattern with `instance` getter and `init()` method
- 300ms animation duration as standard timing across transitions
- AnimatedScale with 150ms for press feedback on all interactive elements
- Shimmer loading with 200ms delay to prevent flash for fast loads
- Priority-based content: weekly summary card > nudge card (no stacking)

### Key Lessons
1. Data layer + UI layer as separate plans per phase works well — allows focused execution and clear dependency boundaries
2. Soft delete is worth the complexity for any user-facing data — prevents support issues and builds trust
3. Foundation widget plan (Phase 6-01) before integration plans (6-02, 6-03) dramatically reduces duplication
4. Keep SUMMARY.md frontmatter up to date during execution — retrofitting is tedious and error-prone

### Cost Observations
- Model mix: balanced profile (opus for planning, sonnet/haiku for execution)
- Timeline: 2 calendar days for 6 phases, 13 plans
- Notable: Parallel plan execution within phases significantly accelerated delivery

---

## Milestone: v2.1 — Demo Mode

**Shipped:** 2026-02-28
**Phases:** 3 | **Plans:** 4 | **Tasks:** 7

### What Was Built
- Sample data engine generating ~90 days of realistic entries with mood patterns, reflections, directions, and connections
- Weekly summary generation with trends, direction insights, and unique takeaway messages for Alex persona
- Launcher screen with demo data / fresh start choice before onboarding
- Triple-tap Home icon reset mechanism to wipe all data and return to launcher

### What Worked
- Focused 3-phase milestone with clear dependency chain (data → UI → reset) kept scope tight
- Direct Hive writes bypassing service layer was the right call for backdated timestamps
- Deterministic seeding ensures consistent demo experience — no randomness surprises during showcases
- Reusing OnboardingGate for reset navigation leveraged existing code instead of duplicating logic

### What Was Inefficient
- Phase 07-02 (weekly summaries) took 4047s vs 134s for 07-01 — summary generation logic was more complex than expected
- Could have combined phases 8 and 9 into a single phase — both were small (1 plan each)

### Patterns Established
- Direct Hive box writes for data seeding/migration scenarios (bypassing service DateTime.now())
- Gate pattern for multi-screen app entry (LauncherScreen → OnboardingGate → HomeShell)
- Settings box cleared last in wipe operations to prevent partial state

### Key Lessons
1. Small focused milestones (3 phases) ship fast and cleanly — no scope creep
2. Demo data is more than entries — weekly summaries, directions, connections all needed for a "lived-in" feel
3. Gate patterns (launcher → onboarding → app) compose well when each gate checks its own setting

### Cost Observations
- Model mix: balanced profile
- Timeline: 1 calendar day for 3 phases, 4 plans
- Notable: Entire milestone completed in a single session

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v2.0 | 6 | 13 | First milestone with GSD workflow — structured planning, verification, audit |
| v2.1 | 3 | 4 | Focused demo mode — tight scope, single-day delivery |

### Cumulative Quality

| Milestone | LOC | Files Modified | Tech Debt Items |
|-----------|-----|----------------|-----------------|
| v2.0 | 12,909 | 71 | 5 (all informational) |
| v2.1 | ~14,200 | 5 | 6 (all cosmetic, pre-existing) |

### Top Lessons (Verified Across Milestones)

1. Data layer → UI layer split per phase keeps plans focused and reduces coupling
2. Foundation widgets before integration work prevents duplication and ensures consistency
3. Small focused milestones (3 phases) ship fast with no scope creep
4. Gate patterns compose well when each gate checks its own setting
