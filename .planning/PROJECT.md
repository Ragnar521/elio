# Elio — Mood Tracking & Journaling App

## What This Is

Elio is a mood tracking and journaling app for iOS and Android that helps users check in with their emotions, set daily intentions, reflect on their experiences, and connect entries to the goals and life directions they care about. The app features premium UX with smooth animations, smart nudges, weekly summaries, calendar heatmaps, goal-aware direction check-ins, and full entry management — delivering a polished, App Store-ready experience.

## Core Value

Users can quickly check in with their mood and intentions, then understand what their data means — through weekly summaries, smart nudges, visual patterns, direction presence, small-step progress, blockers, and actionable takeaways that make self-reflection genuinely useful.

## Current State

Shipped v2.1 Demo Mode on 2026-02-28. Current branch `codex/multi-goal-direction-loop` adds the Direction Reflection Loop: unlimited directions, multi-goal check-ins after intention setting, optional per-goal small steps/blockers/support notes, optional goal-specific reflection prompts, and direction detail stats/editing that separate presence from progress.

## Requirements

### Validated

- ✓ Mood entry with slider (0.0–1.0) and dynamic mood words — v1.0
- ✓ Daily intention setting with mood-adaptive prompts — v1.0
- ✓ Reflection questions (1–3 per entry, favorites, rotation, custom) — v1.0
- ✓ Entry confirmation with streak tracking — v1.0
- ✓ Entry history timeline grouped by date — v1.0
- ✓ Entry detail view with full mood/intention/reflection display — v1.0
- ✓ Insights with week/month toggle, mood wave, stat cards, day patterns — v1.1
- ✓ Directions (life compass) with 6 types and unlimited active goals — direction loop branch
- ✓ Direction connections with mood correlation analysis — v1.1
- ✓ Multi-goal direction check-ins with presence, small steps, blockers, support notes, and linked goal reflection answers — direction loop branch
- ✓ Direction-specific reflection questions selected per check-in — direction loop branch
- ✓ Settings with reflection toggle and question management — v1.0
- ✓ Onboarding flow (welcome, name, first check-in) — v1.0
- ✓ Local-only storage with Hive — v1.0
- ✓ Dark mode design system — v1.0
- ✓ Edit existing entries (mood, intention, reflections) — v2.0
- ✓ Delete entries with confirmation and soft delete undo — v2.0
- ✓ Search entries by keyword — v2.0
- ✓ Filter entries by mood range, date, direction (combinable) — v2.0
- ✓ Calendar heatmap visualization with mood-colored grid — v2.0
- ✓ Weekly summary recaps with trends and actionable takeaways — v2.0
- ✓ Smart nudges (dormant directions, mood patterns, streak celebrations) — v2.0
- ✓ Smooth screen transitions and animations across the app — v2.0
- ✓ Design consistency pass (every screen feels premium) — v2.0
- ✓ Loading states (shimmer), empty states, and error handling polish — v2.0
- ✓ Micro-interactions for all interactive elements — v2.0
- ✓ Launcher screen with sample data / fresh start choice — v2.1
- ✓ ~90 days of realistic sample data (entries, reflections, directions, connections, summaries) — v2.1
- ✓ Triple-tap Home icon resets app to launcher screen — v2.1

### Active

- Direction Reflection Loop branch: multi-goal direction check-ins, goal-specific reflection prompts, and insight/detail updates that separate presence, progress, blockers, and mood relationship.

### Out of Scope

- Cloud backup / multi-device sync — local-first privacy philosophy
- Export data (CSV/JSON/PDF) — useful but deferred
- Photo/voice attachments — adds complexity, defer to future
- Social features / sharing — personal tool, not social
- Push notifications for reminders — defer to future milestone
- Light mode polish — dark mode is primary, light can follow later
- App Store metadata/screenshots — separate from code milestone

## Context

Shipped v2.1 with ~14,200 LOC Dart. Current direction loop branch extends that with `DirectionCheckIn` records. Tech stack: Flutter, Hive (local NoSQL), manual TypeAdapters (typeIds 0-2, 4-8). StatefulWidget + Singleton Service pattern throughout. The app runs on both iOS and Android.

Hive TypeIDs in use: 0 (Entry), 1 (ReflectionQuestion), 2 (ReflectionAnswer), 3 (reserved), 4 (DirectionType), 5 (Direction), 6 (DirectionConnection), 7 (WeeklySummary), 8 (DirectionCheckIn).

New services added in v2.1: SampleDataService. New screens: LauncherScreen. Current direction loop branch adds `DirectionCheckInScreen` between intention and reflection when active directions exist.

Minor tech debt: withOpacity() deprecation warnings (cosmetic), template widget_test.dart references MyApp. No functional issues.

## Constraints

- **Tech stack**: Flutter/Dart, Hive for storage — continue existing patterns
- **Privacy**: All data stays on-device, no network calls
- **Hive TypeIDs**: 0-2 and 4-8 used; TypeId 3 reserved for future use
- **Design system**: Warm dark mode palette (charcoal background, cream text, orange accent)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Keep StatefulWidget + Services pattern | Matches existing codebase, sufficient for app scale | ✓ Good — worked well through 6 phases, 13 plans |
| Stay local-only (no cloud) | Privacy-first philosophy, reduces complexity | ✓ Good — simplified all data layer work |
| iOS + Android simultaneous | Flutter gives both for free, no reason to limit | ✓ Good — zero platform-specific issues |
| App Store as quality target | Drives quality bar for polish and completeness | ✓ Good — Phase 6 polish elevated entire app |
| Soft delete with 30-day retention | Prevents data loss, user-friendly undo | ✓ Good — clean implementation with auto-cleanup |
| Synchronous in-memory filtering | <1000 entries faster sync than async overhead | ✓ Good — instant filter response |
| Denormalize direction/reflection in summaries | Snapshot integrity, no stale references | ✓ Good — summaries always show correct data |
| Separate direction presence from progress | Users can say a goal mattered today without feeling forced to make progress | ✓ Good — supports gentle goal reflection without habit-tracker pressure |
| Column-of-Rows for calendar grid | 35-42 cells, no scrolling needed, simpler than GridView | ✓ Good — clean rendering |
| AnimatedScale for press feedback | 150ms, consistent micro-interaction pattern | ✓ Good — premium feel across all cards |
| Custom PageRouteBuilder for check-in flow | 300ms vertical slide + fade, flow continuity | ✓ Good — check-in feels like one journey |
| Direct Hive writes for demo data | Service methods use DateTime.now(); demo needs backdated timestamps | ✓ Good — realistic 90-day history |
| Deterministic seeding for demo data | Reproducible demo experience across loads | ✓ Good — consistent showcase |
| Settings box cleared last in reset | Prevents partial-wipe state showing launcher before data cleared | ✓ Good — clean reset flow |

---
*Last updated: 2026-05-07 after Direction Reflection Loop branch update*
