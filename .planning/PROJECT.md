# Elio v2.0 — The Proper App

## What This Is

Elio is a mood tracking and journaling app for iOS and Android that helps users check in with their emotions, set daily intentions, reflect on their experiences, and connect entries to life directions they care about. This milestone transforms Elio from a functional prototype into a polished, App Store-ready product with premium UX, deeper insights, and the missing features users expect.

## Core Value

Users can quickly check in with their mood and intentions, then understand what their data means — through weekly summaries, smart nudges, visual patterns, and actionable takeaways that make self-reflection genuinely useful.

## Requirements

### Validated

<!-- Shipped and confirmed valuable — inferred from existing codebase. -->

- ✓ Mood entry with slider (0.0–1.0) and dynamic mood words — existing
- ✓ Daily intention setting with mood-adaptive prompts — existing
- ✓ Reflection questions (1–3 per entry, favorites, rotation, custom) — existing
- ✓ Entry confirmation with streak tracking — existing
- ✓ Entry history timeline grouped by date — existing
- ✓ Entry detail view with full mood/intention/reflection display — existing
- ✓ Insights with week/month toggle, mood wave, stat cards, day patterns — existing
- ✓ Directions (life compass) with 6 types, max 5 active — existing
- ✓ Direction connections with mood correlation analysis — existing
- ✓ Direction-specific reflection questions — existing
- ✓ Settings with reflection toggle and question management — existing
- ✓ Onboarding flow (welcome, name, first check-in) — existing
- ✓ Local-only storage with Hive — existing
- ✓ Dark mode design system — existing

### Active

<!-- Current scope. Building toward these. -->

- [ ] Edit existing entries (mood, intention, reflections)
- [ ] Delete entries with confirmation
- [ ] Search entries by keyword
- [ ] Filter entries by mood range, date, direction
- [ ] Weekly summary recaps (here's what your week looked like)
- [ ] Smart nudges (dormant directions, mood patterns, check-in reminders)
- [ ] Visual mood patterns (heatmap/calendar view)
- [ ] Smooth screen transitions and animations across the app
- [ ] Design consistency pass (every screen feels premium)
- [ ] Loading states, empty states, and error handling polish
- [ ] App Store readiness (icons, screenshots, metadata)

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Cloud backup / multi-device sync — keep local-first simplicity for v2.0
- Export data (CSV/JSON/PDF) — useful but not core to "proper app" feel
- Photo/voice attachments — adds complexity, defer to future
- Social features / sharing — personal tool, not social
- Push notifications for reminders — defer to future milestone
- Light mode polish — dark mode is primary, light can follow later

## Context

Elio has a working v1.1.0 with mood tracking, intentions, reflections, directions, and basic insights. The codebase follows a StatefulWidget + Singleton Service pattern with Hive for local storage. Manual Hive type adapters are used (no build_runner). The app runs on both iOS and Android via Flutter.

The current state is functional but feels like a prototype — screens lack polish, transitions are flat, some features feel half-baked (insights show data but don't help you act on it), and basic operations like editing/deleting entries are missing.

The goal is App Store readiness: a product that feels premium when you open it, has the features users expect, and makes your mood data genuinely useful through summaries, nudges, and visual patterns.

Existing codebase map is available at `.planning/codebase/`.

## Constraints

- **Tech stack**: Flutter/Dart, Hive for storage — continue existing patterns
- **Privacy**: All data stays on-device, no network calls
- **Hive TypeIDs**: 0-2, 4-6 used; TypeId 3 reserved for future use
- **Design system**: Warm dark mode palette (charcoal background, cream text, orange accent)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Keep StatefulWidget + Services pattern | Matches existing codebase, sufficient for app scale | — Pending |
| Stay local-only (no cloud) | Privacy-first philosophy, reduces complexity | — Pending |
| iOS + Android simultaneous | Flutter gives both for free, no reason to limit | — Pending |
| App Store as target | Drives quality bar for polish and completeness | — Pending |

---
*Last updated: 2026-02-26 after initialization*
