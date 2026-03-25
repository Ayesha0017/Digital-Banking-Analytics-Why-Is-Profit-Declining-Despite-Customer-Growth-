-- PHASE 3.4 — Operational Efficiency

-- Average Transactions per Customer
SELECT COUNT(transaction_id) * 1.0/COUNT(DISTINCT a.customer_id) AS avg_transaction
FROM fact_banking_transactions f 
JOIN dim_banking_accounts a ON f.account_id = a.account_id

-- Fee Revenue per Transaction
SELECT SUM(fee_revenue) * 1.0/COUNT(*) AS fee_revenue_per_transaction
FROM fact_banking_transactions 

-- Are Transaction Fees Declining?
SELECT transaction_month, SUM(fee_revenue) * 1.0/COUNT(*) AS fee_revenue_per_transaction, SUM(fee_revenue) AS total_fee_revenue, 
COUNT(*) AS total_transactions
FROM fact_banking_transactions 
GROUP BY transaction_month
ORDER BY transaction_month 

-- Cost-to-Income
WITH fee_income AS (
SELECT SUM(fee_revenue) AS total_fee_income
FROM fact_banking_transactions
),

default_loss AS (
SELECT SUM(CASE WHEN default_flag = 1 THEN loan_amount ELSE 0 END) AS total_default_loss
FROM fact_loans
)

SELECT f.total_fee_income, d.total_default_loss, d.total_default_loss * 1.0 / f.total_fee_income AS cost_to_income_ratio
FROM fee_income f
CROSS JOIN default_loss d

-- Are Small Transactions Increasing Load?
WITH transaction_buckets AS ( SELECT *, CASE WHEN amount < 5000 THEN 'Small (<5K)'
WHEN amount BETWEEN 5000 AND 20000 THEN 'Medium (5K-20K)' 
WHEN amount > 20000 THEN 'Large (>20K)' END AS transaction_bucket
FROM fact_banking_transactions
)

SELECT transaction_bucket, COUNT(*) AS total_transactions, SUM(amount) AS total_amount, AVG(fee_revenue) AS avg_fee
FROM transaction_buckets
GROUP BY transaction_bucket