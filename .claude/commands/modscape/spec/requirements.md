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
   - **Table Relationships** — FK joins between source tables (e.g., `orders.customer_id → customers.id`, cardinality). Ask explicitly if not volunteered: "How do these source tables join to each other?"
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

10.5. Review the conversation for any business or data terms that were introduced or defined.

   Target terms (record these):
   - Project-specific / in-house terms and abbreviations
   - Common words that carry a specific meaning in this project's context

   Skip these (do NOT record):
   - General SQL terms (JOIN, GROUP BY, NULL, etc.)
   - Standard data modeling concepts (fact, dimension, hub, satellite, etc.)
   - Self-evident column names (created_at, id, etc.)

   For each qualifying term, append to `.modscape/changes/<name>/glossary.md` (create the file if it does not exist). Do NOT write to `_glossary.yaml` directly.

   ```markdown
   ## <change-name>

   - **<term-id>**: <definition>
     - label: <日本語名> (optional)
     - tables: <table_a>, <table_b> (optional)
     - columns: <table_a.col> (optional)
   ```

   If no qualifying terms were found, skip silently.

11. Review the **entire conversation** and append question entries to `.modscape/specs/_questions.yaml` for all of the following:

   - **Answered** — questions you asked and the user gave a clear answer to → `status: answered`, record the answer in the `answer` field
   - **Assumed** — items you could not confirm and proceeded with an assumption → `status: assumed`, record the assumption in the `assumption` field
   - **Open** — items still unresolved at the end of the conversation → `status: open`

   **Relationship questions to check specifically** — for each pair of source tables mentioned, verify:
   - Is the join key known? If not → add a question: "What key joins `<A>` and `<B>`?"
   - Is the cardinality known (one-to-many / many-to-one / etc.)? If not → add a question
   - Is the join type known (LEFT / INNER / etc.)? If not → add a question
   These are blocking questions for implementation — do not leave them unasked.

   Use this format. Determine the next ID by reading the current max ID in `_questions.yaml`:
   ```yaml
   - id: Q-NNN
     question: "<question text>"
     answer: "<answer the user gave>"    # only if status: answered
     status: answered                    # answered | assumed | open
     assumption: "<what you assumed>"    # only if status: assumed
     table: <table-id>                   # optional — only if specific to one table
     date: <YYYY-MM-DD>
     change: <name>
   ```

   Record every question that shaped the spec — answered questions are just as important for traceability as open ones.

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
