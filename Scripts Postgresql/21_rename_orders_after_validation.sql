ALTER TABLE ecommify.orders
RENAME TO orders_backup;

ALTER TABLE ecommify.orders_partitioned
RENAME TO orders;
