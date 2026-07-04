# Questions

> 🔴 open · 🟢 answered · 🟡 assumed · 🔵 open (ai-detected)

---

## 🔴 Q-001

> **<question text>**

- **Table:** `<table-id>` *(optional)*
- **Date:** YYYY-MM-DD
- **Change:** <change-name>

---

## 🟢 Q-002

> **<question text>**

- **Table:** `<table-id>` *(optional)*
- **Date:** YYYY-MM-DD
- **Change:** <change-name>

**Answer**

<final answer text>

---

## 🟡 Q-003

> **<question text>**

- **Table:** `<table-id>` *(optional)*
- **Date:** YYYY-MM-DD
- **Change:** <change-name>

**Assumption**

<what was assumed to proceed>

---

## 🔵 Q-004

> **<question text>**

- **Table:** `<table-id>` *(optional)*
- **Date:** YYYY-MM-DD
- **Change:** <change-name>
- **Source:** `ai-detected`

**Investigation query** *(review for PII before running):*

```sql
-- PII-safe: aggregation only
SELECT <column>, COUNT(*) AS cnt
FROM <table>
GROUP BY <column>
ORDER BY cnt DESC
```

**Result**

*(pending — paste query output here)*

**Finding**

*(pending)*

---
