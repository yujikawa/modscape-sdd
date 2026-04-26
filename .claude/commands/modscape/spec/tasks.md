Generate an implementation task list from `spec-model.yaml` and write it to `.modscape/changes/<name>/tasks.md`.

## Instructions

1. If `.modscape/modscape-spec.custom.md` exists, read it — its rules take **priority** for phase structure and additional tasks.

2. Read `.modscape/changes/<name>/spec-model.yaml` (default path) or the path provided by the user.

3. Check that `lineage` is defined.
   - If `lineage` is missing or empty: stop and tell the user:
     > No `lineage` entries found in `spec-model.yaml`. Run `/modscape:spec:design` to add lineage before generating tasks.

4. Build a dependency graph from `lineage` entries (`from` → `to`), then topologically sort all tables.

5. Assign each table to a phase based on its depth in the dependency graph:
   - **Phase 1 — Staging**: tables with no upstream dependencies (leaf sources)
   - **Phase 2 — Core**: tables that depend only on Phase 1 tables (facts, dimensions, hubs, links, satellites)
   - **Phase 3 — Mart**: tables furthest downstream (mart type, or aggregated outputs)
   - **Phase 4 — Tests**: one test task per table that has a primary key column or foreign key column

   For each task, include:
   - Table ID in backticks
   - Materialization type in brackets (from `physical.strategy` or inferred from `conceptual.kind`)
   - Upstream dependencies with `←` notation (omit for Phase 1)

6. Write `.modscape/changes/<name>/tasks.md` using the format below.

7. Update `Status` in `.modscape/changes/<name>/spec.md` from `design` to `tasks` (if spec.md exists).

## tasks.md Format

```markdown
# Pipeline Tasks
> Generated from: .modscape/changes/<name>/spec-model.yaml
> Spec: .modscape/changes/<name>/spec.md
> Progress: 0 / <total>

## Phase 1: Staging
- [ ] `<table_id>` [<materialization>]

## Phase 2: Core
- [ ] `<table_id>` [<materialization>] ← <upstream_1>, <upstream_2>

## Phase 3: Mart
- [ ] `<table_id>` [<materialization>] ← <upstream_1>

## Phase 4: Tests
- [ ] `<table_id>` — <column_id>: unique, not_null
- [ ] `<table_a>` → `<table_b>` FK test
```

## Usage

```
/modscape:spec:tasks <name>
/modscape:spec:tasks <name> path/to/spec-model.yaml
```

## Next Step

After generating `tasks.md`, guide the user:

> `tasks.md` has been generated. Run `/modscape:spec:implement` next to start implementation.
