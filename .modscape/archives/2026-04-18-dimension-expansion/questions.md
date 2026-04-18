# Questions: dimension-expansion

## Pipeline-level

- [x] **Q-001** `raw_customers.csv` の customer_id は `fct_subscription_events` の customer_id と完全に一致するか？
  **A:** 一致する

- [x] **Q-002** `mart_revenue_summary` の粒度は year × month × plan_tier × country_code × customer_segment で良いか？
  **A:** その粒度で大丈夫

## Table-level

### fct_subscription_events

- [x] **Q-003** 既存の `fct_subscription_events` に customer_id カラムは存在するか？JOIN キーとして利用できるか？
  **A:** JOIN できる
