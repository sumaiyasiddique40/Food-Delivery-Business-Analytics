DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100),
    gender VARCHAR(10),
    age INT,
    city VARCHAR(100),
    signup_date DATE,
    customer_segment VARCHAR(50)
);


SELECT * FROM customers;

SELECT COUNT(*) FROM customers;



DROP TABLE IF EXISTS delivery;

CREATE TABLE delivery (
    delivery_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(20),
    delivery_partner_id VARCHAR(20),
    pickup_time TIMESTAMP,
    delivery_time TIMESTAMP,
    estimated_minutes INT,
    actual_minutes INT,
    delivery_status VARCHAR(30),
    distance_km DECIMAL(10,2),
    delay_minutes INT,
    is_late INT
);

SELECT COUNT(*) AS total_deliveries
FROM delivery;


DROP TABLE IF EXISTS delivery_partners;

CREATE TABLE delivery_partners (
    delivery_partner_id VARCHAR(20) PRIMARY KEY,
    partner_name VARCHAR(100),
    vehicle_type VARCHAR(50),
    city VARCHAR(50),
    joining_date DATE,
    rating DECIMAL(3,2)
);

SELECT * FROM delivery_partners;


DROP TABLE IF EXISTS order_items CASCADE;

CREATE TABLE order_items (
    order_item_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(20),
    product_id VARCHAR(20),
    quantity INT,
    unit_price DECIMAL(10,2),
    item_total DECIMAL(10,2)
);

SELECT * FROM order_items;



DROP TABLE IF EXISTS orders CASCADE;

CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    restaurant_id VARCHAR(20),
    order_date DATE,
    order_time TIME,
    order_status VARCHAR(50),
    payment_method VARCHAR(50),
    subtotal DECIMAL(10,2),
    delivery_fee DECIMAL(10,2),
    discount DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    order_month VARCHAR(10),
    order_year INT,
    order_day VARCHAR(20)
);

SELECT * FROM orders;


DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY,
    restaurant_id VARCHAR(20),
    product_name VARCHAR(150),
    category VARCHAR(50),
    price DECIMAL(10,2),
    cost DECIMAL(10,2),
    availability VARCHAR(20)
);

SELECT * FROM products;



DROP TABLE IF EXISTS restaurants CASCADE;

CREATE TABLE restaurants (
    restaurant_id VARCHAR(20) PRIMARY KEY,
    restaurant_name VARCHAR(100),
    cuisine_type VARCHAR(50),
    city VARCHAR(50),
    rating DECIMAL(3,2),
    commission_rate DECIMAL(4,2),
    joining_date DATE
);

SELECT * FROM restaurants;


SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN (
      'customers',
      'restaurants',
      'products',
      'delivery_partners',
      'orders',
      'order_items',
      'delivery'
  )
ORDER BY table_name, ordinal_position;







--Business KPI View

CREATE OR REPLACE VIEW vw_business_kpis AS
SELECT
    COUNT(*) FILTER (
        WHERE order_status = 'Delivered'
    ) AS total_orders,

    COUNT(DISTINCT customer_id) FILTER (
        WHERE order_status = 'Delivered'
    ) AS total_customers,

    ROUND(
        SUM(total_amount) FILTER (
            WHERE order_status = 'Delivered'
        ),
        2
    ) AS total_revenue,

    ROUND(
        AVG(total_amount) FILTER (
            WHERE order_status = 'Delivered'
        ),
        2
    ) AS average_order_value,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE order_status = 'Cancelled'
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate

FROM orders;

SELECT *
FROM vw_business_kpis;


--Monthly Sales View
CREATE OR REPLACE VIEW vw_monthly_sales AS
SELECT
    DATE_TRUNC('month', order_date)::DATE AS month,

    COUNT(*) AS total_orders,

    ROUND(SUM(total_amount), 2) AS revenue,

    ROUND(AVG(total_amount), 2) AS average_order_value

FROM orders

WHERE order_status = 'Delivered'

GROUP BY DATE_TRUNC('month', order_date)

ORDER BY month;

SELECT *
FROM vw_monthly_sales;


--Restaurant Performance View
CREATE OR REPLACE VIEW vw_restaurant_performance AS
SELECT
    r.restaurant_id,
    r.restaurant_name,
    r.city,
    r.cuisine_type,

    COUNT(o.order_id) AS total_orders,

    ROUND(SUM(o.total_amount), 2) AS total_revenue,

    ROUND(AVG(o.total_amount), 2) AS average_order_value

FROM restaurants r

LEFT JOIN orders o
    ON r.restaurant_id = o.restaurant_id
    AND o.order_status = 'Delivered'

GROUP BY
    r.restaurant_id,
    r.restaurant_name,
    r.city,
    r.cuisine_type;

SELECT *
FROM vw_restaurant_performance
ORDER BY total_revenue DESC
LIMIT 10;


--Delivery Performance View
CREATE OR REPLACE VIEW vw_delivery_performance AS
SELECT
    dp.delivery_partner_id,
    dp.partner_name,

    COUNT(d.delivery_id) AS total_deliveries,

    ROUND(AVG(d.actual_minutes), 2) AS avg_delivery_time,

    ROUND(AVG(d.delay_minutes), 2) AS avg_delay_minutes,

    ROUND(
        100.0 * AVG(
            CASE
                WHEN d.is_late = 1 THEN 1
                ELSE 0
            END
        ),
        2
    ) AS late_delivery_rate

FROM delivery_partners dp

LEFT JOIN delivery d
    ON dp.delivery_partner_id = d.delivery_partner_id

GROUP BY
    dp.delivery_partner_id,
    dp.partner_name;


SELECT *
FROM vw_delivery_performance
ORDER BY late_delivery_rate DESC;


--Customer Analysis View
CREATE OR REPLACE VIEW vw_customer_analysis AS
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    c.customer_segment,

    COUNT(o.order_id) FILTER (
        WHERE o.order_status = 'Delivered'
    ) AS total_orders,

    ROUND(
        SUM(o.total_amount) FILTER (
            WHERE o.order_status = 'Delivered'
        ),
        2
    ) AS total_revenue,

    ROUND(
        AVG(o.total_amount) FILTER (
            WHERE o.order_status = 'Delivered'
        ),
        2
    ) AS average_order_value

FROM customers c

LEFT JOIN orders o
    ON c.customer_id = o.customer_id

GROUP BY
    c.customer_id,
    c.customer_name,
    c.city,
    c.customer_segment;

SELECT *
FROM vw_customer_analysis
ORDER BY total_revenue DESC
LIMIT 10;


