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

## Repository Structure

```
modscape-sdd/
├── main-model.yaml              ← Main data model (generated at archive)
├── data/
│   ├── 01_raw__billing_subscriptions.csv    ← Source
│   ├── 02_stg__billing_subscriptions.csv    ← Staging output
│   ├── 03_dim__subscriptions.csv            ← Dimension output
│   ├── 04_fct__subscription_events.csv      ← Fact output
│   └── 05_mart__arr.csv                     ← Mart output
├── pipeline/
│   ├── run_pipeline.py          ← Entry point: python pipeline/run_pipeline.py
│   └── sql/
│       ├── 01_stg_billing_subscriptions.sql
│       ├── 02_dim_subscriptions.sql
│       ├── 03_fct_subscription_events.sql
│       ├── 04_mart_arr.sql
│       └── 05_tests.sql
└── .modscape/
    ├── rules.md                 ← Modeling conventions
    ├── specs/                   ← Permanent per-table documentation
    │   ├── _context.yaml        ← Cross-table decisions
    │   └── <table-id>/spec.md
    ├── changes/                 ← Active work folders (empty after archive)
    └── archives/
        └── 2026-04-18-annual-billing/   ← Completed spec
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
