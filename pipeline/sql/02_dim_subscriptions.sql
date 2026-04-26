-- dim_subscriptions (SCD Type 1)
-- Source : stg_billing_subscriptions
-- Output : 03_dim__subscriptions.csv
-- AC-001 : billing_cycle / annual_price_usd を保持

CREATE TABLE IF NOT EXISTS dim_subscriptions AS
SELECT
    subscription_id,
    customer_id,
    plan_id,
    status,
    billing_cycle,
    CASE WHEN billing_cycle = 'annual' THEN annual_price_usd
         ELSE NULL
    END                                                      AS annual_price_usd,
    ROUND(
        CASE WHEN billing_cycle = 'annual'
             THEN annual_price_usd / 12.0
             ELSE monthly_price_usd
        END,
    2)                                                       AS mrr_amount,
    start_date,
    cancelled_date,
    -- TODO: country_code not available in source data (see Q-003)
    NULL                                                     AS country_code
FROM stg_billing_subscriptions;
