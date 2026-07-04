Lightweight SDD entry point for minor schema changes (column add, table rename, type change). Compresses requirements → design → tasks into a single invocation.

---

## When to use lite vs full SDD

**Use this skill (`requirements-lite`) for:**
- Adding, removing, or changing column types
- Renaming a table or changing its kind
- Updating descriptions or metadata
- Simple, well-understood changes to 1–2 tables

**Use full SDD (`/modscape:spec:requirements`) for:**
- Designing new pipelines or data marts
- Complex changes spanning multiple tables
- Changes with broad downstream impact
- Changes that require stakeholder alignment or AC elicitation

If mid-session you sense "broad downstream impact" or "need to align multiple business requirements," suggest switching to full SDD and exit.

---

## Instructions

0. **Resolve `<name>`** — if no argument was provided:
   ```bash
   modscape spec list
   ```
   - No specs: guide user to run `modscape spec new <name>` and exit.
   - One spec: auto-select and announce "Using spec: `<name>`".
   - Multiple: show list and ask user to choose.

1. Read `.modscape/modscape-spec.custom.md` if it exists. Rules there override these instructions.

   **Always use modscape CLI for model reads — do not grep or read YAML files directly:**
   ```bash
   modscape table list <file>
   modscape table get <file> --id <id>
   modscape lineage list <file>
   modscape summary <file> --json
   ```

2. Collect the following conversationally (skip items already configured in `modscape-spec.custom.md`):
   - **Target table** — which table to change (table ID or name)
   - **Change description** — what to change and how (column add, rename, type change, etc. — be specific)
   - **Reason** — why this change is needed (1–2 sentences)
   - **Main YAML path** — path to the model.yaml file (skip if already configured)
   - **Target tool** — `dbt` | `SQLMesh` | `Spark SQL` | `plain SQL` (skip if already configured)

   Do NOT collect: stakeholders, goal, acceptance criteria, or business context.

   If you sense the change is broader than expected, suggest switching to full SDD.

3. Propose a work folder name:
   - Derive a short kebab-case name from the change (e.g., `add-discount-rate`, `rename-fct-orders`)
   - Confirm with the user:
     > Proposed folder name: `<name>`. Is this OK? (Reply with a different name to rename.)
   - Wait for user confirmation or rename.

4. Check if `.modscape/changes/<name>/` exists.
   - Exists: show a warning and suggest a different name.
   - Not found: proceed to step 6 (do not create the directory manually).

5. Check if `.modscape/changes/<name>/spec.md` exists.
   - Exists: show current content and ask what to update.
   - Not found: proceed to step 6.

6. Create the work folder:
   ```bash
   modscape spec new <name>
   ```
   Skip if the folder already exists.

7. **Read target tables from the model:**

   Read `spec-config.yaml` to get the Main YAML path.
   Fetch the current state of each target table:
   ```bash
   modscape table get <main-yaml> --id <table-id> --json
   modscape lineage list <main-yaml> --from <table-id> --json
   ```

8. **Generate `spec-model.yaml` (first run only):**

   Extract the target tables:
   ```bash
   modscape extract <main-yaml> \
     --tables <id1>,<id2>,... \
     --output .modscape/changes/<name>/spec-model.yaml \
     --record .modscape/changes/<name>/spec-config.yaml
   ```
   Do NOT use `--with-downstream`. Extract target tables only.

9. **Apply mutations to `spec-model.yaml`:**

   Run the appropriate CLI command based on the change type:

   **Column add:**
   ```bash
   modscape column add .modscape/changes/<name>/spec-model.yaml \
     --table <table-id> \
     --id <column-id> \
     --name "<logical-name>" \
     --type <type> \
     [--physical-name <physical-name>] \
     [--physical-type <physical-type>]
   ```

   **Column update:**
   ```bash
   modscape column update .modscape/changes/<name>/spec-model.yaml \
     --table <table-id> \
     --id <column-id> \
     [--name "<new-name>"] \
     [--type <new-type>]
   ```

   **Table update (rename / kind change):**
   ```bash
   modscape table update .modscape/changes/<name>/spec-model.yaml \
     --id <table-id> \
     [--name "<new-name>"] \
     [--type <new-type>] \
     [--logical-name "<new-logical-name>"] \
     [--physical-name <new-physical-name>]
   ```

   After applying mutations, validate:
   ```bash
   modscape validate .modscape/changes/<name>/spec-model.yaml
   ```

10. **Update `spec-config.yaml`:**

    Record the Main YAML path and target table IDs (skip if `modscape extract --record` already did this).

11. **Write `spec.md`:**

    The format template is in `.modscape/formats/spec-format.md`. Read it as a reference.
    Generate only the following sections (omit all others):

    ```markdown
    # Pipeline Spec: <title>

    ---

    ## Background

    <2–3 sentences describing what is being changed and why>

    ## Target Tool

    `<dbt | SQLMesh | Spark SQL | plain SQL>`

    ---
    ```

    Do NOT include: Goal, Stakeholders, Data Sources, Table Relationships, Business Context, Acceptance Criteria.

12. **Write `design.md`:**

    The format template is in `.modscape/formats/design-format.md`. Read it as a reference.
    Generate only the following sections:

    ```markdown
    # Design: <title>

    ---

    ## Mutations Applied

    - `<table-id>`: <description (e.g., added column `discount_rate`, type Decimal)>

    ---

    ## Affected Tables

    | Table | Impact | Details |
    |-------|--------|---------|
    | `<table-id>` | Direct | <column added / renamed / type changed / etc.> |

    ---

    ## Design Progress

    | Table | Type | Status |
    |-------|------|--------|
    | `<table-id>` | Direct Impact | ✅ Designed |

    ---
    ```

    Omit: Design Decisions, Known Open Questions, Related Past Specs, Findings. Do not perform downstream analysis.

13. **Write `design/<table-id>.md` for each target table:**

    The format template is in `.modscape/formats/design-table-format.md`. Read it as a reference.
    Read the post-mutation table state:
    ```bash
    modscape table get .modscape/changes/<name>/spec-model.yaml --id <id> --json
    ```
    Mark added/changed columns in the Notes column (e.g., **added**, **renamed**, **type changed**).
    Omit or keep minimal the Implementation Details section.

    ```markdown
    # `<table-id>`

    ## Table Overview

    - **Type:** Direct Impact
    - **Kind:** <fact | dimension | staging | intermediate | ...>

    ## Columns

    | Column | Type | FK? | Notes |
    |--------|------|-----|-------|
    | `<col>` | `<type>` | | |
    | `<col>` | `<type>` | | **added** |
    ```

14. **Write `tasks.md`:**

    The format template is in `.modscape/formats/tasks-format.md`. Read it as a reference.
    Single phase, target tables only:

    ```markdown
    # Pipeline Tasks
    > Generated from: .modscape/changes/<name>/spec-model.yaml
    > Spec: .modscape/changes/<name>/spec.md
    > Progress: 0 / <total>

    ## Phase 1: Changes

    - [ ] `<table-id>`
    ```

15. **Set the phase:**
    ```bash
    modscape spec set-phase <name> tasks
    ```

## Usage

```
/modscape:spec:requirements-lite
/modscape:spec:requirements-lite <name>
```

## Next Step

**Always show the following message on completion:**

---
✅ Lite setup complete: `.modscape/changes/<name>/`

Generated files:
- `spec.md` — change summary
- `design.md` — mutations summary
- `design/<id>.md` — table details (one per target table)
- `tasks.md` — implementation tasks
- `spec-model.yaml` — working model YAML

**Next:**
```
/modscape:spec:implement <name>
```

---
