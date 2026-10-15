-- SQL Data Engineering Pipeline — Week 6
-- PostgreSQL 16+
-- This script runs automatically on the first Docker database initialization.

\set ON_ERROR_STOP on

CREATE SCHEMA IF NOT EXISTS warehouse;
SET search_path TO warehouse, public;

-- 1. Raw staging tables
CREATE TABLE staging_customers (
    customer_id   INTEGER,
    customer_name TEXT,
    email         TEXT,
    city          TEXT,
    segment       TEXT,
    updated_at    DATE
);

CREATE TABLE staging_sales (
    sale_id     BIGINT,
    customer_id INTEGER,
    sale_date   DATE,
    product     TEXT,
    quantity    INTEGER,
    unit_price  NUMERIC(12,2),
    status      TEXT
);

-- 2. Bulk load CSV data with PostgreSQL server-side COPY.
COPY staging_customers
    (customer_id, customer_name, email, city, segment, updated_at)
FROM '/data/customers.csv'
WITH (FORMAT CSV, HEADER TRUE);

COPY staging_sales
    (sale_id, customer_id, sale_date, product, quantity, unit_price, status)
FROM '/data/sales.csv'
WITH (FORMAT CSV, HEADER TRUE);

-- 3. Customer dimension. The source key is the business key.
CREATE TABLE dim_customer (
    customer_id   INTEGER PRIMARY KEY,
    customer_name TEXT NOT NULL,
    email         TEXT,
    city          TEXT,
    segment       TEXT,
    updated_at    DATE NOT NULL,
    warehouse_loaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Initial load using MERGE. Matched rows are updated only if attributes changed.
MERGE INTO dim_customer AS target
USING staging_customers AS source
ON target.customer_id = source.customer_id
WHEN MATCHED AND (
       target.customer_name IS DISTINCT FROM source.customer_name
    OR target.email         IS DISTINCT FROM source.email
    OR target.city          IS DISTINCT FROM source.city
    OR target.segment       IS DISTINCT FROM source.segment
    OR target.updated_at    IS DISTINCT FROM source.updated_at
)
THEN UPDATE SET
    customer_name = source.customer_name,
    email = source.email,
    city = source.city,
    segment = source.segment,
    updated_at = source.updated_at,
    warehouse_loaded_at = CURRENT_TIMESTAMP
WHEN NOT MATCHED
THEN INSERT (customer_id, customer_name, email, city, segment, updated_at)
     VALUES (source.customer_id, source.customer_name, source.email,
             source.city, source.segment, source.updated_at);

-- 4. Range-partitioned fact table, partitioned by sale_date.
-- Partition bounds are lower-inclusive and upper-exclusive.
CREATE TABLE fact_sales (
    sale_id     BIGINT NOT NULL,
    customer_id INTEGER NOT NULL REFERENCES dim_customer(customer_id),
    sale_date   DATE NOT NULL,
    product     TEXT NOT NULL,
    quantity    INTEGER NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    status      TEXT NOT NULL,
    revenue     NUMERIC(14,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    PRIMARY KEY (sale_date, sale_id)
) PARTITION BY RANGE (sale_date);

CREATE TABLE fact_sales_2026_q1 PARTITION OF fact_sales
    FOR VALUES FROM ('2026-01-01') TO ('2026-04-01');
CREATE TABLE fact_sales_2026_q2 PARTITION OF fact_sales
    FOR VALUES FROM ('2026-04-01') TO ('2026-07-01');
CREATE TABLE fact_sales_2026_q3 PARTITION OF fact_sales
    FOR VALUES FROM ('2026-07-01') TO ('2026-10-01');
CREATE TABLE fact_sales_2026_q4 PARTITION OF fact_sales
    FOR VALUES FROM ('2026-10-01') TO ('2027-01-01');

-- Load facts from staging. In a production pipeline, validate/deduplicate first.
INSERT INTO fact_sales
    (sale_id, customer_id, sale_date, product, quantity, unit_price, status)
SELECT sale_id, customer_id, sale_date, product, quantity, unit_price, status
FROM staging_sales
ORDER BY sale_date, sale_id;

-- 5. Composite index: useful for customer-specific date-range lookups.
CREATE INDEX idx_fact_sales_customer_date
    ON fact_sales (customer_id, sale_date);

-- 6. Partial index: only completed sales are indexed.
CREATE INDEX idx_fact_sales_completed_date
    ON fact_sales (sale_date)
    WHERE status = 'COMPLETED';

-- A supporting index for customer segment filtering.
CREATE INDEX idx_dim_customer_segment
    ON dim_customer (segment);

ANALYZE dim_customer;
ANALYZE fact_sales;

-- Simple load audit table
CREATE TABLE pipeline_run_log (
    run_id BIGSERIAL PRIMARY KEY,
    pipeline_name TEXT NOT NULL,
    status TEXT NOT NULL,
    rows_customers INTEGER NOT NULL,
    rows_sales INTEGER NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO pipeline_run_log
    (pipeline_name, status, rows_customers, rows_sales)
SELECT 'week6_sales_pipeline', 'SUCCESS',
       (SELECT COUNT(*) FROM staging_customers),
       (SELECT COUNT(*) FROM fact_sales);

-- Initialization summary
SELECT 'staging_customers' AS table_name, COUNT(*) AS row_count FROM staging_customers
UNION ALL
SELECT 'staging_sales', COUNT(*) FROM staging_sales
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM fact_sales;
