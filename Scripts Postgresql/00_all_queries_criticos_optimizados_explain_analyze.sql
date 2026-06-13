EXPLAIN (ANALYZE, BUFFERS)
WITH target_order AS (
    SELECT o.order_id, o.customer_id, o.order_status, o.order_purchase_timestamp, o.order_approved_at,
           o.order_delivered_carrier_date, o.order_delivered_customer_date, o.order_estimated_delivery_date
    FROM ecommify.orders_partitioned o
    WHERE o.order_id = '00010242fe8c5a6d1ba2dd792cb16214'
    LIMIT 1
),
items_summary AS (
    SELECT oi.order_id, COUNT(*) AS total_items, SUM(oi.price) AS total_items_value,
           SUM(oi.freight_value) AS total_freight_value
    FROM ecommify.order_items oi
    WHERE oi.order_id = '00010242fe8c5a6d1ba2dd792cb16214'
    GROUP BY oi.order_id
),
payments_summary AS (
    SELECT op.order_id, COUNT(*) AS total_payments, SUM(op.payment_value) AS total_payment_value,
           MAX(op.payment_installments) AS max_installments
    FROM ecommify.order_payments op
    WHERE op.order_id = '00010242fe8c5a6d1ba2dd792cb16214'
    GROUP BY op.order_id
),
reviews_summary AS (
    SELECT r.order_id, AVG(r.review_score) AS average_review_score, COUNT(*) AS total_reviews
    FROM ecommify.order_reviews r
    WHERE r.order_id = '00010242fe8c5a6d1ba2dd792cb16214'
    GROUP BY r.order_id
)
SELECT o.order_id, o.order_status, o.order_purchase_timestamp, c.customer_id, c.customer_unique_id,
       c.customer_city, c.customer_state, COALESCE(i.total_items, 0) AS total_items,
       COALESCE(i.total_items_value, 0) AS total_items_value,
       COALESCE(i.total_freight_value, 0) AS total_freight_value,
       COALESCE(p.total_payments, 0) AS total_payments,
       COALESCE(p.total_payment_value, 0) AS total_payment_value,
       p.max_installments, r.average_review_score, COALESCE(r.total_reviews, 0) AS total_reviews
FROM target_order o
JOIN ecommify.customers c ON c.customer_id = o.customer_id
LEFT JOIN items_summary i ON i.order_id = o.order_id
LEFT JOIN payments_summary p ON p.order_id = o.order_id
LEFT JOIN reviews_summary r ON r.order_id = o.order_id;

EXPLAIN (ANALYZE, BUFFERS)
WITH target_customer AS (
    SELECT c.customer_id, c.customer_unique_id, c.customer_city, c.customer_state
    FROM ecommify.customers c
    WHERE c.customer_unique_id = '871766c5855e863f6eccc05f988b23cb'
),
customer_orders AS (
    SELECT o.order_id, o.customer_id, o.order_status, o.order_purchase_timestamp,
           o.order_delivered_customer_date, o.order_estimated_delivery_date
    FROM ecommify.orders_partitioned o
    JOIN target_customer c ON c.customer_id = o.customer_id
    WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
      AND o.order_purchase_timestamp < DATE '2019-01-01'
),
payments_summary AS (
    SELECT op.order_id, SUM(op.payment_value) AS payment_value
    FROM ecommify.order_payments op
    JOIN customer_orders co ON co.order_id = op.order_id
    GROUP BY op.order_id
)
SELECT c.customer_unique_id, c.customer_city, c.customer_state,
       COUNT(co.order_id) AS total_orders,
       COUNT(*) FILTER (WHERE co.order_status = 'delivered') AS delivered_orders,
       COUNT(*) FILTER (WHERE co.order_delivered_customer_date > co.order_estimated_delivery_date) AS late_orders,
       COALESCE(SUM(p.payment_value), 0) AS total_payment_value,
       MIN(co.order_purchase_timestamp) AS first_order_date,
       MAX(co.order_purchase_timestamp) AS last_order_date
