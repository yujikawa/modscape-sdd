# `<table-id>`

> ⏳ **Pending design** — run the design skill again to detail this table.

## Table Overview

- **Type:** <Direct Impact | Downstream — Implement>
- **Kind:** <fact | dimension | staging | mart | ...>

## Columns

| Column | Type | FK? | Notes |
|--------|------|-----|-------|
| `<column>` | `<type>` | | |

---

## Implementation Details

<!-- Document table-specific details at a level that lets an implementer work from this file alone. -->
<!-- Include expression, filter, validation SQL, and test patterns when they exist. -->

- **Expression**: `<e.g., CAST(raw_amount AS DECIMAL(18,2)) * fx_rate>`
- **Filter condition**: `<e.g., WHERE status != 'cancelled'>`
- **Validation SQL**: `<e.g., SELECT COUNT(*) FROM <table> WHERE amount IS NULL → 0 rows>`
- **Test pattern**: `<e.g., order_id is unique + not_null, customer_id refs dim_customers>`
