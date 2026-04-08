Implement pending tasks from `.modscape/changes/<name>/tasks.md` one by one.

## Usage

```
/modscape:spec:implement <name>
/modscape:spec:implement <name> path/to/model.yaml
```

`<name>` is the work folder name (e.g., `monthly-sales-summary`).

## Instructions

1. Read `.modscape/changes/modscape-spec.custom.md` if it exists — it contains all project-specific rules including target tool, output directories, naming conventions, and code generation preferences. These rules take **priority** over any defaults.
   If `.modscape/codegen-rules.md` also exists, read it as supplementary reference.

   **When reading model information, always use modscape CLI commands or MCP tools — do not use `grep` or direct file reads unless the information is genuinely unavailable from CLI:**
   ```bash
   modscape table list <file>
   modscape table get <file> --id <id>
   modscape lineage list <file>
   modscape summary <file> --json
   ```

2. Check that `.modscape/changes/<name>/tasks.md` exists.
   - If it does not exist: stop and tell the user:
     > `changes/<name>/tasks.md` not found. Run `/modscape:spec:design <name>` first to generate the task list.

3. Check for pending tasks (`- [ ]`).
   - If all tasks are complete (`- [x]`): tell the user:
     > All tasks are complete. Run `/modscape:spec:archive <name>` to sync the permanent table specs.
   - Otherwise: find the first pending task and proceed.

4. For each pending task, in phase order:

   **Staging / Core / Mart tasks:**
   - Read the corresponding table definition from `.modscape/changes/<name>/spec-model.yaml` (the work-scoped YAML, NOT the master model.yaml)
   - Generate implementation code for the target tool (dbt, SQLMesh, etc.)
   - Follow the dependency order defined in `lineage` — always generate upstream tables first
   - Place generated files in the appropriate location (e.g., `models/staging/`, `models/core/`, `models/mart/`)

   **Test tasks:**
   - Generate test definitions for primary keys (unique + not_null) and foreign key relationships
   - For dbt: write to `models/schema.yml` or the appropriate schema file

5. After generating code for a task, immediately update the checkbox in `.modscape/changes/<name>/tasks.md`:
   `- [ ]` → `- [x]`

6. After each task, confirm with the user before proceeding:
   > Task complete. Ready to move on to the next task?

## Code Generation Guidelines

- Follow `implementation.*` fields in `spec-model.yaml` when present; fall back to `appearance.type` defaults
- Use `{{ ref('table_id') }}` (dbt) or equivalent for upstream references derived from `lineage`
- Add `-- TODO:` comments where `spec-model.yaml` lacks sufficient information to generate definitive code
- Keep generated code minimal and correct — do not add logic not supported by the YAML

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
