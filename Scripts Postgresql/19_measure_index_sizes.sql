SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    pg_relation_size(indexrelid) AS index_size_bytes
FROM pg_stat_user_indexes
WHERE schemaname = 'ecommify'
ORDER BY pg_relation_size(indexrelid) DESC;
