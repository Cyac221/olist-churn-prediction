--Data exploring

--Identify first and last order
SELECT
	MIN(order_purchase_timestamp) AS first_order,
	MAX(order_purchase_timestamp) AS last_order
FROM olist_orders;

--QTY orders per state of deliver
SELECT
	order_status,
	COUNT(*) AS total,
	ROUND(COUNT(*)*100/SUM(COUNT(*))OVER(),2) AS percentage
FROM olist_orders
GROUP BY order_status
ORDER BY total;

--Null checks
SELECT
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS without_approbation,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS not_delivered,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS not_estimated
FROM olist_orders;


--			Business questions
--1. How is the currently state with orders, revenue, freight and the average ticket per month
--Sales and revenue per month
SELECT
	DATE_TRUNC('month', o.order_purchase_timestamp) AS monthh,
	COUNT(DISTINCT o.order_id) AS total_orders,
	ROUND(SUM(oi.price)::NUMERIC,2) AS revenue_products,
	ROUND(SUM(oi.freight_value)::NUMERIC,2) AS revenue_freight,
	ROUND(SUM(oi.price + oi.freight_value)::NUMERIC,2) AS revenue_total,
	ROUND(AVG(oi.price)::NUMERIC,2) AS average_ticket
FROM olist_orders AS o
JOIN olist_order_items AS oi
ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_TRUNC('month',o.order_purchase_timestamp)	
ORDER BY monthh;

--Explosive growth during november 2017. Stabilization in 2018
--2016 outlier
--Top 15 categories
SELECT
	COALESCE(t.product_category_name_english,p.product_category_name) AS category,
	COUNT (DISTINCT oi.order_id) AS total_orders,
	ROUND(SUM(oi.price)::NUMERIC,2) AS total_revenue,
	ROUND(AVG(oi.price)::NUMERIC,2) AS average_price,
	COUNT(DISTINCT(oi.seller_id)) AS total_sellers,
	ROUND(COUNT(*)*100/SUM(COUNT(*))OVER(),2) AS percentage
FROM olist_order_items AS oi
JOIN olist_products AS p 
	ON oi.product_id = p.product_id
JOIN olist_orders AS o
	ON oi.order_id = o.order_id
LEFT JOIN product_category_name_translation AS t
	ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY COALESCE(t.product_category_name_english,p.product_category_name)
ORDER BY total_revenue DESC
LIMIT 15
--Categories: health_beauty, watches_gifts, bed_bath_table, sports_leisure, computers_accessories, furniture_decor, housewares
--The first 7 categories represents the 52% of all sales

--delivery times, and avg delayed and advanced
SELECT
    ROUND(AVG(
        EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) 
        / 86400)::NUMERIC, 1) AS days_delivered_real_avg,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (order_estimated_delivery_date - order_purchase_timestamp)) 
        / 86400)::NUMERIC, 1) AS estimated_days_avg,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (order_estimated_delivery_date - order_delivered_customer_date)) 
        / 86400)::NUMERIC, 1) AS days_advanced_avg,
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date > order_estimated_delivery_date
    ) AS late_delivery,
    ROUND(
        COUNT(*) FILTER (
            WHERE order_delivered_customer_date > order_estimated_delivery_date
        ) * 100.0 / COUNT(*)
    , 2) AS percent_delayed
FROM olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
--Olist delivery 11 days before than promissed. 1 in 12 orders has a delay
  

--localizatiosn with more delays
 SELECT
    c.customer_state AS state_location,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))
        / 86400)::NUMERIC, 1) AS delivery_days_avg,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (o.order_estimated_delivery_date - o.order_delivered_customer_date))
        / 86400)::NUMERIC, 1) AS days_advanced_avg,
    COUNT(*) FILTER (
        WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
    ) AS delayed_deliverys
FROM olist_orders o
JOIN olist_customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY delivery_days_avg DESC;
--Cities in the north of the country have more delays. This is caused by infraestructure of country and departments

--Reviews distribution
SELECT 
	review_score AS score,
	COUNT(*) AS total_reviews,
	ROUND(COUNT(*)*100.0/SUM(COUNT(*))OVER(),2) AS percentage
FROM olist_order_reviews
GROUP BY review_score
ORDER BY review_score DESC
--Most of the reviews are positive :). Bimodal distribution. Or love the products or hate

--Relation between delay and reviews
SELECT
	CASE
		WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
		THEN 'At time'
	ELSE 'Delayed'
END AS delivery_status,
ROUND(AVG(r.review_score)::NUMERIC,2) AS avg_score,
COUNT(*) AS total_orders
FROM olist_orders AS o
JOIN olist_order_reviews AS r
ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
	AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status

--Most of the delayed orders have a score under 3 stars

