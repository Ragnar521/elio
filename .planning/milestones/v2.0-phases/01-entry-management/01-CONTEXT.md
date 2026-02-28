# Phase 1: Entry Management - Context

**Gathered:** 2026-02-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can safely edit and delete their mood entries. This includes editing mood value, intention, and reflections on existing entries, plus deleting entries with confirmation and undo capability. Soft delete with 30-day retention runs silently in the background.

</domain>

<decisions>
## Implementation Decisions

### Edit entry flow
- Edit happens directly on the entry detail screen — tap edit, fields become editable in place
- Same screen, two modes: view mode and edit mode
- Mood editing uses the same vertical slider widget from the check-in flow
- Reflections: user can edit existing answers AND add new ones (up to 3 total)
- No "edited" indicator on modified entries — they look the same as originals
- Save button (checkmark) replaces edit icon in app bar when in edit mode; Cancel button also appears

### Delete & undo behavior
- Delete triggered via dialog popup confirmation ("Are you sure?" with Cancel/Delete buttons)
- After deletion: bottom snackbar with "Entry deleted — Undo" for ~5 seconds
- 30-day soft delete runs silently in background — no UI for browsing deleted entries
- Direction connections are preserved on soft-deleted entries (restoring brings everything back)

### Entry detail actions
- Edit (pencil icon) and delete (trash icon) in the top app bar
- Edit toggles the detail screen into edit mode (in-place editing, not a separate screen)
- Save/Cancel buttons appear in app bar during edit mode

### Claude's Discretion
- Whether to add long-press context menu on history list cards for quick edit/delete access
- Edit mode transition animations
- How the mood slider integrates visually into the detail screen layout
- Snackbar styling and positioning
- How reflection editing UI works (inline expand vs modal)

</decisions>

<specifics>
## Specific Ideas

- User wants simplicity: "I can edit it where I can see it" — no navigating through multiple screens
- Keep it uncomplicated — the edit experience should feel lightweight, not like creating a new entry

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-entry-management*
*Context gathered: 2026-02-26*
