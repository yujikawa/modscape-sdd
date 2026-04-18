-- tests.sql — Phase 4 テスト
-- 各クエリが 0 行を返せば PASS。1 行以上返れば FAIL。

-- [AC-001, AC-005] stg_billing_subscriptions.subscription_id: unique
SELECT 'FAIL: stg.subscription_id not unique' AS test, subscription_id, COUNT(*) AS cnt
FROM stg_billing_subscriptions
GROUP BY subscription_id HAVING COUNT(*) > 1;

-- [AC-001, AC-005] stg_billing_subscriptions.subscription_id: not_null
SELECT 'FAIL: stg.subscription_id is NULL' AS test, *
FROM stg_billing_subscriptions
WHERE subscription_id IS NULL;

-- [AC-001, AC-005] stg_billing_subscriptions.billing_cycle: monthly or annual only
SELECT 'FAIL: stg.billing_cycle invalid value' AS test, subscription_id, billing_cycle
FROM stg_billing_subscriptions
WHERE billing_cycle NOT IN ('monthly', 'annual');

-- [AC-005] stg_billing_subscriptions.annual_price_usd: annual rows must not be NULL
SELECT 'FAIL: stg.annual_price_usd is NULL for annual subscription' AS test, subscription_id
FROM stg_billing_subscriptions
WHERE billing_cycle = 'annual' AND annual_price_usd IS NULL;

-- [AC-001] dim_subscriptions.subscription_id: unique
SELECT 'FAIL: dim.subscription_id not unique' AS test, subscription_id, COUNT(*) AS cnt
FROM dim_subscriptions
GROUP BY subscription_id HAVING COUNT(*) > 1;

-- [AC-001] dim_subscriptions.subscription_id: not_null
SELECT 'FAIL: dim.subscription_id is NULL' AS test, *
FROM dim_subscriptions
WHERE subscription_id IS NULL;

-- [AC-002] fct_subscription_events.arr_amount: monthly rows must be NULL
SELECT 'FAIL: fct.arr_amount is not NULL for monthly subscription' AS test, event_id, billing_cycle, arr_amount
FROM fct_subscription_events
WHERE billing_cycle = 'monthly' AND arr_amount IS NOT NULL;

-- [AC-001] dim_customers.customer_id: unique
SELECT 'FAIL: dim_customers.customer_id not unique' AS test, customer_id, COUNT(*) AS cnt
FROM dim_customers
GROUP BY customer_id HAVING COUNT(*) > 1;

-- [AC-001] dim_customers.customer_id: not_null
SELECT 'FAIL: dim_customers.customer_id is NULL' AS test, *
FROM dim_customers
WHERE customer_id IS NULL;

-- [AC-001] dim_customers.country_code: not_null
SELECT 'FAIL: dim_customers.country_code is NULL' AS test, customer_id
FROM dim_customers
WHERE country_code IS NULL;

-- [AC-002] dim_plans.plan_id: unique
SELECT 'FAIL: dim_plans.plan_id not unique' AS test, plan_id, COUNT(*) AS cnt
FROM dim_plans
GROUP BY plan_id HAVING COUNT(*) > 1;

-- [AC-002] dim_plans.plan_tier: not_null
SELECT 'FAIL: dim_plans.plan_tier is NULL' AS test, plan_id
FROM dim_plans
WHERE plan_tier IS NULL;

-- [AC-003] fct → dim_customers FK: all customer_id must exist in dim_customers
SELECT 'FAIL: fct.customer_id not in dim_customers' AS test, f.event_id, f.customer_id
FROM fct_subscription_events f
LEFT JOIN dim_customers dc ON f.customer_id = dc.customer_id
WHERE dc.customer_id IS NULL;

-- [AC-003] fct → dim_plans FK: all plan_id must exist in dim_plans
SELECT 'FAIL: fct.plan_id not in dim_plans' AS test, f.event_id, f.plan_id
FROM fct_subscription_events f
LEFT JOIN dim_plans dp ON f.plan_id = dp.plan_id
WHERE dp.plan_id IS NULL;

-- [AC-005] fct_subscription_events.country_code: not_null (dim_customers から補完済み)
SELECT 'FAIL: fct.country_code is NULL after dim_customers join' AS test, event_id, customer_id
FROM fct_subscription_events
WHERE country_code IS NULL;

-- [AC-004] mart_revenue_summary grain: unique per year × month × plan_tier × country × segment
SELECT 'FAIL: mart_revenue_summary grain not unique' AS test,
       year_key, month_key, plan_tier, country_code, customer_segment, COUNT(*) AS cnt
FROM mart_revenue_summary
GROUP BY year_key, month_key, plan_tier, country_code, customer_segment
HAVING COUNT(*) > 1;
