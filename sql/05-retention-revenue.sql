USE product_analytics;

-- =========================================================
-- 05. RETENTION, CHURN & REVENUE
-- =========================================================

-- A. Paid, cancelled and currently active subscribers
SELECT
    COUNT(DISTINCT CASE WHEN subscription_date IS NOT NULL THEN user_id END) AS paid_users,
    COUNT(DISTINCT CASE WHEN cancel_date IS NOT NULL THEN user_id END) AS cancelled_users,
    COUNT(DISTINCT CASE WHEN subscription_date IS NOT NULL AND cancel_date IS NULL THEN user_id END) AS active_paid_users
FROM subscriptions;

-- B. Overall churn rate
SELECT
    COUNT(DISTINCT user_id) AS paid_users,
    COUNT(DISTINCT CASE WHEN cancel_date IS NOT NULL THEN user_id END) AS cancelled_users,
    ROUND(
        COUNT(DISTINCT CASE WHEN cancel_date IS NOT NULL THEN user_id END) * 100.0 /
        COUNT(DISTINCT user_id),
        2
    ) AS churn_rate
FROM subscriptions
WHERE subscription_date IS NOT NULL;

-- C. Churn by plan
SELECT
    plan,
    COUNT(DISTINCT user_id) AS paid_users,
    COUNT(DISTINCT CASE WHEN cancel_date IS NOT NULL THEN user_id END) AS cancelled_users,
    ROUND(
        COUNT(DISTINCT CASE WHEN cancel_date IS NOT NULL THEN user_id END) * 100.0 /
        COUNT(DISTINCT user_id),
        2
    ) AS churn_rate
FROM subscriptions
WHERE subscription_date IS NOT NULL
GROUP BY plan
ORDER BY churn_rate DESC;

-- D. Feature adoption vs churn
WITH feature_users AS (
    SELECT DISTINCT user_id, feature_name
    FROM events
    WHERE feature_name IS NOT NULL
),
paid_users AS (
    SELECT user_id, cancel_date
    FROM subscriptions
    WHERE subscription_date IS NOT NULL
)
SELECT
    f.feature_name,
    COUNT(DISTINCT f.user_id) AS paid_feature_users,
    COUNT(DISTINCT CASE WHEN p.cancel_date IS NOT NULL THEN f.user_id END) AS churned_users,
    ROUND(
        COUNT(DISTINCT CASE WHEN p.cancel_date IS NOT NULL THEN f.user_id END) * 100.0 /
        COUNT(DISTINCT f.user_id),
        2
    ) AS churn_rate
FROM feature_users f
JOIN paid_users p ON f.user_id = p.user_id
GROUP BY f.feature_name
ORDER BY churn_rate ASC;

-- E. Current MRR
SELECT ROUND(SUM(monthly_price), 2) AS current_mrr
FROM subscriptions
WHERE subscription_date IS NOT NULL
AND cancel_date IS NULL;

-- F. MRR by plan
SELECT
    plan,
    COUNT(DISTINCT user_id) AS active_customers,
    ROUND(SUM(monthly_price), 2) AS mrr
FROM subscriptions
WHERE subscription_date IS NOT NULL
AND cancel_date IS NULL
GROUP BY plan
ORDER BY mrr DESC;

-- G. Active monthly revenue by acquisition channel
SELECT
    u.acquisition_channel,
    COUNT(DISTINCT s.user_id) AS active_paid_users,
    ROUND(SUM(s.monthly_price), 2) AS monthly_revenue
FROM users u
JOIN subscriptions s ON u.user_id = s.user_id
WHERE s.subscription_date IS NOT NULL
AND s.cancel_date IS NULL
GROUP BY u.acquisition_channel
ORDER BY monthly_revenue DESC;

/*
FINAL STORY SHOULD CONNECT:
1. Funnel leakage
2. Acquisition quality
3. Device experience
4. Feature adoption
5. Retention/churn
6. Revenue impact
*/
