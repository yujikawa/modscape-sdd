Merge the work-scoped YAML back into the main model, then sync permanent table specs in `.modscape/specs/`.

## Usage

```
/modscape:spec:archive <name>
/modscape:spec:archive <name> path/to/master.yaml
```

`<name>` is the work folder name (e.g., `monthly-sales-summary`).
`path/to/main.yaml` is the main model file (default: `model.yaml` in the current directory).

## Instructions

**When reading model information, always use modscape CLI commands — do not use `grep` or direct file reads unless the information is genuinely unavailable from CLI:**
```bash
modscape table list <file>
modscape table get <file> --id <id>
modscape lineage list <file>
modscape summary <file> --json
```

1. Verify that `.modscape/changes/<name>/` exists and contains `spec-model.yaml`.
   - If not: stop and tell the user:
     > `changes/<name>/spec-model.yaml` not found. Run `/modscape:spec:design <name>` first.

2. Read the following files:
   - `.modscape/changes/<name>/spec.md`
   - `.modscape/changes/<name>/spec-config.yaml`
   - `.modscape/changes/<name>/design.md`
   - `.modscape/changes/<name>/spec-model.yaml`

   From `design.md`, build the **affected tables classification**:
   - **Direct Impact** tables: listed under `### Direct Impact`
   - **Downstream Impact — Implement** tables: listed under `### Downstream Impact — Implement`
   - **Downstream Impact — Context Only** tables: listed under `### Downstream Impact — Context Only`
   - If `design.md` does not exist or has no `## Affected Tables` section: treat all tables in `spec-model.yaml` as Direct Impact (backwards compatible).

### Step 1: Dry-run — show merge preview and confirm

3. **Check whether a main YAML exists (greenfield detection)**:

   Inspect `spec-config.yaml`:
   - If `main_yamls` is empty or absent, **or** all referenced files do not exist on disk → this is a **greenfield project**.

   **Greenfield path**: Skip Steps 1 and 2 entirely. Display:
   ```
   ## Greenfield Mode

   No main YAML found. spec-model.yaml will become the first model.
   Save as: model.yaml (default) — or enter a path:
   ```
   Wait for user input (press Enter to use `model.yaml`). Copy `spec-model.yaml` to the specified path:
   ```bash
   cp .modscape/changes/<name>/spec-model.yaml <output-path>
   ```
   Then proceed directly to Step 3 (Sync permanent table specs), treating all tables as Direct Impact.

   **Normal path** (main YAML exists): continue below.

4. Build and display the merge preview **before** executing any merge:

   - Read `spec-model.yaml` and compare table IDs against each main YAML listed in `spec-config.yaml`:
     - **Tables to add**: table IDs present in `spec-model.yaml` but not in the main YAML
     - **Tables to update**: table IDs present in both; list key field changes (added/removed columns, updated `physical.strategy`, etc.)
     - **No changes**: Downstream Impact — Context Only tables that will be merged but have no structural changes

   Display the preview:
   ```
   ## Merge Preview

   Tables to add:    fct_new_table, stg_source_x
   Tables to update: fct_orders (+2 columns: revenue_net, tax_amount)
   No changes:       dim_customers (Context Only)

   Proceed to merge into <master>.yaml? (y/N)
   ```

   Wait for user confirmation:
   - If confirmed (y/yes): proceed to Step 2.
   - If declined (N/no/anything else): stop and output:
     > Archive cancelled. No changes were made to the main YAML.

### Step 2: Merge work YAML into main YAML(s)

5. For each main YAML listed in `spec-config.yaml`, extract only the tables assigned to it and merge:
   ```bash
   modscape extract .modscape/changes/<name>/spec-model.yaml --tables <ids-for-this-yaml> --output /tmp/spec-slice.yaml
   modscape merge <master>.yaml /tmp/spec-slice.yaml --output <master>.yaml --patch
   ```

   If `spec-config.yaml` has only one main YAML, merge the entire work YAML directly:
   ```bash
   modscape merge <master>.yaml .modscape/changes/<name>/spec-model.yaml --output <master>.yaml --patch
   ```

6. Check the merge output for duplicate table ID warnings.
   If any duplicates were detected, report them to the user:
   > ⚠ The following tables existed in both the work YAML and the main YAML.
   > The spec version was used: `<table-id>`, `<table-id>`
   > Please verify the main YAML diff looks correct.

7. Run validate on each merged main YAML and fix any errors before proceeding:
   ```bash
   modscape validate <master>.yaml
   ```

### Step 3: Sync permanent table specs

8. Use the **affected tables classification** built in step 2 above.

9. **Migrate old flat-file specs (if any)**:
   For each affected table, check whether `.modscape/specs/<table-id>.md` exists as a plain file (old format).
   If found, move it into the new directory format before proceeding:
   ```bash
   mkdir -p .modscape/specs/<table-id>
   mv .modscape/specs/<table-id>.md .modscape/specs/<table-id>/spec.md
   ```

