Gather business requirements interactively and generate `.modscape/changes/<name>/spec.md`.

## Instructions

1. If `.modscape/modscape-spec.custom.md` exists, read it **in addition** to these instructions.
   Rules in `modscape-spec.custom.md` take **priority** when they conflict.

   **When reading model information (tables, lineage, etc.), always use modscape CLI commands — do not use `grep` or direct file reads unless the information is genuinely unavailable from CLI:**
   ```bash
   modscape table list <file>
   modscape table get <file> --id <id>
   modscape lineage list <file>
   modscape summary <file> --json
   ```

2. Read `modscape-spec.custom.md` carefully and extract any settings already defined there. Treat defined settings as answers — **do not ask the user about anything already specified in `modscape-spec.custom.md`**. Key settings to look for:
   - Main YAML path(s) (e.g. `Main YAMLs: models/sales/HR.yaml`)
   - Target tool (e.g. `Target tool is always dbt`)
   - Any other project-wide defaults

3. Collect the following information through conversation, **skipping anything already answered by `modscape-spec.custom.md`**:
   - **Pipeline title** — a short name for this pipeline or data product
   - **Goal** — who is this for and what problem does it solve?
   - **Stakeholders** — owner (team or person) and consumers (downstream users or systems)
   - **Data Sources** — existing tables, databases, or external systems that feed this pipeline
   - **Acceptance Criteria** — concrete, testable conditions for "done" (at least 2–3 items). Assign a sequential ID (`AC-001`, `AC-002`, ...) to each criterion as you write it into `spec.md`. If the user provides criteria in free-form text, you assign the IDs.
   - **Target Tool** — `dbt` | `SQLMesh` | `Spark SQL` | `plain SQL` (skip if set in custom.md)
   - **Main YAML(s)** — path(s) to main model YAML file(s) (skip if set in custom.md; otherwise ask)

4. After collecting requirements, propose a work folder name:
   - Derive a short, descriptive kebab-case name from the pipeline title (e.g., `monthly-sales-summary`)
   - Present the proposed name to the user:
     > Proposed folder name: `<name>`. Is this OK? (Reply with a different name to rename.)
   - Wait for user confirmation or rename.

5. Check whether `.modscape/changes/<name>/` already exists.
   - If it exists: warn the user:
     > `changes/<name>/` already exists. Please specify a different name.
   - If not: proceed to step 7 — **do not create the directory manually**; `modscape spec new` will handle it.

6. Check whether `.modscape/changes/<name>/spec.md` already exists.
   - If it exists: show the current content and ask the user what to update.
   - If not: write the collected requirements using the format below.

7. Scaffold the work folder by running:
   ```bash
   modscape spec new <name>
   ```
   This creates `spec-config.yaml`, `spec-model.yaml`, `design.md`, and `tasks.md`.
   If the folder already exists, skip this step.

8. Update `spec-config.yaml` with the resolved main YAMLs:
   ```bash
   # edit .modscape/changes/<name>/spec-config.yaml directly
   ```

9. Write the requirements to `.modscape/changes/<name>/spec.md`.

10. Set `Status: requirements` in the spec file.

11. Review the conversation for any items you could not confirm with the user (e.g. unknown data owners, undefined SLAs, ambiguous business rules). For each such item, append a question to `.modscape/changes/<name>/questions.md` using the format below. If proceeding with an assumption, record it on the `**Assumption:**` line.

```markdown
- [ ] **Q-NNN** <question text>
  **Assumption:** <what you assumed to proceed> (unconfirmed)
```

Question IDs are sequential within the change (`Q-001`, `Q-002`, ...). Do **not** add a question if the user already provided a clear answer during the conversation.

## spec.md Format

```markdown
# Pipeline Spec: <title>

## Goal
<Who is this for and what problem does it solve?>

## Stakeholders
- owner: <team or person>
- consumers: [<list of downstream users or systems>]

## Data Sources
- <source 1>
- <source 2>

## Table Relationships
- <source_table>.<column> → <other_table>.<column> [<one-to-many|many-to-one|...>]
- (omit section if no FK relationships are known)

## Acceptance Criteria
- [ ] AC-001: <criterion 1>
- [ ] AC-002: <criterion 2>

## Target Tool
<dbt | SQLMesh | Spark SQL | plain SQL>

## Status
requirements
```

## spec-config.yaml Format

```yaml
# Spec-local config — only valid within this changes/<name>/ folder.
main_yamls:
  - path: models/sales/HR.yaml
    tables: []          # populated by design: tables extracted from this YAML
  - path: models/finance/Finance.yaml
    tables: []
```

- `main_yamls` lists all YAML files involved in this spec.
- `tables` under each entry is populated by `/modscape:spec:design` as tables are extracted or assigned.
- New tables added during design are assigned to the first entry by default; the user can reassign.

## Usage

```
/modscape:spec:requirements
```

## Next Step

**Always output the following message at the end, without exception:**

---
✅ `spec.md` created at `.modscape/changes/<name>/spec.md`

**Next step:**
```
/modscape:spec:design <name>
```
---
