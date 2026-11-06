USE product_analytics;

-- =========================================================
-- 04. FEATURE ADOPTION
-- =========================================================

-- A. Feature adoption among activated users
WITH activated_users AS (
    SELECT DISTINCT user_id
    FROM events
    WHERE event_name = 'project_created'
)
SELECT
    e.feature_name,
    COUNT(DISTINCT e.user_id) AS adopters,
    ROUND(
        COUNT(DISTINCT e.user_id) * 100.0 /
        (SELECT COUNT(*) FROM activated_users),
        2
    ) AS adoption_rate
FROM events e
JOIN activated_users a ON e.user_id = a.user_id
WHERE e.feature_name IS NOT NULL
GROUP BY e.feature_name
ORDER BY adoption_rate DESC;

-- B. Feature adoption vs trial conversion
WITH activated_users AS (
    SELECT DISTINCT user_id
    FROM events
    WHERE event_name = 'project_created'
),
feature_users AS (
    SELECT DISTINCT user_id, feature_name
    FROM events
    WHERE feature_name IS NOT NULL
),
trial_users AS (
    SELECT DISTINCT user_id
    FROM subscriptions
    WHERE trial_start_date IS NOT NULL
)
SELECT
    f.feature_name,
    COUNT(DISTINCT f.user_id) AS feature_adopters,
    COUNT(DISTINCT CASE WHEN t.user_id IS NOT NULL THEN f.user_id END) AS adopters_who_started_trial,
    ROUND(
        COUNT(DISTINCT CASE WHEN t.user_id IS NOT NULL THEN f.user_id END) * 100.0 /
        COUNT(DISTINCT f.user_id),
        2
    ) AS trial_conversion_rate
FROM feature_users f
JOIN activated_users a ON f.user_id = a.user_id
LEFT JOIN trial_users t ON f.user_id = t.user_id
GROUP BY f.feature_name
ORDER BY trial_conversion_rate DESC;

-- C. Feature adoption vs paid conversion
WITH feature_users AS (
    SELECT DISTINCT user_id, feature_name
    FROM events
    WHERE feature_name IS NOT NULL
),
paid_users AS (
    SELECT DISTINCT user_id
    FROM subscriptions
    WHERE subscription_date IS NOT NULL
)
SELECT
    f.feature_name,
    COUNT(DISTINCT f.user_id) AS feature_adopters,
    COUNT(DISTINCT CASE WHEN p.user_id IS NOT NULL THEN f.user_id END) AS paid_adopters,
    ROUND(
        COUNT(DISTINCT CASE WHEN p.user_id IS NOT NULL THEN f.user_id END) * 100.0 /
        COUNT(DISTINCT f.user_id),
        2
    ) AS paid_conversion_rate
FROM feature_users f
LEFT JOIN paid_users p ON f.user_id = p.user_id
GROUP BY f.feature_name
ORDER BY paid_conversion_rate DESC;

-- D. Average time to activation
WITH first_activation AS (
    SELECT user_id, MIN(event_timestamp) AS activation_time
    FROM events
    WHERE event_name = 'project_created'
    GROUP BY user_id
)
SELECT
    ROUND(AVG(TIMESTAMPDIFF(HOUR, u.signup_date, a.activation_time)), 2) AS avg_hours_to_activation
FROM users u
JOIN first_activation a ON u.user_id = a.user_id;

-- E. Time to activation by acquisition channel
WITH first_activation AS (
    SELECT user_id, MIN(event_timestamp) AS activation_time
    FROM events
    WHERE event_name = 'project_created'
    GROUP BY user_id
)
SELECT
    u.acquisition_channel,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, u.signup_date, a.activation_time)), 2) AS avg_hours_to_activation
FROM users u
JOIN first_activation a ON u.user_id = a.user_id
GROUP BY u.acquisition_channel
ORDER BY avg_hours_to_activation ASC;

/*
INTERPRETATION RULE:
Feature adoption can be described as associated with conversion,
but these queries alone do not prove causation.
*/
