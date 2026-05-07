# Feature Research

**Domain:** Mood Tracking & Journaling Apps
**Researched:** 2026-02-26
**Confidence:** MEDIUM (based on training data + existing Elio codebase analysis, not verified with current 2026 market data)

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete or unfinished.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Entry editing** | All journaling apps allow editing past entries. Users expect to fix typos, add forgotten details. | LOW | Elio missing. Just need to modify existing Entry model and add edit UI flow. |
| **Entry deletion** | Users need ability to remove entries (mistakes, privacy). | LOW | Elio missing. Needs confirmation dialog + cascade handling for reflections/connections. |
| **Search/filter entries** | As entry count grows (100+), users need to find specific moments. | MEDIUM | Elio missing. Need search by text + filter by mood range/date/direction. |
| **Data export** | Trust & portability. Users want to own their data (CSV/JSON minimum). | MEDIUM | Elio missing. Generate CSV with entries + reflections. Privacy requirement for mental health apps. |
| **Calendar/heatmap view** | Visual pattern recognition at-a-glance. Industry standard since Daylio popularized it. | MEDIUM | Elio missing. Month grid with mood color-coding. Tappable to day detail. |
| **Entry reminder notifications** | Habit formation. Users forget to check in without prompts. | MEDIUM | Elio has skeleton. Need scheduling UI + local notification triggers. |
| **Streak visualization** | Gamification for consistency. Daylio, Finch, Pixels all have this prominently. | LOW | Elio has streak logic but minimal UI. Needs more visual emphasis (fire icon, progress ring). |
| **Smooth animations** | Premium feel. Jarring transitions = prototype feel. | MEDIUM | Elio has some. Needs comprehensive pass: screen transitions, micro-interactions, loading states. |
| **Empty states** | First-run experience. Users don't know what to do with blank screens. | LOW | Elio has some. Needs audit of all screens for helpful empty states. |
| **Loading states** | Perception of performance. Blank screens feel broken. | LOW | Elio likely missing many. Add skeleton screens, spinners, optimistic updates. |
| **Error handling** | Graceful degradation. Apps that crash or show stack traces feel unprofessional. | MEDIUM | Needs comprehensive error boundary + user-friendly messages. |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable if aligned with core value proposition.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Directions (life compass)** | Unique to Elio. Connects mood to life areas and personal goals. Competitors use tags/activities, not intentional direction-setting. | MEDIUM | ✓ Shipped in v1.1.0; direction loop branch expands this into multi-goal check-ins with presence, small steps, blockers, and support notes. |
| **Mood correlation insights** | "Your mood is 15% higher when connected to Health direction" plus presence/progress/blocker patterns — actionable, not just analytics. | MEDIUM | ✓ Implemented through DirectionConnection mood correlation and DirectionCheckIn presence/progress/blocker stats. |
| **No-guilt design** | Skip buttons, positive language, optional features. Counters shame loops common in tracking apps. | LOW | ✓ Core philosophy already embedded. Maintain in all new features. |
| **Intention setting** | Focus on forward-looking ("what do you want?") vs backward-only ("how did you feel?"). | LOW | ✓ Already core feature. Good differentiator vs pure mood trackers. |
| **Smart weekly summaries** | Automated "Here's your week" recap with insights. Finch does this well. | MEDIUM | Elio missing. Generate weekly digest with top mood, patterns, streak, suggested actions. |
| **Contextual nudges** | "You haven't connected to Peace direction in 7 days" — proactive, not just reactive. | MEDIUM | Elio has detection logic. Need notification/in-app nudge UI. |
| **Question rotation logic** | Daily deterministic rotation (same question all day) + favorites. More thoughtful than random. | LOW | ✓ Already implemented. Nice touch. |
| **Local-first privacy** | Zero cloud storage. Differentiates from Reflectly (cloud), Finch (account required). | LOW | ✓ Core architecture. Marketing point. |
| **Minimal time commitment** | "< 2 minutes" promise. Competitors often bloat check-in flow. | LOW | ✓ Design principle. Maintain in feature additions. |
| **Reflection question library** | 27 curated questions across 9 categories. More depth than Pixels' simple prompts. | LOW | ✓ Already implemented. Could expand categories or allow community sharing (v3+). |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems or dilute the product.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Social sharing** | "Share my mood with friends" | Privacy risk for mental health data. Adds comparison/judgment pressure. Against no-guilt philosophy. | Keep personal. Suggest external sharing (screenshot) if user wants. |
| **Cloud sync / accounts** | "Use on multiple devices" | Adds auth complexity, privacy concerns, server costs. Dilutes local-first value prop. | Defer to v3+ with E2E encryption. Focus on single-device excellence first. |
| **Photo/video/voice attachments** | "Richer journaling" | Storage bloat (Hive not ideal for blobs). Scope creep. Slows check-in flow. | Text-only keeps it fast. Consider mood-associated photo gallery in v3+ if validated. |
| **Mood tracking multiple times per day** | "I want to log every mood change" | Creates obsessive tracking. Against simplicity. Complicates insights (which entry is "the day"?). | One check-in per day. If user wants more, suggest separate evening reflection (v2+). |
| **Unlimited directions** | "I have more than 5 goals or life directions." | Too many prompts can make check-ins feel long. | Allow unlimited directions, but keep check-ins selective and make goal-specific reflections user-chosen. Presence should not imply progress. |
| **Complex mood scales** | "I want 10-point scale or emoji matrix" | Analysis paralysis. Slows entry. Harder to see trends. | Keep 0.0-1.0 slider. Add more mood words if needed, not more scales. |
| **Gamification (levels, achievements)** | "Make it more engaging" | Creates extrinsic motivation. Mood tracking shouldn't be a game. Can create guilt when you "fail". | Use streaks minimally. Focus on intrinsic value (self-awareness), not points. |
| **AI chat / therapist bot** | "Give me advice" | Liability risk. Not a mental health professional. Can give harmful advice. | Show patterns, let user reflect. Add resources link, not AI therapist. |
| **Public goal setting** | "Accountability" | Shame when you don't hit goals. Against no-guilt philosophy. | Keep goals private (intentions). Celebrate showing up, not outcomes. |

