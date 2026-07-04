Save the current session state to `.modscape/changes/<name>/session.md`. Run this at any point — during requirements, design, implement, or amend — before ending a work session. The saved state will be shown next time you run `/modscape:spec:status <name>`.

## Usage

```
/modscape:spec:save <name>
```

## Instructions

1. Verify that `.modscape/changes/<name>/` exists.
   - If not: tell the user the folder was not found and suggest running `/modscape:spec:requirements` to start a new spec.

2. Review the current conversation to extract the following:
   - **決定済み事項** — Things that have been agreed or decided during this session. Be specific (e.g. "grain は month_key に確定", "SCD type2 を採用").
   - **未解決事項** — Open questions or unresolved decisions still being discussed (e.g. "merge_key を order_id にするか composite にするか").
   - **次のアクション** — The single most important thing to do when resuming (e.g. "merge_key の方針を決めてから `/modscape:spec:design` を再実行する").
   - **メモ** — Any other context worth preserving (caveats, discovered constraints, references).

   If the conversation does not contain enough information for a section, write "(なし)" rather than leaving it blank.

3. Write `.modscape/changes/<name>/session.md` with the following format (overwrite if it already exists):

```markdown
## セッション保存 — <name> (<YYYY-MM-DD>)

### 決定済み事項
<bullet list, or "(なし)">

### 未解決事項
<bullet list, or "(なし)">

### 次のアクション
<one line>

### メモ
<free text, or "(なし)">
```

4. Output a confirmation showing the saved content:

---
🔖 セッションを保存しました: `.modscape/changes/<name>/session.md`

**決定済み事項:**
<preview>

**未解決事項:**
<preview>

**次のアクション:** <one line>

再開するには:
```
/modscape:spec:status <name>
```
---
