EXPLAIN (ANALYZE, BUFFERS)
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    c.customer_state,
    COUNT(*) AS total_orders
FROM ecommify.orders o
JOIN ecommify.customers c
    ON c.customer_id = o.customer_id
WHERE o.order_purchase_timestamp >= DATE '2018-01-01'
  AND o.order_purchase_timestamp < DATE '2018-04-01'
GROUP BY
    DATE_TRUNC('month', o.order_purchase_timestamp),
    c.customer_state
ORDER BY month, total_orders DESC;
