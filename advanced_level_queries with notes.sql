-- =====================================================
-- CUSTOMER CHURN ANALYSIS - ADVANCED SQL
-- (Queries, Trigger, Stored Procedures)
--
-- HOW TO RUN IN WORKBENCH:
--  * Queries (Part 1): click inside one query, press Ctrl+Enter
--  * Trigger/Procedures (Parts 2-4): select the whole block from
--    DROP ... through DELIMITER ;  then press Ctrl+Shift+Enter
--  * Create the trigger AFTER the CSV data has been imported
-- =====================================================

USE customer_churn_analysis;

-- =====================================================
-- PART 1: QUERIES
-- =====================================================

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


-- =====================================================
-- PART 2: TRIGGER - Churn status automation
-- Fires after every insert into customer_activity_logs.
-- Last activity > 90 days  -> Active customer becomes Churned
-- Last activity <= 90 days -> Churned customer becomes Active (reactivation)
-- Paused customers are left untouched.
-- =====================================================

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

-- TEST (reactivation): customer 4 is Churned
-- INSERT INTO customer_activity_logs (customer_id, activity_type, activity_date)
-- VALUES (4, 'Login', NOW());
-- SELECT customer_id, status FROM customers WHERE customer_id = 4;   -- now 'Active'
--
-- UNDO the test:
-- DELETE FROM customer_activity_logs WHERE customer_id = 4 AND activity_date >= CURDATE();
-- UPDATE customers SET status = 'Churned' WHERE customer_id = 4;


-- =====================================================
-- PART 3: PROCEDURE - Duplicate campaign response prevention
-- =====================================================

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

-- TEST:
-- CALL DCR(1, 8);   -- customer 8 is already in campaign 1 -> error 'Prohibited: Duplicate Entry'
-- CALL DCR(1, 1);   -- customer 1 is not in campaign 1 -> inserts successfully
--
-- UNDO the test insert:
-- DELETE FROM campaign_responses WHERE campaign_id = 1 AND customer_id = 1;


-- =====================================================
-- PART 4: PROCEDURE - Auto-log churn history
-- Writes a churn_history row, but only for customers marked 'Churned'.
-- =====================================================

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

-- TEST:
-- CALL CH(5, 'Price Too High');   -- customer 5 is Active -> error
-- CALL CH(3, 'Test Reason');      -- customer 3 is Churned -> inserts a row
-- SELECT * FROM churn_history WHERE customer_id = 3;
--
-- UNDO the test insert (every churned customer already had one history row):
-- DELETE FROM churn_history WHERE customer_id = 3 AND churn_reason = 'Test Reason';
