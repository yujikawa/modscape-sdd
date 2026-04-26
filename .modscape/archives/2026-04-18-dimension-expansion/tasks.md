# Pipeline Tasks
> Generated from: .modscape/changes/dimension-expansion/spec-model.yaml
> Spec: .modscape/changes/dimension-expansion/spec.md
> Progress: 0 / 10

## Phase 1: Staging
- [x] `stg_customers` [table] — raw_customers.csv を型変換・ロード
- [x] `stg_plans` [table] — raw_plans.csv を型変換・ロード

## Phase 2: Core
- [x] `dim_customers` [table] ← stg_customers
- [x] `dim_plans` [table] ← stg_plans
- [x] `fct_subscription_events` [table / DROP & RECREATE] ← stg_billing_subscriptions, dim_customers, dim_plans

## Phase 3: Mart
- [x] `mart_revenue_summary` [table] ← fct_subscription_events

## Phase 4: Tests
- [x] `stg_customers` — customer_id: unique, not_null  [→ AC-001]
- [x] `stg_plans` — plan_id: unique, not_null  [→ AC-002]
- [x] `dim_customers` — customer_id: unique, not_null; country_code: not_null  [→ AC-001]
- [x] `dim_plans` — plan_id: unique, not_null; plan_tier: not_null  [→ AC-002]
- [x] `fct_subscription_events` → `dim_customers` FK test (customer_id)  [→ AC-003]
- [x] `fct_subscription_events` → `dim_plans` FK test (plan_id)  [→ AC-003]
- [x] `fct_subscription_events` — country_code: not_null (全レコード補完確認)  [→ AC-005]
- [x] `mart_revenue_summary` — year_key × month_key × plan_tier × country_code × customer_segment: unique  [→ AC-004]
