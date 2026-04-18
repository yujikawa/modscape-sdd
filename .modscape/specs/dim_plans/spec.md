# dim_plans

## Overview
- **Owner**: BI チーム
- **Update Frequency**: パイプライン実行時（バッチ）
- **SLA**: —

## Business Context
プランマスタディメンション。`stg_plans` から生成される SCD Type 1 テーブル。
`fct_subscription_events` が `plan_id` で LEFT JOIN し、`plan_tier` と `plan_category` を補完する。

## Business Rules
- `plan_id` は主キー。重複・NULL を許容しない
- `plan_tier` は `Starter | Pro | Enterprise` のいずれか。NOT NULL
- `plan_category` は `Self-Service | Sales-Assisted` のいずれか
- `fct_subscription_events` との JOIN キーは `plan_id`（N:1）

## Known Issues / Caveats
- なし

## Changelog
- 2026-04-18: Initial version (SDD: dimension-expansion)
