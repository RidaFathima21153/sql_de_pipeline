# DE SQL Pipeline — Week 6

A runnable MySQL-based Data Engineering mini project demonstrating an end-to-end SQL data pipeline for the DataGrokr PLP Week 6 syllabus.

The project covers CSV bulk loading, customer UPSERT operations, date-based range partitioning, indexing, query-plan inspection, transactions, stored procedures, triggers, JSON queries, star-schema reporting, and Slowly Changing Dimensions (SCD) Types 1, 2, and 3.

## Requirements

- MySQL 8.0+
- MySQL Workbench or MySQL command-line client
- CSV input files
- Git (optional, for version control)

MySQL 8.0.18 or later is required for `EXPLAIN ANALYZE`.

## Project Structure

```text
DE_SQL_Pipeline/
├── data/
│   ├── customers.csv
│   └── transactions.csv
├── schema/
│   ├── create_database.sql
│   └── create_indexes.sql
├── queries/
│   ├── bulk_load.sql
│   ├── customer_upsert.sql
│   └── analytics.sql
├── tests/
│   └── validation_queries.sql
├── README.md
└── .gitignore
