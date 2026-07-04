Update SDD artifacts based on issues or discoveries found during implementation. Can be called at any point in the workflow, as many times as needed.

## Usage

```
/modscape:spec:amend <name>
```

`<name>` is the work folder name (e.g., `monthly-sales-summary`).

After the command, describe the issue, error, or change in free text. For example:
- Paste an error message
- Describe a wrong assumption ("the JOIN key is `user_id`, not `customer_id`")
- Note an ambiguity ("I'm not sure if `updated_at` can be NULL — needs checking")

## Instructions

1. Verify that `.modscape/changes/<name>/` exists.
   - If not: stop and tell the user:
     > `changes/<name>/` not found. Run `/modscape:spec:requirements` to start a new spec.

2. Read the following files to understand current state:
   - `.modscape/changes/<name>/spec.md`
   - `.modscape/changes/<name>/design.md`
   - `.modscape/changes/<name>/tasks.md`
   - `.modscape/changes/<name>/questions.md` (if it exists)

3. Analyze the user's input and determine which artifacts need updating:

   | Input type | Target artifacts |
   |---|---|
   | Error message, column name mismatch, wrong data type | `spec.md` (fix related AC) + `tasks.md` (add fix task) |
   | Wrong JOIN key, broken design assumption, schema difference | `design.md` (fix the relevant section) + `tasks.md` (add fix task) |
   | Unresolved question, "needs checking", ambiguity | `questions.md` (add new Q-NNN) |
   | Multiple concerns in one input | All applicable files |

4. **Update `spec.md`** if the issue affects Acceptance Criteria:
   - Find the relevant `AC-NNN` entry
   - Correct it to reflect the actual behaviour or constraint
   - Do NOT renumber existing AC IDs

5. **Update `design.md`** if the issue affects a design decision:
   - Find the relevant section (Decisions, Risks, etc.)
   - Correct or extend it with the discovered information
   - Add a note such as: `> ⚠ Amended <YYYY-MM-DD>: <reason>`

6. **Update `tasks.md`** if code changes are needed:
   - **Never modify `- [x]` completed tasks**
   - Append a new section at the end of the file:
     ```
     ## Amend: <YYYY-MM-DD>

     - [ ] A.1 <fix task description>
     - [ ] A.2 <fix task description>
     ```
   - If multiple amend runs occur on the same date, append to the existing `## Amend: <YYYY-MM-DD>` section.

7. **Update `questions.md`** if an unresolved question arises:
   - Read the existing file and check the highest Q-NNN number to avoid duplication
   - Check whether the question already exists (compare by text; skip if duplicate)
   - Append the new question under the appropriate table section:
     ```markdown
     - [ ] **Q-NNN** <question text> <!-- amend -->
       **Assumption:** <what you will assume to proceed> (unconfirmed)
     ```

8. **Display a change summary**:

   ```
   ## Amend Summary

   **Input interpreted as:** <one-line classification of the issue>

   **Files updated:**
   - `spec.md`: AC-003 corrected — "amount_jpy" → "amount"
   - `tasks.md`: Added Amend: 2026-04-17 with 1 fix task
   ```

   Then output the following next-step guidance:

   ---
   **Next step:**
   - Continue implementing: `/modscape:spec:implement <name>`
   - Re-check open issues: `/modscape:spec:review <name>`
   ---
