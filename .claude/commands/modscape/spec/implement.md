Implement pending tasks from `.modscape/changes/<name>/tasks.md` one by one.

## Usage

```
/modscape:spec:implement <name>
/modscape:spec:implement <name> path/to/model.yaml
```

`<name>` is the work folder name (e.g., `monthly-sales-summary`).

## Instructions

> ⛔ **Do not directly edit generated files**: Even when a fix is needed during implementation, never edit generated SQL/dbt files directly. Always make changes in the order: `design.md → spec-model.yaml → regenerate`.

0. **Resolve `<name>`** — if the user did not provide a spec name argument:
   ```bash
   modscape spec list
   ```
   - No specs: stop and tell the user to run `modscape spec new <name>` first.
   - Exactly one spec: use it automatically and note "Using spec: `<name>`".
   - Multiple specs: show the list and ask the user to choose one.

1. Read `.modscape/modscape-spec.custom.md` if it exists — it contains all project-specific rules including target tool, output directories, naming conventions, and code generation preferences. These rules take **priority** over any defaults.
   If `.modscape/codegen-rules.md` also exists, read it as supplementary reference.

   **When reading model information, always use modscape CLI commands — do not use `grep` or direct file reads unless the information is genuinely unavailable from CLI:**
   ```bash
   modscape table list <file>
   modscape table get <file> --id <id>
   modscape lineage list <file>
   modscape relationship list <file>   # join keys and cardinality between tables
   modscape summary <file> --json
   ```

2. Check that `.modscape/changes/<name>/tasks.md` exists.
   - If it does not exist: stop and tell the user:
     > `changes/<name>/tasks.md` not found. Run `/modscape:spec:design <name>` first to generate the task list.

3. **Build the Context Only skip list** from `design.md`:
   - If `.modscape/changes/<name>/design.md` exists: read the `## Affected Tables` table and extract all table IDs whose Impact column value is `Downstream — Context Only` into a skip list.
   - If `design.md` does not exist or has no matching rows: the skip list is empty — all tables are treated as implementation targets (backwards compatible).

4. Set the phase if not already `implement`:
   ```bash
   modscape spec get <name> --json
   ```
   - If `phase` is not `implement`: run `modscape spec set-phase <name> implement`
   - If `phase` is already `implement`: skip

5. Check for pending tasks (`- [ ]`).
   - If all tasks are complete (`- [x]`): tell the user:
     > All tasks are complete. Run `/modscape:spec:archive <name>` to sync the permanent table specs.
   - Otherwise: find the first pending task and proceed.

6. For each pending task, in phase order:

   **Staging / Core / Mart tasks:**
   - If the table ID for this task is in the **Context Only skip list**: output `⏭️ Skipping \`<id>\` (Context Only)` and move to the next task without generating any code.
   - Otherwise: read the corresponding table definition from `.modscape/changes/<name>/spec-model.yaml` (the work-scoped YAML, NOT the main model.yaml)
   - Load knowledge-base context for the target table:
     ```bash
     modscape spec context --ids <table-id> --json
     ```
     If the command returns empty or `.modscape/specs/` does not exist, skip and continue.
     Apply returned knowledge to code generation:
     - `rules`: reflect filter conditions, NULL handling, and JOIN constraints directly in generated SQL; add `-- NOTE:` comment when `counter_case` is present
     - `decisions`: apply as architectural constraints (grain, calculation basis, SCD patterns)
     - `terms`: resolve business term → column/filter/calculation mappings
   - Read implementation details for the table:
     1. **Preferred**: read `changes/<name>/design/<table-id>.md` if it exists — this contains table-specific expressions, filters, validation SQL, and test patterns.
     2. **Fallback**: if `design/<table-id>.md` does not exist, look for `### <table-id>` under `## Implementation Details` in `design.md` (backwards compatible with older specs).
   - Generate implementation code for the target tool (dbt, SQLMesh, etc.)
   - Follow the dependency order defined in `lineage` — always generate upstream tables first
   - Place generated files in the appropriate location (e.g., `models/staging/`, `models/core/`, `models/mart/`)

   **Test tasks:**
   - Generate test definitions for primary keys (unique + not_null) and foreign key relationships
   - For dbt: write to `models/schema.yml` or the appropriate schema file

6. After generating code for a task, immediately update the checkbox in `.modscape/changes/<name>/tasks.md`:
   `- [ ]` → `- [x]`

