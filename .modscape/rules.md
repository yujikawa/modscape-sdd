# Modscape Modeling Rules for AI Agents

> **Purpose**: This file teaches AI agents how to write valid `model.yaml` files for Modscape.
> Read this file completely before generating or editing any YAML.

> **Extension**: If `.modscape/rules.custom.md` exists in this project, read it **in addition** to this file.
> Rules in `rules.custom.md` take **priority** over this file when they conflict.

---

## QUICK REFERENCE (read this first)

```
ROOT KEYS      version | imports | domains | tables | relationships | lineage | annotations | layout | consumers
COORDINATES    ONLY in `layout`. NEVER inside tables or domains.
LINEAGE        Use top-level `lineage` section (not relationships, not table.lineage.upstream).
               lineage.to can reference either a table ID or a consumer ID.
parentId       Declare a table's domain membership inside layout, not inside domains.
IDs            Every object (table, domain, annotation, consumer) needs a unique `id`.
sampleData     Plain data rows only (no header row). At least 3 realistic data rows.
Grid           All x/y values must be multiples of 40.
```

---

## 1. Root Structure

A valid `model.yaml` has exactly these top-level keys.

```yaml
version:       # (string) schema version (e.g. "1.0.0") — OPTIONAL but recommended
imports:       # (array) cross-file table references — OPTIONAL
domains:       # (array) visual containers — OPTIONAL but recommended
tables:        # (array) entity definitions — REQUIRED
relationships: # (array) ER cardinality edges — OPTIONAL
lineage:       # (array) data lineage edges — OPTIONAL
annotations:   # (array) sticky notes / callouts — OPTIONAL
layout:        # (object) ALL coordinates — REQUIRED if any objects exist
consumers:     # (array) downstream consumers (BI dashboards, ML models, apps) — OPTIONAL
```

**MUST NOT** add any other top-level keys. They will be ignored or cause errors.

---

## 2. Tables

### 2-1. Required and Optional Fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | **REQUIRED** | Unique identifier used as a key in `layout`, `domains.tables`, `lineage`, etc. Use snake_case. |
| `name` | **REQUIRED** | Conceptual (business) name shown large on the canvas. |
| `logical_name` | optional | Formal business name shown medium. Omit if same as `name`. |
| `physical_name` | optional | Actual database table name shown small. |
| `appearance` | optional | Visual type, icon, color. |
| `conceptual` | optional | AI-friendly business context metadata. |
| `columns` | optional | Column definitions. |
| `sampleData` | optional | 2D array of sample rows. Strongly recommended. |

### 2-2. `appearance` Fields

```yaml
appearance:
  type: fact          # REQUIRED if used. See table below.
  sub_type: transaction  # optional free text (transaction | periodic | accumulating | ...)
  scd: type2          # optional. dimension tables only. type0|type1|type2|type3|type4|type6
  icon: "💰"          # optional. any single emoji.
  color: "#e0f2fe"    # optional. hex or CSS color for the header.
```

**`appearance.type` values:**

| type | Use when... |
|------|-------------|
| `fact` | Events, transactions, measurements. Has measures (numbers) and FK columns. |
| `dimension` | Entities, master data, reference lists. Descriptive attributes. |
| `mart` | Aggregated or consumer-facing output. **Always add a top-level `lineage` entry.** |
| `hub` | Data Vault: stores a single unique business key. |
| `link` | Data Vault: joins two or more hubs (transaction or relationship). |
| `satellite` | Data Vault: descriptive attributes of a hub, tracked over time. |
| `table` | Generic. Use when none of the above apply. |

**MUST NOT** use `scd` on `fact`, `mart`, `hub`, `link`, or `satellite` tables.

### 2-3. `conceptual` Fields (AI-readable business context)

```yaml
conceptual:
  description: "One row per order line item."
  tags: [WHAT, HOW_MUCH]   # BEAM* tags: WHO | WHAT | WHEN | WHERE | HOW | COUNT | HOW_MUCH
```

### 2-4. `metadata` Fields (user-defined key-value pairs)

Free-form key-value map for project-specific information that does not fit the standard schema.
Any string key is accepted; values can be strings, numbers, or booleans.

```yaml
metadata:
  owner: data-platform        # Team or person responsible for this table
  sla: "daily 6AM JST"        # Delivery SLA
  sql_path: "models/marts/fct_orders.sql"  # Path to the SQL or model file
  sensitivity: PII            # Data sensitivity label
  cost_center: CC-1234        # Any custom label
```

**Rules:**
- `metadata` is **OPTIONAL**. Omit entirely if not needed.
- All keys must be strings. Values must be scalar (string, number, boolean) — do **not** nest objects or arrays inside `metadata`.
- This field is preserved as-is and never modified by Modscape CLI commands.

### 2-5. `columns` Fields

Each column has an `id` plus optional `logical` and `physical` blocks.

```yaml
columns:
  - id: order_id           # REQUIRED. Unique within the table.
    expression: "CAST(raw.amount AS DECIMAL(18,2)) * fx.rate"  # optional. SQL expression for SELECT clause generation.
    logical:
      name: "Order ID"     # Display name
      type: Int            # Int | String | Decimal | Date | Timestamp | Boolean | ...
      description: "Surrogate key."   # optional
      isPrimaryKey: true   # optional. default false.
      isForeignKey: false  # optional. default false.
      isPartitionKey: false # optional. default false.
      additivity: fully    # optional. fully=summable | semi=balance/stock | non=price/rate/ID
    physical:              # optional. override when warehouse names/types differ.
      name: order_id_pk
      type: "BIGINT"
      constraints: [NOT NULL, UNIQUE]
```

