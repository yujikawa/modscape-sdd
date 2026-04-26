# Pipeline Tasks
> Generated from: .modscape/changes/annual-billing/spec-model.yaml
> Spec: .modscape/changes/annual-billing/spec.md
> Progress: 0 / 10

## Phase 1: Staging
- [x] `stg_billing_subscriptions` [table] — `01_raw__billing_subscriptions.csv` を読み込み、型変換・annual_price_usd NULL フォールバック（monthly_price_usd × 12）を適用し CSV 出力

## Phase 2: Core
- [x] `dim_subscriptions` [table] ← stg_billing_subscriptions — billing_cycle / annual_price_usd / mrr_amount を保持するディメンション CSV を出力
- [x] `fct_subscription_events` [incremental] ← stg_billing_subscriptions, dim_subscriptions — イベント種別判定・arr_amount（annual のみ）・mrr_delta を計算し CSV 出力

## Phase 3: Mart
- [x] `mart_arr` [table] ← fct_subscription_events — annual イベントを year_key × plan_id × country_code で集計し ARR スナップショット CSV を出力

## Phase 4: Tests
- [x] `stg_billing_subscriptions` — subscription_id: unique, not_null                      [→ AC-001]
- [x] `stg_billing_subscriptions` — billing_cycle: 値が monthly または annual のみ          [→ AC-001, AC-005]
- [x] `stg_billing_subscriptions` — annual_price_usd: billing_cycle=annual の行は not_null  [→ AC-005]
- [x] `dim_subscriptions` — subscription_id: unique, not_null                               [→ AC-001]
- [x] `fct_subscription_events` — arr_amount: billing_cycle=monthly の行は NULL             [→ AC-002]
- [ ] `mart_arr` — total_arr_usd: plan × country 別集計値が fct の合計と一致するか          [→ AC-003] [manual verification]
- [ ] AC-004: Revenue Dashboard に mart_arr の CSV を接続し ARR トレンドが表示されること     [manual verification]

## Amend: 2026-04-18

- [x] A.1 Target tool を SQLite + SQL に変更 — pipeline/ の pandas 実装を SQLite + SQL（Python `sqlite3`）で書き直す
