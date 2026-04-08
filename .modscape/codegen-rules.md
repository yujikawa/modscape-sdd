# Modscape Code Generation Rules

This file defines how to interpret a Modscape `model.yaml` when generating implementation code (dbt, SQLMesh, Spark, etc.).

Read this file alongside `.modscape/rules.md` (which defines the YAML schema) before generating any code.

---

## 1. Dependency Order (DAG)

Use the top-level `lineage` section to determine build order. Always generate upstream (`from`) models before downstream (`to`) ones.

```yaml
lineage:
  - from: stg_orders       # must be generated first
    to: fct_orders
  - from: stg_order_items  # must be generated first
    to: fct_orders
```

In dbt this becomes `{{ ref('stg_orders') }}`. In SQLMesh, `MODEL (... grain [...])` with `@this_model` references. Apply the equivalent pattern for your target tool.

---

## 2. Materialization Strategy

Map `implementation.materialization` directly to your target tool's config block. If `implementation` is absent, fall back to `appearance.type` as a hint:

| `appearance.type` | Default materialization |
|-------------------|------------------------|
| `fact`            | `incremental`          |
| `dimension`       | `table`                |
| `mart`            | `table`                |
| `hub` / `link` / `satellite` | `table`   |
| `table` / `staging` | `view`               |

```yaml
# Explicit — always prefer this over the default
implementation:
  materialization: incremental
  incremental_strategy: merge
  unique_key: order_id
  partition_by: { field: order_date, granularity: day }
  cluster_by: [customer_id]
```

---

## 3. JOIN Conditions

Derive JOIN keys from two sources:

1. **`relationships`** — explicit FK links between tables
2. **`columns[].logical.isForeignKey: true`** — columns that carry FK values

Use matching column names across tables to infer the ON clause. When a column is `isForeignKey: true` and shares a name with another table's `isPrimaryKey: true` column, that is the join key.

---

## 4. SCD Type 2

When `appearance.scd: type2`, the dimension requires historical tracking:

- In **dbt**: generate a snapshot (`dbt snapshot`) driven by the `updated_at` column, then build the dimension model on top of the snapshot.
- In other tools: apply the equivalent row-versioning pattern.
- Always expose `valid_from`, `valid_to`, and `is_current` columns (defined in the YAML).
- When joining to a SCD type2 dimension from a fact table, filter `WHERE is_current = true` unless the query is point-in-time.

---

## 5. Mart Aggregations

When `implementation.grain` and `implementation.measures` are defined, use them directly:

```yaml
implementation:
  grain: [month_key, region_id]       # → GROUP BY
  measures:
    - column: total_revenue
      agg: sum
      source_column: fct_sales.amount  # → SUM(s.amount) AS total_revenue
    - column: order_count
      agg: count_distinct
      source_column: fct_orders.order_id
```

When `grain`/`measures` are **not** defined, infer from column metadata:
- `isPrimaryKey: true` non-measure columns → likely GROUP BY candidates
- `additivity: fully` → safe to use `SUM` or `COUNT`
- `additivity: semi` → use `AVG`, `MIN`, `MAX` or similar non-summable aggregation
- Column name patterns (`_count`, `_revenue`, `_total`, `_avg`) provide additional hints

---

## 6. Column Mapping

| YAML field | Code generation use |
|-----------|-------------------|
| `logical.name` | Column alias / documentation |
| `physical.name` | Actual column name in SQL (use this if present, otherwise use `id`) |
| `isPrimaryKey: true` | Declare as primary key constraint or unique test |
| `isForeignKey: true` | JOIN key candidate |
| `isPartitionKey: true` | Confirm as partition column |
| `additivity` | Aggregation function choice (see section 5) |
| `physical.type` | Override the logical type for DDL generation |
| `physical.constraints` | Add NOT NULL / UNIQUE constraints where supported |

---

## 7. TODO Comments for Inferred Logic

When you must make an assumption that cannot be derived from the YAML, leave a `TODO` comment so the user can review it. Keep generated code runnable; do not leave placeholders that cause syntax errors.

Common TODO patterns:

```sql
-- TODO: verify surrogate key generation method (currently using row_number — consider hash if order is non-deterministic)
-- TODO: confirm incremental watermark column (currently using 'updated_at' — adjust if your source uses a different audit column)
-- TODO: verify date range for date dimension (currently 2020-01-01 to 2030-12-31)
-- TODO: grain/measures not defined in YAML — aggregations inferred from column names; verify before production use
-- TODO: source schema assumed to be 'raw' — update {{ source(...) }} references to match your project
```

---

## 8. Physical Table Names

When `physical_name` is set on a table, use it as the actual table name in DDL or config blocks. The `id` field is the logical reference name used in `ref()` calls and the `lineage` section.

---

## 9. What Modscape Does Not Define (Always TODO)

The following are intentionally out of scope for the YAML. Always emit a TODO when you encounter them:

- Surrogate key generation strategy (hash vs. sequence vs. row_number)
- Incremental filter / watermark logic
- Source system schema names
- Date dimension generation range and method
- Database-specific SQL dialect quirks
