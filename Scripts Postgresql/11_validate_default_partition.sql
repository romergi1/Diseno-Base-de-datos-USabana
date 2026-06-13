SELECT
    'orders_default' AS partition_name,
    COUNT(*) AS records_in_default,
    CASE
        WHEN COUNT(*) = 0 THEN 'OK - no out-of-range records'
        ELSE 'Review required - records outside monthly ranges'
    END AS validation_status
FROM ecommify.orders_default;
