# Diseño de Base de Datos - Ecommify

Repositorio académico para el diseño, implementación, análisis y optimización de una arquitectura de base de datos híbrida para **Ecommify**, integrando **PostgreSQL/Supabase** para el núcleo transaccional y **MongoDB Atlas** para escenarios documentales, agregados y análisis complementario.

## Objetivo

Diseñar e implementar una solución de base de datos para un escenario ecommerce, aplicando modelado relacional, modelado documental, carga de datasets, indexación, particionamiento, análisis de rendimiento, consistencia, disponibilidad y evidencias cuantitativas.

## Estructura del repositorio

```text
Diseno-Base-de-datos-USabana/
├── Colab/
├── Documento de la solución de la actividad/
├── Evidencias Imagenes/
├── Scripts Mongo/
├── Scripts Postgresql/
└── README.md
```

## Tecnologías

| Componente | Tecnología |
|---|---|
| Base relacional | PostgreSQL / Supabase |
| Base documental | MongoDB Atlas |
| Análisis | Google Colab / Python |
| Librerías Python | pandas, sqlalchemy, psycopg2-binary, pymongo |
| Evidencias | Supabase SQL Editor, MongoDB Atlas, Colab |
| Dataset | Olist ecommerce adaptado a Ecommify |

## Prerrequisitos

- Cuenta en Supabase.
- Proyecto PostgreSQL en Supabase.
- Cuenta en MongoDB Atlas.
- Clúster MongoDB creado.
- Python 3.9 o superior.
- Google Colab o ambiente local.
- Cliente `psql`.
- Git instalado.

## Clonar repositorio

```bash
git clone https://github.com/romergi1/Diseno-Base-de-datos-USabana.git
cd Diseno-Base-de-datos-USabana
```

## Setup PostgreSQL / Supabase

Crear esquema:

```sql
CREATE SCHEMA IF NOT EXISTS ecommify;
SET search_path TO ecommify, public;
```

Ejecutar los scripts en la carpeta `Scripts Postgresql` en este orden:

```text
1. Creación de esquema y tablas
2. Carga de datasets
3. Validación de conteos
4. Creación de índices
5. Creación de tabla particionada
6. Creación de particiones mensuales
7. Migración hacia tabla particionada, si aplica
8. Ejecución de consultas críticas
9. Ejecución de EXPLAIN ANALYZE
```

## Carga de datasets en Supabase

Para cargas grandes se recomienda `psql` con `\copy`.

Orden recomendado:

```text
1. customers
2. sellers
3. products
4. orders
5. order_items
6. order_payments
7. order_reviews
8. geolocation_raw
```

Ejemplo:

```bash
psql "$DATABASE_URL" -c "\copy ecommify.customers(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state) FROM 'olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8');"
```

Validar conteos:

```sql
SELECT 'customers' AS table_name, COUNT(*) AS total_records FROM ecommify.customers
UNION ALL SELECT 'sellers', COUNT(*) FROM ecommify.sellers
UNION ALL SELECT 'products', COUNT(*) FROM ecommify.products
UNION ALL SELECT 'orders', COUNT(*) FROM ecommify.orders
UNION ALL SELECT 'order_items', COUNT(*) FROM ecommify.order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM ecommify.order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM ecommify.order_reviews
UNION ALL SELECT 'geolocation_raw', COUNT(*) FROM ecommify.geolocation_raw
ORDER BY table_name;
```

Conteos esperados:

| Tabla | Registros |
|---|---:|
| customers | 99.441 |
| sellers | 3.095 |
| products | 32.951 |
| orders | 99.441 |
| order_items | 112.650 |
| order_payments | 103.886 |
| order_reviews | 99.224 |
| geolocation_raw | 1.000.163 |

## Particionamiento aplicado

Se implementa particionamiento `RANGE` mensual sobre `orders`, usando `order_purchase_timestamp`.

```sql
CREATE TABLE IF NOT EXISTS ecommify.orders_partitioned (
    order_id TEXT NOT NULL,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    PRIMARY KEY (order_id, order_purchase_timestamp)
)
PARTITION BY RANGE (order_purchase_timestamp);
```

Ejemplo de partición:

```sql
CREATE TABLE IF NOT EXISTS ecommify.orders_2018_01
PARTITION OF ecommify.orders_partitioned
FOR VALUES FROM ('2018-01-01') TO ('2018-02-01');
```

Partición por defecto:

```sql
CREATE TABLE IF NOT EXISTS ecommify.orders_default
PARTITION OF ecommify.orders_partitioned
DEFAULT;
```

## Índices recomendados

