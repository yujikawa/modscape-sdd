CREATE TABLE IF NOT EXISTS local.vault.hub_subscription (
    subscription_hk STRING,
    subscription_bk STRING,
    load_dts        TIMESTAMP,
    record_source   STRING
)
USING iceberg
TBLPROPERTIES ('format-version'='2', 'write.upsert.enabled'='true');

MERGE INTO local.vault.hub_subscription AS t
USING (
    SELECT
        sha2(subscription_id, 256) AS subscription_hk,
        subscription_id            AS subscription_bk,
        MIN(load_dts)              AS load_dts,
        first(record_source)       AS record_source
    FROM local.vault.stg_billing__subscriptions
    GROUP BY subscription_id
) AS s
ON t.subscription_hk = s.subscription_hk
WHEN NOT MATCHED THEN INSERT *;
