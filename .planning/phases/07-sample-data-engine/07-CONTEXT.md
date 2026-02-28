# Phase 7: Sample Data Engine - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Build a realistic sample data generator that creates ~90 days of entries, reflections, directions, weekly summaries, and streaks. The data should make the app look "lived-in" for demonstration purposes. This phase only creates the data generator/dataset — the launcher screen (Phase 8) and reset mechanism (Phase 9) are separate.

</domain>

<decisions>
## Implementation Decisions

### Mood patterns & realism
- Claude's discretion on overall mood arc (subtle improvement, natural variation, or mixed)
- Light gaps: ~10-15 missed days out of 90 (~75-80% check-in rate)
- Strong, obvious day-of-week pattern — lower Mondays, higher weekends — so the Insights day pattern chart looks compelling during demo
- Occasional double entries on ~5-10 days (morning + evening check-ins)

### Demo persona
- Alex is a coherent person with a consistent life story, not generic sample text
- Alex is a young professional — early career, balancing work growth with health and relationships
- Alex is male — entries can lightly reference this where natural
- Entries reference specific people by name (e.g., "Sarah", "Tom", "Mom") to feel personal and real
- Directions, intentions, and reflections should tell a consistent story across the 90 days

### Content quality
- Each entry gets a unique, hardcoded intention (no pool/rotation — maximum variety)
- Reflection answers should feel natural and conversational — like someone typing on their phone ("good run today", casual phrasing, sometimes short, sometimes thoughtful)
- English only — no localization considerations
- ~70-80% of entries include reflections; some entries have none (shows the feature is optional)

### Data volume & coverage
- Claude's discretion on number of active directions (roadmap says 3-4)
- Uneven, realistic distribution of direction connections — some directions heavily used (e.g., Career), others lighter (e.g., Peace) — creates interesting mood correlation differences
- Claude's discretion on streak values (current and longest) — pick what looks best on the home screen
- Varying reflection count per entry on reflection days: most days 1, some days 2, rare days 3
- Reflections should cover all 9 categories across the dataset

### Claude's Discretion
- Overall mood arc shape (improvement, dip-recovery, or natural variation)
- Number of active directions (3 or 4)
- Specific direction types and custom titles for Alex
- Current streak and longest streak values
- Weekly summary content and trends
- Exact distribution of mood words across the value range
- Technical approach (hardcoded data file vs generator function)

</decisions>

<specifics>
## Specific Ideas

- Alex is a young professional — think someone 1-2 years into their first "real" job, navigating career growth, staying healthy, maintaining friendships
- References specific people: Sarah (girlfriend/partner), Tom (work colleague/friend), Mom, maybe a gym buddy or roommate
- The day pattern chart should be a standout visual during demo — make Monday/weekend difference obvious
- Double entries on some days suggest Alex sometimes checks in morning and evening — shows the feature naturally

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-sample-data-engine*
*Context gathered: 2026-02-28*
