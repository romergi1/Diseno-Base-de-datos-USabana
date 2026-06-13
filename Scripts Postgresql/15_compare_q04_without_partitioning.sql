EXPLAIN (ANALYZE, BUFFERS)
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_estimated_delivery_date
FROM ecommify.orders o
WHERE o.order_status IN ('created', 'approved', 'processing', 'shipped')
  AND o.order_estimated_delivery_date >= DATE '2018-01-01'
  AND o.order_estimated_delivery_date < DATE '2018-04-01'
ORDER BY o.order_estimated_delivery_date;
