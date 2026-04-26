-- mart_arr (ARR Snapshot)
-- Source  : fct_subscription_events
-- Output  : 05_mart__arr.csv
-- Grain   : year_key × plan_id × country_code
-- AC-003  : annual サブスクの年次 ARR スナップショット

CREATE TABLE IF NOT EXISTS mart_arr AS
SELECT
    STRFTIME('%Y', event_date)               AS year_key,
    plan_id,
    country_code,
    COUNT(DISTINCT subscription_id)          AS active_subscription_count,
    ROUND(SUM(arr_amount), 2)                AS total_arr_usd,
    ROUND(
        SUM(arr_amount) / COUNT(DISTINCT subscription_id),
    2)                                       AS avg_arr_per_subscription_usd,
    DATE(STRFTIME('%Y', event_date) || '-12-31') AS snapshot_date
FROM fct_subscription_events
WHERE billing_cycle = 'annual'
  AND event_type IN ('new_subscription', 'trial_conversion')
  AND arr_amount IS NOT NULL
GROUP BY
    STRFTIME('%Y', event_date),
    plan_id,
    country_code;
