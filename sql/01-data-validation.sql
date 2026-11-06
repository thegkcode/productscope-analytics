USE product_analytics;

-- =========================================================
-- 1. TABLE COUNTS
-- =========================================================

SELECT COUNT(*) AS total_users
FROM users;

SELECT COUNT(*) AS total_events
FROM events;

SELECT COUNT(*) AS total_sessions
FROM sessions;

SELECT COUNT(*) AS total_subscriptions
FROM subscriptions;


-- =========================================================
-- 2. DUPLICATE PRIMARY KEYS
-- =========================================================

SELECT user_id, COUNT(*) AS cnt
FROM users
GROUP BY user_id
HAVING COUNT(*) > 1;

SELECT event_id, COUNT(*) AS cnt
FROM events
GROUP BY event_id
HAVING COUNT(*) > 1;

SELECT session_id, COUNT(*) AS cnt
FROM sessions
GROUP BY session_id
HAVING COUNT(*) > 1;

SELECT subscription_id, COUNT(*) AS cnt
FROM subscriptions
GROUP BY subscription_id
HAVING COUNT(*) > 1;


-- =========================================================
-- 3. ORPHAN FOREIGN KEYS
-- =========================================================

SELECT COUNT(*) AS orphan_events
FROM events e
LEFT JOIN users u
    ON e.user_id = u.user_id
WHERE u.user_id IS NULL;

SELECT COUNT(*) AS orphan_sessions
FROM sessions s
LEFT JOIN users u
    ON s.user_id = u.user_id
WHERE u.user_id IS NULL;

SELECT COUNT(*) AS orphan_subscriptions
FROM subscriptions s
LEFT JOIN users u
    ON s.user_id = u.user_id
WHERE u.user_id IS NULL;


-- =========================================================
-- 4. DATE VALIDATION
-- =========================================================

SELECT *
FROM sessions
WHERE session_end < session_start;

SELECT *
FROM subscriptions
WHERE subscription_date < trial_start_date;

SELECT *
FROM subscriptions
WHERE cancel_date < subscription_date;


-- Event before signup
SELECT
    e.user_id,
    e.event_timestamp,
    u.signup_date
FROM events e
JOIN users u
    ON e.user_id = u.user_id
WHERE e.event_timestamp < u.signup_date;