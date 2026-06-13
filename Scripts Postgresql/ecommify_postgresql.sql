-- =============================================================
--  ECOMMIFY — ESQUEMA POSTGRESQL (3NF)
--  Dataset: Brazilian Olist Public Dataset
--  Universidad de la Sabana
--  Motor: PostgreSQL 15+
--  Extensiones requeridas: PostGIS, pg_trgm, pgcrypto, hstore
-- =============================================================

-- -------------------------------------------------------------
-- 0. EXTENSIONES
-- -------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS hstore;

-- -------------------------------------------------------------
-- 1. SCHEMA
-- -------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS ecommify;
SET search_path = ecommify, public;

-- =============================================================
--  TABLAS MAESTRAS
-- =============================================================

-- -------------------------------------------------------------
-- 1.1 CATEGORÍAS DE PRODUCTO
--     Tabla de lookup: nombre en portugués + traducción al inglés
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product_categories (
    category_id          SERIAL PRIMARY KEY,
    category_name        VARCHAR(100) NOT NULL UNIQUE,          -- nombre original (pt-BR)
    category_name_en     VARCHAR(100),                          -- traducción al inglés
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  product_categories            IS 'Catálogo de categorías de producto (fuente: product_category_name_translation.csv)';
COMMENT ON COLUMN product_categories.category_name    IS 'Nombre original en portugués brasileño';
COMMENT ON COLUMN product_categories.category_name_en IS 'Traducción al inglés';

-- -------------------------------------------------------------
-- 1.2 GEOLOCALIZACIÓN
--     Tabla de referencia geográfica por código postal.
--     PostGIS: columna geometry para consultas espaciales.
--     Un zip code puede tener múltiples coordenadas → PK compuesta.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS geolocations (
    geolocation_id          BIGSERIAL PRIMARY KEY,
    zip_code_prefix         VARCHAR(8)    NOT NULL,
    city                    VARCHAR(100)  NOT NULL,
    state                   CHAR(2)       NOT NULL,
    lat                     NUMERIC(10,7) NOT NULL,
    lng                     NUMERIC(10,7) NOT NULL,
    geom                    GEOMETRY(Point, 4326),               -- PostGIS: SRID 4326 (WGS84)
    created_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  geolocations             IS 'Coordenadas GPS por prefijo de código postal (fuente: olist_geolocation_dataset.csv)';
COMMENT ON COLUMN geolocations.geom        IS 'Punto geográfico PostGIS (SRID 4326). Generado desde lat/lng en trigger.';
COMMENT ON COLUMN geolocations.state       IS 'Código de estado brasileño (UF), 2 caracteres';

CREATE INDEX IF NOT EXISTS idx_geo_zip      ON geolocations (zip_code_prefix);
CREATE INDEX IF NOT EXISTS idx_geo_state    ON geolocations (state);
CREATE INDEX IF NOT EXISTS idx_geo_geom     ON geolocations USING GIST (geom);

-- Trigger: poblar geom automáticamente desde lat/lng
CREATE OR REPLACE FUNCTION ecommify.fn_set_geom()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.geom := ST_SetSRID(ST_MakePoint(NEW.lng::float, NEW.lat::float), 4326);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_geolocations_geom ON geolocations;
CREATE TRIGGER trg_geolocations_geom
    BEFORE INSERT OR UPDATE OF lat, lng ON geolocations
    FOR EACH ROW EXECUTE FUNCTION ecommify.fn_set_geom();

-- -------------------------------------------------------------
-- 1.3 CLIENTES
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    customer_id         VARCHAR(36)  PRIMARY KEY,               -- UUID del sistema Olist
    customer_unique_id  VARCHAR(36)  NOT NULL,                  -- ID real del cliente (permite recompras)
    zip_code_prefix     VARCHAR(8)   NOT NULL,
    city                VARCHAR(100) NOT NULL,
    state               CHAR(2)      NOT NULL,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  customers                     IS 'Clientes del ecommerce (fuente: olist_customers_dataset.csv)';
COMMENT ON COLUMN customers.customer_id         IS 'Identificador único por transacción (cambia en cada pedido del mismo cliente)';
COMMENT ON COLUMN customers.customer_unique_id  IS 'Identificador real del cliente — usado para análisis de recompra';

CREATE INDEX IF NOT EXISTS idx_customers_unique_id  ON customers (customer_unique_id);
CREATE INDEX IF NOT EXISTS idx_customers_state       ON customers (state);
CREATE INDEX IF NOT EXISTS idx_customers_city        ON customers USING GIN (to_tsvector('simple', city));

-- Trigger: actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION ecommify.fn_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_customers_updated ON customers;
CREATE TRIGGER trg_customers_updated
    BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION ecommify.fn_set_updated_at();

-- -------------------------------------------------------------
-- 1.4 SELLERS (VENDEDORES)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sellers (
    seller_id           VARCHAR(36)  PRIMARY KEY,
    zip_code_prefix     VARCHAR(8)   NOT NULL,
    city                VARCHAR(100) NOT NULL,
    state               CHAR(2)      NOT NULL,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE sellers IS 'Vendedores registrados en la plataforma (fuente: olist_sellers_dataset.csv)';

CREATE INDEX IF NOT EXISTS idx_sellers_state ON sellers (state);
CREATE INDEX IF NOT EXISTS idx_sellers_city  ON sellers USING GIN (to_tsvector('simple', city));

DROP TRIGGER IF EXISTS trg_sellers_updated ON sellers;
CREATE TRIGGER trg_sellers_updated
    BEFORE UPDATE ON sellers
    FOR EACH ROW EXECUTE FUNCTION ecommify.fn_set_updated_at();

-- -------------------------------------------------------------
-- 1.5 PRODUCTOS
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    product_id                  VARCHAR(36)  PRIMARY KEY,
    category_id                 INT          REFERENCES product_categories(category_id) ON DELETE SET NULL,
    product_name_length         SMALLINT     CHECK (product_name_length > 0),
    product_description_length  INT          CHECK (product_description_length >= 0),
    product_photos_qty          SMALLINT     CHECK (product_photos_qty >= 0),
    weight_g                    INT          CHECK (weight_g > 0),
    length_cm                   SMALLINT     CHECK (length_cm > 0),
    height_cm                   SMALLINT     CHECK (height_cm > 0),
    width_cm                    SMALLINT     CHECK (width_cm > 0),
    -- Metadatos adicionales con hstore (extensible sin ALTER TABLE)
    extra_attributes            HSTORE,
    created_at                  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  products                          IS 'Catálogo de productos (fuente: olist_products_dataset.csv)';
COMMENT ON COLUMN products.extra_attributes         IS 'Atributos adicionales flexibles via hstore (ej: material, color, brand)';
COMMENT ON COLUMN products.product_name_length      IS 'Longitud en caracteres del nombre del producto';
COMMENT ON COLUMN products.product_description_length IS 'Longitud en caracteres de la descripción';

CREATE INDEX IF NOT EXISTS idx_products_category    ON products (category_id);
CREATE INDEX IF NOT EXISTS idx_products_weight      ON products (weight_g);
CREATE INDEX IF NOT EXISTS idx_products_hstore      ON products USING GIN (extra_attributes);

DROP TRIGGER IF EXISTS trg_products_updated ON products;
CREATE TRIGGER trg_products_updated
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION ecommify.fn_set_updated_at();

-- =============================================================
--  TABLAS TRANSACCIONALES
-- =============================================================

-- -------------------------------------------------------------
-- 2.1 ÓRDENES
-- -------------------------------------------------------------
CREATE TYPE ecommify.order_status_enum AS ENUM (
    'created', 'approved', 'invoiced', 'processing',
    'shipped', 'delivered', 'unavailable', 'canceled'
);

CREATE TABLE IF NOT EXISTS orders (
    order_id                        VARCHAR(36)  PRIMARY KEY,
    customer_id                     VARCHAR(36)  NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    order_status                    ecommify.order_status_enum NOT NULL DEFAULT 'created',
    purchase_timestamp              TIMESTAMPTZ  NOT NULL,
    approved_at                     TIMESTAMPTZ,
    delivered_carrier_date          TIMESTAMPTZ,
    delivered_customer_date         TIMESTAMPTZ,
    estimated_delivery_date         TIMESTAMPTZ,
    -- Columnas derivadas calculadas (actualizadas por trigger)
    delivery_days                   SMALLINT     GENERATED ALWAYS AS (
                                        CASE
                                            WHEN delivered_customer_date IS NOT NULL
                                            THEN EXTRACT(DAY FROM delivered_customer_date - purchase_timestamp)::SMALLINT
                                        END
                                    ) STORED,
    is_delivered_on_time            BOOLEAN      GENERATED ALWAYS AS (
                                        CASE
                                            WHEN delivered_customer_date IS NOT NULL AND estimated_delivery_date IS NOT NULL
                                            THEN delivered_customer_date <= estimated_delivery_date
                                        END
                                    ) STORED,
    created_at                      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at                      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_approved_after_purchase
        CHECK (approved_at IS NULL OR approved_at >= purchase_timestamp),
    CONSTRAINT chk_delivery_after_approved
        CHECK (delivered_carrier_date IS NULL OR approved_at IS NULL
               OR delivered_carrier_date >= approved_at)
);

COMMENT ON TABLE  orders                         IS 'Órdenes de compra del ecommerce (fuente: olist_orders_dataset.csv)';
COMMENT ON COLUMN orders.delivery_days           IS 'Días totales desde compra hasta entrega (columna generada)';
COMMENT ON COLUMN orders.is_delivered_on_time    IS 'TRUE si la entrega fue antes o igual a la fecha estimada (columna generada)';

-- Particionamiento por fecha de compra (RANGE mensual)
-- Nota: para activar particionamiento real, convertir a tabla particionada
-- y crear particiones por año: orders_2016, orders_2017, orders_2018

CREATE INDEX IF NOT EXISTS idx_orders_customer      ON orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status        ON orders (order_status);
CREATE INDEX IF NOT EXISTS idx_orders_purchase_ts   ON orders (purchase_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_orders_delivered_ts  ON orders (delivered_customer_date DESC)
    WHERE delivered_customer_date IS NOT NULL;
-- BRIN index para queries sobre rangos de fecha (tablas grandes ordenadas por tiempo)
CREATE INDEX IF NOT EXISTS idx_orders_purchase_brin ON orders USING BRIN (purchase_timestamp);

DROP TRIGGER IF EXISTS trg_orders_updated ON orders;
CREATE TRIGGER trg_orders_updated
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION ecommify.fn_set_updated_at();

-- -------------------------------------------------------------
-- 2.2 ÍTEMS DE ORDEN
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_items (
    order_id              VARCHAR(36)   NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    order_item_id         SMALLINT      NOT NULL CHECK (order_item_id >= 1),
    product_id            VARCHAR(36)   NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    seller_id             VARCHAR(36)   NOT NULL REFERENCES sellers(seller_id) ON DELETE RESTRICT,
    shipping_limit_date   TIMESTAMPTZ   NOT NULL,
    price                 NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    freight_value         NUMERIC(10,2) NOT NULL CHECK (freight_value >= 0),
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    PRIMARY KEY (order_id, order_item_id)
);

COMMENT ON TABLE  order_items               IS 'Líneas de ítem dentro de cada orden (fuente: olist_order_items_dataset.csv)';
COMMENT ON COLUMN order_items.order_item_id IS 'Número secuencial del ítem dentro de la orden (empieza en 1)';
COMMENT ON COLUMN order_items.price         IS 'Precio unitario del producto en BRL';
COMMENT ON COLUMN order_items.freight_value IS 'Costo de flete en BRL';

CREATE INDEX IF NOT EXISTS idx_items_product  ON order_items (product_id);
CREATE INDEX IF NOT EXISTS idx_items_seller   ON order_items (seller_id);
CREATE INDEX IF NOT EXISTS idx_items_price    ON order_items (price);

-- -------------------------------------------------------------
-- 2.3 PAGOS
-- -------------------------------------------------------------
CREATE TYPE ecommify.payment_type_enum AS ENUM (
    'credit_card', 'debit_card', 'boleto', 'voucher', 'not_defined'
);

CREATE TABLE IF NOT EXISTS order_payments (
    order_id              VARCHAR(36)               NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    payment_sequential    SMALLINT                  NOT NULL CHECK (payment_sequential >= 1),
    payment_type          ecommify.payment_type_enum NOT NULL,
    payment_installments  SMALLINT                  NOT NULL CHECK (payment_installments >= 0),
    payment_value         NUMERIC(10,2)             NOT NULL CHECK (payment_value >= 0),
    created_at            TIMESTAMPTZ               NOT NULL DEFAULT NOW(),

    PRIMARY KEY (order_id, payment_sequential)
);

COMMENT ON TABLE  order_payments                     IS 'Pagos asociados a cada orden (fuente: olist_order_payments_dataset.csv)';
COMMENT ON COLUMN order_payments.payment_sequential  IS 'Secuencia del pago cuando una orden tiene múltiples formas de pago';
COMMENT ON COLUMN order_payments.payment_installments IS 'Número de cuotas (0 = pago no fraccionado)';

CREATE INDEX IF NOT EXISTS idx_payments_type  ON order_payments (payment_type);

-- =============================================================
--  VISTAS MATERIALIZADAS (OLAP / REPORTING)
-- =============================================================

-- -------------------------------------------------------------
-- MV 1: Revenue mensual agregado
-- -------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_monthly_revenue AS
SELECT
    DATE_TRUNC('month', o.purchase_timestamp)   AS month,
    COUNT(DISTINCT o.order_id)                  AS total_orders,
    COUNT(oi.order_item_id)                     AS total_items,
    ROUND(SUM(oi.price)::NUMERIC, 2)            AS revenue_brl,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2)    AS freight_brl,
    ROUND(AVG(oi.price)::NUMERIC, 2)            AS avg_item_price,
    ROUND(
        SUM(oi.price) / NULLIF(COUNT(DISTINCT o.order_id), 0)::NUMERIC,
    2)                                          AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY DATE_TRUNC('month', o.purchase_timestamp)
ORDER BY month;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_monthly_revenue_month ON mv_monthly_revenue (month);

-- -------------------------------------------------------------
-- MV 2: Performance por categoría
-- -------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_category_performance AS
SELECT
    pc.category_name_en                             AS category,
    COUNT(DISTINCT oi.order_id)                     AS total_orders,
    COUNT(oi.order_item_id)                         AS units_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2)                AS revenue_brl,
    ROUND(AVG(oi.price)::NUMERIC, 2)                AS avg_price,
    ROUND(AVG(oi.freight_value)::NUMERIC, 2)        AS avg_freight,
    ROUND(
        AVG(oi.freight_value) / NULLIF(AVG(oi.price), 0) * 100
    ::NUMERIC, 2)                                   AS freight_pct
FROM order_items oi
JOIN products p    ON oi.product_id  = p.product_id
JOIN product_categories pc ON p.category_id = pc.category_id
GROUP BY pc.category_name_en
ORDER BY revenue_brl DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_category_perf ON mv_category_performance (category);

-- -------------------------------------------------------------
-- MV 3: Performance por seller
-- -------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_seller_performance AS
SELECT
    s.seller_id,
    s.state                                         AS seller_state,
    s.city                                          AS seller_city,
    COUNT(DISTINCT oi.order_id)                     AS total_orders,
    COUNT(oi.order_item_id)                         AS units_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2)                AS revenue_brl,
    ROUND(AVG(oi.price)::NUMERIC, 2)                AS avg_price,
    ROUND(AVG(r.review_score)::NUMERIC, 2)          AS avg_review_score
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
JOIN orders     o   ON oi.order_id = o.order_id
LEFT JOIN (
    SELECT order_id, AVG(review_score) AS review_score
    FROM ecommify.order_reviews_summary
    GROUP BY order_id
) r ON o.order_id = r.order_id
GROUP BY s.seller_id, s.state, s.city
ORDER BY revenue_brl DESC;

-- Nota: mv_seller_performance depende de order_reviews_summary (ver más abajo)
-- Se debe crear DESPUÉS de cargar los datos de reviews desde MongoDB o vista plana

-- =============================================================
--  FUNCIONES Y PROCEDIMIENTOS ÚTILES
-- =============================================================

-- Función: calcular distancia en km entre seller y cliente de una orden
CREATE OR REPLACE FUNCTION ecommify.fn_order_distance_km(p_order_id VARCHAR)
RETURNS NUMERIC LANGUAGE plpgsql AS $$
DECLARE
    v_dist NUMERIC;
BEGIN
    SELECT
        ROUND(
            ST_Distance(
                g_seller.geom::geography,
                g_customer.geom::geography
            ) / 1000.0, 2
        )
    INTO v_dist
    FROM orders o
    JOIN customers c      ON o.customer_id  = c.customer_id
    JOIN order_items oi   ON o.order_id     = oi.order_id
    JOIN sellers s        ON oi.seller_id   = s.seller_id
    JOIN LATERAL (
        SELECT geom FROM geolocations
        WHERE zip_code_prefix = s.zip_code_prefix
        LIMIT 1
    ) g_seller ON TRUE
    JOIN LATERAL (
        SELECT geom FROM geolocations
        WHERE zip_code_prefix = c.zip_code_prefix
        LIMIT 1
    ) g_customer ON TRUE
    WHERE o.order_id = p_order_id
    LIMIT 1;

    RETURN COALESCE(v_dist, 0);
END;
$$;

COMMENT ON FUNCTION ecommify.fn_order_distance_km IS
    'Calcula la distancia en km entre el seller y el cliente de una orden usando PostGIS ST_Distance';

-- Función: refresh de vistas materializadas
CREATE OR REPLACE PROCEDURE ecommify.sp_refresh_all_mvs()
LANGUAGE plpgsql AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY ecommify.mv_monthly_revenue;
    REFRESH MATERIALIZED VIEW CONCURRENTLY ecommify.mv_category_performance;
    RAISE NOTICE 'Vistas materializadas actualizadas: %', NOW();
END;
$$;

-- =============================================================
--  TABLA AUXILIAR: resumen de reviews (bridge con MongoDB)
--  Se mantiene como tabla plana para joins desde PostgreSQL
--  sin necesidad de consultar MongoDB en tiempo real.
-- =============================================================
CREATE TABLE IF NOT EXISTS order_reviews_summary (
    review_id             VARCHAR(36)   PRIMARY KEY,
    order_id              VARCHAR(36)   NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    review_score          SMALLINT      NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    has_comment_title     BOOLEAN       NOT NULL DEFAULT FALSE,
    has_comment_message   BOOLEAN       NOT NULL DEFAULT FALSE,
    review_creation_date  TIMESTAMPTZ   NOT NULL,
    review_answer_ts      TIMESTAMPTZ,
    -- Referencia al documento completo en MongoDB
    mongo_doc_id          VARCHAR(36),
    synced_at             TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  order_reviews_summary           IS 'Resumen de reviews para joins en PostgreSQL. Documentos completos en MongoDB (colección: reviews).';
COMMENT ON COLUMN order_reviews_summary.mongo_doc_id IS 'ObjectId del documento completo en colección MongoDB reviews';

CREATE INDEX IF NOT EXISTS idx_reviews_order_id  ON order_reviews_summary (order_id);
CREATE INDEX IF NOT EXISTS idx_reviews_score     ON order_reviews_summary (review_score);

-- =============================================================
--  CARGA DE DATOS DESDE CSV
--  Ejecutar con usuario con permisos SUPERUSER o pg_read_server_files
-- =============================================================

-- Ajustar las rutas según el entorno de carga
-- COPY ecommify.product_categories (category_name, category_name_en)
-- FROM '/data/product_category_name_translation.csv'
-- WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- COPY ecommify.geolocations (zip_code_prefix, lat, lng, city, state)
-- FROM '/data/olist_geolocation_dataset.csv'
-- WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- COPY ecommify.customers (customer_id, customer_unique_id, zip_code_prefix, city, state)
-- FROM '/data/olist_customers_dataset.csv'
-- WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- COPY ecommify.sellers (seller_id, zip_code_prefix, city, state)
-- FROM '/data/olist_sellers_dataset.csv'
-- WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- COPY ecommify.products (
--     product_id, category_name_raw, product_name_length,
--     product_description_length, product_photos_qty,
--     weight_g, length_cm, height_cm, width_cm
-- )
-- FROM '/data/olist_products_dataset.csv'
-- WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- COPY ecommify.orders (
--     order_id, customer_id, order_status,
--     purchase_timestamp, approved_at, delivered_carrier_date,
--     delivered_customer_date, estimated_delivery_date
-- )
-- FROM '/data/olist_orders_dataset.csv'
-- WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '', ENCODING 'UTF8');

-- COPY ecommify.order_items (
--     order_id, order_item_id, product_id, seller_id,
--     shipping_limit_date, price, freight_value
-- )
-- FROM '/data/olist_order_items_dataset.csv'
-- WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- COPY ecommify.order_payments (
--     order_id, payment_sequential, payment_type,
--     payment_installments, payment_value
-- )
-- FROM '/data/olist_order_payments_dataset.csv'
-- WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- =============================================================
--  ACTUALIZAR CATEGORÍAS (join post-carga)
-- =============================================================
-- UPDATE ecommify.products p
-- SET category_id = pc.category_id
-- FROM ecommify.product_categories pc
-- WHERE p.category_name_raw = pc.category_name;

-- =============================================================
--  ÍNDICES ADICIONALES pg_trgm (búsqueda fuzzy de texto)
-- =============================================================
CREATE INDEX IF NOT EXISTS idx_trgm_customer_city ON customers USING GIN (city gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_trgm_seller_city   ON sellers   USING GIN (city gin_trgm_ops);

-- Ejemplo de uso:
-- SELECT * FROM customers WHERE city % 'sao paulo';
-- SELECT * FROM customers WHERE city ILIKE '%paulo%';

-- =============================================================
--  FIN DEL SCRIPT
-- =============================================================
-- Tablas PostgreSQL:
--   product_categories  → catálogo estable, joins frecuentes
--   geolocations        → datos espaciales, PostGIS
--   customers           → datos demográficos estructurados
--   sellers             → perfil de vendedores
--   products            → atributos físicos, hstore para extra
--   orders              → ciclo de vida transaccional
--   order_items         → líneas de venta (hecho principal)
--   order_payments      → métodos y valores de pago
--   order_reviews_summary → puente con MongoDB (score + metadata)
--
-- Colecciones MongoDB (ver ecommify_mongodb.js):
--   reviews             → documentos completos con texto libre
--   seller_metrics      → métricas analíticas pre-agregadas
--   geolocation_clusters → clustering espacial pre-calculado
-- =============================================================
