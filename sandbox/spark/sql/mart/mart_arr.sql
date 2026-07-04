CREATE OR REPLACE TABLE local.mart.mart_arr
USING iceberg
TBLPROPERTIES ('format-version'='2')
AS
SELECT
    YEAR(event_date)                AS year_key,
    plan_code                       AS plan_key,
    country_code,
    SUM(arr_amount)                 AS arr,
    COUNT(DISTINCT subscription_id) AS active_annual_subscriptions
FROM local.vault.fct_subscription_events
WHERE arr_amount IS NOT NULL
  AND NOT is_churn
GROUP BY YEAR(event_date), plan_code, country_code
ORDER BY year_key, plan_key, country_code;