**`expression`** (optional) — SQL transformation formula used by SDD implement skill when generating SELECT clauses.
- Omit if the column maps 1:1 from upstream without transformation.
- Can reference multiple source columns: `"CAST(amount AS DECIMAL(18,2)) * fx_rate"`.
- Tool-specific syntax is allowed: `"{{ source('raw', 'orders') }}.amount"`.
- Empty string is invalid — either write a valid SQL expression or omit the field entirely.

---

## 3. Relationships (ER Cardinality)

Use `relationships` **only** for structural ER connections between tables.

```yaml
relationships:
  - id: rel_cust_orders   # Unique ID — REQUIRED for stable referencing
    from:
      table: dim_customers   # table id
      column: [customer_key] # column id(s) — ALWAYS an array of strings
    to:
      table: fct_orders
      column: [customer_key]
    type: one-to-many
    description: "Links each order to its customer via the surrogate key."  # optional
```

**`type` values:**

| type | Typical usage |
|------|--------------|
| `one-to-one` | Lookup table / vertical split |
| `one-to-many` | Dimension → Fact *(most common)* |
| `many-to-one` | Fact → Dimension *(inverse notation of above)* |
| `many-to-many` | Via a bridge / link table |

**`description`** (optional) — A free-text explanation of the relationship's business meaning (e.g. why this join exists, what the key represents). Use it to document non-obvious joins.

**MUST NOT** use `relationships` to express data lineage (use the top-level `lineage` section instead).

---

## 4. Data Lineage

Top-level `lineage` section declares data flow between tables (which source tables feed which derived tables).
This is rendered as dashed arrows in **Lineage Mode**. It is separate from ER relationships.

```yaml
lineage:
  - id: lin_orders_revenue # Unique ID — REQUIRED for stable referencing
    from: fct_orders    # source table id
    to: mart_revenue    # derived table id
    join_type: left     # optional. inner | left | cross | none
    description: "Aggregated daily order amounts into monthly buckets."  # optional
  - id: lin_dates_revenue
    from: dim_dates
    to: mart_revenue
    join_type: inner
```

**`join_type`** (optional) — How the downstream table joins this upstream source.

| value | Meaning |
|-------|---------|
| `inner` | INNER JOIN — only matching rows |
| `left` | LEFT JOIN — keep all downstream rows |
| `cross` | CROSS JOIN — all row combinations |
| `none` | No explicit JOIN — use as CTE or subquery |

**Default behavior when omitted:**
- If a `relationships` entry exists for the same pair → SDD generates `LEFT JOIN` using the relationship columns.
- If no `relationships` entry → treated as `none` (CTE reference).

### When to use lineage vs relationships

| Situation | Use |
|-----------|-----|
| `dim_customers` → `fct_orders` (FK join) | `relationships` |
| `fct_orders` + `dim_dates` → `mart_revenue` (aggregation) | `lineage` |

**MUST** define `lineage` entries for every `mart` or aggregated table.
**MUST NOT** add a `relationships` entry for a connection already expressed in `lineage`.

#### Example: correct separation

```yaml
# CORRECT
lineage:
  - id: lin_orders_revenue
    from: fct_orders
    to: mart_revenue
  - id: lin_dates_revenue
    from: dim_dates
    to: mart_revenue

relationships:
  - id: rel_cust_orders
    from: { table: dim_customers, column: [customer_key] }
    to:   { table: fct_orders,    column: [customer_key] }
    type: one-to-many                     # ER only
```
# WRONG — do not add a relationships entry for the same connection as lineage
relationships:
  - from: { table: fct_orders }
    to:   { table: mart_revenue }
    type: lineage                         # ❌ never do this
```

---

## 5. Domains

```yaml
domains:
  - id: sales_ops           # REQUIRED. Used as key in layout.
    name: "Sales Operations"  # REQUIRED. Display name.
    description: "..."      # optional
    color: "rgba(59, 130, 246, 0.1)"  # optional. rgba recommended.
    members:                # REQUIRED. List of table or consumer IDs inside this domain.
      - fct_orders
      - dim_customers
```

**MUST** list only IDs that actually exist in `tables` or `consumers`.
**MUST** add a layout entry for the domain with `width` and `height`.

---

## 5a. Cross-file Imports

Use `imports:` to reference table definitions from another YAML file without copying them.
Imported tables are resolved at dev/build time and can be used in `domains.members`, `relationships`, and `lineage` just like local tables.

```yaml
imports:
  - from: ./conformed-dims.yaml        # relative path from this file
    ids: [dim_dates, dim_customers]    # optional: specific table IDs to import
                                       # omit ids to import all tables from the file
```

**Rules:**
- `from` is **REQUIRED**. Path is relative to the YAML file containing the `imports:` entry.
- `ids` is optional. When omitted, all tables from the referenced file are imported.
- Local table definitions take precedence — if the same ID exists locally and in an imported file, the local definition wins.
- Imported tables appear on the canvas as read-only nodes. To edit them, update the source file.
- Imported table IDs work in `domains.members`, `relationships`, and `lineage` entries.

**Example: importing a conformed date dimension**

```yaml
# model.yaml
imports:
  - from: ./shared/conformed-dims.yaml
    ids: [dim_dates]

