# Teradata to Snowflake Migration

This directory contains Snowflake-native equivalents of all Teradata ETL scripts (FastLoad, MultiLoad, TPT, BTEQ) from the original repository.

## Script Mapping

| Original Teradata Script | Snowflake Equivalent | Description |
|--------------------------|----------------------|-------------|
| `Customer_fastload.fl.txt` | `load/fastload_customer_new.sql` | Bulk load into `CUSTOMER_NEW` using PUT + COPY INTO |
| `Customerinsert.ml.txt` | `load/mload_insert_customer.sql` | MultiLoad INSERT into `CUSTOMER_NEW_ML` via COPY INTO |
| `CustomerUPDATE.ml` | `load/mload_upsert_customer.sql` | MultiLoad UPSERT converted to staging table + MERGE |
| `data_files/CustomerUPDATE.ml` | `load/mload_upsert_customer.sql` | (duplicate of above, same conversion) |
| `mloadtpt.txt` | `load/tpt_load_customer.sql` | TPT Load into `CUSTOMER_TPT_MLOAD` via COPY INTO |
| `Export.tpt.txt` | `export/tpt_export_customer.sql` | TPT Export converted to COPY INTO @stage + GET |
| `tptscript.txt` | `export/tpt_export_customer.sql` | TPT Export (same as above) |
| `FastExport.fexp.txt` | `export/tpt_export_customer.sql` | FastExport converted to COPY INTO @stage |
| `FastExport_1.fexp.txt` | `export/tpt_export_customer.sql` | FastExport with gender filters |
| `Export.bteq.txt` | `export/tpt_export_customer.sql` | BTEQ export converted to COPY INTO @stage |
| `csvexport.bteq.txt` | `export/tpt_export_customer.sql` | BTEQ CSV export converted to COPY INTO @stage |
| `Condbteq.bteq` | `procedures/conditional_load.sql` | BTEQ conditional logic → Snowflake Scripting procedure |
| `Condbteq2.bteq` | `procedures/conditional_load.sql` | BTEQ conditional run → Snowflake Scripting procedure |
| `Customerdelete.ml.txt` | N/A (use `TRUNCATE TABLE`) | Simple delete; no dedicated script needed |

## Prerequisites

1. **Snowflake Account** with SYSADMIN (or equivalent) role access
2. **Snowflake Warehouse** — create one if it doesn't exist:
   ```sql
   CREATE WAREHOUSE IF NOT EXISTS ETL_WH
       WAREHOUSE_SIZE = 'XSMALL'
       AUTO_SUSPEND = 300
       AUTO_RESUME = TRUE;
   ```
3. **SnowSQL or Snowflake CLI** — required for `PUT` and `GET` commands (file staging)
4. **Roles & Grants** — ensure the executing role has:
   - `CREATE DATABASE`, `CREATE SCHEMA`, `CREATE TABLE`, `CREATE STAGE`, `CREATE FILE FORMAT`
   - `USAGE` on the warehouse
   - `CREATE TASK` and `EXECUTE TASK` (for orchestration)
   - `CREATE PROCEDURE` (for stored procedures)

## Step-by-Step Execution Order

### 1. DDL Setup (run once)

Execute the DDL scripts in order:

```bash
snowsql -f snowflake/ddl/01_databases.sql
snowsql -f snowflake/ddl/02_schemas.sql
snowsql -f snowflake/ddl/03_tables.sql
snowsql -f snowflake/ddl/04_file_formats.sql
snowsql -f snowflake/ddl/05_stages.sql
```

### 2. Stage Data Files

Upload data files to the internal stages:

```bash
snowsql -q "PUT file://snowflake/data/customer_existing.csv @FINANCIAL.PUBLIC.CUSTOMER_STAGE/seed/ AUTO_COMPRESS=TRUE OVERWRITE=TRUE;"
snowsql -q "PUT file://snowflake/data/customer_incoming_pipe.txt @FINANCIAL.PUBLIC.CUSTOMER_STAGE/fastload/ AUTO_COMPRESS=TRUE OVERWRITE=TRUE;"
snowsql -q "PUT file://snowflake/data/customer_incoming_pipe.txt @FINANCIAL.PUBLIC.CUSTOMER_STAGE/mload_upsert/ AUTO_COMPRESS=TRUE OVERWRITE=TRUE;"
snowsql -q "PUT file://snowflake/data/customer_incoming_pipe.txt @FINANCIAL.PUBLIC.CUSTOMER_STAGE/tpt_load/ AUTO_COMPRESS=TRUE OVERWRITE=TRUE;"
snowsql -q "PUT file://snowflake/data/customer_incoming_pipe.txt @TPCH.PUBLIC.CUSTOMER_STAGE/mload_insert/ AUTO_COMPRESS=TRUE OVERWRITE=TRUE;"
```

### 3. Run Load Scripts

Execute load scripts in this order:

