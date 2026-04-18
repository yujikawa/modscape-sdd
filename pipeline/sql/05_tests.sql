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