domains:
  - id: core
    name: Core Layer
    members: [fct_orders, dim_dates]   # dim_dates comes from import

relationships:
  - from: { table: fct_orders, column: date_key }
    to:   { table: dim_dates, column: date_key }   # imported table referenced normally
    type: many-to-one
```

---

## 5b. Consumers

Consumers represent downstream users of your data model — BI dashboards, ML models, applications, etc. They appear as distinct nodes on the canvas and can receive lineage edges.

```yaml
consumers:
  - id: revenue_dashboard       # REQUIRED. Unique ID. Used in lineage and layout.
    name: "Revenue Dashboard"   # REQUIRED. Display name.
    description: "Monthly KPI dashboard for finance team."  # optional
    appearance:
      icon: "📊"                # optional. Defaults to 📊.
      color: "#e0f2fe"          # optional. Header/accent color.
    url: "https://..."          # optional. Link to the actual dashboard or service.
```

**Field rules:**
- `id` and `name` are **REQUIRED**. All other fields are optional.
- Add a `layout` entry for each consumer (same as tables — absolute coordinates or relative inside a domain with `parentId`).
- To connect a consumer with lineage, set `lineage.to` to the consumer's `id`. The `lineage.from` must be a table ID.
- Consumers can be added to domain `members` lists just like tables.

```yaml
# Example: lineage from mart to a consumer
lineage:
  - from: mart_monthly_revenue
    to: revenue_dashboard   # consumer ID

# Example: domain containing consumers
domains:
  - id: dashboards_domain
    name: "BI Dashboards"
    members: [revenue_dashboard, ops_dashboard]
```

---

## 6. Layout

**All coordinates live here.** Never put `x`, `y`, `width`, or `height` inside `tables` or `domains`.

### 6-1. Field Reference

| Field | Required for | Description |
|-------|-------------|-------------|
| `x` | all entries | Canvas x coordinate (integer, multiple of 40) |
| `y` | all entries | Canvas y coordinate (integer, multiple of 40) |
| `width` | domains | Total pixel width of the domain container |
| `height` | domains | Total pixel height of the domain container |
| `parentId` | tables inside a domain | ID of the containing domain. Makes coordinates relative to domain origin. |

### 6-2. Domain Size Formula

Calculate domain dimensions so tables fit without overflow:

```
width  = (numCols * 320) + ((numCols - 1) * 80) + 160
height = (numRows * 240) + ((numRows - 1) * 80) + 160
```

Examples:
- 1 col × 1 row → width: 480, height: 400
- 2 col × 1 row → width: 880, height: 400
- 2 col × 2 row → width: 880, height: 720
- 3 col × 2 row → width: 1280, height: 720

### 6-3. Table Positioning Inside a Domain

When `parentId` is set, `x`/`y` are **relative to the domain's top-left corner (0, 0)**.

```yaml
layout:
  sales_ops:
    x: 0        # absolute canvas position
    y: 0
    width: 880
    height: 400
  dim_customers:
    x: 80       # 80px from domain's left edge
    y: 80       # 80px from domain's top edge
    parentId: sales_ops
  fct_orders:
    x: 480      # 480px from domain's left edge
    y: 80
    parentId: sales_ops
```

**MUST NOT** let any table's right edge (`x + 320`) or bottom edge (`y + 240`) exceed the domain's `width` or `height`.

### 6-4. Layout Flow Conventions

- **ER diagrams**: Dimension/Hub tables TOP, Fact/Link tables BOTTOM
- **Lineage diagrams**: Upstream (source) LEFT, Downstream (mart) RIGHT
- **Grid**: All `x` and `y` values must be multiples of 40
- **Spacing**: Minimum gap of 120px between nodes

### 6-5. Layout Template

```yaml
layout:
  # --- Domain ---
  <domain_id>:
    x: <canvas_x>     # absolute
    y: <canvas_y>
    width: <W>        # use formula above
    height: <H>

  # --- Table inside domain ---
  <table_id>:
    x: <relative_x>   # relative to domain origin
    y: <relative_y>
    parentId: <domain_id>

  # --- Standalone table ---
  <table_id>:
    x: <canvas_x>     # absolute
    y: <canvas_y>
```

---

## 7. Annotations

```yaml
annotations:
  - id: note_001          # REQUIRED. Unique ID.
    type: sticky          # REQUIRED. sticky | callout
    text: "..."           # REQUIRED. Note content.
    color: "#fef9c3"      # optional. background color.
    targetId: fct_orders  # optional. ID of the object to attach to.
    targetType: table     # required if targetId is set. table | domain | relationship | lineage | column
                          # 'relationship' and 'lineage' require the entry to have an explicit id field
    offset:
      x: 100    # offset from target's top-left. if no targetId, this is absolute canvas position.
      y: -80    # negative y = above the target.
```

---

## 8. Sample Data

Every table SHOULD include `sampleData`.

```yaml
sampleData:
  - [1001, 1, 150.00, "COMPLETED"]   # each row = one data record
  - [1002, 2,  89.50, "PENDING"]
  - [1003, 1, 210.00, "COMPLETED"]
