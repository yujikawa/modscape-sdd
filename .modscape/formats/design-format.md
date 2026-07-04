# Design: <pipeline title>

---

## Design Decisions

<!-- Each decision must record both the technical choice AND the business reason.
     "Because the spec says so" is not a rationale — explain the business logic or process. -->

- **<decision>** — <business reason>. *Technical: <technical note if needed>*

---

## Affected Tables

> ⚠️ This classification is an AI proposal. Edit directly if incorrect.

| Table | Impact | Details |
|-------|--------|---------|
| `<table-id>` | Direct | new / column added / restructured |
| `<table-id>` | Downstream — Implement | <which changed column is referenced and why this table must be updated> |
| `<table-id>` | Downstream — Context Only | <why no code change is needed> |

---

## Known Open Questions

*(Populated automatically. Only Direct Impact tables. Omit section if none.)*

- **Q-NNN** → `<table-id>` — see `.modscape/changes/<name>/questions.md`

---

## Related Past Specs

*(Populated automatically via `modscape spec search`. Omit section if no results.)*

- `archives/YYYY-MM-DD-<name>/` — <spec title>

---

## Design Progress

*(Populated automatically on first run. Update Status as each table is designed.)*

| Table | Type | Status |
|-------|------|--------|
| `<table-id>` | Direct Impact | ⏳ Pending |
| `<table-id>` | Downstream — Implement | ⏳ Pending |

---

## Findings

### Requires Model Change

*(Observations that require changes to `spec-model.yaml` — processed first on re-run)*

- `<table-id>`: <issue>

### Implementation Notes

*(Observations that do NOT require model changes — for reference only)*

- <note>
