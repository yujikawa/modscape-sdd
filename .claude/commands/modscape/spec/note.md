Capture free-form knowledge (from a conversation, Slack message, or meeting) and append it to one or more permanent table spec files. Runs outside the SDD implementation workflow — no active change required.

## Usage

```
/modscape:spec:note [table-id]
```

`[table-id]` is optional. After the command, paste or type the knowledge to record.

Examples:
```
/modscape:spec:note fct_orders
> updated_at in Q1 2023 is unreliable — NULL values were introduced by an ETL bug.

/modscape:spec:note
> fct_orders grain is one row per order.
> dim_customers uses SCD Type2; grain is one row per customer validity period.
```

## Instructions

### Step 0: Detect language

If `.modscape/modscape-spec.custom.md` exists, read it and look for a `## Communication` section. If it contains a language directive (e.g., "Always respond in Japanese"), use that language for all output in this session. Otherwise default to English.

### Step 1: Collect input

After the command is invoked, prompt the user to paste or type the knowledge they want to record:

> What would you like to note? (Paste text from a conversation, Slack, or meeting notes)

Wait for the user's free-text input before proceeding.

### Step 2: Determine target table(s)

**If `[table-id]` was provided:**
- Use that table ID directly.
- Skip to Step 3.

**If no `[table-id]` was provided:**
- Analyze the free-text input and identify all table IDs mentioned.
- Match against known tables by looking for snake_case identifiers that resemble table names (e.g., `fct_orders`, `dim_customers`).
- If one or more table IDs are confidently identified, proceed with those.
- If no table ID can be identified, stop and display:

  ```
  Could not identify the target table.
  Re-run with a table ID: `/modscape:spec:note <table-id>`
  ```

  Then exit without writing any file.

### Step 3: Locate spec files

For each identified table ID:

1. Search for the spec file by table ID under `.modscape/specs` — do not assume a specific path structure:
   ```bash
   find .modscape/specs -name "<table-id>.md" -not -name "*.questions.md"
   ```
2. If exactly one file is found: use it as the target.
3. If multiple files are found: show the list and ask the user to choose:
   ```
   Multiple spec files found for <table-id>:
     1. .modscape/specs/model-a/<table-id>.md
     2. .modscape/specs/model-b/<table-id>.md
   Which file should be updated?
   ```
4. If no file is found, stop and display:
   ```
   ⚠ No spec file found for <table-id> under .modscape/specs.
   Run /modscape:spec:archive first to create the spec, or check the table ID.
   ```
   Then exit without writing any file.

### Step 4: Determine target section for each update

For each piece of information extracted from the input, map it to the most appropriate section using the following rules:

| Input type | Target section |
|---|---|
| Business rules, calculation logic, definitions, grain | `## Business Rules` |
| Known issues, data quality caveats, bugs, reliability | `## Known Issues / Caveats` |
| Background, history, intent, origin | `## Business Context` |
| Owner, SLA, update frequency | `## Overview` |
| Dangerous patterns, required filters, JOIN patterns, query examples | `## Usage Guide` |
| Notes that do not fit any of the above | `## Known Issues / Caveats` |

When input covers multiple tables, split the content and assign each piece to the appropriate table and section independently.

### Step 5: Show confirmation preview

Before writing anything, display a preview of all planned updates:

```
Will apply the following updates:

📄 specs/fct_orders/spec.md
  Section: Known Issues / Caveats
  Content: "updated_at in Q1 2023 is unreliable — NULL values were introduced by an ETL bug."

📄 specs/dim_customers/spec.md
  Section: Business Rules
  Content: "SCD Type2. Grain is one row per customer validity period."

Continue? [Y/n]
```

Wait for the user's response:
- If the user confirms (Y or Enter): proceed to Step 6.
- If the user declines (n): display `Update cancelled.` and exit without writing.

### Step 6: Write updates

For each planned update:

1. Read the target `.modscape/specs/<MODEL_SLUG>/<table-id>.md`.
2. Locate the target section (e.g., `## Business Rules`).
   - If the section **exists**: append a new bullet point at the end of that section.
   - If the section **does not exist**: append the section header followed by the new bullet at the end of the file.
3. Format the appended line as:
   ```
   - <content> <!-- noted <YYYY-MM-DD> -->
   ```
   Fill `<YYYY-MM-DD>` with today's date.
4. Write the updated file.

### Step 7: Display completion summary

After all updates are written:

```
✅ spec:note complete

Updated files:
- specs/fct_orders/spec.md (appended to Known Issues / Caveats)
- specs/dim_customers/spec.md (appended to Business Rules)
```
