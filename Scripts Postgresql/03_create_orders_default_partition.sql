CREATE TABLE IF NOT EXISTS ecommify.orders_default
PARTITION OF ecommify.orders_partitioned
DEFAULT;
