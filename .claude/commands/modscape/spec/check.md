Pre-implementation quality check: SSOT-driven consistency + go/no-go readiness.

## Usage

```
/modscape:spec:check <name> [--from <artifact>]
```

- `<artifact>` is one of `spec-model.yaml` (default), `design.md`, or `spec.md`.

## Instructions

0. **Detect language** — If `.modscape/modscape-spec.custom.md` exists, read it and look for a `## Communication` section. If it contains a language directive (e.g., "Always respond in Japanese"), use that language for all output in this session. Otherwise default to English.

1. **Resolve `<name>`** — if the user did not provide a spec name argument:
   ```bash
   modscape spec list
   ```
   - No specs: stop and tell the user to run `modscape spec new <name>` first.
   - Exactly one spec: use it automatically and note "Using spec: `<name>`".
   - Multiple specs: show the list and ask the user to choose one.

2. Check that `.modscape/changes/<name>/` exists.
   - If not: stop and tell the user:
     > `changes/<name>/` not found. Run `/modscape:spec:requirements` to start a new spec.

3. **Resolve the SSOT** from the `--from` argument (default: `spec-model.yaml`).
   Valid values: `spec-model.yaml`, `design.md`, `spec.md`.
   If an invalid value is given, display an error and list valid options.

4. **Read required files** (skip silently if a file does not exist — note which were skipped):
   - `.modscape/changes/<name>/spec.md`
   - `.modscape/changes/<name>/design.md`
   - `.modscape/changes/<name>/tasks.md`
   - `.modscape/changes/<name>/questions.md`
   - `.modscape/changes/<name>/spec-model.yaml` — use `modscape table list` to extract table IDs

---

### Part 1: SSOT-driven Consistency

Run only the checks relevant to the chosen SSOT. For each category, if a required file is missing, display `⏭ skipped — <filename> not found` and move on.

For each issue found, always include a **→ Fix:** line explaining which file to update and why.

---

#### When SSOT = `spec-model.yaml` (default)

**A. spec-model.yaml → design.md: Table classification completeness**

- Get all table IDs from `modscape table list .modscape/changes/<name>/spec-model.yaml`
- Check each ID appears in `design.md` under `## Affected Tables` (Direct Impact, Downstream — Implement, or Downstream — Context Only)
- ❌ Flag any table in `spec-model.yaml` that has no classification in `design.md`
  - → Fix: Run `/modscape:spec:design <name>` to classify the missing table(s).

**B. spec-model.yaml → tasks.md: Direct Impact task coverage**

- Extract table IDs listed under `### Direct Impact` in `design.md`
- For each, check that at least one task in `tasks.md` references it (by table ID or closely matching name)
- ❌ Flag Direct Impact tables with no corresponding task
  - → Fix: Add a task to `tasks.md`, or re-run `/modscape:spec:tasks <name>` to regenerate.

**C. spec-model.yaml → questions.md: Recording assumptions for unresolved questions**

- Find all unresolved Q-NNN entries in `questions.md` (status: open or assumed)
- For each, check if `design.md` contains a reference to that Q-NNN or an assumption statement (`**Assumption**` block)
- ⚠️ Flag unresolved questions with no assumption recorded
  - → Fix: Run `/modscape:spec:answer <name>` to answer or record an assumption.

---

#### When SSOT = `design.md`

**A. design.md → spec-model.yaml: Verifying tables in Implementation Details exist in spec-model.yaml**

- Extract table IDs listed under `## Implementation Details` in `design.md`
- Check each ID against `modscape table list .modscape/changes/<name>/spec-model.yaml`
- ❌ Flag any table in `design.md` Implementation Details that is absent from `spec-model.yaml`
  - → Fix: Update `design.md` to remove or correct the table entry, or add the table to `spec-model.yaml` using the mutation CLI.

**B. design.md → tasks.md: Direct Impact task coverage**

