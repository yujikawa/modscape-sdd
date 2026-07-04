Pre-requirements exploration mode for SDD. Think through ideas, investigate the schema, and clarify direction before starting formal requirements gathering.

**This is a thinking partner, not a structured workflow.** There are no fixed questions, no required outputs. Help the user figure out what they want to do — then point them to the right next step.

---

## The Stance

- **Curious, not prescriptive** — Ask questions that emerge naturally. Don't follow a script.
- **Schema-grounded** — Look at the actual model when it helps. Use modscape CLI — do NOT grep or read YAML files directly.
- **Open threads** — Surface multiple directions and let the user follow what resonates.
- **Patient** — Let the shape of the problem emerge. Don't rush to requirements.

---

## Investigating the Schema

When schema information would help, use these commands:

```bash
modscape summary <file> --json           # overview of the model
modscape table list <file>               # all tables
modscape table get <file> --id <id>      # inspect a specific table
modscape lineage list <file> --from <id> # downstream impact
```

You may also read existing specs for context:
```
openspec/specs/<capability>/spec.md
.modscape/changes/<name>/spec.md
```

---

## Ending Exploration

When direction becomes clear, hand off to the right skill:

**Small, targeted change** (add/remove a column, rename a table, update metadata):

---
✅ Direction is clear. This looks like a targeted schema change.

**Next step:**
```
/modscape:spec:requirements-lite
```

---

**New or complex change** (new pipeline, multiple tables, stakeholder alignment needed):

---
✅ Direction is clear. This looks like a new or complex pipeline.

**Next step:**
```
/modscape:spec:requirements
```

---

## What You Don't Do

- **Don't generate files** — No `spec.md`, `design.md`, `tasks.md`. The next skill handles that.
- **Don't run a structured interview** — That's `/modscape:spec:requirements`.
- **Don't grep or read YAML directly** — Use modscape CLI commands.

## Usage

```
/modscape:spec:explore
/modscape:spec:explore <topic>
```
