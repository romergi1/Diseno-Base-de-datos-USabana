SELECT
    tableoid::regclass AS partition_name,
    COUNT(*) AS total_records
FROM ecommify.orders_partitioned
GROUP BY tableoid::regclass
ORDER BY partition_name;
