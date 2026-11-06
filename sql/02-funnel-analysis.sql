USE product_analytics;

-- =========================================================
-- 02. FUNNEL ANALYSIS
-- Signup -> Activation -> Trial -> Paid
-- Activation definition: project_created
-- =========================================================

WITH funnel AS (
    SELECT
        (SELECT COUNT(DISTINCT user_id) FROM users) AS total_signups,
        (SELECT COUNT(DISTINCT user_id) FROM events WHERE event_name = 'project_created') AS activated_users,
        (SELECT COUNT(DISTINCT user_id) FROM subscriptions WHERE trial_start_date IS NOT NULL) AS trial_users,
        (SELECT COUNT(DISTINCT user_id) FROM subscriptions WHERE subscription_date IS NOT NULL) AS paid_users
)
SELECT
    total_signups,
    activated_users,
    trial_users,
    paid_users,
    ROUND(activated_users * 100.0 / total_signups, 2) AS activation_rate,
    ROUND(trial_users * 100.0 / activated_users, 2) AS trial_conversion_rate,
    ROUND(paid_users * 100.0 / trial_users, 2) AS paid_conversion_rate,
    ROUND(paid_users * 100.0 / total_signups, 2) AS overall_conversion_rate
FROM funnel;

-- Funnel drop-offs
WITH funnel AS (
    SELECT
        (SELECT COUNT(DISTINCT user_id) FROM users) AS signups,
        (SELECT COUNT(DISTINCT user_id) FROM events WHERE event_name = 'project_created') AS activated,
        (SELECT COUNT(DISTINCT user_id) FROM subscriptions WHERE trial_start_date IS NOT NULL) AS trials,
        (SELECT COUNT(DISTINCT user_id) FROM subscriptions WHERE subscription_date IS NOT NULL) AS paid
)
SELECT
    signups,
    activated,
    trials,
    paid,
    signups - activated AS signup_to_activation_drop,
    activated - trials AS activation_to_trial_drop,
    trials - paid AS trial_to_paid_drop,
    ROUND((signups - activated) * 100.0 / signups, 2) AS signup_to_activation_drop_pct,
    ROUND((activated - trials) * 100.0 / activated, 2) AS activation_to_trial_drop_pct,
    ROUND((trials - paid) * 100.0 / trials, 2) AS trial_to_paid_drop_pct
FROM funnel;

/*
KNOWN FINDING:
Signup -> Activation: 63.14%
Activation -> Trial: 49.05%
Trial -> Paid: 63.67%
Overall Signup -> Paid: 19.72%
Largest relative leakage: Activation -> Trial.
*/