10. **Full spec sync for Direct Impact and Downstream Impact — Implement tables**:

   For each table in **Direct Impact** or **Downstream Impact — Implement**:

   a. Check whether `.modscape/specs/<table-id>/spec.md` exists.
      - If **not**: create a new file using the format below (also create the directory).
      - If **exists**: update only the relevant sections (Overview, Business Context, Business Rules, Known Issues); preserve unrelated content.

   b. Append a Changelog entry:
      ```
      - <YYYY-MM-DD>: <brief description of change> (SDD: <name>)
      ```

11. **Changelog only for Downstream Impact — Context Only tables**:
    - Do **not** perform a full spec sync for these tables.
    - Only append a Changelog entry to `.modscape/specs/<table-id>/spec.md` (create the file and directory with minimal content if it does not exist):
      - Append: `- <YYYY-MM-DD>: Referenced in downstream lineage; no structural change required (SDD: <name>)`

12. **Report the sync result**:
    > Merged into main YAML ✓
    > Synced specs:
    > - Created: `specs/mart_monthly_sales/spec.md`
    > - Updated: `specs/fct_orders/spec.md`
    > - Changelog only: `specs/stg_raw_orders/spec.md`

### Step 4: Sync questions per table

13. If `.modscape/changes/<name>/questions.md` exists:

    For each `### <table-id>` section under `## Table-level` in `changes/<name>/questions.md`:

    **Merge rules:**
    - Read the existing `.modscape/specs/<table-id>/questions.md` (create it if absent with `# Questions: <table-id>\n`)
    - Append new questions that do not already exist (compare by question text, not ID)
    - For questions that were answered (`[x]`) in this change, update the corresponding unresolved entry in the per-table file if one exists
    - If a previously recorded question is now invalidated by this change (e.g. the column was removed), add a strikethrough note:
      `~~- [ ] **Q-NNN** <original question>~~ <!-- <name>: <reason e.g. column removed> -->`
    - Append `<!-- <name> -->` as a comment after each newly added question line

    **Pipeline-level questions (`## Pipeline-level` section) are NOT synced to `specs/`.**
    They remain in the archive folder only. If any pipeline-level decision is significant enough to preserve, record it in `_context.yaml` under `decisions` (see Step 5).

### Step 5: Update `_context.yaml`

14. Read or create `.modscape/specs/_context.yaml`.

    For each affected table (Direct Impact + Downstream Impact — Implement):
    - Set `tables.<table-id>.last_change: <name>`
    - Set `tables.<table-id>.has_spec: true`
    - Set `tables.<table-id>.open_questions: <count of [ ] entries in specs/<table-id>/questions.md>`

    For any significant pipeline-level decisions from `changes/<name>/questions.md` `## Pipeline-level`:
    - Append to `decisions` list (only if the question was answered and the decision has cross-table impact):
      ```yaml
      - id: D-NNN
        summary: "<one-line summary of the decision>"
        date: <YYYY-MM-DD>
        affects: [<table-id>, ...]
        change: <name>
      ```

    Do NOT copy `description`, `kind`, or `tags` from `model.yaml` — those fields are already in the main YAML.

    Example `_context.yaml`:
    ```yaml
    tables:
      fct_orders:
        last_change: monthly-sales-summary
        open_questions: 0
        has_spec: true
      dim_customers:
        last_change: customer-segmentation
        open_questions: 2
        has_spec: true

    decisions:
      - id: D-001
        summary: "amount is tax-exclusive across all fact tables"
        date: 2026-03-10
        affects: [fct_orders, mart_revenue]
        change: monthly-sales-summary
    ```

### Step 6: Move to archives

15. Move the work folder to `.modscape/archives/YYYY-MM-DD-<name>/` (today's date):
    ```bash
    mkdir -p .modscape/archives
    mv .modscape/changes/<name> .modscape/archives/YYYY-MM-DD-<name>
    ```

16. **Always output the following summary at the end, without exception:**

---
✅ Archive complete.

**Synced specs:**
- Created: `specs/<table-id>/spec.md` ...
- Updated: `specs/<table-id>/spec.md` ...
- Changelog only: `specs/<table-id>/spec.md` ...

**Questions synced:**
- `specs/<table-id>/questions.md` updated (<n> questions added/updated) ...
- Pipeline-level questions: kept in archive only

**`_context.yaml` updated:** <n> tables

**Spec coverage:** <n>/<total> tables have permanent specs.
Tables without specs: <list or "none">

**AC Coverage:** *(read from `tasks.md` `[→ AC-NNN]` and `[manual verification]` markers; omit if no AC-NNN in spec.md)*
- ✅ Test covered: AC-001, AC-003 (<n> items)
- 🔧 Manual verification: AC-002 (<n> items) — requires manual check
- ❌ Uncovered: AC-005 (<n> items) — closed without verification

🎉 All work for this spec is complete!
---

## `specs/<table-id>/spec.md` Format

```markdown
# <table-id>

## Overview
- **Owner**: <from spec.md stakeholders.owner>
- **Update Frequency**: <inferred from implementation.* or spec.md>
- **SLA**: <from spec.md if available, otherwise "—">

## Business Context
<Business meaning of this table>

## Business Rules
- <Key business rule or calculation logic>

## Known Issues / Caveats
- <From design.md ## Findings section, if any>

## Changelog
- <YYYY-MM-DD>: Initial version (SDD: <name>)
```