## Feature Dependencies

```
Entry editing
    └──requires──> Entry deletion (should be able to delete after editing)

Search/filter
    └──requires──> Calendar view (common to search, then view in calendar context)

Weekly summaries
    └──requires──> Insights calculation (already exists)
    └──enhances──> Nudges (summary surfaces what to nudge about)

Nudges
    └──requires──> Notifications (delivery mechanism)
    └──requires──> Insights logic (what to nudge about)

Calendar view
    └──enhances──> Search/filter (visual complement to text search)
    └──enhances──> History (alternative view mode)

Export
    └──requires──> Entry editing (users want clean data before export)
```

### Dependency Notes

- **Entry editing requires deletion:** Users will want to edit-then-delete workflow. Build both together.
- **Search/filter enhances calendar:** These are complementary views. Build calendar first (visual discovery), then search (specific retrieval).
- **Weekly summaries feed nudges:** Summary logic determines what's worth nudging about. Build summaries first.
- **Nudges require notifications:** In-app nudges can work without push, but push notifications make them effective.
- **Calendar enhances history:** Both show past entries, different contexts. Can reuse entry card components.

## MVP Definition (For v2.0 "Proper App" Milestone)

### Launch With (v2.0 Table Stakes)

Minimum to feel like a complete, professional app on the App Store.

