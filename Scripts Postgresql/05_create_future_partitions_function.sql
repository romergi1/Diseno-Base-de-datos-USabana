CREATE OR REPLACE FUNCTION ecommify.create_future_orders_partitions(months_ahead INT DEFAULT 6)
RETURNS void AS
$$
DECLARE
    start_month DATE;
    end_month DATE;
    partition_name TEXT;
    i INT;
BEGIN
    FOR i IN 0..months_ahead LOOP
        start_month := DATE_TRUNC('month', CURRENT_DATE + (i || ' month')::INTERVAL)::DATE;
        end_month := (start_month + INTERVAL '1 month')::DATE;
        partition_name := 'orders_' || TO_CHAR(start_month, 'YYYY_MM');

        EXECUTE FORMAT(
            'CREATE TABLE IF NOT EXISTS ecommify.%I PARTITION OF ecommify.orders_partitioned FOR VALUES FROM (%L) TO (%L);',
            partition_name,
            start_month,
            end_month
        );
    END LOOP;
END;
$$
LANGUAGE plpgsql;
