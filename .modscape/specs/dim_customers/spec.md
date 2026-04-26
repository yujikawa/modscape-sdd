# dim_customers

## Overview
- **Owner**: BI チーム
- **Update Frequency**: パイプライン実行時（バッチ）
- **SLA**: —

## Business Context
顧客マスタディメンション。`stg_customers` から生成される SCD Type 1 テーブル。
`fct_subscription_events` が `customer_id` で LEFT JOIN し、`country_code` と `customer_segment` を補完する。
Scenario A で NULL だった `country_code`（D-003）をここで解決した。

## Business Rules
- `customer_id` は主キー。重複・NULL を許容しない
- `country_code` は ISO 2文字コード（JP / US / DE 等）。NOT NULL
- `customer_segment` は `SMB | Mid-Market | Enterprise` のいずれか
- `fct_subscription_events` との JOIN キーは `customer_id`（N:1）

## Known Issues / Caveats
- なし（D-003 は本スペックで解決済み）

## Changelog
- 2026-04-18: Initial version。D-003（country_code NULL）を解決 (SDD: dimension-expansion)
