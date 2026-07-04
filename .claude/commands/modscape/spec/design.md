Design the data model based on `spec.md` and update `changes/<name>/spec-model.yaml` (the work-scoped YAML). Does NOT modify the main model.yaml (e.g., HR.yaml) directly. Can be run repeatedly to iterate on the design until the user is satisfied.

## Usage

```
/modscape:spec:design <name>
/modscape:spec:design <name> path/to/main.yaml
```

`<name>` is the work folder name created by `/modscape:spec:requirements` (e.g., `monthly-sales-summary`).
`path/to/main.yaml` is the main model file (default: `model.yaml` in the current directory).

## Instructions

0. **Resolve `<name>`** — if the user did not provide a spec name argument:
   ```bash
   modscape spec list
   ```
   - No specs: stop and tell the user to run `modscape spec new <name>` first.
   - Exactly one spec: use it automatically and note "Using spec: `<name>`".
   - Multiple specs: show the list and ask the user to choose one.

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

4. **One-table-per-invocation mode** — determine what to do this invocation:

   **Case A — `design.md` does not exist** (first run):
   - Proceed to step 5 to initialize the model and write `design.md`.
   - After initialization, generate stub files for ALL affected tables (step 15.5a), then design the **first** Direct Impact table in detail (steps 12–15.5b).

   **Case B — `design.md` exists** (subsequent runs):
   - If `### Requires Model Change` in `## Findings` has entries: apply those model changes first using mutation CLI commands, then run `modscape validate`. Clear processed entries.
   - **Check `## Design Progress` in `design.md`** for the first table with `⏳ Pending` status — that is the target for this invocation.
     - **Fallback**: If `## Design Progress` does not exist (older `design.md`), fall back to checking which table IDs lack a `design/<table-id>.md` file. Then add the `## Design Progress` section to `design.md` based on current file state before continuing.
   - If **all tables in `## Design Progress` are `✅ Designed`**:
     > ✅ All tables are designed (`design/` is complete). Run `/modscape:spec:tasks <name>` to generate implementation tasks.
     Stop here.

4.5. **Conversation-driven table add/remove** — if the user explicitly requests to add or remove a table from the design scope during the conversation:

   **Add a table:**
   - Add the table to `## Affected Tables` in `design.md` with the appropriate Impact type.
   - Add a `⏳ Pending` row to `## Design Progress` in `design.md`.
   - Generate a stub `design/<table-id>.md` for it (same format as step 15.5a).
   - Update `spec-config.yaml`: add the table ID to the appropriate `main_yamls[].tables` entry (remove from `tables_to_remove` if present).

   **Remove a table:**
   - Remove the table from `## Affected Tables` and `## Design Progress` in `design.md`.
   - Update `spec-config.yaml`: remove the table ID from `main_yamls[].tables`; add the old ID to `tables_to_remove` if it existed in the main YAML.
   - The stub/design file `design/<table-id>.md` is left in place; inform the user they may delete it manually if desired.

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
   - Table added → add its ID to the appropriate `main_yamls[].tables` entry; if the table was previously listed in `tables_to_remove`, remove it from there
   - Table removed or renamed → remove its old ID from `main_yamls[].tables`; add the old ID to `tables_to_remove` so archive can delete it from the main YAML
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

   Check `.modscape/specs/_questions.yaml` for entries with `status: open` or `status: assumed` that reference any Direct Impact table ID (via the `ids` field or question text).
   - If matching questions exist: insert their Q-NNN IDs (not the full question text) into `design.md` under `## Known Open Questions`:
     ```markdown
     ## Known Open Questions (from changes/<name>/questions.md)
     There are unresolved questions related to Direct Impact tables. See `.modscape/changes/<name>/questions.md` for details.
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

11.5. **Read `## Business Context` from `spec.md`** before designing. This section contains data occurrence conditions, business process flows, and domain rules that must inform every design decision. If `## Business Context` is absent or sparse, ask the user to fill it in before proceeding — a design without business context produces untraceable decisions.

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

