CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule(
    'create_future_orders_partitions_monthly',
    '0 2 1 * *',
    $$SELECT ecommify.create_future_orders_partitions(6);$$
);
