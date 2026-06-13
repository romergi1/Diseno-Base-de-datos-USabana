SELECT
    'orders_original' AS table_name,
    COUNT(*) AS total_records
FROM ecommify.orders

UNION ALL

SELECT
    'orders_partitioned' AS table_name,
    COUNT(*) AS total_records
FROM ecommify.orders_partitioned;
