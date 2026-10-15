# Project Overview

## Objective
Implement a small, reproducible SQL data engineering workflow in PostgreSQL.

## Week 6 concepts mapped to implementation
| Topic | Implementation |
|---|---|
| MERGE on dimension table | `MERGE INTO dim_customer` in `sql/01_setup_and_load.sql`; repeatable example in `sql/03_incremental_merge_demo.sql` |
| Range partitioning | `fact_sales` partitioned by `sale_date`, with four quarterly partitions for 2026 |
| COPY bulk load | CSV data imported into staging tables using `COPY ... FROM '/data/...'` |
| Composite index | `idx_fact_sales_customer_date` on `(customer_id, sale_date)` |
| Partial index | `idx_fact_sales_completed_date` for rows where `status = 'COMPLETED'` |

## Expected initial row counts
- Staging customers: 5
- Staging sales: 10
- Customer dimension: 5
- Fact sales: 10

## Limitations / production considerations
This is a learning/demo project. A production pipeline would add source deduplication, data-quality checks, transaction/retry strategy, secrets management, incremental watermarks, and automated tests.
