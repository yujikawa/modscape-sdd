Interactively answer a question in `questions.md` for a given change. Collects additional clarification if the answer is ambiguous, then records the final answer and assesses design impact.

## Usage

```
/modscape:spec:answer [<name>] [<id>]
```

- `<name>` — work folder name (e.g., `monthly-sales-summary`). Optional when only one active change exists.
- `<id>` — question ID to answer (e.g., `Q-001`). Optional; if omitted, list open questions and ask which to answer.

## Instructions

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
- Read `.modscape/specs/_questions.yaml`
- List all entries where `status` is `open` or `assumed`, filtered to those with `change: <name>` (or show all open if no change filter matches)
- Display them and ask the user which one to answer

If `<id>` is provided but not found in `_questions.yaml` → stop and tell the user:
> `<id>` not found in `_questions.yaml`.

### Step 3 — Display the question

Show the full question entry from `_questions.yaml`:

```
## Answering <id> — <change name>

**Q:** <question text>
**Current state:** unanswered  (or: assumed — "<assumption text>")
```

Then ask:
> What is your answer? (Type freely — I'll follow up if anything is unclear.)

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

### Step 5 — Write to `_questions.yaml`

Use the Edit tool to update the entry in `.modscape/specs/_questions.yaml`. Do not rewrite the entire file.

**If a clear answer was obtained:**
- Set `answer: "<final clarified answer>"`
- Set `status: answered`
- Remove `assumption` field if present

```yaml
- id: Q-001
  question: "<question text>"
  answer: "<final clarified answer>"
  status: answered
  ...
```

**If unresolvable (proceed with assumption):**
- Set `status: assumed`
- Set `assumption: "<what will be assumed to proceed>"`
- Leave `answer` absent

```yaml
- id: Q-001
  question: "<question text>"
  assumption: "<what will be assumed to proceed>"
  status: assumed
  ...
```

### Step 6 — Update glossary if the answer defines a term

If the answer introduces or clarifies a business/data term definition, update `.modscape/specs/_glossary.yaml`:
- If the term is not yet registered, append a new entry under `terms:`.
- If an existing entry's definition changed, update it.
- If `_glossary.yaml` does not exist, skip silently.

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
**_questions.yaml:** <id> status → answered  (or: assumed — assumption updated)

**Design impact:** <assessment>

**Next step:**
```

Then based on impact:
- Design impact → `Run /modscape:spec:design <name> to incorporate this into the design, or /modscape:spec:amend <name> to patch an existing design.`
- Spec impact → `Run /modscape:spec:amend <name> to update the affected AC.`
- No impact → `No design changes needed. Continue with /modscape:spec:implement <name>.`
