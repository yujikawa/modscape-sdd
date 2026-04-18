Search past archives and specs for a keyword, then display relevant findings.
Optionally incorporate selected results into the current spec or design on explicit request.

## Usage

```
/modscape:spec:search <keyword>
/modscape:spec:search <keyword> [--limit <n>]
```

## Instructions

1. Run the search command and capture JSON output:
   ```bash
   modscape spec search <keyword> --json --limit 10
   ```
   - If `.modscape/archives/` and `.modscape/specs/` do not exist or return no results, inform the user:
     > No results found for "<keyword>". No past archives or specs match this keyword.

2. Parse the JSON result. For each entry, read the matched file(s) to gather additional context (e.g., read `design.md` for design decisions, `spec.md` for pipeline goal and data sources).

3. Display a summary grouped by relevance:

   ```
   ## Search Results for "<keyword>"

   ### [1] archives/YYYY-MM-DD-<name>/
   **Title**: <spec title>
   **Type**: archive
   **Relevant content**:
   - design.md: <brief excerpt of design decision>
   - spec.md: Data Sources: <list>

   ### [2] specs/<table-id>.md
   **Title**: <table id>
   **Type**: permanent spec
   **Relevant content**:
   - <brief excerpt>
   ```

4. After displaying the summary, ask the user:
   > Would you like to incorporate any of these findings into the current spec or design?
   > - If yes, specify which result and what to take from it (e.g., "Take the table design from [1]")
   > - If no, you can continue with your current work

5. **Only on explicit user instruction**, incorporate the relevant parts:
   - Table definitions → apply to `.modscape/changes/<name>/spec-model.yaml` using mutation CLI commands
   - Design decisions → append to `.modscape/changes/<name>/design.md` under `## Related Past Specs`
   - Never auto-merge without explicit instruction

## Usage

```
/modscape:spec:search monthly incremental
/modscape:spec:search fct_orders --limit 3
```

## Notes

- Search targets: `.modscape/archives/*/spec.md`, `.modscape/archives/*/design.md`, `.modscape/specs/*.md`
- Results are sorted newest-first for archives
- `--limit` controls the maximum number of results (default: 5 in CLI, 10 in this skill for richer context)
