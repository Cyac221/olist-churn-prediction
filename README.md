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
