Design the data model based on `spec.md` and update `changes/<name>/spec-model.yaml` (the work-scoped YAML). Does NOT modify the main model.yaml (e.g., HR.yaml) directly. Can be run repeatedly to iterate on the design until the user is satisfied.

## Usage

```
/modscape:spec:design <name>
/modscape:spec:design <name> path/to/main.yaml
```

`<name>` is the work folder name created by `/modscape:spec:requirements` (e.g., `monthly-sales-summary`).
`path/to/main.yaml` is the main model file (default: `model.yaml` in the current directory).

## Instructions

1. Read `.modscape/rules.md` to understand the YAML schema and modeling rules.
   If `.modscape/modscape-spec.custom.md` exists, read it too — its rules take **priority**.

   **Reading rules — follow strictly, no exceptions:**
   - **Model data** (tables, columns, lineage, relationships, domains): ALWAYS use modscape CLI. Never use `grep`, direct file reads, or scripts/code (Python, shell, etc.).
   - **Spec artifacts** (`spec.md`, `design.md`, `_context.yaml`, `_questions.yaml`, etc.): read directly with file read tools — these are not covered by CLI.
   ```bash
   modscape table list <file>
   modscape table get <file> --id <id>
   modscape lineage list <file>
   modscape summary <file> --json
   ```

2. Check that `.modscape/changes/<name>/spec.md` exists.
   - If it does not exist: stop and tell the user:
     > `changes/<name>/spec.md` not found. Run `/modscape:spec:requirements` first to create it.

3. **Check for existing `changes/<name>/spec-model.yaml`** (the work-scoped YAML).
   - If it **does not exist**: this is a first run — extract relevant tables from the main YAML (step 5).
   - If it **exists**: this may be a re-run or continuation — skip the extract step and proceed with the existing work YAML.

4. **Check for existing design.md** at `.modscape/changes/<name>/design.md`.
   - If it **does not exist**: this is a **first run** — proceed to step 5.
   - If it **exists**: this is a **continuation**. Resume the design session:
     1. If `### Requires Model Change` in `## Findings` has entries: **process these first** — apply the model changes to `changes/<name>/spec-model.yaml` using mutation CLI commands, then run `modscape validate`. Clear processed entries from `### Requires Model Change` after applying.
     2. Show the current state:
        ```bash
        modscape summary .modscape/changes/<name>/spec-model.yaml --json
        ```
        Display a brief summary: table count, table IDs, and any unresolved questions from `questions.md`.
     3. Ask the user what they want to continue with:
        > Design is in progress (N tables: `<id1>`, `<id2>`, ...). What would you like to add or change? When satisfied with the design, run `/modscape:spec:tasks <name>` to generate implementation tasks.
     4. Wait for user input, then proceed to step 12 to apply requested changes. Skip steps 5–11 (first-run only steps).

5. **Resolve main YAMLs** (first run only):

   Read `.modscape/changes/<name>/spec-config.yaml`.
   - If it exists and has `main_yamls` entries → use them.
   - If it does not exist:
     - Check `modscape-spec.custom.md` for a `Main YAMLs` setting → use it and create `spec-config.yaml`.
     - If neither found → stop and tell the user:
       > Main YAML is unknown. Run `/modscape:spec:requirements` again to set it, or create `changes/<name>/spec-config.yaml` manually.

6. **Check downstream impact** (when modifying an existing table):

   Before extracting tables, confirm the downstream impact of each directly modified table:
   ```bash
   modscape lineage list <master>.yaml --from <tableId> --recursive --json
   ```
   Use the result to anticipate which downstream tables will need review and classify them in the Affected Tables section of `design.md`.

7. **Extract relevant tables from the main YAML(s)** (first run only):

   Read `.modscape/changes/<name>/spec.md` and identify the tables to modify (Data Sources). Pass all main YAMLs from `spec-config.yaml` as inputs and use `--with-downstream` to automatically collect all downstream tables in one command:

   ```bash
   modscape extract <master1>.yaml <master2>.yaml ... \
     --tables <id1>,<id2>,... \
     --with-downstream \
     --output .modscape/changes/<name>/spec-model.yaml \
     --record .modscape/changes/<name>/spec-config.yaml
   ```

   - `--tables`: comma-separated IDs of the tables being **directly modified**
   - `--with-downstream`: recursively collects all downstream tables across all input YAMLs using BFS, producing the union of all downstreams
   - `--record`: automatically records which tables came from which source YAML in `spec-config.yaml`

   When tables are added or removed during design, always update `spec-config.yaml` manually to keep it in sync:
   - Table added → add its ID to the appropriate `main_yamls[].tables` entry
   - Table removed → remove its ID from whichever `main_yamls[].tables` entry contains it
   If the target main YAML is unclear, use the first entry and inform the user.

   If Data Sources are unclear, skip this step — `spec-model.yaml` was already scaffolded as `tables: []` by `modscape spec new`.

