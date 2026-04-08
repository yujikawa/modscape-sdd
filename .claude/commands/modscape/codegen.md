Generate implementation code from a Modscape YAML model.

## Instructions
1. FIRST, read `.modscape/codegen-rules.md` to understand how to interpret the YAML.
2. SECOND, read the target YAML file specified by the user (default: `model.yaml`).
3. Ask the user which tool to target if not specified (dbt / SQLMesh / Spark SQL / plain SQL).
4. Generate models in dependency order (upstream first) based on `lineage.upstream`.
5. Add `-- TODO:` comments wherever the YAML does not provide enough information to generate definitive code.

## Usage
```
/modscape:codegen
/modscape:codegen path/to/model.yaml
/modscape:codegen path/to/model.yaml --target dbt
```
