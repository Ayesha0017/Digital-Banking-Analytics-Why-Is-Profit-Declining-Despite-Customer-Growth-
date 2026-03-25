# 🏦 Banking Analytics: SQL Analysis

## 📌 Project Overview

This project analyzes a banking dataset to uncover insights across the **entire customer lifecycle**, including:

* Customer acquisition
* Transaction behavior
* Revenue generation
* Loan risk & defaults
* Operational efficiency
* Customer churn & retention

The goal is to simulate a **real-world business analytics scenario** and derive actionable insights using SQL.

---

## 🧱 Data Model

The project is structured using a **star schema approach**:

### 🔹 Fact Tables

* `fact_banking_transactions` → 1 row per transaction
* `fact_loans` → 1 row per loan

### 🔹 Dimension Tables

* `dim_banking_customers` → customer attributes
* `dim_banking_accounts` → account details

### 🔹 Data Cleaning Views

* `clean_transactions`
* `clean_accounts`
* `clean_loans`

---

## ⚙️ Data Preparation

Key transformations performed:

* Removed duplicate transactions using `ROW_NUMBER()`
* Filtered invalid records (negative amounts, null dates)
* Standardized account statuses and flags
* Engineered features:

  * `transaction_month`
  * `active_flag`
  * `loan_duration`
  * `default_flag`
  * `interest_income`

---

## 📊 Analysis Phases

---

### 🔹 Phase 1 — Growth & Revenue Trends

**Key Questions:**

* Monthly transaction volume
* Fee revenue trends
* Loan interest income trends
* Customer growth

**Insights:**

* Revenue growth is inconsistent and driven mainly by transaction volume
* No strong pricing power (stable fee per transaction)

---

### 🔹 Phase 2 — Customer Profitability

**Key Questions:**

* Revenue per customer
* Top 10% customers contribution
* Revenue by income & age segments

**Insights:**

* Revenue is concentrated among a small group of customers
* Indicates **concentration risk**
* Certain segments contribute disproportionately to revenue

---

### 🔹 Phase 3 — Loan Risk & Default Analysis

**Key Questions:**

* Default rates by segment
* Time to default
* Impact of defaults on profitability

**Insights:**

* High default rates significantly impact profitability
* Net interest income becomes negative after accounting for defaults
* Higher interest rates are associated with higher risk

---

### 🔹 Phase 4 — Operational Efficiency

**Key Questions:**

* Transactions per customer
* Fee revenue per transaction
* Cost-to-income ratio
* Transaction size efficiency

**Insights:**

* Business operates on a **low-margin, high-volume model**
* Cost-to-income ratio > 7 → highly inefficient
* Large transactions drive most of the revenue

---

### 🔹 Phase 5 — Churn & Retention

**Churn Definition:**

> Customer with no transaction in the last 90 days

**Key Questions:**

* Churn rate overall and by segment
* Behavior before churn
* Revenue lost due to churn
* Churn trend over time

**Insights:**

* ~39% churn rate → major retention issue
* Churn is consistent across income segments → product-level issue
* Churned users have significantly lower activity before leaving
* Churn is increasing over time → worsening retention
* Significant revenue loss due to churn

---

## 🔥 Key Business Findings

* ❗ High churn (~39%) indicates poor retention
* ❗ Default losses exceed revenue → unsustainable model
* ❗ Revenue is concentrated among a small % of customers
* ❗ Engagement drop is a strong predictor of churn
* ❗ Retention worsens over time

---

## 💡 Recommendations

* Improve **credit risk policies** to reduce defaults
* Introduce **engagement strategies** (nudges, rewards)
* Focus on **high-value customer retention**
* Optimize pricing to improve **per-transaction revenue**
* Monitor early signs of churn using behavioral signals

---

## 🛠️ Tools & Skills Used

* SQL (Advanced)

  * CTEs
  * Window Functions (`LAG`, `RANK`, `NTILE`)
  * Aggregations
  * Joins & Data Modeling
* Analytical Thinking
* Business Problem Solving

---

## 🚀 How to Use

1. Import dataset into SQL Server
2. Run data cleaning scripts
3. Create fact and dimension tables
4. Execute analysis queries phase-wise

---

## 📌 Project Outcome

This project demonstrates the ability to:

* Perform **end-to-end data analysis**
* Translate data into **business insights**
* Identify **key drivers of revenue, risk, and churn**
* Build **real-world analytical frameworks**

---

## 👤 Author

**Ayesha Firdaus Honnur**

---

⭐ If you found this useful, feel free to star the repository!