- [x] Entry editing (mood, intention, reflections, direction connections) — **CRITICAL**. Every journaling app has this.
- [x] Entry deletion with confirmation — **CRITICAL**. Data control = trust.
- [x] Search entries by text — **IMPORTANT**. Users with 50+ entries will need this.
- [x] Filter by mood range / date range — **IMPORTANT**. Complements search.
- [x] Calendar/heatmap view — **CRITICAL**. Industry standard. Users expect visual patterns.
- [x] Smooth screen transitions — **CRITICAL**. Premium feel. Hero animations, page transitions, consistent 300ms timing.
- [x] Comprehensive loading states — **IMPORTANT**. Skeleton screens for heavy operations (insights calculation, etc).
- [x] Empty state polish — **IMPORTANT**. Every screen needs helpful guidance when empty.
- [x] Error handling — **IMPORTANT**. User-friendly messages, graceful degradation, no crashes.
- [x] Weekly summaries — **DIFFERENTIATOR**. "Here's your week" automated recap. Makes insights actionable.
- [x] Smart nudges — **DIFFERENTIATOR**. "Dormant direction" or "mood pattern" notifications.
- [x] Streak visualization enhancement — **IMPORTANT**. Fire icon, progress rings, celebrate milestones.
- [x] Data export (CSV) — **IMPORTANT**. Trust & portability for mental health apps.

### Add After v2.0 Launch (v2.x Iterations)

Features to add once core is solid and validated.

- [ ] Entry reminders (push notifications) — Trigger: users ask for it or check-in rate drops.
- [ ] Monthly summaries — Trigger: weekly summaries validated as useful.
- [ ] Advanced filtering (by direction, by reflection category) — Trigger: power users request it.
- [ ] Entry templates / quick check-in — Trigger: users want even faster flow.
- [ ] Mood prediction — Trigger: enough data (100+ entries) to train patterns.

### Future Consideration (v3+)

Features to defer until product-market fit is solid.

- [ ] Cloud backup with E2E encryption — Only if multi-device sync becomes major request.
- [ ] Photo attachments — Only if text feels limiting (unlikely given "< 2 min" promise).
- [ ] Community question library — Share custom questions anonymously.
- [ ] Integration with Apple Health / Google Fit — If correlation with sleep/exercise data requested.
- [ ] Voice journaling — If accessibility becomes priority.
- [ ] Dark/light mode toggle — Currently dark-first. Add light polish when design bandwidth allows.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Entry editing | HIGH | LOW | **P1** |
| Entry deletion | HIGH | LOW | **P1** |
| Calendar view | HIGH | MEDIUM | **P1** |
| Smooth animations | HIGH | MEDIUM | **P1** |
| Weekly summaries | HIGH | MEDIUM | **P1** |
| Search entries | MEDIUM | MEDIUM | **P1** |
| Filter entries | MEDIUM | LOW | **P1** |
| Smart nudges | MEDIUM | MEDIUM | **P1** |
| Streak visualization | MEDIUM | LOW | **P1** |
| Loading states | MEDIUM | LOW | **P1** |
| Empty states | MEDIUM | LOW | **P1** |
| Error handling | MEDIUM | MEDIUM | **P1** |
| Data export | MEDIUM | MEDIUM | **P1** |
| Entry reminders | HIGH | MEDIUM | **P2** |
| Monthly summaries | MEDIUM | LOW | **P2** |
| Advanced filtering | LOW | MEDIUM | **P2** |
| Entry templates | MEDIUM | MEDIUM | **P2** |
| Cloud sync | HIGH | HIGH | **P3** |
| Photo attachments | MEDIUM | HIGH | **P3** |
| Voice journaling | LOW | HIGH | **P3** |

**Priority key:**
- **P1**: Must have for v2.0 launch (App Store ready)
- **P2**: Should have post-launch (v2.x iterations)
- **P3**: Nice to have (v3+ consideration)

## Competitor Feature Analysis

Based on training data knowledge of mood tracking & journaling app landscape as of January 2025. **MEDIUM confidence** (not verified with current 2026 market state).

