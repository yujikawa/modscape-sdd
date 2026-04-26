# modscape-sdd

A sample repository for **Spec-Driven Data Engineering (SDD)** using [Modscape](https://github.com/yujikawa/modscape).

[日本語版はこちら (Japanese version)](README.ja.md)

---

## What is Spec-Driven Data Engineering?

In traditional data engineering, requirements live in tickets, design decisions get buried in Slack, and the only surviving documentation is the SQL itself. **SDD** flips this by making the spec the single source of truth — from the first business conversation to the archived table docs.

The workflow has four phases, each driven by a slash command:

```
/modscape:spec:requirements   →  capture the "why"
/modscape:spec:design         →  design the "what"
/modscape:spec:implement      →  build the "how"
/modscape:spec:archive        →  preserve the "done"
```

Every decision, question, and change is recorded in the work folder (`.modscape/changes/<name>/`) and archived when the pipeline ships.

---

## Walkthrough: Annual Billing ARR Pipeline

This repository contains a complete, runnable example of the SDD workflow.
The scenario: Finance wants to track **ARR (Annual Recurring Revenue)** separately from MRR after Stripe added `billing_cycle` and `annual_price_usd` to subscriptions.

### Source data

One raw CSV is provided as the data source:

```
data/01_raw__billing_subscriptions.csv   ← 10 subscription records from Stripe
```

The pipeline produces four additional CSVs by running SQL in SQLite:

```
data/02_stg__billing_subscriptions.csv   ← typed, NULL-filled staging layer
data/03_dim__subscriptions.csv           ← subscription dimension (billing_cycle, MRR)
data/04_fct__subscription_events.csv     ← events with arr_amount (annual only)
data/05_mart__arr.csv                    ← ARR snapshot by plan × year
```

Run the full pipeline:

```bash
python pipeline/run_pipeline.py
```

---

## Step-by-Step Workflow

### Step 1 — Requirements `/modscape:spec:requirements`

You describe the business need in plain language. The AI asks clarifying questions, assigns `AC-NNN` IDs to acceptance criteria, and writes `spec.md`.

**Prompt:**
```
Finance チームから年次請求プランの分析要件が来ました。
ゴール: ARR を MRR とは別に計算できるようにする
ステークホルダー: Finance チーム、経営ダッシュボード担当
```

**Output:** `.modscape/changes/annual-billing/spec.md`

```markdown
## Acceptance Criteria
- [ ] AC-001: dim_subscriptions に billing_cycle と annual_price_usd が保存される
- [ ] AC-002: fct_subscription_events に arr_amount カラムが追加される
- [ ] AC-003: mart_arr で年次 ARR スナップショットが取得できる
- [ ] AC-004: Revenue Dashboard が ARR トレンドを表示できる
- [ ] AC-005: annual_price_usd が NULL の場合は monthly_price_usd × 12 でフォールバック

## Target Tool
SQLite + SQL（出力は CSV ファイル）
```

Unresolved questions are tracked in `questions.md` and answered with `/modscape:spec:answer`:

```
Q-001: ダッシュボード実装はスコープに含まれるか？
→ A: データマートまでがスコープ。ダッシュボードは現場対応。

Q-002: mart_arr の粒度は年次か月次か？
→ A: 年次スナップショットのみ。
```

---

### Step 2 — Design `/modscape:spec:design annual-billing`

The AI reads `spec.md`, designs a dimensional model, and uses `modscape` CLI commands to build `spec-model.yaml`.

**Lineage designed:**

```
01_raw (CSV)
  └─► stg_billing_subscriptions   [staging]   NULL fallback, type casting
        ├─► dim_subscriptions      [dimension] billing_cycle, annual_price_usd, mrr_amount
        │     └─► fct_subscription_events  [fact]  arr_amount (annual only), mrr_delta
        │               └─► mart_arr       [mart]  ARR snapshot: year × plan × country
        │                         └─► revenue_dashboard  [consumer]
```

Key design decisions recorded in `design.md`:

| Decision | Rationale |
|---|---|
| `annual_price_usd` NULL → `monthly_price_usd × 12` | Stripe migration left legacy records without the field |
| `arr_amount` is NULL for monthly plans | Keeps monthly/annual semantics explicit (AC-002) |
| `mart_arr` grain: `year_key × plan_id × country_code` | Annual snapshot only — monthly ARR tracking out of scope |
| `country_code` is NULL | Not in source data; planned for next fiscal year |

**Output:** `spec-model.yaml`, `design.md`, `tasks.md`

During design iteration, the model was changed from **Data Vault** (satellite) to **Dimensional Modeling** (dimension table) — the design command is re-runnable and non-destructive.

---

### Step 3 — Implement `/modscape:spec:implement annual-billing`

The AI works through `tasks.md` one task at a time, generating SQL files and updating checkboxes.

**Generated files:**

```
pipeline/
  run_pipeline.py               ← SQLite runner: load CSV → run SQL → export CSV
  sql/
    01_stg_billing_subscriptions.sql   ← COALESCE fallback, empty-string guard
    02_dim_subscriptions.sql           ← SCD Type 1 dimension
    03_fct_subscription_events.sql     ← UNION ALL: new + cancellation events
    04_mart_arr.sql                    ← GROUP BY year_key, plan_id, country_code
    05_tests.sql                       ← 7 data quality assertions
```

A bug was caught during implementation: SQLite loads CSV columns as TEXT, so empty strings cast to `0.0` instead of `NULL`, bypassing the COALESCE fallback. Fixed with an explicit empty-string guard:

```sql
-- Before (broken for empty strings loaded from CSV)
COALESCE(CAST(annual_price_usd AS REAL), monthly_price_usd * 12)

-- After (AC-005 fix)
CASE WHEN annual_price_usd IS NULL OR TRIM(annual_price_usd) = ''
     THEN CAST(monthly_price_usd AS REAL) * 12
     ELSE CAST(annual_price_usd AS REAL)
END
```

Test results:

```
Tests: 7 passed, 0 failed
  [PASS] stg.subscription_id: unique
  [PASS] stg.subscription_id: not_null
  [PASS] stg.billing_cycle: monthly or annual only
  [PASS] stg.annual_price_usd: not_null for annual rows          ← AC-005
  [PASS] dim.subscription_id: unique
  [PASS] dim.subscription_id: not_null
  [PASS] fct.arr_amount: NULL for monthly rows                    ← AC-002
```

---

### Step 4 — Archive `/modscape:spec:archive annual-billing`

The AI merges `spec-model.yaml` into the main model, writes permanent per-table specs, and moves the work folder to archives.

**Permanent specs created:**

```
.modscape/specs/
  stg_billing_subscriptions/spec.md   ← business context + known issues
  dim_subscriptions/spec.md
  fct_subscription_events/spec.md
  mart_arr/spec.md
  _context.yaml                        ← cross-table decisions (D-001 ~ D-003)
```

**Work folder archived:**

```
.modscape/archives/2026-04-18-annual-billing/
  spec.md        ← original requirements
  design.md      ← design decisions + findings
  tasks.md       ← completed checklist
  questions.md   ← all Q&A
  spec-model.yaml
```

---

## Walkthrough: Dimension Expansion — Customer & Plan Analytics

Building on the annual-billing pipeline, Finance and BI teams needed multi-dimensional revenue analysis — slicing ARR and MRR by customer segment, plan tier, and country.

### Source data

Two new raw CSVs are introduced:

```
data/02_raw__customers.csv   ← customer master (country_code, segment, industry)
data/03_raw__plans.csv       ← plan master (tier, category, pricing)
```

The expanded pipeline produces five additional outputs:

```
data/06_stg__customers.csv          ← staged customer records
data/07_stg__plans.csv              ← staged plan records
data/08_dim__customers.csv          ← customer dimension
data/09_dim__plans.csv              ← plan dimension
data/10_mart__revenue_summary.csv   ← multi-axis ARR/MRR summary
```

---

### Step 1 — Requirements `/modscape:spec:requirements`

**Prompt:**
```
既存の ARR パイプラインを拡張して、顧客・プランのディメンションを追加したい。
ARR/MRR を customer_segment × plan_tier × country_code でスライスできるようにする。
```

**Output:** `.modscape/changes/dimension-expansion/spec.md`

```markdown
## Acceptance Criteria
- [ ] AC-001: dim_customers に country_code と customer_segment が保存される
- [ ] AC-002: dim_plans に plan_tier と plan_category が保存される
- [ ] AC-003: fct_subscription_events に customer_segment, plan_tier, plan_category が補完される
- [ ] AC-004: fct の country_code NULL が dim_customers で解決される
- [ ] AC-005: mart_revenue_summary で year × month × plan_tier × country_code × customer_segment の粒度で集計できる

## Target Tool
SQLite + SQL（出力は CSV ファイル）
```

Questions answered with `/modscape:spec:answer`:

```
Q-001: customer_id は fct_subscription_events と一致するか？
→ A: 一致する

Q-002: mart_revenue_summary の粒度は？
→ A: year × month × plan_tier × country_code × customer_segment で大丈夫

Q-003: fct に dim_customers を JOIN できるか？
→ A: JOIN できる
```

---

### Step 2 — Design `/modscape:spec:design dimension-expansion`

**Star schema designed:**

```
raw_customers ──► stg_customers ──► dim_customers ──┐
                                                      │ N:1
raw_plans ──────► stg_plans ────► dim_plans ─────────┤
                                                      ▼
                              dim_subscriptions ──► fct_subscription_events
                              (N:1)                    ├──► mart_arr            (existing)
                                                       └──► mart_revenue_summary ──► revenue_dashboard
```

Key design decisions recorded in `design.md`:

| Decision | Rationale |
|---|---|
| `country_code` resolved via `dim_customers` JOIN | Not in billing source data; D-003 closed here |
| `fct_subscription_events` DROP & RECREATE | SQLite cannot ALTER TABLE + UPDATE with JOIN in-place |
| `mart_revenue_summary` coexists with `mart_arr` | Backward compatibility — existing consumers still reference `mart_arr` (D-004) |
| dim→fct connections are **relationships** (N:1), not lineage | Lineage = build/data-flow dependency; FK references = relationships |

**Output:** `spec-model.yaml`, `design.md`, `tasks.md`

---

### Step 3 — Implement `/modscape:spec:implement dimension-expansion`

**New files:**

```
pipeline/sql/
  06_stg_customers.sql          ← staged customer data
  07_stg_plans.sql              ← staged plan data with CAST
  08_dim_customers.sql          ← customer dimension
  09_dim_plans.sql              ← plan dimension
  10_mart_revenue_summary.sql   ← multi-axis ARR/MRR mart (year × month × tier × country × segment)
```

**Updated files:**

```
pipeline/sql/03_fct_subscription_events.sql   ← DROP & RECREATE with LEFT JOIN dim_customers, dim_plans
pipeline/sql/05_tests.sql                     ← 9 new assertions added (16 total)
pipeline/run_pipeline.py                      ← expanded to 9 steps
```

Key enrichment in `fct_subscription_events`:

```sql
LEFT JOIN dim_customers dc ON stg.customer_id = dc.customer_id
LEFT JOIN dim_plans dp ON stg.plan_id = dp.plan_id
...
COALESCE(dc.country_code, dim_sub.country_code) AS country_code,  -- AC-004
dc.customer_segment,                                               -- AC-003
dp.plan_tier, dp.plan_category                                     -- AC-003
```

Test results:

```
Tests: 16 passed, 0 failed
  [PASS] dim_customers.customer_id: unique
  [PASS] dim_customers.customer_id: not_null
  [PASS] dim_customers.country_code: not_null                      ← AC-001
  [PASS] dim_plans.plan_id: unique
  [PASS] dim_plans.plan_tier: not_null                             ← AC-002
  [PASS] fct → dim_customers: no orphan customer_id               ← AC-003
  [PASS] fct → dim_plans: no orphan plan_id                       ← AC-003
  [PASS] fct.country_code: not_null after enrichment               ← AC-004
  [PASS] mart_revenue_summary grain: unique                        ← AC-005
  ... (7 existing tests from annual-billing)
```

---

### Step 4 — Archive `/modscape:spec:archive dimension-expansion`

**Permanent specs created / updated:**

```
.modscape/specs/
  stg_customers/spec.md          ← new
  stg_plans/spec.md              ← new
  dim_customers/spec.md          ← new
  dim_plans/spec.md              ← new
  mart_revenue_summary/spec.md   ← new
  fct_subscription_events/spec.md  ← updated (D-003 resolved, country_code NULL closed)
  mart_arr/spec.md               ← changelog only (no structural change)
  _context.yaml                  ← D-003 closed, D-004 and D-005 added
```

**Work folder archived:**

```
.modscape/archives/2026-04-18-dimension-expansion/
  spec.md        ← original requirements
  design.md      ← design decisions + findings
  tasks.md       ← completed checklist
  questions.md   ← all Q&A
  spec-model.yaml
```

---

## Sandbox Environment

The `sandbox/` directory contains a ready-to-run **Apache Spark + Apache Iceberg + Apache Airflow** environment. Use it to execute and validate the pipelines you design through the SDD workflow.

### Services

| Service | Role | URL |
|---|---|---|
| Apache Airflow | Pipeline execution & scheduling | http://localhost:8080 |
| Apache Iceberg | Table format on top of Spark (stored in MinIO) | — |
| MinIO | S3-compatible object storage | http://localhost:9001 |
| Jupyter Notebook | Interactive Spark SQL exploration | http://localhost:8888 |

### Prerequisites

**Linux / WSL2:**
```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
# Re-login to apply group change
```

**macOS (Colima):**
```bash
brew install colima docker docker-compose
colima start --cpu 4 --memory 8 --disk 30
```

### Start

```bash
cd sandbox
make up      # Build images & start all services
make ps      # Check status (wait until all services show Up)
```

### Run the Pipeline

```bash
make trigger     # Trigger the annual_billing_pipeline DAG
make query-arr   # Query mart_arr (ARR snapshot result)
```

Or trigger `annual_billing_pipeline` manually from the Airflow UI (http://localhost:8080, admin / admin).

> **First run**: The `seed_raw` task downloads PySpark JARs from Maven automatically (~3–5 min). Subsequent runs use the cache and are much faster.

### Pipeline Phases

```
seed_raw → stg_billing → core_vault → mart_arr
```

| Phase | Airflow Task | Description |
|---|---|---|
| Phase 0 | `seed_raw` | Load sample data into `raw.billing_subscriptions` |
| Phase 1 | `stg_billing` | Create `stg_billing__subscriptions` (staging) |
| Phase 2 | `core_vault` | Build `hub_subscription` / `sat_subscription_status` / `fct_subscription_events` |
| Phase 3 | `mart_arr` | Build `mart_arr` (grain: year × plan × country) |

The `billing_cycle` and `annual_price_usd` columns in `sat_subscription_status`, and `arr_amount` in `fct_subscription_events`, satisfy the acceptance criteria of the `annual-billing` SDD change.

### Stop / Clean Up

```bash
make down        # Stop services (data is preserved)
make clean       # Remove all containers, volumes, and local images
```

---

## Repository Structure

```
modscape-sdd/
├── main-model.yaml              ← Main data model (9 tables, updated at each archive)
├── data/
│   ├── 01_raw__billing_subscriptions.csv    ← Source (annual-billing)
│   ├── 02_raw__customers.csv                ← Source (dimension-expansion)
│   ├── 03_raw__plans.csv                    ← Source (dimension-expansion)
│   ├── 02_stg__billing_subscriptions.csv    ← Staging output
│   ├── 03_dim__subscriptions.csv            ← Dimension output
│   ├── 04_fct__subscription_events.csv      ← Fact output (enriched)
│   ├── 05_mart__arr.csv                     ← ARR mart
│   ├── 06_stg__customers.csv
│   ├── 07_stg__plans.csv
│   ├── 08_dim__customers.csv
│   ├── 09_dim__plans.csv
│   └── 10_mart__revenue_summary.csv         ← Multi-axis ARR/MRR mart
├── pipeline/
│   ├── run_pipeline.py          ← Entry point: python pipeline/run_pipeline.py
│   └── sql/
│       ├── 01_stg_billing_subscriptions.sql
│       ├── 02_dim_subscriptions.sql
│       ├── 03_fct_subscription_events.sql   ← DROP & RECREATE with dim enrichment
│       ├── 04_mart_arr.sql
│       ├── 05_tests.sql                     ← 16 assertions
│       ├── 06_stg_customers.sql
│       ├── 07_stg_plans.sql
│       ├── 08_dim_customers.sql
│       ├── 09_dim_plans.sql
│       └── 10_mart_revenue_summary.sql
└── .modscape/
    ├── rules.md                 ← Modeling conventions
    ├── specs/                   ← Permanent per-table documentation (9 tables)
    │   ├── _context.yaml        ← Cross-table decisions (D-001 ~ D-005)
    │   └── <table-id>/spec.md
    ├── changes/                 ← Active work folders (empty after archive)
    └── archives/
        ├── 2026-04-18-annual-billing/      ← Scenario 1
        └── 2026-04-18-dimension-expansion/ ← Scenario 2
```

---

## SDD Workflow Diagram

```
Business Request
      │
      ▼
┌─────────────────────────────────────────────────────────────┐
│  /modscape:spec:requirements                                │
│  AI asks: goal? stakeholders? ACs? target tool?            │
│  Output: changes/<name>/spec.md  +  questions.md           │
└──────────────────────┬──────────────────────────────────────┘
                       │  /modscape:spec:answer  (Q&A loop)
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  /modscape:spec:design <name>                               │
│  AI designs model → CLI builds spec-model.yaml             │
│  Output: design.md  +  tasks.md                            │
│  Re-runnable: add findings → re-run → model updated        │
└──────────────────────┬──────────────────────────────────────┘
                       │  /modscape:spec:amend   (mid-impl changes)
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  /modscape:spec:implement <name>                            │
│  AI generates SQL/code task by task, checks off tasks.md   │
│  Bugs → findings recorded in design.md                     │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  /modscape:spec:archive <name>                              │
│  Merges spec-model.yaml → main-model.yaml                  │
│  Writes specs/<table-id>/spec.md  +  _context.yaml         │
│  Moves changes/<name>/ → archives/YYYY-MM-DD-<name>/       │
└─────────────────────────────────────────────────────────────┘
```

---

## Setup

```bash
# Install SDD skills for Claude Code
modscape init --claude --sdd
```

Customize behavior by renaming `.modscape/changes/modscape-spec.custom.md.example` to `modscape-spec.custom.md`.

> **Tip:** Run `/modscape:spec:review <name>` at any point to see open questions, AC coverage, and a go/no-go summary.
