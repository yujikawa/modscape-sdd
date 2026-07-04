Interactively answer a question in `questions.md` for a given change. Collects additional clarification if the answer is ambiguous, then records the final answer and assesses design impact.

## Usage

```
/modscape:spec:answer [<name>] [<id>]
```

- `<name>` — work folder name (e.g., `monthly-sales-summary`). Optional when only one active change exists.
- `<id>` — question ID to answer (e.g., `Q-001`). Optional; if omitted, list open questions and ask which to answer.

## Instructions

### Step 0 — Detect language

If `.modscape/modscape-spec.custom.md` exists, read it and look for a `## Communication` section. If it contains a language directive (e.g., "Always respond in Japanese"), use that language for all output in this session. Otherwise default to English.

### Step 1 — Resolve the change name

If `<name>` is not provided:
- List directories under `.modscape/changes/` (exclude `archive/`)
- If exactly one exists → use it automatically
- If multiple exist → display the list and ask the user to specify
- If none exist → stop and tell the user:
  > No active changes found under `.modscape/changes/`. Run `/modscape:spec:requirements` to start a new spec.

Verify that `.modscape/specs/_questions.yaml` exists.
If not → stop and tell the user:
> `_questions.yaml` not found. Run `/modscape:spec:requirements <name>` first to generate questions.

### Step 2 — Resolve the question ID

If `<id>` is not provided:
- Read `.modscape/changes/<name>/questions.md`
- List all entries where `status` is `open` or `assumed`
- For entries with `source: ai-detected` and a non-null `investigation.result`, flag them as **"Ready to analyze"** — these have data and need AI interpretation
- Display the list and ask the user which one to answer

If `<id>` is provided but not found → stop and tell the user:
> `<id>` not found in `questions.md`.

### Step 3 — Display the question and detect investigation mode

Read the entry from `.modscape/changes/<name>/questions.md`.

Show:
```
## Answering <id> — <change name>

**Q:** <question text>
**Current state:** unanswered  (or: assumed — "<assumption text>")
```

**If `investigation.result` is non-null (human has already run the query):**
- Enter **investigation analysis mode** — skip steps 4 and 5, go directly to Step 3.5.

