# SQL Data Engineering Pipeline — Week 6

A runnable PostgreSQL-based Data Engineering project demonstrating an end-to-end SQL data pipeline using CSV bulk loading, incremental dimension updates, date-based partitioning, indexing, and query optimization.

This project is developed as part of the DataGrokr PLP Week 6 syllabus and demonstrates essential data engineering and database optimization concepts using PostgreSQL 16 and Docker Compose.

## Requirements

- Docker Desktop
- Docker Compose
- VS Code (optional)
- Git (optional)

PostgreSQL 16 is used to support the `MERGE` statement.

## Project Structure

```text
sql_de_pipeline_week6/
├── data/
│   ├── customers.csv
│   └── sales.csv
├── sql/
│   ├── 01_setup_and_load.sql
│   ├── 02_analysis_queries.sql
│   └── 03_incremental_merge_demo.sql
├── docker-compose.yml
├── .gitignore
├── LICENSE
├── PROJECT_OVERVIEW.md
└── README.md
```

## Run the Project

### 1. Clone the Repository

Clone the project from GitHub:

```bash
git clone https://github.com/RidaFathima21153/sql_de_pipeline_week6.git
```

Navigate to the project directory:

```bash
cd sql_de_pipeline_week6
```

Alternatively, download the repository as a ZIP file and extract it.

### 2. Start PostgreSQL

Open the project folder in VS Code and open a terminal in the project directory.

Start the PostgreSQL database using Docker Compose:

```bash
docker compose up -d
```

Check the database logs:

```bash
docker compose logs -f db
```

Wait until PostgreSQL finishes initializing.

### 3. Connect to the Database

Connect using pgAdmin or another PostgreSQL client with the following settings:

| Setting | Value |
|---|---|
| Host | `localhost` |
| Port | `5432` |
| Database | `de_pipeline` |
| Username | `de_user` |
| Password | `de_password` |

These are the default local-development credentials configured for this project.

### 4. Load the CSV Data

The project contains two source CSV files:

- `data/customers.csv`
- `data/sales.csv`

The initialization script is:

```text
sql/01_setup_and_load.sql
```

This script creates the required staging tables, customer dimension, partitioned sales fact table, and date partitions. It also loads the CSV data into the staging tables using PostgreSQL's `COPY` command.

The Docker Compose configuration mounts the project's data directory into the database container so PostgreSQL can access the CSV files.

### 5. Run the Analysis Queries

Open:

```text
sql/02_analysis_queries.sql
```

Execute the queries using pgAdmin or the PostgreSQL command-line client.

Alternatively, run the entire script from the project directory:

```bash
docker compose exec -T db psql -U de_user -d de_pipeline < sql/02_analysis_queries.sql
```

The analysis queries demonstrate data retrieval, filtering, aggregation, indexing, partition inspection, and query-plan analysis.

### 6. Run the Incremental MERGE Demonstration

Open:

```text
sql/03_incremental_merge_demo.sql
```

Execute the SQL statements to explore incremental customer dimension updates using PostgreSQL's `MERGE` statement.

This demonstrates how new customers can be inserted and existing customer attributes updated as source data changes.

### 7. Inspect Query Performance

Use `EXPLAIN ANALYZE` to inspect query execution plans and actual execution statistics.

For example:

```sql
EXPLAIN ANALYZE
SELECT *
FROM fact_sales
WHERE sale_date >= DATE '2026-01-01'
  AND sale_date < DATE '2026-02-01';
```

This example assumes that the relevant date partitions and table have been created.

Query plans can help you understand index usage, partition pruning, execution time, and query performance.

## Project Flow

The pipeline follows these stages:

1. **Source Data:** Customer and sales records are provided as CSV files.
2. **Staging:** PostgreSQL loads the CSV records into staging tables using `COPY`.
3. **Dimension Processing:** Customer records are inserted or updated using `MERGE`.
4. **Fact Loading:** Sales records are stored in a date-partitioned fact table.
5. **Indexing:** Composite and partial indexes support common analytical filters.
6. **Query Optimization:** `EXPLAIN ANALYZE` helps inspect query execution plans.
7. **Analytics:** SQL queries analyze the loaded sales and customer data.

## Main Features

| Feature | Implementation |
|---|---|
| Database | PostgreSQL 16 |
| Containerization | Docker Compose |
| Bulk CSV Loading | `COPY` |
| Incremental Updates | `MERGE` |
| Data Modeling | Staging tables, customer dimension, and sales fact table |
| Partitioning | Date-based range partitioning |
| Indexing | Composite and partial indexes |
| Query Optimization | `EXPLAIN ANALYZE` |
| Analytics | SQL filtering, aggregation, and reporting |

## Main Tables

| Table | Purpose |
|---|---|
| `staging_customers` | Stores incoming customer records |
| `staging_sales` | Stores incoming sales records |
| `dim_customer` | Maintains current customer attributes |
| `fact_sales` | Stores sales records in date-based partitions |

## Important Notes

- **PostgreSQL Version:** PostgreSQL 16 is used for compatibility with the `MERGE` statement.
- **Bulk Loading:** PostgreSQL's server-side `COPY` command reads files accessible to the database server. The Docker Compose configuration mounts the data directory into the container.
- **Initialization:** The database initialization scripts run automatically when the database volume is first created.
- **Existing Database Volume:** Changing an initialization script does not automatically rerun it against an already initialized database.
- **Resetting the Database:** To recreate the database from scratch, run:

  ```bash
  docker compose down -v
  docker compose up -d
  ```

  **Warning:** `docker compose down -v` deletes this project's database volume and its stored data.

- **Credentials:** The configured database credentials are intended for local development. Change them before exposing the database outside your machine.

## Validation and Testing

After the database initializes, execute the analysis queries in:

```text
sql/02_analysis_queries.sql
```

Use the results to inspect the loaded records, customer dimension updates, sales partitions, index usage, and query execution plans.

You can also execute the incremental MERGE demonstration in:

```text
sql/03_incremental_merge_demo.sql
```

## Repository

GitHub: [sql_de_pipeline_week6](https://github.com/RidaFathima21153/sql_de_pipeline_week6)

## Disclaimer

This project is intended for educational purposes and demonstrates fundamental Data Engineering concepts using PostgreSQL and SQL. The sample data is fictional and intended for local development and learning.