| Feature | Daylio | Finch | Pixels | Reflectly | Jour | Elio (Current) | Elio (v2.0 Plan) |
|---------|--------|-------|--------|-----------|------|----------------|------------------|
| **Mood tracking** | ✓ 5-point | ✓ Emotion + energy | ✓ 1-10 scale | ✓ Slider | ✓ Scale | ✓ 0-1 slider | ✓ Same |
| **Daily activities** | ✓ Tags | ✓ Journey tasks | ✓ Tags | — | ✓ Tags | ✓ Intentions + Directions | ✓ Same |
| **Reflection questions** | — | ✓ Prompts | ✓ Prompts | ✓ AI prompts | ✓ Prompts | ✓ 27 questions, rotation | ✓ Same |
| **Calendar view** | ✓ Heatmap | ✓ Timeline | ✓ Heatmap | ✓ Timeline | ✓ Calendar | — **MISSING** | ✓ **ADD** |
| **Entry editing** | ✓ | ✓ | ✓ | ✓ | ✓ | — **MISSING** | ✓ **ADD** |
| **Entry deletion** | ✓ | ✓ | ✓ | ✓ | ✓ | — **MISSING** | ✓ **ADD** |
| **Search/filter** | ✓ | ✓ | ✓ | ✓ | ✓ | — **MISSING** | ✓ **ADD** |
| **Data export** | ✓ CSV | ✓ | ✓ | ✓ | ✓ | — **MISSING** | ✓ **ADD** |
| **Weekly summaries** | ✓ Stats | ✓ Recap | — | ✓ | ✓ | — Partial (insights) | ✓ **ENHANCE** |
| **Reminders** | ✓ | ✓ | ✓ | ✓ | ✓ | — Skeleton only | — **P2** |
| **Streaks** | ✓ Fire icon | ✓ Progress | ✓ | ✓ | ✓ | ✓ Basic number | ✓ **ENHANCE** |
| **Insights/analytics** | ✓ Charts | ✓ Progress | ✓ Patterns | ✓ AI insights | ✓ Analytics | ✓ Week/month view | ✓ Same |
| **Mood correlation** | ✓ Activity analysis | — | ✓ | — | — | ✓ **UNIQUE** to Directions | ✓ Same |
| **Local-first** | ✓ | — (cloud) | ✓ | — (cloud) | — (cloud) | ✓ **UNIQUE** | ✓ Same |
| **No account required** | ✓ | — (account) | ✓ | — (account) | — (account) | ✓ **UNIQUE** | ✓ Same |
| **Premium UX** | Basic | Excellent (Finch is gold standard) | Good | Good | Excellent | Prototype feel | ✓ **GOAL** |

**Key Takeaways:**
- **Elio is missing table stakes:** Entry edit/delete, search, calendar, export. Competitors have all of these.
- **Elio has unique differentiators:** Directions with mood correlation, local-first privacy, no-guilt design.
- **Finch is UX benchmark:** Best-in-class animations, gamification without guilt, delightful interactions. Elio should study their polish.
- **Reflectly/Jour use AI heavily:** Elio deliberately avoids this (anti-feature). Focus on human reflection, not AI advice.
- **Daylio popularized calendar heatmap:** Now industry standard. Elio must have this.

## Sources

**Confidence Level: MEDIUM**

Research based on:
- Training data knowledge of Daylio, Finch, Pixels, Reflectly, Jour (as of Jan 2025)
- Existing Elio codebase analysis (v1.1.0 from CLAUDE.md)
- General UX patterns for mood tracking & journaling apps
- App Store quality standards for mental health apps

**Not verified with:**
- Current 2026 feature sets (WebSearch unavailable during research)
- Recent app updates or new competitors
- Latest App Store review guidelines

**Validation recommended:**
- Manual review of competitor apps before finalizing roadmap
- User research with target audience (existing mood tracking app users)
- App Store search for "mood tracker" to see current top charts

---
*Feature research for: Elio v2.0 — The Proper App*
*Researched: 2026-02-26*
