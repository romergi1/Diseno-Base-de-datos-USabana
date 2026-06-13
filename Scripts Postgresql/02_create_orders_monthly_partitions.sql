CREATE TABLE IF NOT EXISTS ecommify.orders_2016_09
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2016-09-01') TO ('2016-10-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2016_10
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2016-10-01') TO ('2016-11-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2016_11
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2016-11-01') TO ('2016-12-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2016_12
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2016-12-01') TO ('2017-01-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2017_01
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2017-01-01') TO ('2017-02-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2017_02
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2017-02-01') TO ('2017-03-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2017_03
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2017-03-01') TO ('2017-04-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2017_04
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2017-04-01') TO ('2017-05-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2017_05
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2017-05-01') TO ('2017-06-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2017_06
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2017-06-01') TO ('2017-07-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2017_07
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2017-07-01') TO ('2017-08-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2017_08
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2017-08-01') TO ('2017-09-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2017_09
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2017-09-01') TO ('2017-10-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2017_10
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2017-10-01') TO ('2017-11-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2017_11
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2017-11-01') TO ('2017-12-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2017_12
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2017-12-01') TO ('2018-01-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2018_01
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2018-01-01') TO ('2018-02-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2018_02
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2018-02-01') TO ('2018-03-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2018_03
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2018-03-01') TO ('2018-04-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2018_04
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2018-04-01') TO ('2018-05-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2018_05
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2018-05-01') TO ('2018-06-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2018_06
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2018-06-01') TO ('2018-07-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2018_07
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2018-07-01') TO ('2018-08-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2018_08
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2018-08-01') TO ('2018-09-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2018_09
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2018-09-01') TO ('2018-10-01');

CREATE TABLE IF NOT EXISTS ecommify.orders_2018_10
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2018-10-01') TO ('2018-11-01');
