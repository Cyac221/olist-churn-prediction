# Olist Brazil — Customer Churn Prediction

> End-to-end data project: from raw e-commerce data to a machine learning model for customer reactivation.
> Dataset: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce


---

## Business Problem

Olist is a Brazilian e-commerce platform that connects small businesses to major marketplaces. This project analyzes **100,000+ real orders placed between 2016 and 2018** to understand customer behavior and identify clients at risk of not returning.

The central question: **can we predict which customers are unlikely to buy again?**

---

## Project Structure

```
olist-churn-prediction/
│
├── README.md
├── .gitignore
│
├── original_data/
│   ├── olist_customer_dataset.csv
│   ├── olist_order_items_dataset.csv
│   ├── olist_order_payments_dataset.csv
│   ├── olist_order_reviews_dataset.csv
│   ├── olist_orders_dataset.csv
│   ├── olist_products_dataset.csv
│   ├── olist_sellers_dataset.csv
│   └── product_category_name_translation.csv
│
├── sql/
│   ├── 01_olist_ddl.sql           # Database schema, FK, indexes
│   ├── 02_exploratory_dataset.sql # EDA: revenue, delivery, reviews
│   └── 03_clients.sql             # RFM analysis + rfm_final view
│
├── python/
│   └── 04_churn_model.py          # ML model: feature engineering + training
│
└── images/
    └── churn_model_evaluation.png # ROC curve + confusion matrix
```

---

## Tech Stack

| Layer | Tools |
|---|---|
| Database | PostgreSQL 16 + pgAdmin |
| Data exploration | SQL (CTEs, window functions, NTILE) |
| Data manipulation | Python · pandas · NumPy |
| Machine learning | scikit-learn |
| Visualization | matplotlib |
| Version control | Git · GitHub |

---

## Methodology

### Phase 1 — Exploratory Data Analysis (SQL)
- Identified dataset timeframe: September 2016 – October 2018
- Analyzed order status distribution (97% delivered)
- Mapped null values per table and business impact
- Answered key business questions: monthly revenue trends, top categories, delivery performance, review distribution

### Phase 2 — RFM Analysis (SQL)
Built a customer scoring model with three stages:

**Stage 2.1 — Raw metrics per customer**
- `recency_days`: days since last purchase (reference date: 2018-10-17)
- `frequency`: number of distinct orders
- `monetary_value`: total spend
- `avg_review_score`: average rating left by the customer

**Stage 2.2 — Score assignment**
- R score: quintile-based (inverted — fewer days = higher score)
- F score: stepped scale (0–3) — chosen over NTILE because 97% of customers purchased exactly once, making quintile distribution meaningless
- M score: quintile-based
- Experience score: quintile-based on avg review, NULLs assigned lowest group

**Stage 3 — Segmentation**
Rule-based CASE WHEN classification into 11 segments:
Champions, Loyal, Cannot Lose, At Risk, Lost, Hibernating, Promising, New Customer, About to Sleep, Potential Loyalist, Price Sensitive.

Results saved as a reusable PostgreSQL view: `rfm_final`.

### Phase 3 — Churn Prediction (Python + scikit-learn)

**Churn definition:**
Customers labeled as Lost, Hibernating, At Risk, or Cannot Lose were tagged as churn = 1.
This is a **hypothetical business rule**, not a directly observed event.
→ 32% churn rate (29,875 of 93,358 customers)

---

## Experiments & Findings

Three modeling approaches were tested. All results are documented — including the ones that didn't work.

### Experiment 1 — Logistic Regression with RFM scores
```
Features: recency_days, frequency, monetary_value,
          avg_review_score, r_score, f_score, m_score, experience_score
AUC-ROC:  0.9459
Recall (Churn): 0.01
```
**Problem:** indirect data leakage. The RFM scores were derived from the same variables used to define churn labels. The model learned a circular relationship, not real patterns.

### Experiment 2 — Random Forest (unconstrained)
```
Features: recency_days, frequency, monetary_value, avg_review_score
AUC-ROC:  0.9997
Accuracy: 1.00
```
**Problem:** severe overfitting. `recency_days` perfectly separates the classes because it was the primary variable used to define churn segments. Customers with recency < 300 days showed 0% churn rate — the model memorized this boundary instead of generalizing.

### Experiment 3 — Logistic Regression (raw features only) ✅
```
Features: recency_days, frequency, monetary_value, avg_review_score
AUC-ROC:  0.9433
Precision (Churn): 0.80
Recall (Churn):    0.89
F1 (Churn):        0.84
Accuracy:          0.89
```
**Selected model.** Honest, generalizable, and explainable.

---

## Key Findings

**1. Recency dominates everything**
`recency_days` has a coefficient of 3.09 — by far the strongest predictor. In low-recurrence e-commerce platforms, inactivity is the clearest signal of churn.

**2. High spenders tend to churn**
`monetary_value` shows a positive coefficient (0.196) — counterintuitive at first. Explanation: high-spend customers on Olist tend to buy large one-time items (furniture, electronics, appliances). They spend a lot once and don't return. The model captured this pattern correctly.

**3. Frequency is nearly useless as a feature**
97% of customers purchased exactly once. NTILE(5) on this variable creates arbitrary groups with no discriminatory power.

**4. Review score has minimal predictive value**
Despite being theoretically meaningful, `avg_review_score` contributes almost nothing (coefficient: 0.001). The distribution is heavily skewed toward 5 stars, leaving little variance for the model to learn from.

---

## Model Limitations & Honest Notes

This project intentionally documents what didn't work and why.

- **Churn is not directly observed.** The target variable is derived from RFM segments — a proxy for inactivity, not a confirmed business outcome.
- **The dataset structure limits ML.** With 97% single-purchase customers, traditional churn modeling assumptions don't hold.
- **recency_days leaks information.** The near-perfect separation at the 300-day boundary means the model is partially confirming our own segmentation rules.
- **Recommended next steps:**
  - Reframe as a **regression problem** (predict future customer value)
  - Limit population to repeat buyers (2,801 customers) for a cleaner classification problem
  - Add external signals: product category, payment method, delivery delay experienced

---
