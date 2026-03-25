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

SELECT TOP 1 *
FROM clean_transactions

SELECT  TOP 1 *
FROM clean_accounts

SELECT  TOP 1 *
FROM clean_loans


SELECT  TOP 1 *
FROM dim_banking_accounts

SELECT  TOP 1 *
FROM dim_banking_customers


SELECT  TOP 1 *
FROM fact_banking_transactions

SELECT top 1*
FROM fact_loans

-- Default rate overall
SELECT (COUNT(DISTINCT CASE WHEN default_flag = 1 THEN loan_id END) * 1.0) * 100/COUNT(DISTINCT loan_id) AS overall_default
FROM fact_loans

-- Default rate by income_band
SELECT income_band,  SUM(default_flag) * 1.0 / COUNT(*) AS default_rate
FROM dim_banking_customers c
JOIN fact_loans f ON c.customer_id = f.customer_id
GROUP BY income_band

-- Default rate by loan size bucket
WITH loan_bucketed AS (
    SELECT *,
        CASE 
            WHEN loan_amount BETWEEN 50000 AND 140000 THEN '50K-140K'
            WHEN loan_amount BETWEEN 140001 AND 230000 THEN '140K-230K'
            WHEN loan_amount BETWEEN 230001 AND 320000 THEN '230K-320K'
            WHEN loan_amount BETWEEN 320001 AND 410000 THEN '320K-410K'
            ELSE '410K+' 
        END AS loan_bucket
    FROM fact_loans
)

SELECT 
    loan_bucket,
    SUM(default_flag) * 1.0 / COUNT(*) AS default_rate
FROM loan_bucketed
GROUP BY loan_bucket


-- time to deault analysis
WITH default_loans AS (
SELECT *, 
CASE WHEN days_before_default BETWEEN 0 AND 90 THEN '0–90 days'
WHEN days_before_default BETWEEN 91 AND 180 THEN '91–180 days'
WHEN days_before_default BETWEEN 181 AND 360 THEN '181–360 days'
WHEN days_before_default > 360 THEN '360+ days' END AS loan_default_buckets
FROM (
SELECT *, DATEDIFF(day, start_date, last_payment_date) AS days_before_default
FROM fact_loans
WHERE default_flag = 1 AND last_payment_date IS NOT NULL AND start_date <= last_payment_date) AS t1
)

SELECT AVG(days_before_default) AS avg_time_to_default
FROM default_loans

SELECT loan_default_buckets, COUNT(*) AS no_of_defaults
FROM default_loans	
GROUP BY loan_default_buckets




--  Cohort default rate (by start_date month)
WITH cohort_cte AS (
SELECT loan_id, customer_id, default_flag, start_date, FORMAT(start_date,'yyyy-MM') AS cohort_month
FROM fact_loans)

SELECT cohort_month,  (SUM(default_flag) * 1.0) * 100/ COUNT(*) AS default_rate
FROM cohort_cte
GROUP BY cohort_month
ORDER BY cohort_month


--  Default impact on profit
SELECT SUM(interest_income) AS total_interest_income, SUM(CASE WHEN default_flag = 1 THEN loan_amount ELSE 0 END) AS total_default_loss, SUM(interest_income) - SUM(CASE WHEN default_flag = 1 THEN loan_amount ELSE 0 END) AS net_profit
FROM fact_loans

-- Net Interest Income After Default Losses
SELECT SUM(interest_income) AS total_interest_income, SUM(CASE WHEN default_flag = 1 THEN loan_amount ELSE 0 END) AS total_default_loss, SUM(interest_income) - SUM(CASE WHEN default_flag = 1 THEN loan_amount ELSE 0 END) AS net_interest_income
FROM fact_loans


SELECT income_band, SUM(interest_income) AS total_interest_income, SUM(CASE WHEN default_flag = 1 THEN loan_amount ELSE 0 END) AS total_default_loss, SUM(interest_income) - SUM(CASE WHEN default_flag = 1 THEN loan_amount ELSE 0 END) AS net_interest_income
FROM dim_banking_customers c
JOIN fact_loans f ON c.customer_id = f.customer_id
GROUP BY income_band


WITH loan_bucketed AS (
    SELECT *,
        CASE 
            WHEN loan_amount BETWEEN 50000 AND 140000 THEN '50K-140K'
            WHEN loan_amount BETWEEN 140001 AND 230000 THEN '140K-230K'
            WHEN loan_amount BETWEEN 230001 AND 320000 THEN '230K-320K'
            WHEN loan_amount BETWEEN 320001 AND 410000 THEN '320K-410K'
            ELSE '410K+' 
        END AS loan_bucket
    FROM fact_loans
)

SELECT 
    loan_bucket, SUM(interest_income) AS total_interest_income, SUM(CASE WHEN default_flag = 1 THEN loan_amount ELSE 0 END) AS total_default_loss, SUM(interest_income) - SUM(CASE WHEN default_flag = 1 THEN loan_amount ELSE 0 END) AS net_interest_income
FROM loan_bucketed
GROUP BY loan_bucket

WITH interest_rate AS (
SELECT *, CASE WHEN interest_rate BETWEEN 0 AND 0.10 THEN 'Low (0–10%)' WHEN interest_rate BETWEEN 0.10 AND 0.13 THEN 'Medium (10–13%)' ELSE 'High (13%+)' END AS interest_rate_buckets
FROM fact_loans)

SELECT 
    interest_rate_buckets, SUM(interest_income) AS total_interest_income, SUM(CASE WHEN default_flag = 1 THEN loan_amount ELSE 0 END) AS total_default_loss, SUM(interest_income) - SUM(CASE WHEN default_flag = 1 THEN loan_amount ELSE 0 END) AS net_interest_income
FROM interest_rate
GROUP BY interest_rate_buckets

SELECT interest_rate_buckets, SUM(default_flag) * 1.0 / COUNT(*) AS default_rate
FROM interest_rate
GROUP BY interest_rate_buckets