```

**Rules:**
- Each row is a plain data record. No header row.
- The order of values MUST match the order of `columns` defined in the table.
- Use realistic values. Do NOT use "test1", "foo", "xxx".
- Numeric measures should be plausible business amounts.
- Dates should be in ISO 8601 format: `"2024-01-15"` or `"2024-01-15T00:00:00Z"`.

---

## 9. Implementation Hints

`implementation` is an **optional** block inside each table. AI agents read it to generate dbt / Spark / SQLMesh code. Omitting it is fine — the visualizer works without it.

```yaml
tables:
  - id: fct_orders
    appearance: { type: fact }
    implementation:
      materialization: incremental      # table | view | incremental | ephemeral
      incremental_strategy: merge       # merge | append | delete+insert
      unique_key: order_id              # column id used for upsert
      partition_by:
        field: event_date
        granularity: day                # day | month | year | hour
      cluster_by: [customer_id, region_id]
      grain: [month_key, region_id]     # GROUP BY columns (mart only)
      measures:
        - column: total_revenue         # output column id in this table
          agg: sum                      # sum | count | count_distinct | avg | min | max
          source_column: amount         # upstream column id (use <table_id>.<col_id> to disambiguate)
      incremental_key: updated_at       # optional. column id for WHERE filter in incremental models
      incremental_lookback: "3 days"    # optional. safety margin added to incremental filter
```

**`incremental_key`** (optional) — Column ID used as the timestamp/date filter for incremental loads.
- Only meaningful when `materialization: incremental`.
- SDD generates: `WHERE <incremental_key> > {{ last_run_timestamp }}`.
- When omitted, SDD infers from column names (e.g. `updated_at`, `created_at`).

**`incremental_lookback`** (optional) — Safety margin subtracted from the incremental filter boundary.
- Format: `"N days"`, `"N hours"`, `"N minutes"`.
- SDD generates: `WHERE updated_at > {{ last_run_timestamp }} - INTERVAL 3 DAY`.
- When omitted, no lookback margin is applied.

For SCD Type2 dimensions, add an `scd2` block:

```yaml
tables:
  - id: dim_customers
    appearance: { type: dimension, scd: type2 }
    implementation:
      materialization: table
      scd2:
        business_key: [customer_id]     # natural key column id(s)
        valid_from: valid_from          # column id for start date
        valid_to: valid_to              # column id for end date
        current_flag: is_current        # optional. column id for current record flag
```

**`scd2`** (optional) — Specifies SCD Type2 column roles for the SDD implement skill.
- Only valid when `appearance.scd: type2`.
- `business_key`: array of natural key column IDs (supports composite keys).
- `valid_from` / `valid_to`: column IDs holding the effective date range.
- `current_flag`: optional boolean flag column for the active record.
- When omitted, SDD infers column roles from names and outputs TODO comments for unknowns.

### AI Inference Defaults (when `implementation` is absent)

| `appearance.type` | `appearance.scd` | Inferred `materialization` |
|------------------|-----------------|--------------------------|
| `fact` | — | `incremental` |
| `dimension` | `type2` | `table` (snapshot pattern) |
| `dimension` | other | `table` |
| `mart` | — | `table` |
| `hub` / `link` / `satellite` | — | `incremental` |
| `table` | — | `view` |

**Rules:**
- `measures` and `grain` are for `mart` tables only.
- `incremental_strategy` and `unique_key` are only relevant when `materialization: incremental`.
- When `source_column` is ambiguous across multiple upstream tables, qualify it as `<table_id>.<column_id>` (e.g., `fct_orders.amount`).
- **MUST NOT** define `implementation` inside `domains`, `relationships`, or `annotations`.

---

## 10. Common Mistakes (Before → After)

### ❌ Coordinates inside a table definition

```yaml
# WRONG
tables:
  - id: fct_orders
    x: 200        # ❌ coordinates do not belong here
    y: 400
```

```yaml
# CORRECT
tables:
  - id: fct_orders
    name: Orders

layout:
  fct_orders:
    x: 200        # ✅ coordinates belong in layout
    y: 400
```

---

### ❌ Using relationships for lineage

```yaml
# WRONG
relationships:
  - from: { table: fct_orders }
    to: { table: mart_revenue }
    type: lineage   # ❌ 'lineage' is not a valid relationship type
```

```yaml
# CORRECT
lineage:
  - from: fct_orders
    to: mart_revenue    # ✅ express lineage in the top-level lineage section
```

---

### ❌ Table listed in domain but missing from layout

```yaml
# WRONG
domains:
  - id: sales_ops
    members: [fct_orders, dim_customers]   # dim_customers listed here...

layout:
  sales_ops: { x: 0, y: 0, width: 880, height: 400 }
  fct_orders: { x: 480, y: 80, parentId: sales_ops }
  # ❌ dim_customers has no layout entry → will render at origin (0,0)
```

```yaml
# CORRECT — every table in a domain MUST have a layout entry
layout:
  sales_ops:    { x: 0, y: 0, width: 880, height: 400 }
  dim_customers: { x: 80,  y: 80, parentId: sales_ops }  # ✅
  fct_orders:   { x: 480, y: 80, parentId: sales_ops }  # ✅
```

---

### ❌ Table overflows domain boundary

```yaml
# WRONG — domain width is 480 but table at x:280 + width:320 = 600 > 480
layout:
  small_domain: { x: 0, y: 0, width: 480, height: 400 }
  fct_orders:   { x: 280, y: 80, parentId: small_domain }  # ❌ right edge = 600
```

```yaml
# CORRECT — use the formula: 1 col = width 480
layout:
  small_domain: { x: 0, y: 0, width: 480, height: 400 }
  fct_orders:   { x: 80, y: 80, parentId: small_domain }   # ✅ right edge = 400
