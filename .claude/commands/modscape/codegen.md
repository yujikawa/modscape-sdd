Generate implementation code from a Modscape YAML model.

## Instructions
1. FIRST, read `.modscape/codegen-rules.md` to understand how to interpret the YAML.
2. SECOND, read the target YAML file specified by the user (default: `model.yaml`).
3. THIRD, collect the target table IDs from the YAML model, then load relevant SDD context:
   ```bash
   modscape spec context --ids <id1>,<id2>,... --json
   ```
   If `.modscape/specs/` does not exist or the command returns empty results, skip this step.
   Use the returned `decisions`, `rules`, and `terms` to generate more accurate code:
   - `decisions`: apply as architectural constraints (grain, calculation standards, SCD patterns)
   - `rules`: apply filter conditions, NULL handling, and JOIN constraints directly in generated code; if `counter_case` is present, add a `-- NOTE:` comment explaining the exception
   - `terms`: resolve business term → column/filter/calculation mappings
   Also read `<table-id>/spec.md` for each table if it exists under `.modscape/specs/`.
4. Ask the user which tool to target if not specified (dbt / SQLMesh / Spark SQL / plain SQL).
5. Generate models in dependency order (upstream first) based on `lineage.upstream`.
6. Add `-- TODO:` comments only where no information (YAML or SDD context) resolves the ambiguity.

## Usage
```
/modscape:codegen
/modscape:codegen path/to/model.yaml
/modscape:codegen path/to/model.yaml --target dbt
```
