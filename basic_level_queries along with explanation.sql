-- =====================================================
-- CUSTOMER CHURN ANALYSIS - BASIC LEVEL QUERIES (1-20)
-- Run each query separately: select it, then press Ctrl+Enter
-- =====================================================

USE customer_churn_analysis;

-- 1. Find all customers who signed up in the last 6 months.
SELECT customer_id, first_name, last_name, signup_date
FROM customers
WHERE signup_date >= CURDATE() - INTERVAL 6 MONTH;

-- 2. Retrieve all customers whose status = 'Churned'.
SELECT customer_id, first_name, last_name, status
FROM customers
WHERE status = 'Churned';

-- 3. Find the total number of customers in each region.
SELECT r.region_name, COUNT(c.customer_id) AS total_customers
FROM regions r
LEFT JOIN customers c ON r.region_id = c.region_id
GROUP BY r.region_name;

-- 4. Display all customers on the 'Premium' plan.
SELECT DISTINCT c.customer_id, c.first_name, c.last_name, p.plan_name
FROM customers c
JOIN subscriptions s ON c.customer_id = s.customer_id
JOIN subscription_plans p ON s.plan_id = p.plan_id
WHERE p.plan_name LIKE 'Premium%';

-- 5. Find the total number of subscriptions per plan.
SELECT p.plan_name, COUNT(s.subscription_id) AS total_subscriptions
FROM subscription_plans p
LEFT JOIN subscriptions s ON p.plan_id = s.plan_id
GROUP BY p.plan_name;

-- 6. Retrieve customers who have no payment method on file.
-- (Returns 0 rows with the sample data: every customer has a payment method)
SELECT c.customer_id, c.first_name, c.last_name
FROM customers c
LEFT JOIN payment_methods pm ON c.customer_id = pm.customer_id
WHERE pm.payment_method_id IS NULL;

-- 7. Find all transactions where the amount exceeds 10,000.
SELECT transaction_id, customer_id, amount, transaction_date
FROM transactions
WHERE amount > 10000;

-- 8. Display the top 10 highest transaction amounts.
SELECT transaction_id, customer_id, amount
FROM transactions
ORDER BY amount DESC
LIMIT 10;

-- 9. Find the total number of active subscriptions per region.
SELECT r.region_name, COUNT(s.subscription_id) AS active_subscriptions
FROM subscriptions s
JOIN customers c ON s.customer_id = c.customer_id
JOIN regions r ON c.region_id = r.region_id
WHERE s.renewal_status = 'Active'
GROUP BY r.region_name;

-- 10. Retrieve all subscriptions with renewal_status = 'Cancelled'.
SELECT subscription_id, customer_id, plan_id, start_date, end_date
FROM subscriptions
WHERE renewal_status = 'Cancelled';

-- 11. Find the average transaction amount grouped by plan.
SELECT p.plan_name, ROUND(AVG(t.amount), 2) AS avg_amount
FROM transactions t
JOIN subscriptions s ON t.subscription_id = s.subscription_id
JOIN subscription_plans p ON s.plan_id = p.plan_id
GROUP BY p.plan_name;

-- 12. Retrieve customers having more than 5 support tickets.
-- (Returns 0 rows with the sample data: max is 4 per customer. Try > 2 to see results)
SELECT customer_id, COUNT(ticket_id) AS ticket_count
FROM support_tickets
GROUP BY customer_id
HAVING COUNT(ticket_id) > 5;

-- 13. Find the total number of activity logs for each customer.
SELECT customer_id, COUNT(activity_id) AS total_logs
FROM customer_activity_logs
GROUP BY customer_id
ORDER BY total_logs DESC;

-- 14. Display all support tickets that are still 'Open'.
SELECT ticket_id, customer_id, issue_type, created_date
FROM support_tickets
WHERE status = 'Open';

-- 15. Find all customers who churned and later reactivated.
SELECT c.customer_id, c.first_name, c.last_name, h.churn_date
FROM churn_history h
JOIN customers c ON h.customer_id = c.customer_id
WHERE h.reactivated = 1;

-- 16. Retrieve regions having more than 50 churned customers.
-- (Likely 0 rows with the sample data: roughly 18 churned per region. Try > 15 to see results)
SELECT r.region_name, COUNT(c.customer_id) AS churned_customers
FROM customers c
JOIN regions r ON c.region_id = r.region_id
WHERE c.status = 'Churned'
GROUP BY r.region_name
HAVING COUNT(c.customer_id) > 50;

-- 17. Find all feedback surveys with score below 5.
SELECT survey_id, customer_id, score, comments
FROM feedback_surveys
WHERE score < 5;

-- 18. Display the latest 20 churn records.
SELECT churn_id, customer_id, churn_date, churn_reason
FROM churn_history
ORDER BY churn_date DESC
LIMIT 20;

-- 19. Find the total revenue generated through transactions.
SELECT SUM(amount) AS total_revenue
FROM transactions
WHERE payment_status = 'Success';

-- 20. Retrieve the count of new signups month-wise.
SELECT DATE_FORMAT(signup_date, '%Y-%m') AS signup_month,
       COUNT(customer_id) AS new_signups
FROM customers
GROUP BY DATE_FORMAT(signup_date, '%Y-%m')
ORDER BY signup_month;
