Customer Churn Analysis 

MySQL Customer Churn Analysis project with 15 tables, queries, triggers and stored procedures

A MySQL database project that analyses customer churn: which customers stop using a service, when, and why. It includes a 15-table schema, sample data for 1,000 customers, and SQL queries at basic, intermediate and advanced levels, including a trigger and stored procedures.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------

What is customer churn analysis?

Churn means a customer leaves or becomes inactive, for example by cancelling a subscription or no longer using the service. Churn analysis studies who leaves and why, so a business can spot at-risk customers early and keep them.


How to run the project
Create the tables. Open create_tables_mysql.sql in MySQL Workbench and run the whole script.

Import the data. In Workbench, right-click each table, choose Table Data Import Wizard, and select the matching CSV file. Import in this order so the foreign keys work: regions → subscription_plans → products → marketing_campaigns → customers → employees → subscriptions → transactions → payment_methods → customer_activity_logs → support_tickets → feedback_surveys → campaign_responses → churn_history → product_usage

Check the import. Compare each table's COUNT(*) with the sample rows in the schema table above.

Run the queries. Open the query files and run them one at a time with Ctrl+Enter.

Create the trigger last. Run the trigger in advanced_level_queries.sql only after the data import is finished, because it fires on every row inserted into customer_activity_logs.

What the queries cover?
Basic: filtering with WHERE, GROUP BY and HAVING, JOIN and LEFT JOIN, sorting and LIMIT, and date functions.

Intermediate: top-N and second-highest queries, cancellation rates, revenue share per region and plan, duplicate detection, and a customer risk ranking that combines days since last activity, support ticket count and feedback score.

Advanced:
Customers who are still marked Active but have been inactive for 90 or more days.
Customers who raised a support ticket within 7 days of a failed payment.

Duplicate campaign response detection.
A trigger (churnAutomation) that updates a customer's status from their latest activity.
A procedure (DCR) that prevents duplicate campaign responses.
A procedure (CH) that logs churn history.

Assumptions
Revenue counts only transactions with payment_status = 'Success'.
A customer is considered churned after more than 90 days without activity.
The sample data is synthetic. It was generated for this project and does not describe real customers.

