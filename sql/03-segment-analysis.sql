USE product_analytics;

-- =========================================================
-- 03. SEGMENT ANALYSIS
-- =========================================================

-- A. Acquisition channel funnel
WITH signups AS (
    SELECT acquisition_channel, COUNT(DISTINCT user_id) AS signup_users
    FROM users
    GROUP BY acquisition_channel
),
activations AS (
    SELECT u.acquisition_channel, COUNT(DISTINCT e.user_id) AS activated_users
    FROM users u
    JOIN events e ON u.user_id = e.user_id
    WHERE e.event_name = 'project_created'
    GROUP BY u.acquisition_channel
),
trials AS (
    SELECT u.acquisition_channel, COUNT(DISTINCT s.user_id) AS trial_users
    FROM users u
    JOIN subscriptions s ON u.user_id = s.user_id
    WHERE s.trial_start_date IS NOT NULL
    GROUP BY u.acquisition_channel
),
paid AS (
    SELECT u.acquisition_channel, COUNT(DISTINCT s.user_id) AS paid_users
    FROM users u
    JOIN subscriptions s ON u.user_id = s.user_id
    WHERE s.subscription_date IS NOT NULL
    GROUP BY u.acquisition_channel
)
SELECT
    s.acquisition_channel,
    s.signup_users,
    COALESCE(a.activated_users, 0) AS activated_users,
    COALESCE(t.trial_users, 0) AS trial_users,
    COALESCE(p.paid_users, 0) AS paid_users,
    ROUND(COALESCE(a.activated_users, 0) * 100.0 / s.signup_users, 2) AS activation_rate,
    ROUND(COALESCE(t.trial_users, 0) * 100.0 / NULLIF(a.activated_users, 0), 2) AS trial_conversion_rate,
    ROUND(COALESCE(p.paid_users, 0) * 100.0 / NULLIF(t.trial_users, 0), 2) AS paid_conversion_rate
FROM signups s
LEFT JOIN activations a ON s.acquisition_channel = a.acquisition_channel
LEFT JOIN trials t ON s.acquisition_channel = t.acquisition_channel
LEFT JOIN paid p ON s.acquisition_channel = p.acquisition_channel
ORDER BY activation_rate ASC;

-- B. Activation by device
WITH signups AS (
    SELECT device, COUNT(DISTINCT user_id) AS signup_users
    FROM users
    GROUP BY device
),
activations AS (
    SELECT u.device, COUNT(DISTINCT e.user_id) AS activated_users
    FROM users u
    JOIN events e ON u.user_id = e.user_id
    WHERE e.event_name = 'project_created'
    GROUP BY u.device
)
SELECT
    s.device,
    s.signup_users,
    COALESCE(a.activated_users, 0) AS activated_users,
    ROUND(COALESCE(a.activated_users, 0) * 100.0 / s.signup_users, 2) AS activation_rate
FROM signups s
LEFT JOIN activations a ON s.device = a.device
ORDER BY activation_rate ASC;

-- C. Acquisition channel x device
WITH signups AS (
    SELECT acquisition_channel, device, COUNT(DISTINCT user_id) AS signup_users
    FROM users
    GROUP BY acquisition_channel, device
),
activations AS (
    SELECT u.acquisition_channel, u.device, COUNT(DISTINCT e.user_id) AS activated_users
    FROM users u
    JOIN events e ON u.user_id = e.user_id
    WHERE e.event_name = 'project_created'
    GROUP BY u.acquisition_channel, u.device
)
SELECT
    s.acquisition_channel,
    s.device,
    s.signup_users,
    COALESCE(a.activated_users, 0) AS activated_users,
    ROUND(COALESCE(a.activated_users, 0) * 100.0 / s.signup_users, 2) AS activation_rate
FROM signups s
LEFT JOIN activations a
    ON s.acquisition_channel = a.acquisition_channel
    AND s.device = a.device
ORDER BY activation_rate ASC;

-- D. Activation by company size
WITH signups AS (
    SELECT company_size, COUNT(DISTINCT user_id) AS signup_users
    FROM users
    GROUP BY company_size
),
activations AS (
    SELECT u.company_size, COUNT(DISTINCT e.user_id) AS activated_users
    FROM users u
    JOIN events e ON u.user_id = e.user_id
    WHERE e.event_name = 'project_created'
    GROUP BY u.company_size
)
SELECT
    s.company_size,
    s.signup_users,
    COALESCE(a.activated_users, 0) AS activated_users,
    ROUND(COALESCE(a.activated_users, 0) * 100.0 / s.signup_users, 2) AS activation_rate
FROM signups s
LEFT JOIN activations a ON s.company_size = a.company_size
ORDER BY activation_rate ASC;

/*
CURRENT OBSERVATIONS:
- Paid Search has the weakest overall activation rate.
- Mobile activation is weaker than Desktop.
- Paid Search Mobile is a particularly weak segment.
- Company-size differences are relatively small.
*/
