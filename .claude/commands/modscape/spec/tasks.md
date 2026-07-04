Generate an implementation task list from `spec-model.yaml` and write it to `.modscape/changes/<name>/tasks.md`.

## Instructions

0. **Resolve `<name>`** — if the user did not provide a spec name argument:
   ```bash
   modscape spec list
   ```
   - No specs: stop and tell the user to run `modscape spec new <name>` first.
   - Exactly one spec: use it automatically and note "Using spec: `<name>`".
   - Multiple specs: show the list and ask the user to choose one.

1. If `.modscape/modscape-spec.custom.md` exists, read it — its rules take **priority** over all defaults, including phase structure, additional tasks, and **communication preferences** (language, response format, etc.). Apply every rule in the file.

2. Read `.modscape/changes/<name>/spec-model.yaml` (default path) or the path provided by the user.

3. **Build the Context Only skip list** from `design.md`:
   - If `.modscape/changes/<name>/design.md` exists: read the Affected Tables section and extract all table IDs with "Downstream — Context Only" in the Impact column into a skip list.
   - If `design.md` does not exist or has no such entries: the skip list is empty — all tables are treated as implementation targets.

4. Check that `lineage` is defined.
   - If `lineage` is missing or empty: stop and tell the user:
     > No `lineage` entries found in `spec-model.yaml`. Run `/modscape:spec:design` to add lineage before generating tasks.

5. Build a dependency graph from `lineage` entries (`from` → `to`).
   - Only include nodes that exist in `tables`. Exclude `consumers` and any node not in `tables`.

6. Group tables into phases based on their position in the dependency graph (upstream tables first). Name each phase in a way that clearly describes the role of tables it contains — choose names that match the spec's context (e.g., "Staging", "Core", "Mart", "Reference Data", "Intermediate"). If `.modscape/modscape-spec.custom.md` specifies phase names or structure, follow those instructions instead.
   - **Skip any table in the Context Only skip list** — do not assign it to any phase.

   For each task, include only:
   - Table ID in backticks

7. **Write `.modscape/changes/<name>/tasks.md`** — behavior depends on the current state of the file:

   - **`tasks.md` does not exist** → generate fresh following the format.
   - **`tasks.md` exists and has 0 completed tasks (`- [x]`)** → overwrite and regenerate.
   - **`tasks.md` exists and has 1 or more completed tasks (`- [x]`)** → perform a merge:
     1. Compute the diff and present it to the user:
        - **Add**: tables present in the new `spec-model.yaml` but not in the current `tasks.md` → add as `[ ]`
        - **Keep**: tasks present in both with `[x]` → preserve `[x]`
        - **Remove**: tables present in the current `tasks.md` but removed from the new `spec-model.yaml` → delete
        ```
        Updating tasks.md.

        Add:    [ ] <table-id> (new)
        Keep:   [x] <table-id>, [x] <table-id>
        Remove: <table-id> (removed from spec-model.yaml)

        Continue? [y/N]
        ```
     2. After the user confirms, execute the merge and write following the format.

   Use the table ID as the task identifier key. If an ID changes, treat it as a remove + add.

8. Set the phase by running:
   ```bash
   modscape spec set-phase <name> tasks
   ```

## tasks.md Format

The format template is defined in `.modscape/formats/tasks-format.md`.
Read that file before writing `tasks.md` and use it as the template.

Omit the `## Context Only (Skipped)` section entirely if the skip list is empty.

## Usage

```
/modscape:spec:tasks <name>
/modscape:spec:tasks <name> path/to/spec-model.yaml
```

## Next Step

After generating `tasks.md`, guide the user:

> `tasks.md` has been generated. Run `/modscape:spec:implement` next to start implementation.
