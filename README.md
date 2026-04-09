# Teradata Utilities — dbt Migration

This repository has been migrated from legacy Teradata-native ETL scripts (FastLoad, MultiLoad, TPT, BTEQ) to a **dbt-core** project using the **dbt-teradata** adapter.

## Table of Contents

- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Configuration](#configuration)
- [End-to-End Workflow](#end-to-end-workflow)
- [Script Mapping: Legacy to dbt](#script-mapping-legacy-to-dbt)
- [Companion Scripts](#companion-scripts)
- [Macros](#macros)
- [Testing](#testing)
- [Legacy Scripts Reference](#legacy-scripts-reference)

---

## Project Structure

```
.
├── dbt_project.yml                  # dbt project configuration
├── profiles.yml                     # Teradata connection template (credentials via env vars)
├── packages.yml                     # dbt package dependencies (dbt-utils)
├── requirements.txt                 # Python dependencies
├── models/
│   ├── staging/
│   │   ├── schema.yml               # Source definitions and staging model docs/tests
│   │   └── stg_customer.sql         # Staging model with type casting
│   └── marts/
│       ├── schema.yml               # Mart model documentation and tests
│       └── customer_new.sql         # Incremental (merge/upsert) model
├── seeds/
│   ├── customer_existing.csv        # Seed: existing customer data (500 rows)
│   └── customer_incoming.csv        # Seed: incoming customer data (151 rows)
├── macros/
│   └── delete_customer.sql          # Delete macro (replaces Customerdelete.ml.txt)
├── scripts/
│   ├── load_customer_data.py        # Ingestion script (replaces FastLoad/MultiLoad/TPT)
│   └── export_customer_data.py      # Export script (replaces FastExport/TPT Export/BTEQ Export)
├── tests/                           # Custom dbt tests (placeholder)
├── data_files/                      # Original data files (preserved for reference)
│   ├── customer_existing.csv
│   ├── customer_incoming.csv
│   ├── customer_incoming_pipe.txt
│   ├── target_output.csv
│   └── CustomerUPDATE.ml
└── (legacy scripts)                 # Original .fl, .ml, .bteq, .fexp, .tpt scripts
```

## Prerequisites

- **Python 3.9+**
- **Teradata database** accessible over the network
- **pip** (Python package manager)

## Setup

1. **Install dependencies:**

   ```bash
   pip install -r requirements.txt
   ```

   This installs `dbt-core`, `dbt-teradata`, and `teradatasql`.

2. **Install dbt packages:**

   ```bash
   dbt deps
   ```

3. **Configure Teradata credentials** (see [Configuration](#configuration) below).

## Configuration

The `profiles.yml` file uses environment variables for Teradata connection details. Set these before running dbt:

```bash
export TD_HOST="your-teradata-host"
export TD_USER="your-username"
export TD_PASSWORD="your-password"
```

These replace the hardcoded `.logon 192.168.128.128/dbc,dbc` credentials found in all legacy scripts.

| Environment Variable | Description                         |
|----------------------|-------------------------------------|
| `TD_HOST`            | Teradata server hostname or IP      |
| `TD_USER`            | Teradata username                   |
| `TD_PASSWORD`        | Teradata password                   |

The profile targets the `financial` schema with ANSI transaction mode and TD2 authentication, matching the original scripts.

## End-to-End Workflow

### Development (using seeds)

```bash
# 1. Load seed data into Teradata (for dev/testing)
dbt seed

# 2. Run all models (staging view + incremental mart table)
dbt run

# 3. Run tests
dbt test
```

### Production

```bash
# 1. Ingest raw data from flat files into staging table
python scripts/load_customer_data.py \
  --file /path/to/customer_data.txt \
  --delimiter '|'

# 2. Run dbt models (transforms staging → marts)
dbt run

# 3. Run dbt tests
dbt test

# 4. Export final data to flat file
python scripts/export_customer_data.py \
  --output /path/to/customer_export.csv \
  --delimiter ','
```

### Delete operations

```bash
# Delete specific customers
dbt run-operation delete_customers --args '{"condition": "cust_id = '\''C0001'\''"}'

# Delete all customers
dbt run-operation delete_customers --args '{"condition": "1=1"}'
```

## Script Mapping: Legacy to dbt

| Legacy Script                 | Replacement                                      | Description                              |
|-------------------------------|--------------------------------------------------|------------------------------------------|
| `Customer_fastload.fl.txt`    | `scripts/load_customer_data.py` + `dbt seed`     | Bulk load from pipe-delimited file       |
| `Customerinsert.ml.txt`       | `scripts/load_customer_data.py` + `stg_customer`  | MultiLoad insert into staging            |
| `CustomerUPDATE.ml`           | `models/marts/customer_new.sql` (incremental)     | Upsert: update existing, insert new rows |
| `Customerdelete.ml.txt`       | `macros/delete_customer.sql`                      | Delete rows from customer table          |
| `mloadtpt.txt`                | `scripts/load_customer_data.py` + `customer_new`  | TPT load + insert                        |
| `Export.tpt.txt`              | `scripts/export_customer_data.py`                 | TPT export to flat file                  |
| `tptscript.txt`               | `scripts/export_customer_data.py`                 | TPT export variant                       |
| `Export.bteq.txt`             | `scripts/export_customer_data.py`                 | BTEQ export with pipe delimiter          |
| `csvexport.bteq.txt`          | `scripts/export_customer_data.py`                 | BTEQ CSV export                          |
| `FastExport.fexp.txt`         | `scripts/export_customer_data.py`                 | FastExport (partial columns)             |
| `FastExport_1.fexp.txt`       | `scripts/export_customer_data.py --where "..."`   | FastExport with gender filter            |
| `Condbteq.bteq`               | dbt models + seeds                               | Conditional BTEQ create/insert           |
| `Condbteq2.bteq`              | dbt models + tests                               | Conditional BTEQ count check             |

## Companion Scripts

### `scripts/load_customer_data.py`

Replaces FastLoad, MultiLoad, and TPT load operations. Reads CSV or pipe-delimited files and bulk-inserts into a Teradata staging table using the `teradatasql` driver.

```bash
# Load pipe-delimited file
python scripts/load_customer_data.py --file data_files/customer_incoming_pipe.txt --delimiter '|'

# Load CSV file with truncate-before-load
python scripts/load_customer_data.py --file seeds/customer_incoming.csv --delimiter ',' --truncate

# Custom target table and batch size
python scripts/load_customer_data.py --file data.csv --delimiter ',' --target-table financial.customer_staging --batch-size 5000
```

### `scripts/export_customer_data.py`

Replaces FastExport, TPT Export, and BTEQ export operations. Queries the final `customer_new` table and writes to a delimited file.

```bash
# Export to CSV
python scripts/export_customer_data.py --output customer_export.csv --delimiter ','

# Export to pipe-delimited without header
python scripts/export_customer_data.py --output export.txt --delimiter '|' --no-header

# Export with filter (replaces FastExport_1.fexp.txt gender filter)
python scripts/export_customer_data.py --output males.csv --where "gender = 'M'"
```

## Macros

### `delete_customers(condition)`

Executes a DELETE statement against `customer_new` with the given WHERE condition.

```bash
dbt run-operation delete_customers --args '{"condition": "cust_id = '\''C0001'\''"}'
```

## Testing

dbt tests are defined in `models/staging/schema.yml` and `models/marts/schema.yml`:

| Test                          | Model / Source        | Column          |
|-------------------------------|-----------------------|-----------------|
| `unique`                      | source.customer       | `cust_id`       |
| `not_null`                    | source.customer       | `cust_id`       |
| `accepted_values`             | source.customer       | `gender`        |
| `accepted_values`             | source.customer       | `marital_status`|
| `unique`                      | stg_customer          | `cust_id`       |
| `not_null`                    | stg_customer          | `cust_id`       |
| `unique`                      | customer_new          | `cust_id`       |
| `not_null`                    | customer_new          | `cust_id`       |
| `not_null`                    | customer_new          | `income`        |
| `not_null`                    | customer_new          | `age`           |
| `not_null`                    | customer_new          | `years_with_bank`|
| `accepted_values`             | customer_new          | `gender`        |
| `accepted_values`             | customer_new          | `marital_status`|

Run all tests:

```bash
dbt test
```

## Legacy Scripts Reference

The original Teradata scripts are preserved in the repository root for reference:

- **FastLoad:** `Customer_fastload.fl.txt`
- **MultiLoad:** `CustomerUPDATE.ml`, `Customerinsert.ml.txt`, `Customerdelete.ml.txt`
- **TPT:** `Export.tpt.txt`, `tptscript.txt`, `mloadtpt.txt`
- **BTEQ:** `Condbteq.bteq`, `Condbteq2.bteq`, `Export.bteq.txt`, `csvexport.bteq.txt`
- **FastExport:** `FastExport.fexp.txt`, `FastExport_1.fexp.txt`

All scripts previously used hardcoded credentials (`.logon 192.168.128.128/dbc,dbc`) which have been replaced by environment-variable-based configuration.
