USE db

SELECT TOP 1 *
FROM banking_customers

SELECT TOP 1 *
FROM banking_accounts

SELECT TOP 1 *
FROM banking_transactions

SELECT TOP 1 *
FROM banking_loans

SELECT TOP 1 * 
FROM banking_loan_payments


CREATE VIEW clean_transactions AS 
SELECT *
FROM (SELECT *, ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY transaction_date DESC) AS rn
FROM banking_transactions
WHERE amount > 0 AND transaction_date IS NOT NULL) t
WHERE rn = 1

CREATE VIEW clean_accounts AS 
SELECT account_id, customer_id, account_type, open_date, [status],
CASE WHEN status = 'active' THEN 1 ELSE 0 END AS active_flag
FROM banking_accounts
WHERE status IN ('active','closed')

CREATE VIEW clean_loans AS 
SELECT loan_id, customer_id, loan_amount, interest_rate, start_date, status
FROM banking_loans
WHERE loan_amount > 0 and start_date IS NOT NULL

CREATE VIEW dim_banking_customers AS
SELECT customer_id, signup_date, age, city, income_band,
FORMAT(signup_date, 'yyyy-MM') AS signup_cohort,
CASE WHEN age < 25 THEN '18-24' WHEN age BETWEEN 25 and 34 THEN '25-34' WHEN age BETWEEN 35 and 50 THEN '35-49' ELSE '50+' END AS age_bucket
FROM banking_customers

CREATE VIEW dim_banking_accounts AS 
SELECT account_id, customer_id, account_type, open_date, active_flag
FROM clean_accounts

CREATE VIEW fact_banking_transactions AS
SELECT transaction_id, account_id, transaction_date, FORMAT(transaction_date,'yyyy-MM') AS transaction_month,
transaction_type, amount, transaction_fee AS fee_revenue, amount - transaction_fee AS net_transaction_amount
FROM clean_transactions

SELECT *
FROM fact_banking_transactions

SELECT *
FROM clean_loans

SELECT *
FROM banking_loan_payments

CREATE VIEW fact_loans AS
SELECT l.loan_id, l.customer_id, l.loan_amount, l.interest_rate, l.start_date, l.status,
MAX(b.payment_date) AS last_payment_date, DATEDIFF(day, l.start_date, MAX(b.payment_date)) AS loan_duration,
SUM(b.payment_amount) AS total_paid, CASE WHEN l.status = 'defaulted' THEN 1 ELSE 0 END AS default_flag,
l.loan_amount * l.interest_rate AS interest_income
FROM clean_loans l 
LEFT JOIN banking_loan_payments b ON l.loan_id = b.loan_id
GROUP BY l.loan_id, l.customer_id, l.loan_amount, l.interest_rate, l.start_date, l.status