14.5. **Check `spec.md` Acceptance Criteria for consistency** (run after every `spec-model.yaml` change):

   Read `.modscape/changes/<name>/spec.md` and extract all `AC-NNN:` entries. For each changed table or column, check whether any AC references it and whether the change contradicts the AC.

   - **Contradiction found**: Fix `spec.md` inline — update the relevant AC to reflect the actual state. Do NOT renumber AC IDs. Note the change in the ripple-effect report as `spec.md: ✅ Updated`.
   - **No contradiction**: Note in the ripple-effect report as `spec.md: ✅ No impact`.
   - **spec.md does not exist**: Skip silently.

15. Write `.modscape/changes/<name>/design.md` — **table-agnostic content only**.
    - On first run: create using the format in `.modscape/formats/design-format.md`. Populate `## Design Decisions`, `## Affected Tables`, and `## Design Progress`. Initialize `## Findings` with empty subsections.
    - On re-run: preserve `## Findings`; update `## Design Decisions` and `## Affected Tables` only. Do NOT overwrite `## Design Progress` — it is updated in step 15.5b.
    - **Do NOT write `## Implementation Details` to `design.md`** — table-specific details go to `design/<table-id>.md` (step 15.5).

15.5a. **Generate stub files for ALL remaining tables** (Case A — first run only):

   After writing `design.md`, create a stub `design/<table-id>.md` for **every** table listed in `## Affected Tables` whose type is **Direct Impact** or **Downstream — Implement**. Exclude Context Only tables.

   For each table:
   1. Run `modscape table get .modscape/changes/<name>/spec-model.yaml --id <table-id> --json` to get table metadata.
   2. Read the format template from `.modscape/formats/design-table-format.md`.
   3. Write a stub file to `changes/<name>/design/<table-id>.md` with:
      - The Pending banner (`> ⏳ **Pending design** — run...`) at the top.
      - `## Table Overview` with Type and Kind filled in from the model.
      - `## Columns` table populated from the model's column list (name, type, FK indicator).
      - `## Implementation Details` with TBD placeholders.
   4. Create the `design/` directory if it does not exist.

   **Do NOT** overwrite the stub for the current invocation's target table — that table will be written with full detail in step 15.5b.

15.5b. **Write full design for the current invocation's target table**:

   - Read the format template from `.modscape/formats/design-table-format.md`.
   - Overwrite `changes/<name>/design/<table-id>.md` (replacing its stub) with full detail:
     - Remove the Pending banner.
     - Document the table-specific details: transformation expressions, filter conditions, validation SQL, and test patterns.
     - Omit sections for which no detail exists — the file may be lean if the table has no transformation logic.
   - Update `## Design Progress` in `design.md`: change the target table's Status from `⏳ Pending` to `✅ Designed`.

16. Set the phase by running:
   ```bash
   modscape spec set-phase <name> design
   ```

18. Review the **entire design conversation** and append question entries to `.modscape/changes/<name>/questions.md` (create if it does not exist) for all of the following:

   - **Answered** — questions you asked during design and the user gave a clear answer to → `status: answered`, record the answer in the `answer` field
   - **Assumed** — items you could not confirm and proceeded with an assumption → `status: assumed`, record the assumption in the `assumption` field
   - **Open** — items still unresolved → `status: open`

   Determine the next ID by reading the current max Q-NNN across both `.modscape/specs/_questions.yaml` and `questions.md`. Use the format defined in `.modscape/formats/questions-format.md` (standard question entry).

   Record every question that shaped the design — answered questions are just as important for traceability as open ones.

   If there are unresolved questions (`status: open` or `status: assumed`) at the end of design, output:
    > ⚠ There are **N** unresolved questions (Q-NNN, ...). Answer them with `modscape spec answer <id> "<answer>"`, or proceed to tasks with `/modscape:spec:tasks <name>`.