7. If during implementation you discover anything that requires human investigation (e.g. unexpected column type, NULL in a column assumed non-null, source record not found), append a question to `.modscape/changes/<name>/questions.md` (create if it does not exist) using the next available Q-NNN ID (read current max across both `_questions.yaml` and `questions.md` first), then ask the user whether to pause or continue with an assumption:
   ```yaml
   - id: Q-NNN
     question: "<what needs investigation>"
     status: open         # or: assumed (if you proceed with an assumption)
     assumption: "<what you assumed>"   # only if status: assumed
     ids: [<model-id>]  # model-id: any id defined in model.yaml (table, relationship, domain, metric). Omit if not applicable.
     date: <YYYY-MM-DD>
     change: <name>
   ```
   > ⚠ A question came up during implementation (recorded as **Q-NNN** in `questions.md`). Should I wait for your answer or proceed with an assumption?

   Also flag signals that would cause an **analyst to draw wrong conclusions from this data** — add to `questions.md` with `source: ai-detected` and `status: open` WITHOUT pausing. Also generate a PII-safe investigation query in the `investigation:` block:
   - A cross-system JOIN produces unexpected row counts — the join key may not be semantically equivalent, causing silent over- or under-counting
   - A source column contains values not listed in the spec (unknown status codes, unexpected NULL patterns) — an analyst filtering on documented values would miss these records
   - An ID column has mixed formats or patterns suggesting it was populated by different processes — selecting "all" rows may include records with different business meaning
   - A measure column has a wider value range than expected (e.g., negative values, zero, outliers) — analysts may not know to handle these correctly

   Use this format for `ai-detected` entries:
   ```yaml
   - id: Q-NNN
     question: "<specific question: what would an analyst get wrong without knowing this?>"
     status: open
     source: ai-detected
     ids: [<model-id>]  # model-id: any id defined in model.yaml (table, relationship, domain, metric). Omit if not applicable.
     date: <YYYY-MM-DD>
     change: <name>
     investigation:
       query: |
         -- PII-safe: aggregation only
         SELECT <column>, COUNT(*) AS cnt
         FROM <table>
         GROUP BY <column>
         ORDER BY cnt DESC
       result: null     # human fills in after running the query
       finding: null    # AI fills in after result is provided via /modscape:spec:answer
   ```

   **PII safety rules for the generated query:**
   - Only aggregate functions: COUNT, COUNT(DISTINCT), MIN, MAX, AVG, SUM
   - Never SELECT * or raw row samples
   - Never include columns that may contain PII (names, emails, phone numbers, addresses, birth dates, national IDs, IP addresses, account numbers)
   - If unsure whether a column contains PII, exclude it and add a `-- PII risk: excluded` comment

   > ⚠️ **Human review required before running**: The AI generates this query as a starting point following PII-safety rules, but **the human must review the query before executing it** to verify no PII columns are inadvertently included. AI cannot know which columns contain PII in your specific environment. Never run without reviewing.

8. **One-task-per-invocation**: After completing the task, update the checkbox and stop. Output the completion message and guide the user to run again:
   > ✅ Task complete. Run `/modscape:spec:implement <name>` again to implement the next task.

## Code Generation Guidelines

- Follow `physical.*` fields in `spec-model.yaml` when present; fall back to `conceptual.kind` defaults
- Use `{{ ref('table_id') }}` (dbt) or equivalent for upstream references derived from `lineage`
- Add `-- TODO:` comments where `spec-model.yaml` lacks sufficient information to generate definitive code
- Keep generated code minimal and correct — do not add logic not supported by the YAML

### SELECT clause — `columns[].expression`

For each column in the target table:
- **If `expression` is set**: use it verbatim as the SELECT expression.
  ```sql
  -- expression: "CAST(raw_amount AS DECIMAL(18,2)) * fx_rate"
  CAST(raw_amount AS DECIMAL(18,2)) * fx_rate AS amount
  ```
- **If `expression` is absent**: derive the expression from `column.physical.name` → `column.name` → column `id` (in that priority order), or add a `-- TODO:` comment if none can be resolved.

### FROM / JOIN clause — `lineage[].join_type` + `relationships`

Before generating any JOIN clause, run:
```bash
modscape relationship list .modscape/changes/<name>/spec-model.yaml
```
This gives the ON columns and cardinality for every table pair.

