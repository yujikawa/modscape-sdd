Investigate a topic by reading repository files and record findings in `design.md`.

## Usage

```
/modscape:spec:investigate [<name>]
```

`<name>` is the work folder name (e.g., `monthly-sales-summary`). Optional when only one active change exists.

## Instructions

### Step 0 — Detect language

If `.modscape/modscape-spec.custom.md` exists, read it and look for a `## Communication` section. If it contains a language directive (e.g., "Always respond in Japanese"), use that language for all output in this session. Otherwise default to English.

### Step 1 — Resolve the change name

If `<name>` is not provided:
- List directories under `.modscape/changes/` (exclude `archive/`)
- If exactly one exists → use it automatically
- If multiple exist → display the list and ask the user to specify
- If none exist → stop and tell the user:
  > No active changes found under `.modscape/changes/`. Run `/modscape:spec:requirements` to start a new spec.

### Step 2 — Receive the investigation request

Ask the user:
> What would you like me to investigate? Describe freely — what to compare, what discrepancy you noticed, or what you want to understand.

If the request is unclear about **which tables or files** to focus on, ask one clarifying question before proceeding. Do not ask multiple questions at once.

### Step 3 — Identify relevant files

Based on the request, determine which files to read. Prioritize in this order:

1. `.modscape/changes/<name>/spec-model.yaml` — table definitions, columns, lineage
2. `.modscape/changes/<name>/design.md` — existing design decisions and findings
3. `.modscape/changes/<name>/spec.md` — acceptance criteria
4. `.modscape/specs/<table-id>/spec.md` — permanent specs for referenced tables
5. SQL / dbt model files in the project (match by table name or file path mentioned in request)
6. Main `model.yaml` (if a broader model comparison is needed)

Read only the files directly relevant to the request. Do not read every file in the project.

### Step 4 — Investigate

Read the identified files. Perform the analysis requested — compare logic, identify discrepancies, trace lineage, check column definitions, etc.

If additional files are needed that were not initially identified, read them now.

### Step 5 — Summarize findings

Produce a clear finding summary:

```
## 🔍 Investigation Result

**Request:** <brief summary of what was asked>
**Files read:** <list of files actually read>

**Finding:**
<What was discovered — be specific. Include column names, logic differences, line references where helpful.>

**Impact:**
<What does this mean for the design, implementation, or spec?>

**Recommended action:** <one of: no action needed / implement inline fix / re-run design / update spec.md AC>
```

### Step 6 — Write to design.md

Append the finding to `.modscape/changes/<name>/design.md` under `## Findings`. If the section does not exist, create it.

Format:

```markdown
### Finding: <title> (<YYYY-MM-DD>)
**Request:** <one-line summary of the request>
**Files read:** <files read>
**Finding:** <what was found>
**Impact:** <impact on design / implementation / spec>
**Next action:** <recommended action>
```

### Step 7 — Guide next action

Based on the finding, provide specific guidance:

| Finding | Next step |
|---|---|
| Logic error or discrepancy in implemented files | `Run /modscape:spec:implement <name> and describe the fix — the inline fix protocol will handle design.md → spec-model.yaml → regenerate.` |
| Model structure change needed (new table, lineage change) | `Run /modscape:spec:design <name> to update the model.` |
| AC in spec.md contradicts finding | `Update the affected AC-NNN in spec.md directly, then continue with /modscape:spec:implement <name>.` |
| Reference only, no action needed | `Finding recorded. No changes required.` |
