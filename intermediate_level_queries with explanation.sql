-- =====================================================
-- CUSTOMER CHURN ANALYSIS - INTERMEDIATE LEVEL QUERIES (1-16)
-- Run each query separately: select it, then press Ctrl+Enter
-- Revenue = transactions with payment_status = 'Success'
-- =====================================================

USE customer_churn_analysis;

-- 1. Find the top 5 customers by total transaction amount.
SELECT c.customer_id, c.first_name, c.last_name, SUM(t.amount) AS total_amount
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
WHERE t.payment_status = 'Success'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_amount DESC
LIMIT 5;

-- 2. Retrieve customers who switched plans more than once.
-- (Returns 0 rows with the sample data: max is 2 subscriptions = 1 switch.
--  Use HAVING COUNT(*) >= 2 to see customers who switched at least once)
SELECT customer_id,
       COUNT(*)     AS total_subscriptions,
       COUNT(*) - 1 AS plan_switches
FROM subscriptions
GROUP BY customer_id
HAVING COUNT(*) - 1 > 1;

-- 3. Find the region generating maximum revenue.
SELECT r.region_name, SUM(t.amount) AS revenue
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
JOIN regions r   ON c.region_id = r.region_id
WHERE t.payment_status = 'Success'
GROUP BY r.region_name
ORDER BY revenue DESC
LIMIT 1;

-- 4. Display customers who raised more than 3 support tickets.
SELECT c.customer_id, c.first_name, c.last_name, COUNT(s.ticket_id) AS ticket_count
FROM customers c
JOIN support_tickets s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(s.ticket_id) > 3;

-- 5. Find the most common churn reason.
SELECT churn_reason, COUNT(*) AS occurrences
FROM churn_history
GROUP BY churn_reason
ORDER BY occurrences DESC
LIMIT 1;

-- 6. Retrieve customers whose average feedback score is above 8.
SELECT c.customer_id, c.first_name, c.last_name, ROUND(AVG(f.score), 2) AS avg_score
FROM customers c
JOIN feedback_surveys f ON c.customer_id = f.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING AVG(f.score) > 8;

-- 7. Retrieve the second highest paying customer.
WITH customer_totals AS (
    SELECT customer_id, SUM(amount) AS total_paid
    FROM transactions
    WHERE payment_status = 'Success'
    GROUP BY customer_id
),
ranked AS (
    SELECT customer_id, total_paid,
           DENSE_RANK() OVER (ORDER BY total_paid DESC) AS rnk
    FROM customer_totals
)
SELECT c.customer_id, c.first_name, c.last_name, r.total_paid
FROM ranked r
JOIN customers c ON r.customer_id = c.customer_id
WHERE r.rnk = 2;

-- 8. Find the plan with the highest cancellation rate.
SELECT p.plan_name,
       COUNT(*) AS total_subscriptions,
       SUM(s.renewal_status = 'Cancelled') AS cancelled,
       ROUND(100 * SUM(s.renewal_status = 'Cancelled') / COUNT(*), 2) AS cancellation_rate_pct
FROM subscriptions s
JOIN subscription_plans p ON s.plan_id = p.plan_id
GROUP BY p.plan_name
ORDER BY cancellation_rate_pct DESC
LIMIT 1;

-- 9. Retrieve average transaction amount by region.
SELECT r.region_name, ROUND(AVG(t.amount), 2) AS avg_amount
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
JOIN regions r   ON c.region_id = r.region_id
WHERE t.payment_status = 'Success'
GROUP BY r.region_name
ORDER BY avg_amount DESC;

-- 10. Find the top 10 regions generating maximum revenue.
SELECT r.region_name, SUM(t.amount) AS revenue
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
JOIN regions r   ON c.region_id = r.region_id
WHERE t.payment_status = 'Success'
GROUP BY r.region_name
ORDER BY revenue DESC
LIMIT 10;

