# dim_subscriptions

## Overview
- **Owner**: Finance チーム
- **Update Frequency**: パイプライン実行時（バッチ、SCD Type 1 上書き）
- **SLA**: —

## Business Context
サブスクリプションのディメンションテーブル。
`billing_cycle` と `annual_price_usd` を保持し、ARR/MRR 計算の基盤となる（AC-001）。

## Business Rules
- `billing_cycle = annual` の場合: `mrr_amount = annual_price_usd / 12`
- `billing_cycle = monthly` の場合: `mrr_amount = monthly_price_usd`
- `annual_price_usd` は Staging でフォールバック済みの値（NULL なし）
- SCD Type 1 — 最新状態のみ保持

## Known Issues / Caveats
- `country_code` は現在 NULL。来期のシステム開発で追加予定（Q-003）

## Changelog
- 2026-04-18: Initial version (SDD: annual-billing)
