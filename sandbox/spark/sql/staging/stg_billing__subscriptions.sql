CREATE OR REPLACE TABLE local.vault.stg_billing__subscriptions
USING iceberg
TBLPROPERTIES ('format-version'='2')
AS
SELECT
    subscription_id,
    user_id,
    plan_code,
    status,
    billing_cycle,
    annual_price_usd,
    mrr_amount,
    start_date,
    cancelled_date,
    country_code,
    record_source,
    load_dts
FROM local.raw.billing_subscriptions
WHERE subscription_id IS NOT NULL;
