--DDL: Owner: Carlos Jose Yepes Aristizábal

--1. Customers
CREATE TABLE olist_customers(
	customer_id VARCHAR(50) PRIMARY KEY,
	customer_unique_id VARCHAR(50) NOT NULL,
	customer_zip_code_prefix CHAR(5),
	customer_city VARCHAR(50),
	customer_state CHAR(4)
);

--2. Sellers
CREATE TABLE olist_sellers(
	seller_id VARCHAR(50) PRIMARY KEY,
	seller_zip_code_prefix CHAR(5) NOT NULL,
	seller_city VARCHAR(100),
	seller_state CHAR(2)
);

--3. Product category translation
CREATE TABLE product_category_name_translation(
	product_category_name VARCHAR(100) PRIMARY KEY,
	product_category_name_english VARCHAR(100)
);

--4. Products
CREATE TABLE olist_products(
	product_id VARCHAR(50) PRIMARY KEY,
	product_category_name VARCHAR(100)
	product_name_lenght INTEGER,
	product_description_lenght INTEGER,
	product_photos_qty INTEGER,
	product_weight_g NUMERIC(10,2),
	product_lenght_cm NUMERIC (10,2),
	product_height_cm NUMERIC (10,2),
	product_width_cm NUMERIC(10,2)
);

--5. Orders
CREATE TABLE olist_orders(
	order_id VARCHAR(50) PRIMARY KEY,
	customer_id VARCHAR(50) NOT NULL
		REFERENCES olist_customers(customer_id),
	order_status VARCHAR(30),
	order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

--6. Order items
CREATE TABLE olist_order_items(
	order_id VARCHAR(50) NOT NULL
		REFERENCES olist_orders(order_id),
	order_item_id INTEGER NOT NULL,
	product_id VARCHAR(50)
		REFERENCES olist_products(product_id),
	seller_id VARCHAR(50)
		REFERENCES olist_sellers(seller_id),
	shipping_limit_date TIMESTAMP,
	price NUMERIC(10,2),
	freight_value NUMERIC(10,2),
	PRIMARY KEY(order_id,order_item_id)
);

--7. Order Payments
CREATE TABLE olist_order_payments(
	order_id VARCHAR(50) NOT NULL
		REFERENCES olist_orders(order_id),
	payment_sequential INTEGER NOT NULL,
	payment_type VARCHAR(30),
	payment_installments INTEGER,
	payment_value NUMERIC(10,2),
	PRIMARY KEY (order_id,payment_sequential)

	
);

--8. Order reviews
CREATE TABLE olist_order_reviews(
	review_id VARCHAR(50),
	order_id VARCHAR(50) NOT NULL
		REFERENCES olist_orders(order_id),
	review_score SMALLINT,
	review_comment_title TEXT,
	review_comment_message TEXT,
	review_creation_date TIMESTAMP,
	review_answer_timestamp TIMESTAMP,
	PRIMARY KEY (review_id,order_id)
);

--Index creation - used for improve performance in queries

CREATE INDEX IF NOT EXISTS idx_orders_customer    ON olist_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status      ON olist_orders(order_status);
CREATE INDEX IF NOT EXISTS idx_orders_purchase_ts ON olist_orders(order_purchase_timestamp);
CREATE INDEX IF NOT EXISTS idx_items_product      ON olist_order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_items_seller       ON olist_order_items(seller_id);
CREATE INDEX IF NOT EXISTS idx_reviews_score      ON olist_order_reviews(review_score);


-- Bulk insert using local paths


-- 1. Customers
COPY olist_customers (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
FROM 'C:\olist\olist_customers_dataset.csv'
DELIMITER ';' CSV HEADER ENCODING 'UTF8';

-- 2. Sellers
COPY olist_sellers (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
FROM 'C:\olist\olist_sellers_dataset.csv'
DELIMITER ',' CSV HEADER ENCODING 'UTF8';

-- 3. Product category translate
COPY product_category_name_translation (
    product_category_name,
    product_category_name_english
)
FROM 'C:\olist\product_category_name_translation.csv'
DELIMITER ',' CSV HEADER ENCODING 'UTF8';


-- 4. Products
COPY olist_products (
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_lenght_cm,
    product_height_cm,
    product_width_cm
)
FROM 'C:\olist\olist_products_dataset.csv'
DELIMITER ',' CSV HEADER ENCODING 'UTF8';

-- 5. Orders
COPY olist_orders (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
)
FROM 'C:\olist\olist_orders_dataset.csv'
DELIMITER ',' CSV HEADER ENCODING 'UTF8';

-- 6. Order items
COPY olist_order_items (
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
)
FROM 'C:\olist\olist_order_items_dataset.csv'
DELIMITER ',' CSV HEADER ENCODING 'UTF8';

-- 7. Order payments
COPY olist_order_payments (
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
FROM 'C:\olist\olist_order_payments_dataset.csv'
DELIMITER ',' CSV HEADER ENCODING 'UTF8';

-- 8. Order reviews
COPY olist_order_reviews (
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)
FROM 'C:\olist\olist_order_reviews_dataset.csv'
DELIMITER ',' CSV HEADER ENCODING 'UTF8';

-- Check if data was loades succesfully 

SELECT 'olist_customers' AS tabla, 
COUNT(*) AS filas FROM olist_customers

UNION ALL

SELECT 'olist_sellers',
COUNT(*) FROM olist_sellers

UNION ALL

SELECT 'product_category_name_translation',
COUNT(*) FROM product_category_name_translation

UNION ALL

SELECT 'olist_products',
COUNT(*) FROM olist_products
UNION ALL

SELECT 'olist_orders',
COUNT(*) FROM olist_orders
UNION ALL

SELECT 'olist_order_items',
COUNT(*) FROM olist_order_items
UNION ALL

SELECT 'olist_order_payments',
COUNT(*) FROM olist_order_payments
UNION ALL

SELECT 'olist_order_reviews',
COUNT(*) FROM olist_order_reviews
ORDER BY tabla;