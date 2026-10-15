-- Optional hands-on MERGE demo. Run in psql/pgAdmin after initial setup.
SET search_path TO warehouse, public;

-- Simulate an incoming change for customer 1 and a brand-new customer 6.
UPDATE staging_customers
SET city = 'Pune', updated_at = DATE '2026-10-10'
WHERE customer_id = 1;

INSERT INTO staging_customers
    (customer_id, customer_name, email, city, segment, updated_at)
VALUES
    (6, 'Ishaan Das', 'ishaan@example.com', 'Pune', 'Consumer', DATE '2026-10-10')
ON CONFLICT DO NOTHING;

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

-- Verify that customer 1 was updated and customer 6 was inserted.
SELECT customer_id, customer_name, city, updated_at
FROM dim_customer
WHERE customer_id IN (1, 6)
ORDER BY customer_id;
