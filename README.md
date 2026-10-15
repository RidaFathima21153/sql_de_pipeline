# SQL Data Engineering Pipeline — Week 6

A runnable PostgreSQL project demonstrating:

- CSV bulk loading with `COPY`
- Incremental dimension updates with `MERGE`
- Date-based range partitioning
- Composite and partial indexes
- Query-plan inspection with `EXPLAIN ANALYZE`

## Requirements

- Docker Desktop (recommended), with Docker Compose
- VS Code (optional, for editing SQL and project files)

PostgreSQL 16 is used so the `MERGE` statement is supported.

## Run the project

1. Extract the ZIP file.
2. Open the extracted `sql_de_pipeline_week6` folder in VS Code.
3. Open a terminal in that folder.
4. Start the database:

   ```bash
   docker compose up -d
   ```

5. Wait a few seconds for PostgreSQL to initialize. View logs if needed:

   ```bash
   docker compose logs -f db
   ```

   The database runs initialization scripts only the first time its data volume is created.

## Connect to PostgreSQL

Use pgAdmin or a VS Code PostgreSQL extension:

- Host: `localhost`
- Port: `5432`
- Database: `de_pipeline`
- Username: `de_user`
- Password: `de_password`

## Run the example queries

Open `sql/02_analysis_queries.sql` and execute its queries in pgAdmin or `psql`.

Using the container terminal:

```bash
docker compose exec db psql -U de_user -d de_pipeline
```

Then paste SQL queries from `sql/02_analysis_queries.sql` individually. To run the entire analysis script from the project folder:

```bash
docker compose exec -T db psql -U de_user -d de_pipeline < sql/02_analysis_queries.sql
```

## Project flow

1. `data/customers.csv` and `data/sales.csv` contain incoming source records.
2. `sql/01_setup_and_load.sql` creates staging tables, dimension/fact tables, and date partitions.
3. PostgreSQL `COPY` bulk-loads the CSV files into staging tables.
4. `MERGE` inserts new customers and updates existing customer attributes.
5. Sales records are inserted into a range-partitioned fact table.
6. Composite and partial indexes support common analytics filters.

## Main tables

- `staging_customers`: raw customer input
- `staging_sales`: raw sales input
- `dim_customer`: current customer attributes
- `fact_sales`: sales facts partitioned by `sale_date`

## Important notes

- The demo data is fictional.
- The initialization script is run automatically on a fresh database volume.
- If you edit the initialization SQL and want to rerun it from scratch, run:

  ```bash
  docker compose down -v
  docker compose up -d
  ```

  **Warning:** `docker compose down -v` deletes this project's local database volume and its data.
- The database password is intended for local development only. Change it before exposing the database outside your machine.
- PostgreSQL's server-side `COPY` reads files from the database container. The Compose file mounts the project's `data` directory at `/data` for this reason.

## GitHub

Suggested repository name: `sql-de-pipeline-week6`

Before pushing, you can add screenshots of query results and `EXPLAIN ANALYZE` output to a `screenshots/` folder.
