EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_state,
    c.customer_city,
    COUNT(*) AS late_orders
FROM ecommify.orders_partitioned o
JOIN ecommify.customers c
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date > o.order_estimated_delivery_date
  AND o.order_purchase_timestamp >= DATE '2018-01-01'
  AND o.order_purchase_timestamp < DATE '2018-04-01'
GROUP BY
    c.customer_state,
    c.customer_city
ORDER BY late_orders DESC;
