Show the current status of a spec work folder. Optionally show a detailed view for handoff or onboarding.

## Usage

```
/modscape:spec:status <name>
/modscape:spec:status <name> detail
```

## Instructions

**When reading model information, always use modscape CLI commands — do not use `grep` or direct file reads unless the information is genuinely unavailable from CLI:**
```bash
modscape table list <file>
modscape summary <file> --json
```

1. Check that `.modscape/changes/<name>/` exists.
   - If not: tell the user:
     > `changes/<name>/` not found. Run `/modscape:spec:requirements` to start a new spec.

2. Check which files exist in `.modscape/changes/<name>/`:
   - `spec.md`
   - `spec-config.yaml`
   - `spec-model.yaml`
   - `design.md`
   - `tasks.md`

3. Determine the current phase based on what exists and task progress:
   - No `spec.md` → `not started`
   - `spec.md` only → `requirements`
   - `spec-model.yaml` + `design.md` + `tasks.md` exist → check tasks
     - Any `- [ ]` remaining → `implement`
     - All `- [x]` → `ready to archive`

4. If `tasks.md` exists, count tasks:
   - Total tasks: count all `- [ ]` and `- [x]` lines
   - Completed: count `- [x]` lines
   - Remaining: count `- [ ]` lines
   - Break down by Phase section

5. If `design.md` exists, check `## Findings > ### Requires Model Change`:
   - If it has entries: flag as ⚠️ model changes pending

6. **Always output the following status block:**

---
📋 Spec: `<name>`

**Phase:** <requirements | design | implement | ready to archive>

**Files:**
  <✓ or ✗> spec.md
  <✓ or ✗> spec-config.yaml
  <✓ or ✗> spec-model.yaml
  <✓ or ✗> design.md
  <✓ or ✗> tasks.md

**Tasks:** <n>/<total> complete
  <✓ or ○> Phase 1: Staging   (<done>/<total>)
  <✓ or ○> Phase 2: Core      (<done>/<total>)
  <✓ or ○> Phase 3: Mart      (<done>/<total>)
  <✓ or ○> Phase 4: Tests     (<done>/<total>)

<If Requires Model Change entries exist:>
⚠️  Unresolved model changes in `design.md → ## Findings → Requires Model Change`
    Re-run `/modscape:spec:design <name>` to apply them first.

**Next step:**
```
<the appropriate next command based on current phase>
```
---

## Next command by phase

| Phase | Next command |
|---|---|
| `requirements` | `/modscape:spec:design <name>` |
| `implement` | `/modscape:spec:implement <name>` |
| `ready to archive` | `/modscape:spec:archive <name>` |
| Unresolved model changes | `/modscape:spec:design <name>` |

---

## `detail` subcommand

When invoked as `/modscape:spec:status <name> detail`, run the standard status check first (steps 1–6 above), then append the following detail section.

### Detail instructions

Read the following files if they exist:

**From `spec.md`:**
- Extract the **Why** section (background / motivation) — summarize in 2–3 sentences
- Extract the **What Changes** section — list as bullets

**From `design.md`:**
- Extract the **Decisions** section — list each decision title and chosen approach in one line
- Extract the **Non-Goals** section — list as bullets

**From `tasks.md`:**
- List all remaining `- [ ]` tasks with their full text, grouped by Phase section

### Detail output block

Append the following after the standard status block:

---
📖 Detail: `<name>`

## Overview
<2–3 sentences from spec.md's Why section. If spec.md does not exist, write "No spec.md yet.">

## What Changes
<Bullet list from spec.md's What Changes section. Omit if not available.>

## Key Decisions
<One line per decision from design.md's Decisions section: "**Decision title**: chosen approach". Write "No design decisions recorded yet." if design.md does not exist or has no Decisions section.>

## Non-Goals
<Bullet list from design.md's Non-Goals. Omit if not present.>

## Remaining Tasks
<List all `- [ ]` lines from tasks.md, grouped under their Phase headings. Write "All tasks complete." if none remain.>

## Handoff Notes
**Next step:**
```
<the appropriate next command based on current phase>
```
<If any `- [ ]` tasks remain, add: "Pick up from the first remaining task above.">
<If design.md has entries under `## Findings > ### Requires Model Change`, add:>
⚠️  Unresolved model changes in `design.md → Findings → Requires Model Change`. Run `/modscape:spec:design <name>` before implementing.
---
