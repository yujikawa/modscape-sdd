-- dim_customers
-- Source : stg_customers
-- Output : 08_dim__customers.csv
-- AC-001 : country_code と customer_segment を保存
-- D-003  : country_code NULL 問題の解決

CREATE TABLE IF NOT EXISTS dim_customers AS
SELECT
    customer_id,
    customer_name,
    country_code,
    customer_segment,
    industry,
    created_at
FROM stg_customers;
