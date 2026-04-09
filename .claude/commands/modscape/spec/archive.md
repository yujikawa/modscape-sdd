Merge the work-scoped YAML back into the master model, then sync permanent table specs in `.modscape/specs/`.

## Usage

```
/modscape:spec:archive <name>
/modscape:spec:archive <name> path/to/master.yaml
```

`<name>` is the work folder name (e.g., `monthly-sales-summary`).
`path/to/master.yaml` is the master model file (default: `model.yaml` in the current directory).

## Instructions

**When reading model information, always use modscape CLI commands or MCP tools — do not use `grep` or direct file reads unless the information is genuinely unavailable from CLI:**
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

### Step 1: Merge work YAML into master YAML(s)

3. For each master YAML listed in `spec-config.yaml`, extract only the tables assigned to it and merge:
   ```bash
   modscape extract .modscape/changes/<name>/spec-model.yaml --tables <ids-for-this-yaml> --output /tmp/spec-slice.yaml
   modscape merge <master>.yaml /tmp/spec-slice.yaml --output <master>.yaml --patch
   ```

   If `spec-config.yaml` has only one master YAML, merge the entire work YAML directly:
   ```bash
   modscape merge <master>.yaml .modscape/changes/<name>/spec-model.yaml --output <master>.yaml --patch
   ```

4. Check the merge output for duplicate table ID warnings.
   If any duplicates were detected, report them to the user:
   > ⚠ The following tables existed in both the work YAML and the master YAML.
   > The spec version was used: `<table-id>`, `<table-id>`
   > Please verify the master YAML diff looks correct.

5. Run validate on each merged master YAML and fix any errors before proceeding:
   ```bash
   modscape validate <master>.yaml
   ```

### Step 2: Sync permanent table specs

5. Use the **affected tables classification** built in step 2 above.

6. **Full spec sync for Direct Impact and Downstream Impact — Implement tables**:

   For each table in **Direct Impact** or **Downstream Impact — Implement**:

   a. Check whether `.modscape/specs/<table-id>.md` exists.
      - If **not**: create a new file using the format below.
      - If **exists**: update only the relevant sections (Overview, Business Context, Business Rules, Known Issues); preserve unrelated content.

   b. Append a Changelog entry:
      ```
      - <YYYY-MM-DD>: <brief description of change> (SDD: <name>)
      ```

7. **Changelog only for Downstream Impact — Context Only tables**:
   - Do **not** perform a full spec sync for these tables.
   - Only append a Changelog entry to `.modscape/specs/<table-id>.md` (create the file with minimal content if it does not exist):
     - Append: `- <YYYY-MM-DD>: Referenced in downstream lineage; no structural change required (SDD: <name>)`

8. **Report the sync result**:
   > Merged into master YAML ✓
   > Synced specs:
   > - Created: `specs/mart_monthly_sales.md`
   > - Updated: `specs/fct_orders.md`
   > - Changelog only: `specs/stg_raw_orders.md`

### Step 3: Move to archives

9. Move the work folder to `.modscape/archives/YYYY-MM-DD-<name>/` (today's date):
   ```bash
   mkdir -p .modscape/archives
   mv .modscape/changes/<name> .modscape/archives/YYYY-MM-DD-<name>
   ```

10. **Always output the following summary at the end, without exception:**

---
✅ Archive complete.

**Synced specs:**
- Created: `specs/<table-id>.md` ...
- Updated: `specs/<table-id>.md` ...
- Changelog only: `specs/<table-id>.md` ...

**Spec coverage:** <n>/<total> tables have permanent specs.
Tables without specs: <list or "none">

🎉 All work for this spec is complete!
---

## `specs/<table-id>.md` Format

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
- <YYYY-MM-DD>: 初版 (SDD: <name>)
```