```

---

## 11. dbt Project Integration

If the user has a dbt project, AI agents SHOULD recommend using the built-in import commands instead of writing YAML from scratch.

### 11-1. Commands

```bash
# Prerequisite: generate manifest.json first
dbt parse

# Import a dbt project into Modscape YAML (one-time)
modscape dbt import [project-dir] [options]

# Sync dbt changes into existing Modscape YAML (incremental)
modscape dbt sync [project-dir] [options]
```

**`dbt import` options:**

| Option | Description |
|--------|-------------|
| `-o, --output <dir>` | Output directory (default: `modscape-<project-name>`) |
| `--split-by folder` | One YAML file per dbt folder |
| `--split-by schema` | One YAML file per database schema |
| `--split-by tag` | One YAML file per dbt tag |

### 11-2. What `dbt import` generates

The command reads `target/manifest.json` and produces YAML with:

| Field | Source | Notes |
|-------|--------|-------|
| `id` | `node.unique_id` | Format: `model.project.name` or `source.project.src.table` |
| `name` | `node.name` | Model / source name |
| `physical_name` | `node.alias` | Falls back to `node.name` |
| `conceptual.description` | `node.description` | From dbt docs |
| `columns[].logical.name/type/description` | `node.columns` | From dbt schema.yml |
| `lineage` (top-level) | `node.depends_on.nodes` | Auto-populated as `{from, to}` entries |
| `appearance.type` | — | **Always `table`. Must be reclassified.** |
| `sampleData` | — | **Not generated. Must be added.** |
| `layout` | — | **Not generated. Must be added.** |
| `domains` | dbt folder structure | Auto-grouped by `fqn[1]` |

### 11-3. What AI agents MUST do after `dbt import`

After running `modscape dbt import`, the generated YAML needs enrichment. AI agents MUST:

1. **Reclassify `appearance.type`** — All tables default to `type: table`. Inspect the table name and columns to assign the correct type (`fact`, `dimension`, `mart`, etc.).
   - Tables named `fct_*` → `fact`
   - Tables named `dim_*` → `dimension`
   - Tables named `mart_*` or `rpt_*` → `mart`
   - Tables named `hub_*` → `hub`, `lnk_*` → `link`, `sat_*` → `satellite`

2. **Add `layout`** — The import does not generate coordinates. Calculate domain sizes and add `layout` entries for all tables and domains using the formula in Section 6.

3. **Add `sampleData`** — The import does not generate sample data. Add at least 3 realistic rows per table.

4. **Do NOT re-generate `lineage` entries** — Top-level `lineage` is already correctly populated from `depends_on.nodes`.

### 11-4. `dbt sync` — Incremental updates

Use `modscape dbt sync` when the dbt project has changed (new models, updated columns, etc.) and you want to update the existing Modscape YAML without losing manual edits.

**What `sync` overwrites:**
- `name`, `logical_name`, `physical_name`
- `conceptual.description`
- `columns` (all)
- `lineage` (top-level)

**What `sync` preserves (safe to edit manually):**
- `appearance` (type, icon, color, scd)
- `sampleData`
- `layout`
- `domains`
- `annotations`
- Any fields not listed above

> **Workflow**: `dbt import` once → enrich with AI → `dbt sync` when dbt changes → re-enrich as needed.

### 11-5. Table ID format in dbt-imported models

In dbt-imported YAML, table IDs are dbt `unique_id` strings, not short names:

```yaml
# dbt-imported table ID examples
id: "model.my_project.fct_orders"
id: "source.my_project.raw.orders"
id: "seed.my_project.product_categories"

# top-level lineage also uses unique_id format
lineage:
  - from: "model.my_project.stg_orders"
    to: "model.my_project.fct_orders"
  - from: "source.my_project.raw.customers"
    to: "model.my_project.fct_orders"
```

**MUST NOT** shorten these IDs. They are the join keys between `tables`, `domains.members`, `lineage`, and `layout`.

---

## 12. Merging YAML Files

When a user asks to **combine, merge, or consolidate** multiple YAML model files, use the built-in `merge` command instead of editing YAML manually.

```bash
# Merge specific files
modscape merge sales.yaml marketing.yaml -o combined.yaml

# Merge all YAML files in a directory
modscape merge ./models -o combined.yaml

# Merge multiple directories
modscape merge ./sales ./marketing -o combined.yaml
```

**Merge behavior:**

| Section | Behavior |
|---------|----------|
| `tables` | Deduplicated by `id`. First occurrence wins on conflict. |
| `relationships` | All entries included (no deduplication). |
| `domains` | Deduplicated by `id`. First occurrence wins on conflict. |
| `layout` | **Not included in output.** Must be added after merging. |
| `annotations` | **Not included in output.** Must be added after merging. |

**What AI agents MUST do after merge:**

1. **Add `layout`** — Run `modscape dev <output>` and use auto-layout, or calculate coordinates manually using the formula in Section 6.
2. **Check for relationship duplication** — If the same relationship exists in multiple source files, it will appear twice. Deduplicate manually if needed.

---

## 13. Model Mutation CLI

Use the built-in mutation commands to **add, update, or remove individual entities** in a YAML model. These commands validate input and write atomically — safer than editing YAML directly.

**MUST** use these commands when making targeted changes. Only edit YAML directly for complex nested fields not covered by CLI flags (e.g., `implementation`, `sampleData`, `columns` full definition).

### 13-1. Available Operations

| Resource | Operations |
|----------|-----------|
| `table` | `list` `get` `add` `update` `remove` |
| `column` | `list` `add` `update` `remove` |
| `relationship` | `list` `add` `remove` |
| `lineage` | `list` `add` `remove` |
| `domain` | `list` `get` `add` `update` `remove` |
| `domain member` | `add` `remove` |
| `annotation` | `list` `add` `update` `remove` |
| `consumer` | `list` `get` `add` `update` `remove` |
| `summary` | (model overview) |

### 13-2. Recommended AI Agent Flow

When inspecting a model's current state, **prefer using the list/get commands** over reading the YAML file directly.
They return validated, structured JSON output that is easier to process.

```bash
# Get a full overview of the model first
modscape summary model.yaml --json

