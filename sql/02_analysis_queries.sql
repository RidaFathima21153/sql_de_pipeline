-- SQL DE Pipeline Week 6 — analysis and verification queries
SET search_path TO warehouse, public;

-- A. Check pipeline audit
SELECT * FROM pipeline_run_log ORDER BY completed_at DESC;

-- B. Confirm loaded row counts
SELECT 'customers' AS entity, COUNT(*) AS total_rows FROM dim_customer
UNION ALL
SELECT 'sales', COUNT(*) FROM fact_sales;

-- C. Inspect the dimension table
SELECT customer_id, customer_name, city, segment, updated_at
FROM dim_customer
ORDER BY customer_id;

-- D. Monthly revenue by sale status
SELECT date_trunc('month', sale_date)::date AS sales_month,
       status,
       SUM(revenue) AS total_revenue,
       COUNT(*) AS transaction_count
FROM fact_sales
GROUP BY 1, 2
ORDER BY 1, 2;

-- E. Top customers by completed revenue
SELECT c.customer_id, c.customer_name,
       SUM(f.revenue) AS completed_revenue
FROM dim_customer AS c
JOIN fact_sales AS f ON f.customer_id = c.customer_id
WHERE f.status = 'COMPLETED'
GROUP BY c.customer_id, c.customer_name
ORDER BY completed_revenue DESC
LIMIT 5;

-- F. Composite index use case: filter by customer and date range
EXPLAIN ANALYZE
SELECT sale_id, sale_date, product, revenue
FROM fact_sales
WHERE customer_id = 1
  AND sale_date >= DATE '2026-01-01'
  AND sale_date < DATE '2026-07-01'
ORDER BY sale_date;

-- G. Partial index use case: completed sales in a date window
EXPLAIN ANALYZE
SELECT sale_date, sale_id, revenue
FROM fact_sales
WHERE status = 'COMPLETED'
  AND sale_date >= DATE '2026-07-01'
  AND sale_date < DATE '2027-01-01'
ORDER BY sale_date;

-- H. Show partition sizes / row counts
SELECT child.relname AS partition_name,
       child.reltuples::bigint AS estimated_rows
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child ON pg_inherits.inhrelid = child.oid
JOIN pg_namespace ns ON parent.relnamespace = ns.oid
WHERE ns.nspname = 'warehouse'
  AND parent.relname = 'fact_sales'
ORDER BY child.relname;

-- I. Demonstrate MERGE incrementally (safe to run repeatedly).
-- Change a customer city and add a new customer in staging, then run this block.
-- Example:
-- UPDATE staging_customers SET city = 'Pune', updated_at = DATE '2026-10-10'
-- WHERE customer_id = 1;
-- INSERT INTO staging_customers
-- VALUES (6, 'Ishaan Das', 'ishaan@example.com', 'Pune', 'Consumer', DATE '2026-10-10');
--
-- MERGE INTO dim_customer AS target
-- USING staging_customers AS source
-- ON target.customer_id = source.customer_id
-- WHEN MATCHED AND (
--        target.customer_name IS DISTINCT FROM source.customer_name
--     OR target.email IS DISTINCT FROM source.email
--     OR target.city IS DISTINCT FROM source.city
--     OR target.segment IS DISTINCT FROM source.segment
--     OR target.updated_at IS DISTINCT FROM source.updated_at
-- )
-- THEN UPDATE SET customer_name = source.customer_name,
--                 email = source.email,
--                 city = source.city,
--                 segment = source.segment,
--                 updated_at = source.updated_at,
--                 warehouse_loaded_at = CURRENT_TIMESTAMP
-- WHEN NOT MATCHED THEN
-- INSERT (customer_id, customer_name, email, city, segment, updated_at)
-- VALUES (source.customer_id, source.customer_name, source.email,
--         source.city, source.segment, source.updated_at);