- Extract table IDs listed under `### Direct Impact` in `design.md`
- For each, check that at least one task in `tasks.md` references it (by table ID or closely matching name)
- ❌ Flag Direct Impact tables with no corresponding task
  - → Fix: Add a task to `tasks.md`, or re-run `/modscape:spec:tasks <name>` to regenerate.

**C. design.md → spec.md: Consistency check between AC entries and design decisions**

- Extract all `AC-NNN` entries from `spec.md`
- For each AC, check if `design.md` references that AC-NNN or its topic
- ⚠️ Flag ACs that have no corresponding mention in `design.md`
  - → Fix: Update `design.md` to reference the AC, or update `spec.md` if the requirement changed.

---

#### When SSOT = `spec.md`

**A. spec.md → design.md: Verify each AC is referenced in design.md**

- Extract all `AC-NNN` entries from `spec.md`
- Check if each AC-NNN is mentioned in `design.md`
- ❌ Flag ACs absent from `design.md`
  - → Fix: Update `design.md` to address the AC, or note it as out-of-scope with a reason.

**B. spec.md → tasks.md: Phase 4 test coverage for each AC**

- For each AC-NNN in `spec.md`, check if at least one Phase 4 task in `tasks.md` contains `[→ AC-NNN]`, or if `[manual verification]` is noted near the AC
- Classify each AC:
  - ✅ **Test covered**: Phase 4 task references it with `[→ AC-NNN]`
  - 🔧 **Manual verification**: no test task but `[manual verification]` appears
  - ❌ **Uncovered**: no reference in tasks file
- ❌ Flag uncovered ACs
  - → Fix: Add a Phase 4 test task, or mark as `[manual verification]` in `tasks.md`.

---

### Part 2: Readiness (always run regardless of SSOT)

**Unresolved questions**
- Count lines matching open/assumed status in `questions.md`; list their Q-NNN IDs

**Assumptions**
- Find all `**Assumption**` blocks in `questions.md` and `design.md`; count and list briefly

**AC Coverage** (requires both `spec.md` and `tasks.md`)
- For each AC-NNN in `spec.md`, check Phase 4 task coverage (same logic as SSOT=spec.md check B)
- Skip if already run as Part 1

**Documentation Coverage** (only when `modscape-spec.custom.md` has a `## Coverage Policy` section with a minimum threshold)
- Run: `modscape coverage .modscape/changes/<name>/spec-model.yaml`
- Flag tables below the threshold with ⚠️
- If no Coverage Policy: `⏭ skipped — no Coverage Policy set in modscape-spec.custom.md`

---

5. **Display the combined report:**

```
## Check: <name>  (SSOT: <artifact>)

### Part 1: Consistency

#### A. <check title>
✅ <pass message>
❌ <table-id>: <issue description>
   → Fix: <what to do>

#### B. <check title>
...

---

### Part 2: Readiness

#### Unresolved Questions
- <n> — <Q-NNN list>

#### Assumptions
- <n>
  - ...

#### AC Coverage (<n>/<total>)
- ✅ AC-001 ← Phase 4 test
- 🔧 AC-002 [manual verification]
- ❌ AC-003 — no test or manual note found

#### Documentation Coverage
⏭ skipped — no Coverage Policy set in modscape-spec.custom.md
```

6. **Evaluate overall status:**

- **Ready** — no ❌ in Part 1 AND no uncovered ACs AND no unresolved questions:
  → `✅ No issues found. Ready to implement.`
- **Proceed with caution** — only ⚠️ warnings, or open questions/assumptions exist but no ❌:
  → `⚠️ Issues found above. Review before implementing. You may still proceed if needed.`
- **Blocker** — at least one ❌:
  → `🚫 Blocking issues found. Fix inconsistencies before implementing.`

7. **Always output the following next steps at the end:**

---
**Next steps:**
```
/modscape:spec:design <name>    # re-run design to fix model/task gaps
/modscape:spec:implement <name> # proceed to implementation
/modscape:spec:check <name>     # re-run after making changes
/modscape:spec:check <name> --from design.md   # check from design.md as SSOT
/modscape:spec:check <name> --from spec.md     # check from spec.md as SSOT
```
---
