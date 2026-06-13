SELECT
    parent.relname AS parent_table,
    child.relname AS partition_name,
    CASE
        WHEN child.relname = 'orders_default' THEN 'DEFAULT partition'
        ELSE 'monthly range partition'
    END AS partition_type,
    'Active' AS partition_status
FROM pg_inherits
JOIN pg_class parent
    ON pg_inherits.inhparent = parent.oid
JOIN pg_class child
    ON pg_inherits.inhrelid = child.oid
WHERE parent.relname = 'orders_partitioned'
ORDER BY child.relname;
