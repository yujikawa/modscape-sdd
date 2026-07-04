Implement pending tasks from `.modscape/changes/<name>/tasks.md` one by one.

## Usage

```
/modscape:spec:implement <name>
/modscape:spec:implement <name> path/to/model.yaml
```

`<name>` is the work folder name (e.g., `monthly-sales-summary`).

## Instructions

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
   - If `.modscape/changes/<name>/design.md` exists: read the `### Downstream Impact — Context Only` section and extract all table IDs listed there into a skip list.
   - If `design.md` does not exist or has no such section: the skip list is empty — all tables are treated as implementation targets (backwards compatible).

4. Check for pending tasks (`- [ ]`).
   - If all tasks are complete (`- [x]`): tell the user:
     > All tasks are complete. Run `/modscape:spec:archive <name>` to sync the permanent table specs.
   - Otherwise: find the first pending task and proceed.

5. For each pending task, in phase order:

   **Staging / Core / Mart tasks:**
   - If the table ID for this task is in the **Context Only skip list**: output `⏭️ Skipping \`<id>\` (Context Only)` and move to the next task without generating any code.
   - Otherwise: read the corresponding table definition from `.modscape/changes/<name>/spec-model.yaml` (the work-scoped YAML, NOT the main model.yaml)
   - Generate implementation code for the target tool (dbt, SQLMesh, etc.)
   - Follow the dependency order defined in `lineage` — always generate upstream tables first
   - Place generated files in the appropriate location (e.g., `models/staging/`, `models/core/`, `models/mart/`)

   **Test tasks:**
   - Generate test definitions for primary keys (unique + not_null) and foreign key relationships
   - For dbt: write to `models/schema.yml` or the appropriate schema file

6. After generating code for a task, immediately update the checkbox in `.modscape/changes/<name>/tasks.md`:
   `- [ ]` → `- [x]`

7. If during implementation you discover anything that requires human investigation (e.g. unexpected column type, NULL in a column assumed non-null, source record not found), append a question to `.modscape/changes/<name>/questions.md` using the next available Q-NNN ID, then ask the user whether to pause or continue with an assumption:
   > ⚠ 実装中に不明な点が見つかりました（**Q-NNN** として questions.md に記録しました）。回答を待ちますか、それとも仮定で進めますか？

8. After each task, confirm with the user before proceeding:
   > Task complete. Ready to move on to the next task?

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

### FROM / JOIN clause — `lineage[].join_type`

For each `lineage` entry where `to` is the current table:
- **`inner`**: generate `INNER JOIN {{ ref('from_table') }} ON ...`
- **`left`**: generate `LEFT JOIN {{ ref('from_table') }} ON ...`
- **`cross`**: generate `CROSS JOIN {{ ref('from_table') }}`
- **`none`**: reference the table as a CTE only; do not generate a JOIN clause
- **When omitted**:
  - If a `relationships` entry exists for the pair → default to `LEFT JOIN` using the relationship columns
  - Otherwise → treat as `none` (CTE reference)

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

## If You Discover Issues During Implementation

If running the pipeline reveals unexpected results (wrong grain, high NULL rate, upstream data issues, etc.):

1. Add the finding to `.modscape/changes/<name>/design.md` under the `## Findings` section
2. Re-run `/modscape:spec:design <name>` to update the design and regenerate pending tasks
3. Resume implementation with the updated task list

**When notifying the user of a discovered issue, always output:**

---
⚠️ Issue found during implementation: <issue description>

**Next step:**
1. Add the following to `### Requires Model Change` in `.modscape/changes/<name>/design.md`:
   `- <table-id>: <issue and proposed fix>`
2. Then re-run:
```
/modscape:spec:design <name>
```
---

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
> Run `modscape dev spec-model.yaml` to review the final model in the visualizer.
