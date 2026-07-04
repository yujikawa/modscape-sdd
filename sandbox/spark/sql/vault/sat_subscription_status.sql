CREATE TABLE IF NOT EXISTS local.vault.sat_subscription_status (
    subscription_hk  STRING,
    load_dts         TIMESTAMP,
    hash_diff        STRING,
    status           STRING,
    start_date       DATE,
    cancelled_date   DATE,
    mrr_amount       DOUBLE,
    billing_cycle    STRING,
    annual_price_usd DOUBLE
)
USING iceberg
PARTITIONED BY (months(load_dts))
TBLPROPERTIES ('format-version'='2', 'write.upsert.enabled'='true');

MERGE INTO local.vault.sat_subscription_status AS t
USING (
    SELECT
        sha2(subscription_id, 256)                             AS subscription_hk,
        load_dts,
        sha2(concat_ws('|', status, mrr_amount,
                       billing_cycle, annual_price_usd), 256) AS hash_diff,
        status,
        start_date,
        cancelled_date,
        mrr_amount,
        billing_cycle,
        annual_price_usd
    FROM local.vault.stg_billing__subscriptions
) AS s
ON t.subscription_hk = s.subscription_hk
   AND t.load_dts = s.load_dts
WHEN NOT MATCHED THEN INSERT *;
