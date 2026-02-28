# Phase 3: Calendar Visualization - Context

**Gathered:** 2026-02-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Calendar heatmap view showing mood patterns at a glance. Users see color-coded days on a monthly grid, tap days to view entries, and navigate between months. Lives inside the existing Insights tab. No new tabs, no new data entry — visualization only.

</domain>

<decisions>
## Implementation Decisions

### Heatmap layout
- Calendar lives inside the Insights tab (not a new tab)
- Rounded squares for each day cell — modern feel with day numbers visible
- Full standard calendar grid layout — 7 columns (Mon-Sun), empty cells for leading/trailing days outside the month
- Weekday header row (M, T, W, T, F, S, S)

### Color mapping
- Use Elio's existing mood color gradient — same color progression as the mood slider (low mood colors → mid → high mood colors)
- Small compact color legend (gradient bar) showing the mood scale, placed near the calendar
- Days with multiple entries: Claude's discretion on whether to use average or another approach
- Days with no entries: Claude's discretion on visual treatment (subtle outline vs dimmed surface)

### Day detail interaction
- Tap a day with entries → bottom sheet (consistent with existing Day Entries Sheet pattern)
- Days with no entries are not tappable — no response on tap
- Selected/tapped day gets a visual highlight (accent border/ring) while the sheet is open
- Bottom sheet content: Claude's discretion on whether to include a mini summary header or just entry list

### Month navigation
- Both arrow buttons AND swipe gestures for month navigation
- Navigation synced with the Insights tab's existing period navigation — changing month updates both
- Today's date gets an accent-colored border ring as a marker
- Navigation stops at the month of the user's first-ever entry — no scrolling past data boundaries
- Cannot navigate past current month into the future

### Claude's Discretion
- Whether calendar respects Week/Month period toggle or always shows full month
- Empty day visual treatment (outline vs dimmed surface)
- Multi-entry day color calculation (average vs highest)
- Bottom sheet content (entry list only vs mini summary + entries)
- Animated transitions between months
- Calendar section positioning within the Insights tab layout
- Day cell sizing and spacing

</decisions>

<specifics>
## Specific Ideas

- Calendar should reuse the existing bottom sheet pattern from the Day Pattern Chart (Day Entries Sheet) for consistency
- Arrow navigation should match the existing Insights period nav look and feel (left/right arrows flanking a label)
- The heatmap colors should feel immediately familiar since they match the mood slider the user already knows

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-calendar-visualization*
*Context gathered: 2026-02-26*
