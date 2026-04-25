Show the current status of a spec work folder.

## Usage

```
/modscape:spec:status <name>
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
