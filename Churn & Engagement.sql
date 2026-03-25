

CREATE VIEW customer_churn AS
WITH customer_transactions AS (SELECT a.customer_id, MAX(transaction_date) AS max_txn_date
FROM fact_banking_transactions f 
JOIN dim_banking_accounts a ON f.account_id = a.account_id
GROUP BY a.customer_id),

max_transaction AS (SELECT  MAX(transaction_date) AS max_transaction
FROM fact_banking_transactions)

SELECT ct.customer_id, ct.max_txn_date, mt.max_transaction, CASE WHEN DATEDIFF(day, ct.max_txn_date, mt.max_transaction) > 90 THEN 1 ELSE 0 END AS churn_flag
FROM customer_transactions ct
CROSS JOIN max_transaction mt

-- Churn Rate (Overall)
SELECT (SUM(CASE WHEN churn_flag = 1 THEN 1 ELSE 0 END) * 1.0) * 100/COUNT(customer_id) AS churn_rate
FROM customer_churn

-- Churn by Cohort
SELECT signup_cohort, (SUM(CASE WHEN churn_flag = 1 THEN 1 ELSE 0 END) * 1.0) * 100/COUNT(b.customer_id) AS churn_rate
FROM dim_banking_customers b
JOIN customer_churn c ON b.customer_id = c.customer_id
GROUP BY signup_cohort
ORDER BY signup_cohort


-- Churn by Income Band
SELECT income_band, (SUM(CASE WHEN churn_flag = 1 THEN 1 ELSE 0 END) * 1.0) * 100/COUNT(customer_id) AS churn_rate
FROM (
SELECT c.customer_id, b.income_band, c.churn_flag
FROM dim_banking_customers b
JOIN customer_churn c ON b.customer_id = c.customer_id) AS t1
GROUP BY income_band

-- Behavior Before Churn
WITH customer_transactions AS (SELECT a.customer_id, COUNT(*) AS transaction_count
FROM fact_banking_transactions f 
JOIN dim_banking_accounts a ON f.account_id = a.account_id
GROUP BY a.customer_id)

SELECT churn_flag, AVG(transaction_count) AS avg_transactions
FROM customer_churn c
JOIN customer_transactions t ON c.customer_id = t.customer_id 
GROUP BY churn_flag

-- Revenue Lost from Churn
WITH fee_revenue AS (SELECT a.customer_id, SUM(f.fee_revenue) AS fee_revenue
FROM fact_banking_transactions f 
JOIN dim_banking_accounts a ON f.account_id = a.account_id
GROUP BY a.customer_id),

interest_revenue AS (SELECT customer_id, SUM(interest_income) AS interest_revenue
FROM fact_loans
GROUP BY customer_id
),

customer_revenue AS (SELECT COALESCE(f.customer_id, i.customer_id) AS customer_id, COALESCE(fee_revenue, 0) + COALESCE(interest_revenue, 0) AS revenue
FROM fee_revenue f
FULL JOIN interest_revenue i ON f.customer_id = i.customer_id
),

total_revenue AS (
    SELECT SUM(revenue) AS total_revenue
    FROM customer_revenue
)

SELECT MAX(t.total_revenue) AS total_revenue, SUM(cust.revenue) AS revenue_lost
FROM customer_churn c
JOIN customer_revenue cust ON c.customer_id = cust.customer_id
CROSS JOIN total_revenue t
WHERE c.churn_flag = 1


-- Is Churn Increasing Over Time?
WITH customer_transactions AS (
SELECT a.customer_id, MAX(transaction_date) AS last_txn_date
FROM dim_banking_customers c
LEFT JOIN dim_banking_accounts a ON c.customer_id = a.customer_id
LEFT JOIN fact_banking_transactions f ON a.account_id = f.account_id
GROUP BY a.customer_id
),

max_transaction AS (
    SELECT MAX(transaction_date) AS max_txn_date
    FROM fact_banking_transactions
),

customer_churn_base AS (SELECT ct.customer_id, ct.last_txn_date, mt.max_txn_date,
CASE WHEN DATEDIFF(day, ct.last_txn_date, mt.max_txn_date) > 90 THEN 1 ELSE 0 END AS churn_flag, FORMAT(DATEADD(day, 90, ct.last_txn_date), 'yyyy-MM') AS churn_month
FROM customer_transactions ct
CROSS JOIN max_transaction mt
)

SELECT 
    churn_month,
    COUNT(*) * 1.0 / (SELECT COUNT(*) FROM dim_banking_customers) AS churn_rate
FROM customer_churn_base
WHERE churn_flag = 1
GROUP BY churn_month
ORDER BY churn_month