FROM target_customer c
LEFT JOIN customer_orders co ON co.customer_id = c.customer_id
LEFT JOIN payments_summary p ON p.order_id = co.order_id
GROUP BY c.customer_unique_id, c.customer_city, c.customer_state;

EXPLAIN (ANALYZE, BUFFERS)
WITH orders_filtered AS (
    SELECT o.order_id, o.customer_id, DATE_TRUNC('month', o.order_purchase_timestamp) AS sales_month
    FROM ecommify.orders_partitioned o
    WHERE o.order_purchase_timestamp >= DATE '2018-01-01'
      AND o.order_purchase_timestamp < DATE '2018-04-01'
      AND o.order_status = 'delivered'
),
items_summary AS (
    SELECT oi.order_id, SUM(oi.price) AS total_sales, SUM(oi.freight_value) AS total_freight
    FROM ecommify.order_items oi
    JOIN orders_filtered o ON o.order_id = oi.order_id
    GROUP BY oi.order_id
)
SELECT o.sales_month, c.customer_state, COUNT(DISTINCT o.order_id) AS total_orders,
       SUM(i.total_sales) AS total_sales, SUM(i.total_freight) AS total_freight,
       SUM(i.total_sales + i.total_freight) AS gross_value
FROM orders_filtered o
JOIN ecommify.customers c ON c.customer_id = o.customer_id
JOIN items_summary i ON i.order_id = o.order_id
GROUP BY o.sales_month, c.customer_state
ORDER BY o.sales_month, total_sales DESC;

EXPLAIN (ANALYZE, BUFFERS)
SELECT o.order_id, o.customer_id, c.customer_city, c.customer_state, o.order_status,
       o.order_purchase_timestamp, o.order_estimated_delivery_date, o.order_delivered_customer_date,
       CASE
           WHEN o.order_delivered_customer_date IS NULL
                AND o.order_estimated_delivery_date < CURRENT_DATE THEN 'Overdue'
           WHEN o.order_delivered_customer_date IS NULL
                AND o.order_estimated_delivery_date <= CURRENT_DATE + INTERVAL '3 days' THEN 'Near risk'
           ELSE 'On track'
       END AS logistics_risk_status
FROM ecommify.orders_partitioned o
JOIN ecommify.customers c ON c.customer_id = o.customer_id
WHERE o.order_purchase_timestamp >= DATE '2018-01-01'
  AND o.order_purchase_timestamp < DATE '2018-04-01'
  AND o.order_status IN ('created', 'approved', 'processing', 'shipped')
  AND o.order_estimated_delivery_date IS NOT NULL
ORDER BY o.order_estimated_delivery_date, logistics_risk_status;

EXPLAIN (ANALYZE, BUFFERS)
WITH delivered_orders AS (
    SELECT o.order_id, o.customer_id, o.order_purchase_timestamp, o.order_estimated_delivery_date,
           o.order_delivered_customer_date,
           EXTRACT(DAY FROM o.order_delivered_customer_date - o.order_estimated_delivery_date) AS delay_days
    FROM ecommify.orders_partitioned o
    WHERE o.order_purchase_timestamp >= DATE '2018-01-01'
      AND o.order_purchase_timestamp < DATE '2018-04-01'
      AND o.order_status = 'delivered'
      AND o.order_delivered_customer_date > o.order_estimated_delivery_date
)
SELECT c.customer_state, c.customer_city, COUNT(*) AS late_orders,
       ROUND(AVG(d.delay_days), 2) AS average_delay_days,
       MAX(d.delay_days) AS max_delay_days,
       MIN(d.delay_days) AS min_delay_days
FROM delivered_orders d
JOIN ecommify.customers c ON c.customer_id = d.customer_id
GROUP BY c.customer_state, c.customer_city
ORDER BY late_orders DESC, average_delay_days DESC;
