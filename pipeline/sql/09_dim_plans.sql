-- dim_plans
-- Source : stg_plans
-- Output : 09_dim__plans.csv
-- AC-002 : plan_tier と plan_category を保存

CREATE TABLE IF NOT EXISTS dim_plans AS
SELECT
    plan_id,
    plan_name,
    plan_tier,
    plan_category,
    base_monthly_price_usd,
    base_annual_price_usd
FROM stg_plans;
