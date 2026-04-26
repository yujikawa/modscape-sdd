# fct_subscription_events

## Overview
- **Owner**: Finance チーム
- **Update Frequency**: パイプライン実行時（インクリメンタル・マージ）
- **SLA**: —

## Business Context
サブスクリプションのイベント（新規契約・解約・トライアル転換）を記録するファクトテーブル。
MRR の増減と ARR を追跡する中心的テーブル（AC-002）。

## Business Rules
- `event_type` は `new_subscription | cancellation | trial_conversion | plan_upgrade`
- `arr_amount`: `billing_cycle = annual` の場合のみ `annual_price_usd` を格納。`monthly` は NULL（AC-002）
- `mrr_delta`: 新規は `+mrr_amount`、解約は `-mrr_amount`
- トライアル経由の契約は `trial_end_date` が非 NULL の場合 `trial_conversion` として記録
- `country_code`: `dim_customers.country_code` から LEFT JOIN で補完（AC-005、D-003 解決済み）
- `customer_segment`: `dim_customers.customer_segment` から補完（AC-003）
- `plan_tier` / `plan_category`: `dim_plans` から補完（AC-003）
- `customer_id` は `dim_customers`（N:1）、`plan_id` は `dim_plans`（N:1）の FK

## Known Issues / Caveats
- なし（`country_code` NULL は dimension-expansion で解決済み）

## Changelog
- 2026-04-18: Initial version (SDD: annual-billing)
- 2026-04-18: dim_customers・dim_plans FK 追加。country_code/customer_segment/plan_tier/plan_category を補完（D-003 解決）(SDD: dimension-expansion)
