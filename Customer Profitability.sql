SELECT *
FROM clean_accounts

SELECT *
FROM clean_loans

--Top 10% customers by revenue

WITH transactions AS (
SELECT ca.customer_id, SUM(bt.fee_revenue) AS fee_revenue
FROM fact_banking_transactions bt
JOIN clean_accounts ca ON bt.account_id = ca.account_id
GROUP BY ca.customer_id),

loan AS (
SELECT customer_id, SUM(loan_amount * interest_rate) AS interest_revenue
FROM clean_loans
GROUP BY customer_id
) 

SELECT customer_id 
FROM (
SELECT customer_id, total_revenue, NTILE(10) OVER(ORDER BY total_revenue DESC) AS ntile_rnk
FROM (
SELECT COALESCE(t.customer_id, l.customer_id) AS customer_id, COALESCE(fee_revenue, 0) + COALESCE(interest_revenue, 0) AS total_revenue
FROM transactions t 
FULL JOIN loan l ON t.customer_id = l.customer_id) AS t1) AS t2
WHERE ntile_rnk = 1


-- Revenue by income_band
WITH transactions AS (
SELECT ca.customer_id, SUM(bt.fee_revenue) AS fee_revenue
FROM fact_banking_transactions bt
JOIN clean_accounts ca ON bt.account_id = ca.account_id
GROUP BY ca.customer_id),

loan AS (
SELECT customer_id, SUM(loan_amount * interest_rate) AS interest_revenue
FROM clean_loans
GROUP BY customer_id
) 

SELECT income_band, SUM(total_revenue) AS total_revenue
FROM (
SELECT COALESCE(t.customer_id, l.customer_id) AS customer_id, income_band, COALESCE(fee_revenue, 0) + COALESCE(interest_revenue, 0) AS total_revenue
FROM transactions t 
FULL JOIN loan l ON t.customer_id = l.customer_id
JOIN dim_banking_customers b ON COALESCE(t.customer_id, l.customer_id) = b.customer_id) AS t1
GROUP BY income_band


-- Revenue by age_bucket
WITH transactions AS (
SELECT ca.customer_id, SUM(bt.fee_revenue) AS fee_revenue
FROM fact_banking_transactions bt
JOIN clean_accounts ca ON bt.account_id = ca.account_id
GROUP BY ca.customer_id),

loan AS (
SELECT customer_id, SUM(loan_amount * interest_rate) AS interest_revenue
FROM clean_loans
GROUP BY customer_id
) 

SELECT age_bucket, SUM(total_revenue) AS total_revenue
FROM (
SELECT COALESCE(t.customer_id, l.customer_id) AS customer_id, age_bucket, COALESCE(fee_revenue, 0) + COALESCE(interest_revenue, 0) AS total_revenue
FROM transactions t 
FULL JOIN loan l ON t.customer_id = l.customer_id
JOIN dim_banking_customers b ON COALESCE(t.customer_id, l.customer_id) = b.customer_id) AS t1
GROUP BY age_bucket

-- Profit per account_type
WITH transactions AS (
SELECT ca.account_id, account_type, SUM(bt.fee_revenue) AS fee_revenue
FROM fact_banking_transactions bt
JOIN clean_accounts ca ON bt.account_id = ca.account_id
GROUP BY ca.account_id, ca.account_type),

loan AS (
SELECT customer_id, SUM(loan_amount * interest_rate) AS interest_revenue
FROM clean_loans
GROUP BY customer_id
) 

SELECT a.account_type, SUM(COALESCE(tr.fee_revenue,0) + COALESCE(lr.interest_revenue,0)) AS profit
FROM clean_accounts a
LEFT JOIN transactions tr ON a.account_id = tr.account_id
LEFT JOIN loan lr ON a.customer_id = lr.customer_id
GROUP BY a.account_type


-- Revenue concentration risk
WITH transactions AS (
SELECT ca.customer_id, SUM(bt.fee_revenue) AS fee_revenue
FROM fact_banking_transactions bt
JOIN clean_accounts ca ON bt.account_id = ca.account_id
GROUP BY ca.customer_id),

loan AS (
SELECT customer_id, SUM(loan_amount * interest_rate) AS interest_revenue
FROM clean_loans
GROUP BY customer_id
),

customer_revenue AS (
SELECT COALESCE(t.customer_id, l.customer_id) AS customer_id, COALESCE(fee_revenue, 0) AS fee_revenue, COALESCE(interest_revenue, 0) AS interest_revenue, COALESCE(fee_revenue, 0) + COALESCE(interest_revenue, 0) AS total_revenue
FROM transactions t 
FULL JOIN loan l ON t.customer_id = l.customer_id)

SELECT * 
FROM (
SELECT *, (rnk * 1.0)/total_customers AS customer_share
FROM (
SELECT *, cumulative_revenue / overall_revenue AS revenue_share,
COUNT(customer_id) OVER() AS total_customers
FROM (
SELECT *, RANK() OVER(ORDER BY total_revenue DESC) AS rnk,
SUM(total_revenue) OVER(ORDER BY total_revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue,
SUM(total_revenue) OVER() AS overall_revenue
FROM customer_revenue) AS t1
) AS t2) AS t3
WHERE customer_share <= 0.2