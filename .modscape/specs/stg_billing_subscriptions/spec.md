# stg_billing_subscriptions

## Overview
- **Owner**: Finance チーム
- **Update Frequency**: パイプライン実行時（バッチ）
- **SLA**: —

## Business Context
`billing.subscriptions` の生データを型変換・NULL 補完したステージング層。
以降のすべての下流テーブルはこのテーブルを起点とする。

## Business Rules
- `annual_price_usd` が NULL または空文字列の場合、`monthly_price_usd × 12` でフォールバック（AC-005）
- CSV ロード時は空文字列も NULL として扱う（SQLite の `TRIM(col) = ''` ガード）

## Known Issues / Caveats
- `country_code` はソースに存在しない。来期のシステム開発で追加予定（Q-003）

## Changelog
- 2026-04-18: Initial version (SDD: annual-billing)
