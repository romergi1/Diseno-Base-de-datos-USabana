CREATE TABLE IF NOT EXISTS ecommify.orders_partitioned (
    order_id TEXT NOT NULL,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    PRIMARY KEY (order_id, order_purchase_timestamp)
)
PARTITION BY RANGE (order_purchase_timestamp);
