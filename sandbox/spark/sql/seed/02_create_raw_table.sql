CREATE TABLE IF NOT EXISTS local.raw.billing_subscriptions (
    subscription_id  STRING,
    user_id          STRING,
    plan_code        STRING,
    status           STRING,
    billing_cycle    STRING,
    annual_price_usd DOUBLE,
    mrr_amount       DOUBLE,
    start_date       DATE,
    cancelled_date   DATE,
    country_code     STRING,
    record_source    STRING,
    load_dts         TIMESTAMP
)
USING iceberg
PARTITIONED BY (months(load_dts))
TBLPROPERTIES ('format-version'='2');
