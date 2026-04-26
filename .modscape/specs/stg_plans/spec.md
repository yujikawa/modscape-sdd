# stg_plans

## Overview
- **Owner**: BI チーム
- **Update Frequency**: パイプライン実行時（バッチ）
- **SLA**: —

## Business Context
`data/03_raw__plans.csv` を型変換・NULL チェックしたステージング層。
プランマスタ（plan_tier、plan_category、価格帯）の入口となるテーブル。
下流の `dim_plans` に直接供給する。

## Business Rules
- `plan_id` は主キー。重複・NULL を許容しない
- `plan_tier` は `Starter | Pro | Enterprise` のいずれか
- `plan_category` は `Self-Service | Sales-Assisted` のいずれか
- `base_monthly_price_usd` / `base_annual_price_usd` は REAL にキャスト済み

## Known Issues / Caveats
- なし

## Changelog
- 2026-04-18: Initial version (SDD: dimension-expansion)
