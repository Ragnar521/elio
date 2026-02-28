# Phase 4: Weekly Summaries - Context

**Gathered:** 2026-02-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Automated weekly recaps that make check-in data actionable. Users see mood trends, direction patterns, reflection highlights, and an encouraging takeaway after each week. Summaries are browsable as a history. Smart nudges and notifications are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Summary trigger & entry point
- Card appears on Home screen at the start of a new week (not a modal/overlay)
- Summary also persists in Insights tab for ongoing access
- Scrollable history of all past weekly summaries (not just the latest)
- Tapping the Home card opens the full summary screen

### Summary content & layout
- 3-4 focused sections — not overwhelming but more than just numbers
- Mini mood wave (reuse existing MoodWave component) showing the week's mood trajectory
- 1-2 standout reflection answers surfaced from the week, giving a personal/journaling feel
- Sections: mood overview (wave + stats), direction patterns, reflection highlights, takeaway

### Mood visualization
- Reuse the existing MoodWave widget from Insights for consistency
- Shows each day's mood as dots connected by a line

### Directions & patterns display
- Mini cards for each active direction with mood correlation data
- Each card shows: emoji + title, weekly connection count, mood when connected vs overall
- Highlight the top mood-impact direction with a callout (e.g., "Peace days boosted your mood by 15%")
- If user has no directions: skip directions section and include gentle prompt to create one ("Add a direction to see how your mood connects to what matters")
- Always generate summaries regardless of check-in count (even 1 day gets a summary)

### Takeaways & tone
- Warm encouragement style — feels like a friend, not a coach
- Reference specific moments from the week (e.g., "Your best mood was Thursday when you felt Joyful")
- Supportive language, never guilt-inducing
- Tone adapts to the week's mood patterns (acknowledge tough weeks without forcing positivity)

### Claude's Discretion
- Home card persistence behavior (dismiss after viewed vs persist for the week)
- Headline stats selection and layout (differentiate from existing Insights stat cards)
- Number of takeaway messages per summary (1 vs 2-3)
- Tone for low/negative mood weeks (gentle acknowledgment vs subtle encouragement)
- Dormant directions display (show with gentle note vs hide)
- How to select "standout" reflection answers from the week
- Summary layout when data is sparse (1-2 check-ins in a week)

</decisions>

<specifics>
## Specific Ideas

- Reuse MoodWave widget from Insights — user is already familiar with the visualization
- Direction mini cards should feel similar to existing DirectionCard widget but more compact for summary context
- Takeaway should reference specific entries: "Your best mood was Thursday when you felt Joyful"
- Direction impact highlight: "Peace days boosted your mood by 15% this week"
- No-directions prompt should link to the Directions tab
- Summary always generates — even partial weeks get a recap to encourage consistency

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-weekly-summaries*
*Context gathered: 2026-02-26*
