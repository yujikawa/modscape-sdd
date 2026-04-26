Explain the content of a spec work folder for handoff or onboarding.

## Usage

```
/modscape:spec:explain <name>
```

## Instructions

1. Check that `.modscape/changes/<name>/` exists.
   - If not: tell the user:
     > `changes/<name>/` not found. Run `/modscape:spec:requirements` to start a new spec.

2. Determine the current phase (same logic as `/modscape:spec:status`):
   - No `spec.md` → `not started`
   - `spec.md` only → `requirements`
   - `spec-model.yaml` + `design.md` + `tasks.md` exist → check tasks
     - Any `- [ ]` remaining → `implement`
     - All `- [x]` → `ready to archive`

3. Read `spec.md` if it exists:
   - Extract the **Why** (background / motivation)
   - Extract the **What** (what is being built or changed)
   - Extract **Acceptance Criteria** if present

4. Read `design.md` if it exists:
   - Extract the **Decisions** section — list each decision title and the chosen approach in one line
   - Note any **Non-Goals** that clarify scope boundaries

5. Read `tasks.md` if it exists:
   - Count completed (`- [x]`) and remaining (`- [ ]`) tasks
   - List all remaining (`- [ ]`) tasks with their full text, grouped by Phase section

6. **Output the following explain block:**

---
📖 Spec: `<name>`

**Phase:** <requirements | design | implement | ready to archive>

## Overview
<2–3 sentences summarizing the background and purpose, derived from spec.md's Why section. If spec.md does not exist, write "No spec.md yet.">

## What Changes
<Bullet list from spec.md's What Changes / What section. If not available, omit this section.>

## Key Decisions
<One line per decision from design.md's Decisions section: "**Decision title**: chosen approach". If design.md does not exist or has no Decisions, write "No design decisions recorded yet.">

## Non-Goals
<Bullet list from design.md's Non-Goals. If not present, omit this section.>

## Task Progress
**<completed>/<total> tasks complete**

### Remaining Tasks
<List all `- [ ]` lines from tasks.md, grouped under their Phase headings.
If all tasks are complete, write "All tasks complete.">

## Handoff Notes
**Next step:**
```
<the appropriate next command based on current phase>
```
<If any `- [ ]` tasks remain, add: "Pick up from the first remaining task above.">
<If design.md has entries under `## Findings > ### Requires Model Change`, add:>
⚠️  Unresolved model changes in `design.md → Findings → Requires Model Change`. Run `/modscape:spec:design <name>` before implementing.
---

## Next command by phase

| Phase | Next command |
|---|---|
| `requirements` | `/modscape:spec:design <name>` |
| `implement` | `/modscape:spec:implement <name>` |
| `ready to archive` | `/modscape:spec:archive <name>` |
| Unresolved model changes | `/modscape:spec:design <name>` |
