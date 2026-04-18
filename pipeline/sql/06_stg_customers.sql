-- stg_customers
-- Source : raw_customers (loaded from 02_raw__customers.csv)
-- Output : 06_stg__customers.csv

CREATE TABLE IF NOT EXISTS stg_customers AS
SELECT
    customer_id,
    customer_name,
    country_code,
    customer_segment,
    industry,
    created_at,
    CURRENT_TIMESTAMP AS loaded_at
FROM raw_customers;