18.5. **Proactive Tacit Knowledge Detection** — Review `spec-model.yaml` and the design conversation for signals that would cause an **analyst using this data product to draw wrong conclusions**. For each signal found, add a question to `questions.md` with `status: open` and `source: ai-detected`:

   Focus on signals that affect **analytical correctness**:
   - A column named `type`, `kind`, `status`, `flag`, `code`, or `_kbn` — whose possible values and meanings for analysis were not documented (an analyst filtering on unknown values will silently miss records)
   - A lineage JOIN across tables from different source systems — without confirmation that the join keys mean the same thing in both systems
   - A table grain assumed during design but never confirmed by the user — grain misunderstanding is the most common cause of incorrect aggregations
   - A measure or dimension column whose scope (which business events are included) was assumed rather than stated
   - A date column in a fact table — whose timestamp semantics (event time / entry time / processing time) affect time-series analysis but were not specified

   For each signal, write the entry to `questions.md` **and generate a PII-safe investigation query** in the `investigation:` block. This query is ready to run against the real data — the human fills in `result:` after running it, then AI fills in `finding:` via `/modscape:spec:answer`.

   Use the format defined in `.modscape/formats/questions-format.md` (ai-detected entry with investigation query).

   **PII safety rules for the generated query:**
   - Only aggregate functions: COUNT, COUNT(DISTINCT), MIN, MAX, AVG, SUM
   - Never SELECT * or raw row samples
   - Never include columns that may contain PII (names, emails, phone numbers, addresses, birth dates, national IDs, IP addresses, account numbers)
   - For value distribution: use GROUP BY + COUNT(*) — never show raw PII values
   - If unsure whether a column contains PII, exclude it and add a `-- PII risk: excluded` comment

   > ⚠️ **Human review required before running**: The AI generates this query as a starting point following PII-safety rules, but **the human must review the query before executing it** to verify no PII columns are inadvertently included. AI cannot know which columns contain PII in your specific environment. Never run without reviewing.

19. Review the design conversation for any project-specific or in-house business terms that were introduced or defined. Append qualifying terms to `.modscape/changes/<name>/glossary.md` (create the file if it does not exist).

   Target terms (record these):
   - Project-specific / in-house terms and abbreviations
   - Common words that carry a specific meaning in this project's context

   Skip these (do NOT record):
   - General SQL terms (JOIN, GROUP BY, NULL, etc.)
   - Standard data modeling concepts (fact, dimension, hub, satellite, etc.)
   - Self-evident column names (created_at, id, etc.)

   The format template is defined in `.modscape/formats/glossary-format.md`.
   Read that file and use it when writing entries to `glossary.md`.

   If no qualifying terms were found, skip silently.

## design.md Format

The format template is defined in `.modscape/formats/design-format.md`.
Read that file before writing `design.md` and use it as the template.

## Next Step

**Always output the following at the end, without exception. Build the review summary from the actual state of `.modscape/changes/<name>/questions.md`, `design.md`, and the `design/` directory:**

---
✅ Design updated. `spec-model.yaml` and `design.md` are current.

## Impact report

| File | Status | Details |
|---|---|---|
| spec.md | ✅ No impact / ✅ Updated | <AC number and content changed, or "No impact"> |
| design.md | ✅ Updated | <summary of updates> |
| spec-model.yaml | ✅ Updated | <changed tables and summary of changes> |

## Design Progress

| Table | Type | Status |
|-------|------|--------|
| `<table-id>` | Direct Impact | ✅ Designed |
| `<table-id>` | Direct Impact | ⏳ Pending |
| `<table-id>` | Downstream — Implement | ⏳ Pending |

Designed **N/M** tables. Next: `<next-pending-table-id>`

## Review Checkpoint

**Unresolved Questions:** N — Q-NNN, Q-NNN (see `questions.md`) *(show "none" if 0)*

**Assumptions:** N *(list `status: assumed` entries from `questions.md`; show "none" if 0)*

**Downstream Classification (Low Confidence):** `<table-id>` *(show "none" if empty)*

⚠️ Open issues found. Please review before continuing. *(If zero issues: ✅ No open issues.)*

**Next steps:**
```
/modscape:spec:design <name>     # design the next table (one table per invocation)
/modscape:spec:tasks <name>      # all tables designed? generate implementation tasks
/modscape:spec:review <name>     # review design status
```

To preview the model:
```
modscape spec dev <name>
```

If you discover issues, add them to `## Findings` in `design.md` and re-run `/modscape:spec:design <name>`.

---
