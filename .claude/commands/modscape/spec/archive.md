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

### Step 4: Merge questions into _questions.yaml

13. If `.modscape/changes/<name>/questions.md` exists (legacy format from older SDD runs):

    Read `.modscape/changes/<name>/questions.md` and `.modscape/specs/_questions.yaml`.
    Determine the current maximum ID in `_questions.yaml` (e.g. Q-005), then assign new sequential IDs starting from Q-006.

    **For each entry in `questions.md`:**
    - Parse: question text, answer (if `[x]`), assumption (if `**Assumption:**` line present)
    - Determine `status`: `answered` if answered, `assumed` if only assumption present, `open` otherwise
    - Infer `table` from the section header if the questions.md has per-table sections; leave absent for pipeline-level questions
    - Append to `_questions.yaml` with `change: <name>` and `date: <YYYY-MM-DD>`

    After merging all entries, delete `.modscape/changes/<name>/questions.md`:
    ```bash
    rm .modscape/changes/<name>/questions.md
    ```

    **If `questions.md` does not exist:** skip this step entirely.

### Step 4.5: Merge glossary into _glossary.yaml

13.5. If `.modscape/changes/<name>/glossary.md` exists:

    Read `.modscape/changes/<name>/glossary.md` and `.modscape/specs/_glossary.yaml` (create `_glossary.yaml` if it does not exist).

    **For each term entry in `glossary.md`:**
    - Parse: `id`, `definition`, and optional fields (`label`, `tables`, `columns`)
    - Check if the `id` already exists in `_glossary.yaml`:
      - **Not registered** → append a new entry under `terms:` with `change: <name>`
      - **Already registered** → update `change` field only; do NOT overwrite `definition` (preserve manual edits)

    After merging all entries, delete `glossary.md`:
    ```bash
    rm .modscape/changes/<name>/glossary.md
    ```

    **If `glossary.md` does not exist:** skip this step entirely.

### Step 5: Update `_context.yaml`

14. Read or create `.modscape/specs/_context.yaml`.

    `_context.yaml` stores only **cross-project architectural decisions** — NOT Q&A (those are in `_questions.yaml`).

    **Decisions**: For any significant cross-project decisions surfaced during this change:
    - Append to `decisions` list (only if significant beyond a single table):
      ```yaml
      - id: D-NNN
        summary: "<one-line summary of the decision>"
        rationale: "<why this decision was made>"  # optional but recommended
        date: <YYYY-MM-DD>
        change: <name>
      ```

    Do NOT write `questions`, `tables.*`, or any schema fields to `_context.yaml`.

    Example `_context.yaml`:
    ```yaml
    decisions:
      - id: D-001
        summary: "amount is tax-exclusive across all fact tables"
        rationale: "Finance team requirement — gross amount only at mart layer"
        date: 2026-03-10
        change: monthly-sales-summary
    ```

### Step 5.5: Extract and record project conventions

Review `design.md`, `spec.md`, and the decisions recorded in `_context.yaml` during this change for any **project-wide conventions** that were established or confirmed.

**Decision axis — which file to update:**
- `rules.custom.md`: rules about the **data model** (YAML shape, naming of table/column IDs, required columns, allowed table kinds, domain structure, SCD policy). These rules apply regardless of the implementation tool.
- `modscape-spec.custom.md`: rules about the **SDD workflow and code generation** (target tool, output directories, tasks.md format additions, code style, main YAML paths). These rules are tool- or process-specific.

**Quick test:** "Would this rule need to change if we switched implementation tools (e.g., dbt → SQLMesh)?"
- Yes → `modscape-spec.custom.md`
- No → `rules.custom.md`

If any conventions are found, present them to the user:

> The following conventions may have been established in this change:
>
> **Data model rules** (candidate for `rules.custom.md`):
> - \<candidate\>
>
> **Workflow / code generation rules** (candidate for `modscape-spec.custom.md`):
> - \<candidate\>
>
> Add any of these to the project convention files? (y/N)

If confirmed:
- Create the target file if it does not exist.
- Append the new rules under an appropriate section heading.
- Avoid duplicating rules already present in the file.

If no conventions are found, or the user declines: skip this step silently.

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

**Questions merged:**
- `_questions.yaml`: <n> entries added from `questions.md` (or: no questions.md found)

**`_context.yaml` updated:** <n> decisions added

**Conventions recorded:**
- `rules.custom.md`: <n> rules added (or: none)
- `modscape-spec.custom.md`: <n> rules added (or: none)

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
