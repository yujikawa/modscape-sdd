# mart_arr

## Overview
- **Owner**: Finance チーム
- **Update Frequency**: 年次スナップショット（バッチ）
- **SLA**: —

## Business Context
年次 ARR（Annual Recurring Revenue）スナップショット。
`year_key × plan_id × country_code` 粒度で annual サブスクリプションの ARR を集計する（AC-003）。
Revenue Dashboard の ARR トレンド表示に使用（AC-004）。

## Business Rules
- `billing_cycle = annual` かつ `event_type IN (new_subscription, trial_conversion)` のイベントのみ集計
- `total_arr_usd = SUM(arr_amount)` — annual プランの年間収益合計
- `avg_arr_per_subscription_usd = total_arr_usd / active_subscription_count`
- `snapshot_date` は各年の 12/31

## Known Issues / Caveats
- `country_code` は現在 NULL のため、plan 単位での集計になっている。来期追加予定（Q-003）

## Changelog
- 2026-04-18: Initial version (SDD: annual-billing)
