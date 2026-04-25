CREATE TABLE IF NOT EXISTS local.vault.fct_subscription_events (
    subscription_id STRING,
    plan_code       STRING,
    country_code    STRING,
    event_date      DATE,
    event_type      STRING,
    mrr_amount      DOUBLE,
    mrr_delta       DOUBLE,
    arr_amount      DOUBLE,
    is_churn        BOOLEAN,
    is_new_business BOOLEAN
)
USING iceberg
PARTITIONED BY (months(event_date))
TBLPROPERTIES ('format-version'='2', 'write.upsert.enabled'='true');

MERGE INTO local.vault.fct_subscription_events AS t
USING (
    SELECT
        subscription_id,
        plan_code,
        country_code,
        CAST(start_date AS DATE)             AS event_date,
        CASE
            WHEN status = 'active'    THEN 'activated'
            WHEN status = 'trialing'  THEN 'trial_start'
            WHEN status = 'cancelled' THEN 'cancelled'
            ELSE status
        END                                  AS event_type,
        mrr_amount,
        mrr_amount                           AS mrr_delta,
        CASE WHEN billing_cycle = 'annual'
             THEN annual_price_usd ELSE NULL
        END                                  AS arr_amount,
        status = 'cancelled'                 AS is_churn,
        status = 'active'                    AS is_new_business
    FROM local.vault.stg_billing__subscriptions
    WHERE start_date IS NOT NULL
) AS s
ON t.subscription_id = s.subscription_id
   AND t.event_date  = s.event_date
   AND t.event_type  = s.event_type
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;
