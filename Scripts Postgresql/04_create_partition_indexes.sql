CREATE INDEX IF NOT EXISTS idx_orders_partitioned_customer_id
ON ecommify.orders_partitioned (customer_id);

CREATE INDEX IF NOT EXISTS idx_orders_partitioned_status
ON ecommify.orders_partitioned (order_status);

CREATE INDEX IF NOT EXISTS idx_orders_partitioned_purchase_timestamp
ON ecommify.orders_partitioned (order_purchase_timestamp);

CREATE INDEX IF NOT EXISTS idx_orders_partitioned_estimated_delivery
ON ecommify.orders_partitioned (order_estimated_delivery_date);

CREATE INDEX IF NOT EXISTS idx_orders_partitioned_delivered_customer
ON ecommify.orders_partitioned (order_delivered_customer_date);

CREATE INDEX IF NOT EXISTS idx_orders_partitioned_status_delivery_dates
ON ecommify.orders_partitioned (
    order_status,
    order_estimated_delivery_date,
    order_delivered_customer_date
);
