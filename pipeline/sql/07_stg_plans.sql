-- stg_plans
-- Source : raw_plans (loaded from 03_raw__plans.csv)
-- Output : 07_stg__plans.csv

CREATE TABLE IF NOT EXISTS stg_plans AS
SELECT
    plan_id,
    plan_name,
    plan_tier,
    plan_category,
    CAST(base_monthly_price_usd AS REAL) AS base_monthly_price_usd,
    CAST(base_annual_price_usd  AS REAL) AS base_annual_price_usd,
    CAST(max_seats AS INTEGER)           AS max_seats,
    created_at,
    CURRENT_TIMESTAMP AS loaded_at
FROM raw_plans;
