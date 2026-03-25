--PHASE 3.1 — Growth & Revenue Trends

/*Monthly transaction volume?*/
SELECT transaction_month, COUNT(*) AS transaction_volume 
FROM fact_banking_transactions
GROUP BY transaction_month
ORDER BY transaction_month

-- Monthly fee revenue
SELECT *, RANK() OVER(ORDER BY fee_revenue DESC) AS rnk
FROM (
SELECT transaction_month, SUM(fee_revenue) AS fee_revenue
FROM fact_banking_transactions
GROUP BY transaction_month) AS t1

-- Loan interest income trend,
SELECT *, RANK() OVER(ORDER BY interest_income DESC) AS rnk
FROM (
SELECT FORMAT(start_date,'yyyy-MM') AS month, SUM(interest_income) AS interest_income
FROM fact_loans
GROUP BY FORMAT(start_date,'yyyy-MM')) AS t1

-- Customer growth by month
SELECT signup_cohort, COUNT(DISTINCT customer_id) AS total_customers
FROM dim_banking_customers
GROUP BY signup_cohort
ORDER BY signup_cohort


-- MoM growth rate
SELECT transaction_month, COALESCE((fee_revenue- previous_revenue) * 100.0/previous_revenue, 0) AS MOM_revenue
FROM (
SELECT transaction_month, fee_revenue,
LAG(fee_revenue) OVER(ORDER BY transaction_month) AS previous_revenue
FROM (
SELECT transaction_month, SUM(fee_revenue) AS fee_revenue
FROM fact_banking_transactions
GROUP BY transaction_month) AS t1) AS t2


-- Revenue per active customer
SELECT (SUM(fee_revenue) + SUM(interest_income)) * 1.0/COUNT(DISTINCT c.customer_id) AS ARPU
FROM fact_banking_transactions f
LEFT JOIN dim_banking_accounts a ON f.account_id = a.account_id
LEFT JOIN dim_customers c ON c.customer_id = a.customer_id
LEFT JOIN fact_loans l ON l.customer_id = c.customer_id
WHERE active_flag = 1

-- Revenue per account type
SELECT account_type, SUM(f.fee_revenue) AS fee_revenue, SUM(l.interest_income) AS interest_income,
SUM(f.fee_revenue) + SUM(l.interest_income) AS total_revenue
FROM dim_banking_accounts a 
LEFT JOIN fact_banking_transactions f ON a.account_id = f.account_id
LEFT JOIN fact_loans l ON a.customer_id = l.customer_id
GROUP BY account_type



WITH fee_revenue AS (
SELECT transaction_month AS month, SUM(fee_revenue) AS monthly_fee_revenue
FROM fact_banking_transactions
GROUP BY transaction_month ),

interest_revenue AS (
SELECT FORMAT(start_date, 'yyyy-MM') AS month, SUM(interest_income) AS monthly_interest_revenue
FROM fact_loans
GROUP BY FORMAT(start_date, 'yyyy-MM') )

SELECT f.month, f.monthly_fee_revenue, i.monthly_interest_revenue,  f.monthly_fee_revenue + i.monthly_interest_revenue AS total_revenue
FROM fee_revenue f 
JOIN interest_revenue i ON f.month = i.month
ORDER BY f.month



WITH monthly_customers AS (
SELECT FORMAT(signup_date, 'yyyy-MM') AS month, COUNT(*) AS customers
FROM dim_customers
GROUP BY FORMAT(signup_date, 'yyyy-MM')
), 

transactions_per_customer AS (
SELECT transaction_month AS month, COUNT(*) * 1.0/COUNT(DISTINCT b.customer_id) AS transactions_per_customer
FROM fact_banking_transactions f
LEFT JOIN dim_banking_accounts b ON f.account_id = b.account_id
GROUP BY transaction_month),

monthly_loans AS (
SELECT FORMAT(start_date,'yyyy-MM') AS month, SUM(loan_amount) AS loan_volume
FROM fact_loans
GROUP BY FORMAT(start_date,'yyyy-MM'))

SELECT c.month, customers, transactions_per_customer, loan_volume
FROM monthly_customers c 
LEFT JOIN transactions_per_customer t ON c.month = t.month
LEFT JOIN monthly_loans l ON c.month = l.month
ORDER BY c.month