```sql
CREATE INDEX IF NOT EXISTS idx_orders_partitioned_customer_id
ON ecommify.orders_partitioned (customer_id);

CREATE INDEX IF NOT EXISTS idx_orders_partitioned_status
ON ecommify.orders_partitioned (order_status);

CREATE INDEX IF NOT EXISTS idx_orders_partitioned_purchase_timestamp
ON ecommify.orders_partitioned (order_purchase_timestamp);

CREATE INDEX IF NOT EXISTS idx_orders_partitioned_estimated_delivery
ON ecommify.orders_partitioned (order_estimated_delivery_date);

CREATE INDEX IF NOT EXISTS idx_orders_partitioned_delivered_customer
ON ecommify.orders_partitioned (order_delivered_customer_date);
```

## Consultas críticas PostgreSQL

| Consulta | Descripción |
|---|---|
| Q01 | Vista 360 del pedido |
| Q02 | Vista 360 del cliente |
| Q03 | Ventas por estado y mes |
| Q04 | Pedidos con riesgo logístico |
| Q05 | Entregas tardías por región |

Validación de rendimiento:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ...
```

## Setup MongoDB Atlas

Crear una base de datos llamada:

```text
EcommifyDB
```

Colecciones sugeridas:

```text
products
reviews
sellers
orders_summary
customer_profiles
```

Ejemplo de índices:

```javascript
db.products.createIndex({ product_category_name: 1 });
db.reviews.createIndex({ review_score: 1 });
db.orders_summary.createIndex({ customer_state: 1, order_purchase_month: 1 });
```

Ejemplo de agregación:

```javascript
db.products.aggregate([
  { $group: { _id: "$product_category_name", total_products: { $sum: 1 } } },
  { $sort: { total_products: -1 } }
]);
```

## Google Colab con Supabase

```python
!pip install sqlalchemy psycopg2-binary pandas

from sqlalchemy import create_engine, text
import pandas as pd

DATABASE_URL = "postgresql://usuario:password@host:puerto/postgres"
engine = create_engine(DATABASE_URL)

with engine.connect() as conn:
    result = conn.execute(text("SELECT current_database(), now();"))
    for row in result:
        print(row)
```

## Google Colab con MongoDB

```python
!pip install pymongo pandas

from pymongo import MongoClient

MONGO_URI = "mongodb+srv://usuario:password@cluster.mongodb.net/"
client = MongoClient(MONGO_URI)
db = client["EcommifyDB"]

db.list_collection_names()
```

## Evidencias de rendimiento

Las evidencias se encuentran en `Evidencias Imagenes/`.

Resultados destacados:

| Métrica | Antes | Después | Mejora |
|---|---:|---:|---:|
| Tiempo total de ejecución | 2.786,066 ms | 340,828 ms | 87,77% |
| Bloques leídos | 1.103 | 123 | 88,85% |

## Limitaciones del free tier

### Supabase

- Almacenamiento limitado.
- Riesgo de superar capacidad con `geolocation`, índices y vistas.
- Posibles límites de ejecución en SQL Editor.

Workarounds:

- Carga por lotes.
- Uso de `psql` y `\copy`.
- Índices estrictamente necesarios.
- Particionamiento mensual sobre `orders`.

### MongoDB Atlas

- Almacenamiento reducido en free tier.
- Recursos compartidos.
- Monitoreo avanzado limitado.

Workarounds:

- Carga documental controlada.
- Índices específicos.
- No duplicar todo el modelo relacional.
- Usar documentos agregados orientados a consulta.

## Flujo recomendado

```text
1. Clonar repositorio.
2. Crear proyecto en Supabase.
3. Crear esquema ecommify.
4. Ejecutar scripts de tablas.
5. Cargar datasets.
6. Validar conteos.
7. Crear índices.
8. Crear particiones.
9. Migrar orders a orders_partitioned, si aplica.
10. Ejecutar consultas críticas.
11. Ejecutar EXPLAIN ANALYZE.
12. Crear clúster MongoDB.
13. Ejecutar scripts Mongo.
14. Consolidar evidencias.
```

## Buenas prácticas

- No subir credenciales al repositorio.
- Usar variables de entorno.
- Ejecutar `ANALYZE` después de cargas masivas.
- Crear índices después de cargar grandes volúmenes.
- Validar conteos antes de analizar rendimiento.
- Separar responsabilidades entre PostgreSQL y MongoDB.

## Variables de entorno

```bash
DATABASE_URL=postgresql://usuario:password@host:puerto/postgres
MONGO_URI=mongodb+srv://usuario:password@cluster.mongodb.net/
```

## Autor

Proyecto académico para la asignatura **Diseño de Base de Datos**.

Repositorio: `romergi1/Diseno-Base-de-datos-USabana`