-- 11. Display campaigns responded to by more than 100 customers.
-- (Returns 0 rows with the sample data: best campaign has 75 responders. Try > 50)
SELECT m.campaign_name, COUNT(DISTINCT r.customer_id) AS responders
FROM marketing_campaigns m
JOIN campaign_responses r ON m.campaign_id = r.campaign_id
WHERE r.responded = 1
GROUP BY m.campaign_id, m.campaign_name
HAVING COUNT(DISTINCT r.customer_id) > 100;

-- 12. Find customers who never responded to any marketing campaign.
SELECT c.customer_id, c.first_name, c.last_name
FROM customers c
LEFT JOIN campaign_responses r
       ON c.customer_id = r.customer_id AND r.responded = 1
WHERE r.response_id IS NULL;

-- 13. Retrieve duplicate customer records based on email/phone.
-- (Returns 0 rows with the sample data: no duplicates exist)
SELECT 'email' AS duplicate_field, email AS value, COUNT(*) AS occurrences
FROM customers
GROUP BY email
HAVING COUNT(*) > 1
UNION ALL
SELECT 'phone', phone, COUNT(*)
FROM customers
GROUP BY phone
HAVING COUNT(*) > 1;

-- 14. Find the percentage contribution of each region to total revenue.
SELECT r.region_name,
       SUM(t.amount) AS revenue,
       ROUND(100 * SUM(t.amount) / SUM(SUM(t.amount)) OVER (), 2) AS pct_of_total
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
JOIN regions r   ON c.region_id = r.region_id
WHERE t.payment_status = 'Success'
GROUP BY r.region_name
ORDER BY pct_of_total DESC;

-- 15. Find the percentage contribution of each plan to total revenue.
SELECT p.plan_name,
       SUM(t.amount) AS revenue,
       ROUND(100 * SUM(t.amount) / SUM(SUM(t.amount)) OVER (), 2) AS pct_of_total
FROM transactions t
JOIN subscriptions s ON t.subscription_id = s.subscription_id
JOIN subscription_plans p ON s.plan_id = p.plan_id
WHERE t.payment_status = 'Success'
GROUP BY p.plan_name
ORDER BY pct_of_total DESC;

-- 16. Display customer risk rank using: days since last activity,
--     support ticket count, feedback score.
-- (Active customers only; remove the status filter to include everyone)
WITH last_act AS (
    SELECT customer_id, DATEDIFF(CURDATE(), MAX(activity_date)) AS days_inactive
    FROM customer_activity_logs
    GROUP BY customer_id
),
tickets AS (
    SELECT customer_id, COUNT(*) AS ticket_count
    FROM support_tickets
    GROUP BY customer_id
),
fb AS (
    SELECT customer_id, AVG(score) AS avg_score
    FROM feedback_surveys
    GROUP BY customer_id
),
metrics AS (
    SELECT c.customer_id, c.first_name, c.last_name,
           COALESCE(l.days_inactive, 0) AS days_inactive,
           COALESCE(t.ticket_count, 0)  AS ticket_count,
           COALESCE(f.avg_score, 5)     AS avg_score
    FROM customers c
    LEFT JOIN last_act l ON c.customer_id = l.customer_id
    LEFT JOIN tickets  t ON c.customer_id = t.customer_id
    LEFT JOIN fb       f ON c.customer_id = f.customer_id
    WHERE c.status = 'Active'
),
scored AS (
    SELECT m.*,
           ROUND(  PERCENT_RANK() OVER (ORDER BY days_inactive)
                 + PERCENT_RANK() OVER (ORDER BY ticket_count)
                 + PERCENT_RANK() OVER (ORDER BY avg_score DESC), 3) AS risk_score
    FROM metrics m
)
SELECT customer_id, first_name, last_name,
       days_inactive, ticket_count, ROUND(avg_score, 1) AS avg_score, risk_score,
       RANK() OVER (ORDER BY risk_score DESC) AS risk_rank
FROM scored
ORDER BY risk_rank
LIMIT 20;