8. Read all existing `specs/*.md` files (if any) to understand current business context.

9. **Identify affected tables** from the extraction result and classify downstream tables:
   - **Direct Impact**: Tables specified in `--tables` (will be newly created or structurally modified)
   - **Downstream Impact — Implement**: Downstream tables that reference a column being added or changed in a Direct Impact table → must be updated
   - **Downstream Impact — Context Only**: Downstream tables that reference a Direct Impact table but do not use the changed columns → no code changes required, collected for reference only
   - If a downstream table has no column detail (lineage only) → classify as **Context Only** and add a comment noting that classification confidence is low

   This classification is an **AI proposal**. Write the disclaimer in `design.md` (see format below) and instruct the user to edit it directly if the classification is wrong.

10. **Surface known open questions** (first run only):

   Check `.modscape/specs/questions.md` for unresolved questions (`- [ ]`) that reference any Direct Impact table ID.
   - If matching questions exist: insert their Q-NNN IDs (not the full question text) into `design.md` under `## Known Open Questions`:
     ```markdown
     ## Known Open Questions (from specs/questions.md)
     There are unresolved questions related to Direct Impact tables. See `.modscape/specs/questions.md` for details.
     - Q-012, Q-015 → `fct_orders`
     - Q-019 → `dim_customers`
     ```
   - If no matching questions: omit the `## Known Open Questions` section entirely.

11. **Search past archives for related patterns** (first run only):

   For each Direct Impact table ID, run:
   ```bash
   modscape spec search <table-id> --json --limit 5
   ```
   - If results exist: record them in `design.md` under `## Related Past Specs`:
     ```markdown
     ## Related Past Specs
     The following past specs may be relevant. See each archive for details.
     - `archives/2026-03-15-monthly-sales/` — Monthly Sales Summary Pipeline
     - `specs/fct_orders.md` — fct_orders
     ```
   - If no results: omit the `## Related Past Specs` section entirely.
   - To incorporate findings from a past spec, run `/modscape:spec:search <keyword>`.

12. Design the data model — **all changes go to `changes/<name>/spec-model.yaml`, never to the main YAML**:
   - Propose tables (with `conceptual.kind`: staging → core fact/dimension → mart)
   - Define `lineage` entries to answer: **"which tables does this table's query read from?"** — one entry per input→output pair
   - Define `relationships` entries to answer: **"which two tables share a join key?"** — one entry per FK pair, regardless of data flow direction
   - **❌ DO NOT use `lineage` to represent FK joins between tables. `lineage` is for ETL/build data flow only. FK joins MUST be expressed as `relationship` entries.**
   - These two are independent: a pair of tables may have lineage, a relationship, both, or neither
     - If table C is built by joining A and B: lineage(A→C) + lineage(B→C); if A and B also share a FK key: relationship(A↔B)
     - If A and B share a FK but neither builds from the other: relationship only, no lineage
   - **Relationships are prerequisites for query construction.** Any JOIN between two tables requires a relationship entry defining the key and cardinality — without it, the implementer cannot write the query. If the join key is unknown, add it to `questions.md` immediately rather than leaving the relationship undefined.
     - Read `## Table Relationships` in `spec.md` and convert each entry to a `relationship`
     - Also infer from columns where `isForeignKey: true` — match by column name pattern (e.g., `customer_id` → `dim_customers.customer_id`)
     - Cover both source-to-source joins and fact ↔ dimension joins
     - When a FK relationship is ambiguous or the join key is unknown, add a question to `questions.md` instead of silently omitting it
   - Do **not** create `domains` unless the user explicitly requests it
   - Add `conceptual.description` and BEAM* tags to each table where relevant
   - Add `physical` strategy hints where the target tool and table type make them clear
   - Do **not** set `display.color` on tables — leave the `display` section unset unless the user explicitly requests a specific color
   - On re-run: incorporate `## Findings` from `design.md` before applying changes

13. Apply changes using mutation CLI commands targeting `changes/<name>/spec-model.yaml`:
   ```bash
   modscape table add .modscape/changes/<name>/spec-model.yaml --id <id> --name "<name>" --type <type>
   modscape lineage add .modscape/changes/<name>/spec-model.yaml --from <from> --to <to>
   # FK relationship: --from / --to accepts "table.column" or just "table"
   modscape relationship add .modscape/changes/<name>/spec-model.yaml \
     --from <table>.<column> --to <table>.<column> --type <one-to-many|many-to-one|one-to-one|many-to-many>
   # domain add: only when explicitly requested by the user
   modscape domain add .modscape/changes/<name>/spec-model.yaml --id <id> --name "<name>"
   ```
   Edit YAML directly only for complex nested fields (`physical`, `logical.scd`, `columns`, `sampleData`, composite FK with multiple columns).

