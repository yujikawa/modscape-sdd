# Pipeline Spec: Dimension Expansion — Multi-Dimensional Revenue Analytics

## Goal
BI チームの要件として、ARR/MRR をより細かい軸で分析できるようにする。
現在の `mart_arr` は plan × year でしか見られないため、顧客ディメンション・プランディメンションを追加し、
国・セグメント・プランティアなど複数の軸でスライスできる `mart_revenue_summary` を新設する。
シナリオ A で未解決だった `country_code` NULL の問題（Q-003）もここで解決する。

## Stakeholders
- owner: BI チーム
- consumers: [Finance チーム, revenue_dashboard]

## Data Sources
- `data/02_raw__customers.csv` — 顧客マスタ（country_code, customer_segment, industry など）
- `data/03_raw__plans.csv` — プランマスタ（plan_tier, plan_category, base_price_usd など）
- `fct_subscription_events` — 既存ファクト（FK 追加対象）
- `mart_arr` — 既存マート（mart_revenue_summary の前身）

## Acceptance Criteria
- [ ] AC-001: dim_customers に country_code と customer_segment が保存される
- [ ] AC-002: dim_plans に plan_tier と plan_category が保存される
- [ ] AC-003: fct_subscription_events から dim_customers・dim_plans を JOIN できる
- [ ] AC-004: mart_revenue_summary で country × segment × plan_tier 別に ARR/MRR が集計できる
- [ ] AC-005: country_code が NULL だった既存レコードが dim_customers の値で補完される

## Target Tool
SQLite + SQL（出力は CSV ファイル）

## Status
design
