# mart_revenue_summary

## Overview
- **Owner**: BI チーム
- **Update Frequency**: パイプライン実行時（バッチ）
- **SLA**: —

## Business Context
多軸 ARR/MRR 集計マート。`fct_subscription_events` を集約して生成する `mart_arr` の上位互換。
`year × month × plan_tier × country_code × customer_segment` の粒度で ARR/MRR をスライスできる。
Finance チームと BI チームが revenue_dashboard でレポートに使用する。

## Business Rules
- グレイン: `year_key × month_key × plan_tier × country_code × customer_segment`（複合主キー）
- `event_type IN ('new_subscription', 'trial_conversion')` のイベントのみ集計（解約は除外）
- `total_arr_usd` は annual サブスクリプションのみ計上（monthly は 0 扱い）
- `total_mrr_usd` は全 billing_cycle を含む
- `mart_arr` は後方互換のため削除せず共存

## Known Issues / Caveats
- なし

## Changelog
- 2026-04-18: Initial version。mart_arr の上位互換として新設 (SDD: dimension-expansion)
