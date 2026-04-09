# Pipeline Spec: Annual Billing Support

## Goal
Finance チームが年次請求プランの ARR (Annual Recurring Revenue) を MRR とは別に追跡できるようにする。
Stripe 側で `billing_cycle` (monthly|annual) と `annual_price_usd` が追加済みのため、
これをデータモデルに取り込み、Revenue Dashboard での ARR トレンド表示を可能にする。

## Stakeholders
- owner: Finance チーム
- consumers: [経営ダッシュボード担当, revenue_dashboard]

## Data Sources
- `billing.subscriptions` — `billing_cycle` (monthly|annual) と `annual_price_usd` カラムが追加済み

## Acceptance Criteria
- [ ] `sat_subscription_status` に `billing_cycle` と `annual_price_usd` が保存される
- [ ] `fct_subscription_events` に `arr_amount` カラムが追加される
- [ ] `mart_arr` で年次 ARR スナップショット（plan × country 別）が取得できる
- [ ] Revenue Dashboard が ARR トレンドを表示できる

## Target Tool
dbt

## Status
design
