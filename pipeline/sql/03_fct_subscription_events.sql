-- fct_subscription_events
-- Sources : stg_billing_subscriptions, dim_subscriptions (LEFT JOIN),
--           dim_customers (LEFT JOIN), dim_plans (LEFT JOIN)
-- Output  : 04_fct__subscription_events.csv
-- AC-002  : arr_amount は annual のみ。monthly は NULL
-- AC-003  : dim_customers・dim_plans を JOIN して属性を補完
-- AC-005  : country_code を dim_customers から補完（D-003 解決）

CREATE TABLE IF NOT EXISTS fct_subscription_events AS
WITH stg AS (
    SELECT * FROM stg_billing_subscriptions
),
dim_sub AS (
    SELECT subscription_id, country_code FROM dim_subscriptions
),

-- 開始イベント（トライアル経由はtrial_conversion、直接契約はnew_subscription）
new_events AS (
    SELECT
        stg.subscription_id || '_new'                        AS event_id,
        stg.subscription_id,
        stg.customer_id,
        stg.plan_id,
        stg.start_date                                       AS event_date,
        CASE WHEN stg.trial_end_date IS NOT NULL
             THEN 'trial_conversion'
             ELSE 'new_subscription'
        END                                                  AS event_type,
        stg.billing_cycle,
        ROUND(
            CASE WHEN stg.billing_cycle = 'annual'
                 THEN stg.annual_price_usd / 12.0
                 ELSE stg.monthly_price_usd
            END,
        2)                                                   AS mrr_amount,
        CASE WHEN stg.billing_cycle = 'annual'
             THEN stg.annual_price_usd
             ELSE NULL
        END                                                  AS arr_amount,  -- AC-002
        ROUND(
            CASE WHEN stg.billing_cycle = 'annual'
                 THEN stg.annual_price_usd / 12.0
                 ELSE stg.monthly_price_usd
            END,
        2)                                                   AS mrr_delta,
        COALESCE(dc.country_code, dim_sub.country_code)      AS country_code,  -- AC-005
        dc.customer_segment,                                 -- AC-003
        dp.plan_tier,                                        -- AC-003
        dp.plan_category                                     -- AC-003
    FROM stg
    LEFT JOIN dim_sub      ON stg.subscription_id = dim_sub.subscription_id
    LEFT JOIN dim_customers dc ON stg.customer_id  = dc.customer_id
    LEFT JOIN dim_plans     dp ON stg.plan_id       = dp.plan_id
),

-- 解約イベント
cancel_events AS (
    SELECT
        stg.subscription_id || '_cancel'                     AS event_id,
        stg.subscription_id,
        stg.customer_id,
        stg.plan_id,
        stg.cancelled_date                                   AS event_date,
        'cancellation'                                       AS event_type,
        stg.billing_cycle,
        ROUND(
            CASE WHEN stg.billing_cycle = 'annual'
                 THEN stg.annual_price_usd / 12.0
                 ELSE stg.monthly_price_usd
            END,
        2)                                                   AS mrr_amount,
        CASE WHEN stg.billing_cycle = 'annual'
             THEN stg.annual_price_usd
             ELSE NULL
        END                                                  AS arr_amount,
        -ROUND(
            CASE WHEN stg.billing_cycle = 'annual'
                 THEN stg.annual_price_usd / 12.0
                 ELSE stg.monthly_price_usd
            END,
        2)                                                   AS mrr_delta,
        COALESCE(dc.country_code, dim_sub.country_code)      AS country_code,
        dc.customer_segment,
        dp.plan_tier,
        dp.plan_category
    FROM stg
    LEFT JOIN dim_sub      ON stg.subscription_id = dim_sub.subscription_id
    LEFT JOIN dim_customers dc ON stg.customer_id  = dc.customer_id
    LEFT JOIN dim_plans     dp ON stg.plan_id       = dp.plan_id
    WHERE stg.cancelled_date IS NOT NULL
)

SELECT * FROM new_events
UNION ALL
SELECT * FROM cancel_events;
