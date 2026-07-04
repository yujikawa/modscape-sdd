## billing-job-propagation

- **job**: 顧客の職業を表す属性カラム
  - label: 職業
  - tables: stg_billing_subscriptions, fct_subscription_events, dim_subscriptions, mart_arr, mart_revenue_summary
  - columns: stg_billing_subscriptions.job
