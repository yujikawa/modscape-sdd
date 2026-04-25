Show a review summary of the current spec work folder — open questions, assumptions, AC coverage, and downstream classification confidence — to support go/no-go decisions before implementation.

## Usage

```
/modscape:spec:review <name>
```

## Instructions

1. Check that `.modscape/changes/<name>/` exists.
   - If not: stop and tell the user:
     > `changes/<name>/` not found. Run `/modscape:spec:requirements` to start a new spec.

2. Read the following files (skip silently if a file does not exist):
   - `.modscape/changes/<name>/spec.md` — Acceptance Criteria (AC-NNN entries)
   - `.modscape/changes/<name>/questions.md` — open questions
   - `.modscape/changes/<name>/design.md` — assumptions (`**仮定:**` / `**Assumption:**` lines), downstream classification confidence notes
   - `.modscape/changes/<name>/tasks.md` — Phase 4 test tasks with `[→ AC-NNN]` and `[手動検証]` markers

3. Build the review summary:

   **a. Unresolved questions**
   - Count lines matching `- [ ]` in `questions.md`
   - List their Q-NNN IDs

   **b. Assumptions**
   - Find lines containing `**仮定:**` or `**Assumption:**` in `design.md` and `questions.md`
   - Count and list them briefly (first 60 chars of each line)

   **c. AC Coverage** (requires both `spec.md` and `tasks.md`)
   - Extract all `AC-NNN:` entries from `spec.md` Acceptance Criteria
   - For each AC-NNN, check if any Phase 4 task in `tasks.md` contains `[→ AC-NNN]`
   - Classify each AC as:
     - **Test covered**: at least one Phase 4 task references it with `[→ AC-NNN]`
     - **Manual verification**: no test task, but `[manual verification]` appears near the AC in tasks.md, or the AC text describes a non-automatable condition (e.g. "match source", "row count matches source")
     - **Uncovered**: no reference found in tasks.md at all
   - If `spec.md` or `tasks.md` do not exist, or have no AC-NNN entries: skip this section

   **d. Downstream classification confidence**
   - Scan `design.md` for tables marked with low confidence (text like "confidence is low" or "classification confidence is low")
   - List those table IDs

4. Display the summary:

   ```
   ## Review: <name>

   ### Unresolved Questions
   - 3 件 — Q-001, Q-003, Q-007 (see .modscape/changes/<name>/questions.md)

   ### Assumptions
   - 2 件
     - `fct_orders`: NULL rate assumed < 5% (unconfirmed)
     - ...

   ### AC Coverage (4/6)
   - ✅ AC-001: <text> ← Phase 4 test
   - ✅ AC-003: <text> ← Phase 4 test
   - 🔧 AC-002: <text> [manual verification]
   - ❌ AC-004: <text> — no test generated
   - ❌ AC-005: <text> — no test generated

   ### Downstream Classification (Low Confidence)
   - `dim_customer`: lineage only — Context Only (low confidence)
   ```

5. Evaluate overall status:
   - If **all** of the following are true: no unresolved questions AND no assumptions AND all ACs are covered AND no low-confidence downstream tables
     → Display: `✅ No open issues. Ready to implement.`
   - Otherwise:
     → Display: `⚠️ Open issues found above. Please review before implementing. You may still proceed to implementation if needed.`

6. **Always output the following next steps at the end, without exception:**

---
**Next steps:**
```
/modscape:spec:implement <name>   # proceed to implementation
/modscape:spec:review <name>      # re-run this summary after making changes
```
---