```bash
# a. Seed the CUSTOMER source table (required before exports and conditional loads)
snowsql -f snowflake/load/seed_customer.sql

# b. FastLoad equivalent
snowsql -f snowflake/load/fastload_customer_new.sql

# c. MultiLoad INSERT equivalent
snowsql -f snowflake/load/mload_insert_customer.sql

# d. MultiLoad UPSERT equivalent (MERGE)
snowsql -f snowflake/load/mload_upsert_customer.sql

# e. TPT Load equivalent
snowsql -f snowflake/load/tpt_load_customer.sql
```

### 4. Run Stored Procedures

```bash
# Create the procedures
snowsql -f snowflake/procedures/conditional_load.sql

# Execute them
snowsql -q "CALL FINANCIAL.PUBLIC.CONDITIONAL_LOAD_CUSTOMER_AUG18();"
snowsql -q "CALL FINANCIAL.PUBLIC.CONDITIONAL_RUN_IF_DATA_EXISTS();"
```

### 5. Run Exports

```bash
snowsql -f snowflake/export/tpt_export_customer.sql
```

### 6. Set Up Orchestration (optional)

To automate the pipeline with Snowflake Tasks:

```bash
snowsql -f snowflake/tasks/orchestration.sql
```

The root task runs daily at 2 AM ET. Adjust the CRON schedule as needed.

## Credential Management

The original Teradata scripts contain hardcoded credentials (`dbc/dbc`). In Snowflake:

- **Never hardcode credentials** in SQL scripts
- Use **key-pair authentication** for automated/service accounts:
  ```bash
  snowsql -a <account> --authenticator externalbrowser
  # or
  snowsql -a <account> -u <user> --private-key-path <path>
  ```
- For Snowflake Tasks, authentication is handled by the task owner's role
- Store sensitive values in environment variables:
  ```bash
  export SNOWSQL_ACCOUNT=myaccount
  export SNOWSQL_USER=myuser
  export SNOWSQL_PWD=$SNOWFLAKE_PASSWORD   # Avoid if possible; prefer key-pair
  ```

## Directory Structure

```
snowflake/
├── README.md                              # This file
├── ddl/
│   ├── 01_databases.sql                   # CREATE DATABASE statements
│   ├── 02_schemas.sql                     # CREATE SCHEMA statements
│   ├── 03_tables.sql                      # CREATE TABLE for all 5 target tables
│   ├── 04_file_formats.sql                # FILE FORMAT for pipe and CSV
│   └── 05_stages.sql                      # Internal stages for data staging
├── load/
│   ├── seed_customer.sql                  # Seed CUSTOMER table from CSV
│   ├── fastload_customer_new.sql          # FastLoad → PUT + COPY INTO
│   ├── mload_insert_customer.sql          # MultiLoad INSERT → COPY INTO
│   ├── mload_upsert_customer.sql          # MultiLoad UPSERT → staging + MERGE
│   └── tpt_load_customer.sql              # TPT Load → COPY INTO
├── export/
│   └── tpt_export_customer.sql            # All exports → COPY INTO @stage + GET
├── procedures/
│   └── conditional_load.sql               # BTEQ conditional logic → Snowflake Scripting
├── tasks/
│   └── orchestration.sql                  # Snowflake Task DAG for pipeline scheduling
└── data/
    ├── README.md                          # Data file documentation
    ├── customer_existing.csv              # Existing customer records (CSV)
    ├── customer_incoming.csv              # Incoming customer records (CSV)
    └── customer_incoming_pipe.txt         # Incoming customer records (pipe-delimited)
```

## Key Conversion Patterns

| Teradata Concept | Snowflake Equivalent |
|------------------|----------------------|
| FastLoad | `PUT` + `COPY INTO` (empty table) |
| MultiLoad INSERT | `COPY INTO` |
| MultiLoad UPSERT | Staging table + `MERGE INTO` |
| MultiLoad DELETE | `TRUNCATE TABLE` or `DELETE FROM` |
| TPT Load Operator | `COPY INTO` (auto-parallelized) |
| TPT Export Operator | `COPY INTO @stage FROM (SELECT ...)` + `GET` |
| FastExport | `COPY INTO @stage FROM (SELECT ...)` + `GET` |
| BTEQ `.export` | `COPY INTO @stage FROM (SELECT ...)` |
| BTEQ `.IF ERRORCODE` | Snowflake Scripting `IF ... THEN ... END IF` |
| BTEQ `.IF ACTIVITYCOUNT` | Snowflake Scripting `IF (count = 0)` |
| BTEQ `.RUN FILE` | `CALL` stored procedure |
| BTEQ `.LABEL` / `.GOTO` | Sequential flow in `BEGIN...END` blocks |
| `ERRORFILES` | `ON_ERROR = 'CONTINUE'` |
| `CHECKPOINT` | Snowflake built-in transaction handling |
| `LOGTABLE` | Not needed; Snowflake tracks load metadata |
| `SESSIONS` / `MAXSESSIONS` | Automatic parallelism |
| `SET RECORD VARTEXT '\|'` | `FILE_FORMAT` with `FIELD_DELIMITER = '\|'` |
