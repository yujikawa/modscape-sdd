# Pipeline Tasks
> Generated from: changes/annual-billing/spec-model.yaml
> Spec: .modscape/changes/annual-billing/spec.md
> Progress: 0 / 9

## Phase 1: Staging
- [ ] `stg_billing__subscriptions` [view] — `billing_cycle`, `annual_price_usd` カラムを追加

## Phase 2: Core
- [ ] `sat_subscription_status` [incremental] ← `stg_billing__subscriptions` — `billing_cycle`, `annual_price_usd` カラムを追加
- [ ] `fct_subscription_events` [incremental] ← `sat_subscription_status` — `arr_amount` カラムを追加（`billing_cycle = 'annual'` の場合のみ `annual_price_usd`、それ以外は NULL）

## Phase 3: Mart
- [ ] `mart_mrr` [table] ← `fct_subscription_events` — `arr` カラムを追加（`arr_amount` の SUM）
- [ ] `mart_arr` [table] ← `fct_subscription_events` — 新規作成（grain: `year_key × plan_key × country_code`）

## Phase 4: Tests
- [ ] `sat_subscription_status` — `billing_cycle`: accepted_values (`monthly`, `annual`)
- [ ] `sat_subscription_status` — `annual_price_usd`: not_null when `billing_cycle = 'annual'`
- [ ] `fct_subscription_events` — `arr_amount`: not_null when `billing_cycle = 'annual'`
- [ ] `mart_arr` — `year_key`, `plan_key`, `country_code`: unique composite key, not_null