14. After all changes are applied, always run validate and fix any errors before proceeding:
    ```bash
    modscape validate .modscape/changes/<name>/spec-model.yaml
    ```

15. Write `.modscape/changes/<name>/design.md` using the format below.
    - On first run: create with design decisions and affected tables. Initialize `## Findings` with empty subsections.
    - On re-run: preserve `## Findings` content; update `## Design Decisions` and `## Affected Tables` only.

16. Update `Status` in `.modscape/changes/<name>/spec.md` to `design` if not already set.

18. Review the **entire design conversation** and append entries to `.modscape/changes/<name>/questions.md` for all of the following:

   - **Answered** — questions you asked during design and the user gave a clear answer to → mark `[x]` and append the answer inline
   - **Assumed** — items you could not confirm and proceeded with an assumption → mark `[ ]` with an `**Assumption:**` line
   - **Open** — items still unresolved → mark `[ ]` with no assumption

   Use this format. Use the next available ID continuing from any existing questions:

```markdown
- [x] **Q-NNN** <question text>
  **Answer:** <answer the user gave>

- [ ] **Q-NNN** <question text>
  **Assumption:** <what you assumed to proceed> (unconfirmed)
```

   Record every question that shaped the design — answered questions are just as important for traceability as open ones.

   If there are unresolved questions (`- [ ]`) at the end of design, output:
    > ⚠ There are **N** unresolved questions (Q-NNN, ...). Answer them with `modscape spec answer <id> "<answer>"`, or proceed to implementation with `/modscape:spec:implement <name>`.

19. Review the design conversation for any project-specific or in-house business terms that were introduced or defined. Append qualifying terms to `.modscape/changes/<name>/glossary.md` (create the file if it does not exist).

   Target terms (record these):
   - Project-specific / in-house terms and abbreviations
   - Common words that carry a specific meaning in this project's context

   Skip these (do NOT record):
   - General SQL terms (JOIN, GROUP BY, NULL, etc.)
   - Standard data modeling concepts (fact, dimension, hub, satellite, etc.)
   - Self-evident column names (created_at, id, etc.)

   ```markdown
   ## <change-name>

   - **<term-id>**: <definition>
     - label: <日本語名> (optional)
     - tables: <table_a>, <table_b> (optional)
     - columns: <table_a.col> (optional)
   ```

   If no qualifying terms were found, skip silently.

## design.md Format

```markdown
# Design: <pipeline title>

## Design Decisions
<Key design choices and their rationale — updated on each re-run>

## Affected Tables

> ⚠️ This Affected Tables classification is an AI proposal. Edit directly if the classification is incorrect.

### Direct Impact
- `<table-id>`: <reason (new / column added / restructured)>

### Downstream Impact — Implement
- `<table-id>`: <which changed column is referenced and why this table must be updated>

### Downstream Impact — Context Only
- `<table-id>`: <why no code change is needed — e.g., does not reference changed columns>

## Known Open Questions (from specs/questions.md)
<!-- Populated automatically by /modscape:spec:design. Only Direct Impact tables. Omit section if none. -->
- Q-NNN → `<table-id>` — see .modscape/specs/questions.md

## Related Past Specs
<!-- Populated automatically by /modscape:spec:design via modscape spec search. Omit section if no results. -->
- `archives/YYYY-MM-DD-<name>/` — <spec title>

## Findings

### Requires Model Change
<Observations that require changes to spec-model.yaml — processed first on re-run>
<Example:>
<- `fct_orders`: NULL rate for customer_id was 12% → add `null_customer_flag` column>
<- Grain was off: one row per order line, not per order → redesign fct_orders>

### Implementation Notes
<Observations that do NOT require model changes — for reference only>
<Example:>
<- stg_raw_sales partition by event_date works as expected>
<- dbt incremental merge on order_id performs well>
```

## Next Step

**Always output the following at the end, without exception. Build the review summary from the actual state of `questions.md` and `design.md`:**

---
✅ Design updated. `spec-model.yaml` and `design.md` are current.

## Review Checkpoint

**Unresolved Questions:** N — Q-NNN, Q-NNN (see questions.md) *(show "none" if 0)*

**Assumptions:** N *(list `**Assumption:**` lines from design.md / questions.md; show "none" if 0)*

**Downstream Classification (Low Confidence):** `<table-id>` *(show "none" if empty)*

⚠️ Open issues found. Please review before continuing. *(If zero issues: ✅ No open issues.)*

**Next steps:**
```
/modscape:spec:design <name>     # continue iterating on the design
/modscape:spec:tasks <name>      # satisfied with the design? generate implementation tasks
/modscape:spec:review <name>     # review design status
```

To preview the model:
```
modscape dev .modscape/changes/<name>/spec-model.yaml
```

If you discover issues, add them to `## Findings` in `design.md` and re-run `/modscape:spec:design <name>`.
---
