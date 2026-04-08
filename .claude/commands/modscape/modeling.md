Start an interactive data modeling session.

## Instructions
1. FIRST, read `.modscape/rules.md` to understand the project strategy, naming conventions, and YAML schema. If `.modscape/rules.custom.md` exists, read it too — custom rules take priority over the base rules.
2. SECOND, analyze the existing `model.yaml` if it exists.
3. Listen to the user's requirements and propose/apply changes to `model.yaml` strictly following the rules.

## Mutation CLI — Use Before Editing YAML Directly

For targeted changes to tables, columns, relationships, lineage, or domains, **PREFER the mutation CLI commands** over editing YAML directly. CLI commands validate input and write atomically.

Recommended flow:
1. Check existence: `modscape table get model.yaml --id <id> --json`
2. Add or update: `modscape table add` / `modscape table update`
3. After adding tables: `modscape layout model.yaml` to assign coordinates

See Section 13 of `.modscape/rules.md` for the full command reference.

Only edit YAML directly for complex nested fields not covered by CLI flags (e.g., `implementation`, `sampleData`, full `columns` definition).

## Appearance & Layout
- **Appearance**: For new tables, include the `appearance: { type: "..." }` block.
- **Layout**: When creating new entities, always assign initial `x` and `y` coordinates in the `layout` section. Position them logically near their related entities to avoid stacking.

Always prioritize consistency and project-specific standards.
