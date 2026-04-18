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

## Known Issues / Caveats
- `country_code` は現在 NULL。来期のシステム開発で追加予定（Q-003）

## Changelog
- 2026-04-18: Initial version (SDD: annual-billing)
