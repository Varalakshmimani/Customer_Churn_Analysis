create database customer_churn_analysis
use customer_churn_analysis
CREATE TABLE regions (region_id INT PRIMARY KEY AUTO_INCREMENT,region_name VARCHAR(50) NOT NULL,country VARCHAR(50));

-- Maintable--  
CREATE TABLE customers (customer_id INT PRIMARY KEY AUTO_INCREMENT,first_name VARCHAR(50) NOT NULL,last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    signup_date DATE NOT NULL,
    region_id INT,
    segment VARCHAR(30),
    status VARCHAR(20) DEFAULT 'Active',FOREIGN KEY (region_id) REFERENCES regions(region_id));
    
    CREATE TABLE subscription_plans (
    plan_id INT PRIMARY KEY AUTO_INCREMENT,
    plan_name VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    billing_cycle_days INT NOT NULL,
    features VARCHAR(255)
);

CREATE TABLE subscriptions (
    subscription_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    plan_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    renewal_status VARCHAR(20) DEFAULT 'Active',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (plan_id) REFERENCES subscription_plans(plan_id)
);

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    subscription_id INT,
    transaction_date DATETIME NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'Success',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id)
);

CREATE TABLE payment_methods (
    payment_method_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    method_type VARCHAR(30),
    is_default BOOLEAN DEFAULT FALSE,
    added_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE customer_activity_logs (
    activity_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    activity_type VARCHAR(50),
    activity_date DATETIME NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE support_tickets (
    ticket_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    issue_type VARCHAR(50),
    created_date DATETIME NOT NULL,
    resolved_date DATETIME,
    status VARCHAR(20) DEFAULT 'Open',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE feedback_surveys (
    survey_id       INT PRIMARY KEY AUTO_INCREMENT,
    customer_id     INT NOT NULL,
    survey_date     DATE NOT NULL,
    score           INT,
    comments        VARCHAR(255),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE marketing_campaigns (
    campaign_id     INT PRIMARY KEY AUTO_INCREMENT,
    campaign_name   VARCHAR(100),
    campaign_type   VARCHAR(50),
    start_date      DATE,
    end_date        DATE
);

CREATE TABLE campaign_responses (
    response_id     INT PRIMARY KEY AUTO_INCREMENT,
    campaign_id     INT NOT NULL,
    customer_id     INT NOT NULL,
    sent_date       DATE,
    responded       BOOLEAN DEFAULT FALSE,
    response_date   DATE,
    FOREIGN KEY (campaign_id) REFERENCES marketing_campaigns(campaign_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE churn_history (
    churn_id                    INT PRIMARY KEY AUTO_INCREMENT,
    customer_id                 INT NOT NULL,
    churn_date                  DATE NOT NULL,
    churn_reason                VARCHAR(100),
    days_inactive_before_churn  INT,
    reactivated                 BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE products (
    product_id      INT PRIMARY KEY AUTO_INCREMENT,
    product_name    VARCHAR(100),
    category        VARCHAR(50),
    price           DECIMAL(10,2)
);

CREATE TABLE product_usage (
    usage_id        INT PRIMARY KEY AUTO_INCREMENT,
    customer_id     INT NOT NULL,
    product_id      INT NOT NULL,
    usage_date      DATE NOT NULL,
    usage_count     INT DEFAULT 1,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE employees (
    employee_id         INT PRIMARY KEY AUTO_INCREMENT,
    employee_name       VARCHAR(100),
    role                VARCHAR(50),
    assigned_region_id  INT,
    FOREIGN KEY (assigned_region_id) REFERENCES regions(region_id)
);

SELECT COUNT(*) FROM transactions;

-- CUSTOMER CHURN ANALYSIS - BASIC LEVEL QUERIES (1-20)

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

#---------- INTERMEDIATE LEVEL QUERIES ----------

-- 1. Top 5 customers by total transaction amount

SELECT c.customer_id, c.first_name, c.last_name, SUM(t.amount) AS total_amount
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
WHERE t.payment_status = 'Success'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_amount DESC
LIMIT 5;

-- 2. Customers who switched plans more than once

SELECT customer_id,
       COUNT(*)     AS total_subscriptions,
       COUNT(*) - 1 AS plan_switches
FROM subscriptions
GROUP BY customer_id
HAVING COUNT(*) - 1 > 1;

-- 3. Region generating the maximum revenue

SELECT r.region_name, SUM(t.amount) AS revenue
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
JOIN regions r   ON c.region_id = r.region_id
WHERE t.payment_status = 'Success'
GROUP BY r.region_name
ORDER BY revenue DESC
LIMIT 1;

-- 4. Customers who raised more than 3 support tickets

SELECT c.customer_id, c.first_name, c.last_name, COUNT(s.ticket_id) AS ticket_count
FROM customers c
JOIN support_tickets s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(s.ticket_id) > 3;

-- 5. Most common churn reason

SELECT churn_reason, COUNT(*) AS occurrences
FROM churn_history
GROUP BY churn_reason
ORDER BY occurrences DESC
LIMIT 1;

-- 6. Customers whose average feedback score is above 8

SELECT c.customer_id, c.first_name, c.last_name, ROUND(AVG(f.score), 2) AS avg_score
FROM customers c
JOIN feedback_surveys f ON c.customer_id = f.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING AVG(f.score) > 8;

-- 7. Second highest paying customer

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

-- 8. Plan with the highest cancellation rate

SELECT p.plan_name,
       COUNT(*) AS total_subscriptions,
       SUM(s.renewal_status = 'Cancelled') AS cancelled,
       ROUND(100 * SUM(s.renewal_status = 'Cancelled') / COUNT(*), 2) AS cancellation_rate_pct
FROM subscriptions s
JOIN subscription_plans p ON s.plan_id = p.plan_id
GROUP BY p.plan_name
ORDER BY cancellation_rate_pct DESC
LIMIT 1;

-- 9. Average transaction amount by region

SELECT r.region_name, ROUND(AVG(t.amount), 2) AS avg_amount
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
JOIN regions r   ON c.region_id = r.region_id
WHERE t.payment_status = 'Success'
GROUP BY r.region_name
ORDER BY avg_amount DESC;

-- 10. Top 10 regions generating maximum revenue

SELECT r.region_name, SUM(t.amount) AS revenue
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
JOIN regions r   ON c.region_id = r.region_id
WHERE t.payment_status = 'Success'
GROUP BY r.region_name
ORDER BY revenue DESC
LIMIT 10;

-- 11. Campaigns responded to by more than 100 customers

SELECT m.campaign_name, COUNT(DISTINCT r.customer_id) AS responders
FROM marketing_campaigns m
JOIN campaign_responses r ON m.campaign_id = r.campaign_id
WHERE r.responded = 1
GROUP BY m.campaign_id, m.campaign_name
HAVING COUNT(DISTINCT r.customer_id) > 100;

-- 12. Customers who never responded to any campaign

SELECT c.customer_id, c.first_name, c.last_name
FROM customers c
LEFT JOIN campaign_responses r
       ON c.customer_id = r.customer_id AND r.responded = 1
WHERE r.response_id IS NULL;

-- 13. Duplicate customer records by email or phone

SELECT 'email' AS duplicate_field, email AS value, COUNT(*) AS occurrences
FROM customers
GROUP BY email
HAVING COUNT(*) > 1
UNION ALL
SELECT 'phone', phone, COUNT(*)
FROM customers
GROUP BY phone
HAVING COUNT(*) > 1;

-- 14. Percentage contribution of each region to total revenue

SELECT r.region_name,
       SUM(t.amount) AS revenue,
       ROUND(100 * SUM(t.amount) / SUM(SUM(t.amount)) OVER (), 2) AS pct_of_total
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
JOIN regions r   ON c.region_id = r.region_id
WHERE t.payment_status = 'Success'
GROUP BY r.region_name
ORDER BY pct_of_total DESC;

-- 15. Percentage contribution of each plan to total revenue

SELECT p.plan_name,
       SUM(t.amount) AS revenue,
       ROUND(100 * SUM(t.amount) / SUM(SUM(t.amount)) OVER (), 2) AS pct_of_total
FROM transactions t
JOIN subscriptions s ON t.subscription_id = s.subscription_id
JOIN subscription_plans p ON s.plan_id = p.plan_id
WHERE t.payment_status = 'Success'
GROUP BY p.plan_name
ORDER BY pct_of_total DESC;

-- 16. Customer risk rank (days since last activity, support tickets, feedback score)

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

-- ADVANCED SQL (STORED PROCEDURE, TRIGGERS)

-- 1. Identify customers inactive for 90+ days but still marked 'Active'.
-- (Row count depends on today's date: CURDATE() is used)

SELECT c.customer_id, c.first_name, c.last_name, c.status,
       MAX(a.activity_date) AS last_activity,
       DATEDIFF(CURDATE(), MAX(a.activity_date)) AS days_inactive
FROM customers c
JOIN customer_activity_logs a ON c.customer_id = a.customer_id
WHERE c.status = 'Active'
GROUP BY c.customer_id, c.first_name, c.last_name, c.status
HAVING DATEDIFF(CURDATE(), MAX(a.activity_date)) >= 90
ORDER BY days_inactive DESC;

-- 2. Find customers who raised a support ticket within 7 days of a failed transaction.
-- (Counts tickets raised 0-7 days AFTER the failure.
--  For either direction, replace the two date conditions with:
--  AND ABS(DATEDIFF(s.created_date, t.transaction_date)) <= 7)

SELECT t.customer_id, c.first_name, c.last_name,
       t.transaction_id, t.transaction_date AS failed_on,
       s.ticket_id, s.created_date AS ticket_raised_on,
       DATEDIFF(s.created_date, t.transaction_date) AS days_after_failure
FROM transactions t
JOIN support_tickets s
      ON t.customer_id = s.customer_id
     AND s.created_date >= t.transaction_date
     AND s.created_date <= t.transaction_date + INTERVAL 7 DAY
JOIN customers c ON t.customer_id = c.customer_id
WHERE t.payment_status = 'Failed'
ORDER BY t.customer_id, t.transaction_date;

-- 3. Detect duplicate campaign responses for the same customer and campaign.
-- (Returns 0 rows with the sample data: no duplicates exist)

SELECT campaign_id, customer_id, COUNT(*) AS times_recorded
FROM campaign_responses
GROUP BY campaign_id, customer_id
HAVING COUNT(*) > 1;

-- PART 2: TRIGGER - Churn status automation
-- Fires after every insert into customer_activity_logs.
-- Last activity > 90 days  -> Active customer becomes Churned
-- Last activity <= 90 days -> Churned customer becomes Active (reactivation)
-- Paused customers are left untouched.

DROP TRIGGER IF EXISTS churnAutomation;

DELIMITER //
CREATE TRIGGER churnAutomation
AFTER INSERT ON customer_activity_logs
FOR EACH ROW
BEGIN
    DECLARE lastActivity DATE;

    SELECT MAX(activity_date) INTO lastActivity
    FROM customer_activity_logs
    WHERE customer_id = NEW.customer_id;

    IF DATEDIFF(CURDATE(), lastActivity) > 90 THEN
        UPDATE customers SET status = 'Churned'
        WHERE customer_id = NEW.customer_id AND status = 'Active';
    ELSE
        UPDATE customers SET status = 'Active'
        WHERE customer_id = NEW.customer_id AND status = 'Churned';
    END IF;
END //
DELIMITER ; 

-- PART 3: PROCEDURE - Duplicate campaign response prevention

DROP PROCEDURE IF EXISTS DCR;

DELIMITER //
CREATE PROCEDURE DCR (IN p_CampaignID INT, IN p_CustomerID INT)
BEGIN
    DECLARE CountResponse INT;

    SELECT COUNT(response_id) INTO CountResponse
    FROM campaign_responses
    WHERE campaign_id = p_CampaignID AND customer_id = p_CustomerID;

    IF CountResponse >= 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Prohibited: Duplicate Entry';
    ELSE
        INSERT INTO campaign_responses (campaign_id, customer_id, sent_date)
        VALUES (p_CampaignID, p_CustomerID, CURDATE());
    END IF;
END //
DELIMITER ;

-- PART 4: PROCEDURE - Auto-log churn history
-- Writes a churn_history row, but only for customers marked 'Churned'.

DROP PROCEDURE IF EXISTS CH;

DELIMITER //
CREATE PROCEDURE CH (IN p_CustomerID INT, IN p_Reason TEXT)
BEGIN
    DECLARE custStatus VARCHAR(20);

    SELECT status INTO custStatus
    FROM customers
    WHERE customer_id = p_CustomerID;

    IF custStatus = 'Churned' THEN
        INSERT INTO churn_history (customer_id, churn_date, churn_reason)
        VALUES (p_CustomerID, CURDATE(), p_Reason);
    ELSE
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Customer is not marked as Churned';
    END IF;
END //
DELIMITER ;