For each `lineage` entry where `to` is the current table:
1. Look up the `relationships` entry where `from.table` and `to.table` match the lineage pair → use `from.column` / `to.column` as the ON condition
2. Apply the join type from `lineage[].join_type`:
   - **`inner`**: `INNER JOIN {{ ref('from_table') }} ON a.col = b.col`
   - **`left`**: `LEFT JOIN {{ ref('from_table') }} ON a.col = b.col`
   - **`cross`**: `CROSS JOIN {{ ref('from_table') }}` (no ON clause)
   - **`none`**: reference as CTE only; do not generate a JOIN clause
   - **When omitted**: default to `LEFT JOIN` if a relationship exists; otherwise treat as `none`
3. If no matching `relationship` entry exists for the pair → add `-- TODO: relationship not defined for this join` and record a question in `questions.md`

### WHERE clause — `physical.filter_key` / `physical.lookback`

When `physical.strategy: incremental` and `physical.filter_key` is set:
```sql
WHERE {{ filter_key }} > {{ last_run_timestamp() }}
```
If `physical.lookback` is also set (e.g. `"3 days"`):
```sql
WHERE {{ filter_key }} > {{ last_run_timestamp() }} - INTERVAL 3 DAY
```
When `filter_key` is absent, infer from column names (`updated_at`, `created_at`, `loaded_at`) or add `-- TODO: specify physical.filter_key`.

### SCD Type2 SQL — `logical.scd`

When `logical.scd.type: type2`, generate a MERGE/snapshot pattern:
- Use `logical.scd.business_key` columns as the JOIN condition to identify existing records
- Use `logical.scd.valid_from` / `logical.scd.valid_to` as the effective date range columns
- If `logical.scd.current_flag` is set, include it as a boolean flag for the active record
- For composite `business_key`, build a multi-column JOIN: `ON src.a = tgt.a AND src.b = tgt.b`

When `logical.scd.type: type2` but `business_key`/`valid_from`/`valid_to` are absent:
- Attempt to infer roles from column names (`valid_from`, `valid_to`, `is_current`, `current_flag`, etc.)
- Add `-- TODO: set logical.scd fields to specify column roles` for any unresolved column

## When User Requests a Modification During Implementation

When the user explicitly requests a modification during the implementation session — whether via a command or **in plain conversation** ("change this column type", "add a table", "modify the lineage") — handle it inline without switching commands. Update all three files in order, then ask to continue.

**Update sequence (all modifications):**

1. **Update `design/<table-id>.md`** — update the relevant Implementation Details in `changes/<name>/design/<table-id>.md` (create the file if it does not exist, using the format in `.modscape/formats/design-table-format.md`).
2. **Update `spec-model.yaml`** — apply changes with mutation CLI and run validate:
   ```bash
   modscape column update .modscape/changes/<name>/spec-model.yaml --table <id> --column <col-id> --type <new-type>
   modscape validate .modscape/changes/<name>/spec-model.yaml
   ```
3. **Update `tasks.md` surgically** — update only the affected tasks:
   - **Column-level changes** (type, name, constraint, expression): uncheck the affected table's task (`[x]` → `[ ]`) — confirm with user first (see output format below)
   - **Table additions**: determine the new table's phase from its lineage (leaf node = Staging, 1-hop downstream = Core, furthest downstream = Mart), insert a new `- [ ]` task in the correct phase group
   - **Table deletions**: remove the task row for the deleted table (skip if already `[x]`)
   - **Lineage / grain changes**: uncheck the changed table's task AND all downstream tables' tasks (`[x]` → `[ ]`)
4. **Output the update summary** and ask to continue:

---
✅ Modification complete.

| File | Changes |
|---|---|
| design.md | <description of what was updated> |
| spec-model.yaml | <what was changed> |
| tasks.md | <list of tasks added, removed, or unchecked> |

Ready to continue implementation? (yes / no)

---

- **yes** → resume from the next pending task
- **no** → stop (show save hint)

## Completion

**When all tasks are done, always output the following message, without exception:**

---
✅ All tasks complete!

**Next step:**
```
/modscape:spec:archive <name>
```
---

**After each individual task completion**, also output:

---
✅ Task complete: `<task description>`

<n> tasks remaining. Ready to continue?

---
> Run `modscape spec dev <name>` to review the final model in the visualizer.