# Inspect specific sections
modscape table list model.yaml --json
modscape table list model.yaml --type fact --json        # filter by type
modscape table list model.yaml --domain sales_ops --json # filter by domain
modscape table list model.yaml --orphan --json           # tables with no domain
modscape domain list model.yaml --json
modscape relationship list model.yaml --json
modscape lineage list model.yaml --json
modscape annotation list model.yaml --json
modscape consumer list model.yaml --json
modscape column list model.yaml --table <tableId> --json
```

Before `add` or `update`, check existence with `get` or `list`:

```bash
# 1. Check if table exists
modscape table get model.yaml --id fct_orders --json
# → found: use update / not found: use add

# 2a. Add new table
modscape table add model.yaml --id fct_orders --name "Orders" --type fact

# 2b. Update existing table
modscape table update model.yaml --id fct_orders --physical-name fct_sales_orders
```

### 13-3. CLI Flag Reference

**table add / update**
```bash
modscape table add model.yaml \
  --id <id> --name <name> \
  [--type fact|dimension|mart|hub|link|satellite|table] \
  [--logical-name <name>] [--physical-name <name>] \
  [--description <text>] [--json]
```

**column list / add / update**
```bash
modscape column list model.yaml --table <tableId> [--json]
modscape column add model.yaml \
  --table <tableId> --id <id> --name <name> \
  [--type Int|String|Decimal|Date|Timestamp|Boolean] \
  [--primary-key] [--foreign-key] \
  [--physical-name <name>] [--physical-type <type>] [--json]
```

**relationship get / add / update / remove**
```bash
modscape relationship get model.yaml --id <id> [--json]
modscape relationship get model.yaml --from <table> --to <table> [--json]
modscape relationship add model.yaml \
  --from <table.column> --to <table.column> \
  --type one-to-one|one-to-many|many-to-one|many-to-many \
  [--id <id>] [--description <text>] [--json]
modscape relationship update model.yaml --id <id> \
  [--type one-to-one|one-to-many|many-to-one|many-to-many] \
  [--description <text>] [--json]
modscape relationship remove model.yaml --id <id> [--json]
```

**lineage get / add / update / remove**
```bash
modscape lineage get model.yaml --id <id> [--json]
modscape lineage get model.yaml --from <tableId> --to <tableId> [--json]
modscape lineage add model.yaml --from <tableId> --to <tableId> \
  [--id <id>] [--description <text>] [--json]
modscape lineage update model.yaml --from <tableId> --to <tableId> [--description <text>] [--json]
modscape lineage remove model.yaml --id <id> [--json]
```

**domain add / update**
```bash
modscape domain add model.yaml \
  --id <id> --name <name> [--description <text>] [--color <color>] [--json]
```

**domain member add / remove**
```bash
modscape domain member add model.yaml --domain <domainId> --id <tableId|consumerId> [--json]
modscape domain member remove model.yaml --domain <domainId> --id <tableId|consumerId> [--json]
```

**consumer list / get / add / update / remove**
```bash
modscape consumer list model.yaml [--json]
modscape consumer get model.yaml --id <id> [--json]
modscape consumer add model.yaml \
  --id <id> --name <name> [--description <text>] \
  [--icon <icon>] [--color <color>] [--url <url>] [--json]
modscape consumer update model.yaml --id <id> \
  [--name <name>] [--description <text>] [--icon <icon>] [--color <color>] [--url <url>] [--json]
modscape consumer remove model.yaml --id <id> [--json]
```

**annotation list / add / update / remove**
```bash
modscape annotation list model.yaml [--json]
modscape annotation add model.yaml \
  --text <text> [--id <id>] [--type sticky|callout] \
  [--color <color>] [--target-id <id>] [--target-type table|domain|relationship|lineage|column] \
  [--offset-x <x>] [--offset-y <y>] [--json]
modscape annotation update model.yaml --id <id> \
  [--text <text>] [--type sticky|callout] [--color <color>] \
  [--target-id <id>] [--target-type <type>] [--offset-x <x>] [--offset-y <y>] [--json]
