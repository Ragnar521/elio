# Phase 5: Smart Nudges - Context

**Gathered:** 2026-02-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Intelligent, non-intrusive in-app nudges based on user patterns and dormant directions. Three nudge types: dormant direction reminders, mood pattern highlights, and streak milestone celebrations. All nudges must be dismissible and follow Elio's no-guilt design philosophy. Push notifications and settings UI for nudge preferences are out of scope.

</domain>

<decisions>
## Implementation Decisions

### Nudge Placement
- Nudges blend in with existing card styles (same surface color, similar visual treatment as other cards like weekly summary)
- Tapping a nudge can optionally navigate to a relevant screen (Claude decides per nudge type)
- Subtle CTA text where appropriate (e.g., "Reconnect →") — no pushy buttons

### Trigger Timing
- Dormant direction nudges: evaluated on app open
- Streak celebrations and mood pattern nudges: evaluated after check-in completion
- Brief cooldown after check-in before showing informational nudges — only celebrations show immediately post-check-in
- Streak milestones at specific numbers: 3, 7, 14, 30, 60, 100 days

### Content & Tone
- **Mood patterns (mixed specificity):** Use numbers for positive patterns ("Your mood is 15% higher on days you reflect"), gentle/soft language for tougher patterns ("Mornings seem harder lately") — no guilt-inducing data on negative trends
- **Streak celebrations (warm & brief):** Short, calm messages like "7 days in a row. You're building something." — matches Elio's mindful tone, no exclamation-heavy or confetti-style language
- **Dormant directions (curious invitation):** "It's been a while since you connected with Health. Still on your mind?" — no pressure, no data-driven guilt, just a gentle reminder

### Claude's Discretion
- Specific placement of nudges (Home screen cards, inline banners, or contextual placement per nudge type)
- Whether to show one nudge at a time or allow stacking (2-3 max)
- Repeat/cooldown logic for nudge types (how long before a dismissed nudge can reappear)
- Navigation targets per nudge type (which screen tapping navigates to, if any)
- Exact nudge copy and message variations

</decisions>

<specifics>
## Specific Ideas

- Celebration style should feel like Elio's existing confirmation screen affirmations ("You showed up.", "Noted.") — warm, understated, not performative
- Direction nudges use the direction's emoji + title for personalization
- Pattern nudges should feel like a friend noticing something, not a dashboard alert

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-smart-nudges*
*Context gathered: 2026-02-26*
