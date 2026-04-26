-- mart_revenue_summary
-- Source : fct_subscription_events
-- Output : 10_mart__revenue_summary.csv
-- AC-004 : country × segment × plan_tier 別に ARR/MRR を集計

CREATE TABLE IF NOT EXISTS mart_revenue_summary AS
SELECT
    STRFTIME('%Y',    event_date)    AS year_key,
    STRFTIME('%Y-%m', event_date)    AS month_key,
    plan_tier,
    plan_category,
    country_code,
    customer_segment,
    COUNT(DISTINCT subscription_id)  AS active_subscriptions,
    ROUND(SUM(mrr_amount), 2)        AS total_mrr_usd,
    ROUND(SUM(COALESCE(arr_amount, 0)), 2) AS total_arr_usd
FROM fct_subscription_events
WHERE event_type IN ('new_subscription', 'trial_conversion')
GROUP BY year_key, month_key, plan_tier, plan_category, country_code, customer_segment;
