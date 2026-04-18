-- stg_billing_subscriptions
-- Source : raw_billing_subscriptions (loaded from 01_raw__billing_subscriptions.csv)
-- Output : 02_stg__billing_subscriptions.csv
-- AC-005 : annual_price_usd NULL → COALESCE(annual_price_usd, monthly_price_usd * 12)

CREATE TABLE IF NOT EXISTS stg_billing_subscriptions AS
SELECT
    id                                                        AS subscription_id,
    customer_id,
    plan_id,
    status,
    billing_cycle,
    CAST(monthly_price_usd AS REAL)                          AS monthly_price_usd,
    -- CSV ロード時は空文字列も NULL 扱いにしてフォールバックを有効化 (AC-005)
    CASE WHEN annual_price_usd IS NULL OR TRIM(annual_price_usd) = ''
         THEN CAST(monthly_price_usd AS REAL) * 12
         ELSE CAST(annual_price_usd AS REAL)
    END                                                       AS annual_price_usd,
    start_date,
    cancelled_date,
    trial_start_date,
    trial_end_date,
    CURRENT_TIMESTAMP                                         AS loaded_at
FROM raw_billing_subscriptions;
