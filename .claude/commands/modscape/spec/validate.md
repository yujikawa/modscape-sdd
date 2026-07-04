Check cross-artifact consistency across all SDD documents in a work folder — spec.md, design.md, tasks.md, spec-model.yaml, and questions.md — and report mismatches, gaps, and drift by category.

## Usage

```
/modscape:spec:validate <name>
```

`<name>` is the work folder name (e.g., `monthly-sales-summary`).

## Instructions

1. Check that `.modscape/changes/<name>/` exists.
   - If not: stop and tell the user:
     > `changes/<name>/` not found. Run `/modscape:spec:requirements` to start a new spec.

2. Read the following files (skip silently if a file does not exist — note which were skipped):
   - `.modscape/changes/<name>/spec.md`
   - `.modscape/changes/<name>/design.md`
   - `.modscape/changes/<name>/tasks.md`
   - `.modscape/changes/<name>/questions.md`
   - `.modscape/changes/<name>/spec-model.yaml` — use `modscape table list` to get table IDs

3. Run checks by category. For each category, if a required file is missing, display `⏭ skipped — <filename> not found` and move to the next category.

---

### Category A: spec.md ↔ design.md

**A-1. Table coverage**
- Extract table IDs mentioned in `spec.md` (kebab-case identifiers matching table IDs in the model)
- Check that each ID appears in `design.md` under `## Affected Tables` (in any classification: Direct Impact, Downstream — Implement, or Downstream — Context Only)
- Flag any table ID found in `spec.md` but absent from `design.md` Affected Tables

**A-2. Requires Model Change tracking**
- Extract entries listed under `### Requires Model Change` in `design.md`
- For each entry, check if a corresponding task exists in `tasks.md` (match by table ID or keyword)
- Flag any entry with no corresponding task

---

### Category B: design.md ↔ spec-model.yaml

**B-1. Direct Impact tables exist in model**
- Extract table IDs listed under `### Direct Impact` in `design.md`
- Check each ID against `modscape table list .modscape/changes/<name>/spec-model.yaml`
- Flag any ID listed as Direct Impact but absent from `spec-model.yaml`

**B-2. Model tables are classified in design**
- Get all table IDs from `modscape table list .modscape/changes/<name>/spec-model.yaml`
- Check each ID appears somewhere in `design.md` `## Affected Tables`
- Flag any table in `spec-model.yaml` that has no classification in `design.md`

---

### Category C: design.md ↔ tasks.md

**C-1. Direct Impact table task coverage**
- Extract table IDs under `### Direct Impact` in `design.md`
- For each table ID, check if at least one task in `tasks.md` references it (by ID or closely matching name)
- Flag Direct Impact tables with no corresponding task

---

### Category D: questions.md ↔ design.md

**D-1. Unresolved questions recorded as assumptions**
- Find all `- [ ]` entries in `questions.md` (unresolved Q-NNN)
- For each, check if `design.md` contains a corresponding `**Assumption:**` line referencing the same Q-NNN or topic
- Flag unresolved questions with no assumption recorded in `design.md`

---

4. Display the report:

```
## Validate: <name>

### A. spec.md ↔ design.md
✅ All tables in spec.md are classified in design.md
❌ Requires Model Change "fct_orders: add column revenue_net" has no corresponding task in tasks.md
   → Add a task to tasks.md or re-run /modscape:spec:design <name>

### B. design.md ↔ spec-model.yaml
✅ All Direct Impact tables exist in spec-model.yaml
⚠️  mart_summary: exists in spec-model.yaml but not classified in design.md Affected Tables
   → Re-run /modscape:spec:design <name> to classify this table

### C. design.md ↔ tasks.md
⚠️  stg_orders: Direct Impact but no matching task found in tasks.md
   → Add a task or re-run /modscape:spec:design <name>

### D. questions.md ↔ design.md
✅ All unresolved questions are recorded as assumptions in design.md
```

5. Evaluate overall status:
   - If all categories show only ✅ → Display: `✅ No consistency issues found.`
   - Otherwise → Display: `⚠️ Consistency issues found above. Fix before implementing or re-run /modscape:spec:design <name>.`

6. **Always output the following next steps at the end:**

---
**Next steps:**
```
/modscape:spec:design <name>    # re-run design to fix model/task gaps
/modscape:spec:review <name>    # go/no-go check (questions, assumptions, AC coverage)
/modscape:spec:implement <name> # proceed to implementation
```
---
