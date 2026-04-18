# Design: Dimension Expansion — Multi-Dimensional Revenue Analytics

## Design Decisions

### スタースキーマ構成
`fct_subscription_events` を中心に `dim_customers`・`dim_plans`・`dim_subscriptions`（既存）の
3ディメンションが接続するスタースキーマを採用。

### country_code の解決（D-003）
`dim_customers.country_code` を正典として使用。
`fct_subscription_events` を再生成する際に `customer_id` 経由で `dim_customers` を LEFT JOIN し、
`country_code`・`customer_segment` を補完する（AC-003、AC-005）。
Scenario A で NULL だったすべての country_code がここで解決される。

### fct_subscription_events の再生成方式
SQLite には ALTER TABLE + UPDATE JOIN に制約があるため、
`stg_billing_subscriptions` と新規ディメンションを JOIN して DROP & RECREATE で対応する。

### mart_revenue_summary のグレイン
`year_key × month_key × plan_tier × country_code × customer_segment`
ARR（annual のみ）と MRR（全プラン）を同一マートで提供する（Q-002 確認済み）。

### mart_arr との共存
`mart_arr` は後方互換のため削除しない。
`mart_revenue_summary` が上位互換として機能する（Downstream Impact — Context Only）。

## Affected Tables

> ⚠️ This Affected Tables classification is an AI proposal. Edit directly if the classification is incorrect.

### Direct Impact
- `stg_customers`: 新規作成 — raw_customers.csv のステージング層
- `stg_plans`: 新規作成 — raw_plans.csv のステージング層
- `dim_customers`: 新規作成 — 顧客マスタディメンション（AC-001、D-003 解決）
- `dim_plans`: 新規作成 — プランマスタディメンション（AC-002）
- `fct_subscription_events`: 既存改修 — customer_segment・plan_tier・plan_category・country_code を補完（AC-003、AC-005）
- `mart_revenue_summary`: 新規作成 — 多軸 ARR/MRR 集計マート（AC-004）

### Downstream Impact — Implement
（なし — mart_revenue_summary が新規追加のため downstream 改修なし）

### Downstream Impact — Context Only
- `mart_arr`: `fct_subscription_events` の下流だが、追加カラムを使用しないため変更不要。後方互換のまま維持。

## Findings

### Requires Model Change
（なし）

### Implementation Notes
（実装中に発見があればここに記録）