**Otherwise:** ask the user:
> What is your answer? (Type freely — I'll follow up if anything is unclear.)
> 
> If you have already run the investigation query and have results to share, paste them here.

### Step 3.5 — Investigation analysis mode (when `investigation.result` is filled)

Read `investigation.result`. Interpret the query results in the context of the original question and the data model.

1. **Write `finding`** — a concise, analyst-facing interpretation:
   - What the data shows
   - Whether it confirms or contradicts the assumption in the spec
   - What an analyst must know before using this data

2. **Update the `questions.md` entry**:
   - Set `investigation.finding` to the interpretation
   - Set `status: answered`
   - Set `answer` to a one-line summary of the finding

3. **Assess design impact** — go to Step 7.

### Step 4 — Evaluate the answer

Receive the user's free-text reply. Evaluate it against these criteria:

**Ambiguous / incomplete — ask a follow-up:**
- Contains hedging expressions: "probably", "maybe", "I think", "should be", "たぶん", "おそらく", "〜のはず"
- Contains vague quantities: "around", "roughly", "as much as possible", "大体", "なるべく"
- Missing concrete values (e.g., precision/scale for a numeric type, a concrete range for a threshold)

**Unresolvable — record as assumption:**
- User says "I don't know", "need to check", "TBD", "わからない", "後で確認"

**Clear — record directly:**
- Specific, concrete answer with no hedging

If ambiguous, ask a targeted follow-up question (one question at a time). Continue until the answer is clear or the user says it is unresolvable.

### Step 4.5 — Update `design.md` before recording the answer

Before writing to `questions.md`, check whether the answer has design impact:

| Answer content | Impact |
|---|---|
| Affects column types, JOIN keys, schema structure, table decisions, transformation expressions, filter conditions | **Design impact** |
| Affects acceptance criteria (AC-NNN) in `spec.md` | **Spec impact** |
| Purely contextual / reference information | **No structural impact** |

**If design impact:**
1. Read `.modscape/changes/<name>/design.md`
2. Update the relevant section — typically `## Design Decisions` or `## Implementation Details > ### <table-id>`
3. Output a brief update summary: `design.md updated: <section> — <what was changed>`

**If spec impact:**
1. Note the affected AC-NNN for update (update spec.md or note it as pending)

**If no structural impact:**
1. Proceed to Step 5 without modifying design.md

This step ensures design.md reflects the answer *before* the question is marked as answered.

### Step 5 — Write to `questions.md`

Use the Edit tool to update the `## 🔴 Q-NNN` (or `## 🔵 Q-NNN`) section in `.modscape/changes/<name>/questions.md`. Do not rewrite the entire file. The format is defined in `.modscape/formats/questions-format.md`.

**If a clear answer was obtained:**
1. Change the heading emoji: `## 🔴 Q-NNN` → `## 🟢 Q-NNN` (or `## 🔵` → `## 🟢`)
2. Add an **Answer** block after the metadata list:
   ```
   **Answer**

   <final clarified answer>
   ```
3. Remove the **Assumption** block if present.

**If unresolvable (proceed with assumption):**
1. Change the heading emoji: `## 🔴 Q-NNN` → `## 🟡 Q-NNN`
2. Add an **Assumption** block after the metadata list:
   ```
   **Assumption**

   <what will be assumed to proceed>
   ```
3. Remove the **Answer** block if present.

**If the entry has an Investigation query block:** also replace `*(pending — paste query output here)*` under **Result** with the actual query output, and replace `*(pending)*` under **Finding** with the interpretation (see Step 3.5). Change `## 🔵` → `## 🟢` if fully resolved.

### Step 6 — Update glossary if the answer defines a term

If the answer introduces or clarifies a business/data term definition, update `.modscape/changes/<name>/glossary.md`:
- If the term is not yet registered, append a new entry.
- If an existing entry's definition changed, update it.
- If `glossary.md` does not exist, create it.

### Step 7 — Assess design impact

After recording the answer, check `.modscape/changes/<name>/design.md` and `.modscape/changes/<name>/spec.md` (if they exist).

Determine impact category:

| Answer content | Impact |
|---|---|
| Affects column types, JOIN keys, schema structure, or table decisions in `design.md` | **Design impact** |
| Affects acceptance criteria (AC-NNN) in `spec.md` | **Spec impact** |
| Purely contextual / reference information | **No structural impact** |

**Display the result and next-step guidance:**

```
## Answer Recorded — <id>

**Answer:** <the recorded answer>
**questions.md:** <id> status → answered  (or: assumed — assumption updated)

**Design impact:** <assessment>

| File | Status | Details |
|---|---|---|
| design.md | ✅ Updated / ✅ No impact | <updated section or "No impact"> |
| spec.md | ✅ Updated / ✅ No impact | <updated AC or "No impact"> |

**Next step:**
```

After recording the answer, determine the next step as follows:

1. Check if other open/assumed questions remain in `.modscape/changes/<name>/questions.md` (entries still marked `- [ ]`).
   - If yes → `There are <n> open questions remaining. Continue with /modscape:spec:answer <name>.`

2. If no open questions remain, get the current phase:
   ```bash
   modscape spec get <name> --json
   ```
   Use the `phase` field to determine the next step:
   - `requirements` → `Continue with /modscape:spec:design <name>.`
   - `design` → `Continue with /modscape:spec:tasks <name>.`
   - `tasks` or `implement` → `Continue with /modscape:spec:implement <name>.`
   - `done` → `This spec is already archived.`
   - `null` (phase not set) → `Run /modscape:spec:status <name> to check the current state.`
