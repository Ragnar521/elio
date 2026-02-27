# Phase 6: UX Polish - Context

**Gathered:** 2026-02-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Make every screen feel premium with smooth animations, helpful loading/empty/error states, design system consistency, and micro-interactions. This phase polishes existing screens — no new features or capabilities are added.

</domain>

<decisions>
## Implementation Decisions

### Animation style & feel
- Calm & smooth personality — gentle easeInOut curves, no bouncing or spring physics
- Page transitions use platform defaults (iOS slide-from-right, Android material)
- Check-in flow (mood → intention → reflection → confirmation) gets special custom transitions to feel like a journey — distinct from normal navigation
- Confirmation screen gets enhanced entrance animations: stagger the affirmation text, mood/intention/reflection chips appearing sequentially, and animate the streak counter up
- Standard animation timing: 300ms with easeInOut curves

### Loading & shimmer design
- Content-shaped shimmer placeholders that match the layout of actual content (card-shaped for history, bar-shaped for insights charts)
- 200ms delay before showing shimmers — if data loads fast, user never sees them
- Only apply shimmers to screens with perceptible computation: Insights (analytics calculation) and History (sorting many entries). Other screens load instantly from Hive
- Warm subtle glow color: shimmer uses surface color (#313134) with a warm highlight sweep matching Elio's palette

### Empty state personality
- Warm & encouraging tone — "Your story starts here" not "No entries found"
- Simple line art illustrations per screen — minimal line drawings in cream/accent colors, SVG assets, clean and elegant (think Notion-style), not cartoonish
- CTA buttons only on actionable empty states (History empty → "Start your first check-in"). Non-actionable screens (Insights with no data) get encouragement text only

### Micro-interaction intensity
- Buttons: subtle scale to ~0.97 on press, then back. Barely visible but gives tactile confirmation
- Tappable cards (entry cards, direction cards): scale to ~0.98 on press. Consistent with button behavior
- Toggles: Flutter default Switch widget themed with Elio accent orange and surface colors. No custom toggle
- Haptic feedback on key moments: light haptic on mood slider selection, medium haptic on entry save, subtle on button taps

### Claude's Discretion
- Exact easeInOut curve variants per animation type
- Check-in flow transition style (vertical slide, fade, or custom)
- Specific shimmer animation speed and sweep direction
- Which screens need error states vs which can't realistically error (local DB)
- Design consistency pass details — spacing/radius/color fixes found during audit
- Line art illustration content per empty state screen

</decisions>

<specifics>
## Specific Ideas

- Check-in flow should feel like a journey — each step flowing into the next, not just pushing screens
- Confirmation screen is a celebration moment — stagger elements appearing, animate the streak counter
- Shimmers should feel warm, not cold/corporate — match the cozy dark theme
- Empty state illustrations should be Notion-style: simple line art, elegant, not cute or cartoonish
- Line art should use cream (#F9DFC1) and accent (#FF6436) colors on the dark background

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-ux-polish*
*Context gathered: 2026-02-27*