modscape annotation remove model.yaml --id <id> [--json]
```

**summary**
```bash
modscape summary model.yaml        # human-readable overview
modscape summary model.yaml --json # machine-readable JSON
```

### 13-4. After Adding Tables

`table add` does **not** create layout coordinates. After adding tables, run:

```bash
modscape layout model.yaml
```

This assigns coordinates to all layout-less entries automatically.

### 13-5. Validate

Check a model.yaml file for structural errors before visualizing or committing:

```bash
modscape validate model.yaml          # Human-readable output
modscape validate model.yaml --json   # Machine-readable output for AI agents
```

Checks performed:
- Duplicate IDs (tables, domains, relationships, lineage)
- Coordinates inside `tables` or `domains` (must be in `layout` only)
- Broken references in `relationships`, `lineage`, `domains.members`, and `layout`
- Orphaned `layout` entries (keys not found in tables or domains)

### 13-5. Reading Model Information

When investigating or querying a YAML model, always prefer modscape CLI commands or MCP tools over `grep` / `cat` / direct file reads:

```bash
modscape table list <file>               # List all tables
modscape table get <file> --id <id>      # Get a specific table
modscape lineage list <file>             # List all lineage entries
modscape relationship list <file>        # List all relationships
modscape domain list <file>              # List all domains
modscape summary <file>                  # Overview of the entire model
modscape summary <file> --json           # Machine-readable summary
```

If the modscape MCP server is active, prefer `mcp__modscape__*` tools (e.g. `mcp__modscape__list_tables`, `mcp__modscape__get_table`) for zero-overhead reads.

Fall back to `grep` or direct file reads only when the information genuinely cannot be obtained from the above commands.

### 13-5. JSON Output for AI Pipelines

All commands support `--json` for machine-readable output:

```json
{ "ok": true,  "action": "add", "resource": "table", "id": "fct_orders" }
{ "ok": false, "error": "Table \"fct_orders\" already exists", "hint": "Use `table update` instead" }
```

---

## 13-6. Project Initialization Flags

```bash
modscape init [--gemini] [--codex] [--claude] [--all] [--sdd]
```

| Flag | Description |
|------|-------------|
| `--gemini` | Scaffold skills for Gemini CLI |
| `--codex`  | Scaffold skills for Codex |
| `--claude` | Scaffold skills for Claude Code |
| `--all`    | Scaffold for all three agents |
| `--sdd`    | Add SDD (Spec-Driven Data Engineering) skills — **Claude Code only**, combine with `--claude` |

`--sdd` installs five slash commands for Claude Code and creates the `.modscape/changes/` and `.modscape/specs/` directories:

| Command | Purpose |
|---------|---------|
| `/modscape:spec:requirements`        | Collect business requirements → `.modscape/changes/<name>/spec.md` |
| `/modscape:spec:design <name>`       | Design `model.yaml` from `spec.md`, generate `design.md` and `tasks.md` |
| `/modscape:spec:implement <name>`    | Implement tasks one by one, generating dbt / SQLMesh code |
| `/modscape:spec:archive <name>`      | Sync permanent table specs to `.modscape/specs/<table-id>.md` |
| `/modscape:spec:status <name>`       | Show current phase, task progress, and next recommended command |

```bash
modscape spec new <name>   # Scaffold work folder (spec-config.yaml, model.yaml, design.md, tasks.md)
```

### SDD Directory Structure

```
.modscape/
├── changes/
│   ├── modscape-spec.custom.md         # Project-wide custom rules (optional)
│   └── <name>/                         # Work folder per pipeline (temporary)
│       ├── spec.md                     # Business requirements
│       ├── spec-config.yaml            # Master YAML mapping for this spec
│       ├── model.yaml                  # Work-scoped YAML (extracted + new tables)
│       ├── design.md                   # Design decisions + real-data findings
│       └── tasks.md                    # Implementation task list
├── archives/
│   └── YYYY-MM-DD-<name>/              # Archived work folders
└── specs/
    └── <table-id>.md                   # Permanent business spec per table
```

### Permanent Table Spec Format (`specs/<table-id>.md`)

```markdown
# <table-id>

## Overview
- **Owner**: <team or person>
- **Update Frequency**: <daily / weekly / etc.>
- **SLA**: <e.g., "Available by 07:00 JST">

## Business Context
<Business meaning of this table>

## Business Rules
- <Key business rule or calculation logic>

## Known Issues / Caveats
- <Known data quality issues or edge cases>

## Changelog
- YYYY-MM-DD: 初版 (SDD: <name>)
```

Customize SDD behavior by creating `.modscape/changes/modscape-spec.custom.md` (rename from the generated `.example` file).

---

## 14. Schema Version

`model.yaml` supports an optional `version` field at the root level to indicate the schema version.

```yaml
version: "1.0.0"   # optional. semver string. Current schema version is "1.0.0".
```

- The field is **optional** — omitting it is valid and backward-compatible.
- The current schema version is `"1.0.0"`.
- AI agents SHOULD include `version: "1.0.0"` in newly generated files.
- The parser does not branch on the version value (reserved for future migrations).

---

## 15. Project-Specific Rule Extensions

A project MAY place a `.modscape/rules.custom.md` file to define rules that extend or override this base file.

**How to use it:**

- Create `.modscape/rules.custom.md` in the project root (alongside `rules.md`)
- Write any project-specific rules, naming conventions, or overrides in Markdown
- AI agents reading this file will also check for `rules.custom.md` and apply it

**Priority:** Rules in `rules.custom.md` take priority over this file when they conflict.

**What to put in `rules.custom.md`** (examples):

```markdown
## Naming Conventions
- All fact table IDs must use the prefix `fct_` followed by the domain: e.g., `fct_sales_orders`
- All dimension table IDs must end in `_dim`: e.g., `customers_dim`

## Allowed Table Types
- This project only uses `fact`, `dimension`, and `mart`. Do NOT use `hub`, `link`, or `satellite`.

