# stg_customers

## Overview
- **Owner**: BI チーム
- **Update Frequency**: パイプライン実行時（バッチ）
- **SLA**: —

## Business Context
`data/02_raw__customers.csv` を型変換・NULL チェックしたステージング層。
顧客マスタ（country_code、customer_segment、industry）の入口となるテーブル。
下流の `dim_customers` に直接供給する。

## Business Rules
- `customer_id` は主キー。重複・NULL を許容しない
- `customer_segment` は `SMB | Mid-Market | Enterprise` のいずれか
- `loaded_at` はパイプライン実行時刻を記録

## Known Issues / Caveats
- なし

## Changelog
- 2026-04-18: Initial version (SDD: dimension-expansion)
