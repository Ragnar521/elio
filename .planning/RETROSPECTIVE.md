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

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v2.0 | 6 | 13 | First milestone with GSD workflow — structured planning, verification, audit |

### Cumulative Quality

| Milestone | LOC | Files Modified | Tech Debt Items |
|-----------|-----|----------------|-----------------|
| v2.0 | 12,909 | 71 | 5 (all informational) |

### Top Lessons (Verified Across Milestones)

1. Data layer → UI layer split per phase keeps plans focused and reduces coupling
2. Foundation widgets before integration work prevents duplication and ensures consistency