## Domain Topology
- This project has three domains: `sales`, `marketing`, `finance`
- Every new table MUST be assigned to one of these domains

## SCD Policy
- Dimension tables use SCD Type 1 only. Do NOT apply `scd: type2` or higher.
```

`rules.custom.md` is NOT generated by `modscape init`. Create it manually when your project needs it.

---

## 16. Complete Example

```yaml
domains:
  - id: sales_domain
    name: "Sales Operations"
    description: "Core transactional data."
    color: "rgba(239, 68, 68, 0.1)"
    members: [dim_customers, fct_orders]

  - id: analytics_domain
    name: "Analytics & Insights"
    color: "rgba(245, 158, 11, 0.1)"
    members: [mart_monthly_revenue]

  - id: dashboards_domain
    name: "BI Dashboards"
    color: "rgba(139, 92, 246, 0.1)"
    members: [revenue_dashboard]

consumers:
  - id: revenue_dashboard
    name: "Revenue Dashboard"
    description: "Monthly KPI dashboard for the finance team."
    appearance:
      icon: "📊"
      color: "#e0f2fe"
    url: "https://bi.example.com/revenue"

tables:
  - id: dim_customers
    name: "Customers"
    logical_name: "Customer Master"
    physical_name: "dim_customers_v2"
    appearance:
      type: dimension
      scd: type2
      icon: "👤"
    conceptual:
      description: "One row per unique customer version (SCD Type 2)."
      tags: [WHO]
    columns:
      - id: customer_key
        logical: { name: "Customer Key", type: Int, isPrimaryKey: true }
      - id: customer_name
        logical: { name: "Name", type: String }
      - id: dw_valid_from
        logical: { name: "Valid From", type: Timestamp }
    sampleData:
      - [1, "Acme Corp", "2024-01-01T00:00:00Z"]
      - [2, "Beta Ltd",  "2024-03-15T00:00:00Z"]
      - [3, "Gamma Inc", "2024-06-01T00:00:00Z"]

  - id: fct_orders
    name: "Orders"
    logical_name: "Order Transactions"
    physical_name: "fct_sales_orders"
    appearance: { type: fact, sub_type: transaction, icon: "🛒" }
    conceptual:
      description: "One row per order line item."
      tags: [WHAT, HOW_MUCH]
    implementation:
      materialization: incremental
      incremental_strategy: merge
      unique_key: order_id
      partition_by: { field: order_date, granularity: day }
      cluster_by: [customer_key]
    columns:
      - id: order_id
        logical: { name: "Order ID", type: Int, isPrimaryKey: true }
        physical: { name: "order_id", type: "BIGINT", constraints: [NOT NULL] }
      - id: customer_key
        logical: { name: "Customer Key", type: Int, isForeignKey: true }
      - id: amount
        logical: { name: "Amount", type: Decimal, additivity: fully }
    sampleData:
      - [1001, 1, 150.00]
      - [1002, 2,  89.50]
      - [1003, 1, 210.00]

  - id: mart_monthly_revenue
    name: "Monthly Revenue"
    logical_name: "Executive Revenue Summary"
    physical_name: "mart_finance_monthly_revenue_agg"
    appearance: { type: mart, icon: "📈" }
    implementation:
      materialization: table
      grain: [month_key]
      measures:
        - column: total_revenue
          agg: sum
          source_column: fct_orders.amount
    columns:
      - id: month_key
        logical: { name: "Month", type: String, isPrimaryKey: true }
      - id: total_revenue
        logical: { name: "Revenue", type: Decimal, additivity: fully }
    sampleData:
      - ["2024-01", 12450.50]
      - ["2024-02", 15200.00]
      - ["2024-03", 18900.75]

lineage:                            # data flow — separate from ER
  - id: lin_orders_revenue
    from: fct_orders
    to: mart_monthly_revenue
  - id: lin_cust_revenue
    from: dim_customers
    to: mart_monthly_revenue
  - id: lin_rev_dashboard
    from: mart_monthly_revenue
    to: revenue_dashboard           # consumer ID — valid lineage target

relationships:                      # ER only — not for lineage
  - id: rel_cust_orders
    from: { table: dim_customers, column: [customer_key] }
    to:   { table: fct_orders,    column: [customer_key] }
    type: one-to-many

annotations:
  - id: note_001
    type: sticky
    text: "Grain: one row per order line item."
    targetId: fct_orders
    targetType: table
    offset: { x: 100, y: -80 }

layout:
  # Domains — width/height calculated by formula
  # sales_domain: 2 tables side by side → 2-col × 1-row → w:880, h:400
  sales_domain:
    x: 0
    y: 0
    width: 880
    height: 400

  # Tables inside sales_domain — coordinates relative to domain origin
  dim_customers:
    x: 80
    y: 80
    parentId: sales_domain

  fct_orders:
    x: 480
    y: 80
    parentId: sales_domain

  # analytics_domain: 1 table → 1-col × 1-row → w:480, h:400
  analytics_domain:
    x: 1000
    y: 0
    width: 480
    height: 400

  mart_monthly_revenue:
    x: 80
    y: 80
    parentId: analytics_domain

  # dashboards_domain: 1 consumer → w:480, h:280
  dashboards_domain:
    x: 1560
    y: 0
    width: 480
    height: 280

  revenue_dashboard:
    x: 80
    y: 80
    parentId: dashboards_domain
```
