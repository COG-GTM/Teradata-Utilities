# Data Files

This directory contains the sample customer data files used by the Snowflake load scripts.

## Files

| File | Format | Description |
|------|--------|-------------|
| `customer_existing.csv` | CSV (comma-delimited, with header) | Existing customer records for seeding the `CUSTOMER` table |
| `customer_incoming.csv` | CSV (comma-delimited, with header) | New/updated customer records for upsert operations |
| `customer_incoming_pipe.txt` | Pipe-delimited (`\|`), no header | Customer records in the same format used by Teradata FastLoad/MultiLoad/TPT |

## Schema

All files share the same 7-column schema:

| Column | Description |
|--------|-------------|
| `CUST_ID` | Customer identifier (e.g., `C0001`) |
| `INCOME` | Annual income |
| `AGE` | Customer age |
| `YEARS_WITH_BANK` | Tenure with the bank |
| `NBR_CHILDREN` | Number of children |
| `GENDER` | Gender code (`M`, `F`, or `X`) |
| `MARITAL_STATUS` | Marital status (`Y`, `N`, or `Z`) |

## Uploading to Snowflake

Use the `PUT` command from SnowSQL or the Snowflake CLI to upload files to an internal stage before running `COPY INTO`:

```sql
-- Upload pipe-delimited file to FINANCIAL stage
PUT file://snowflake/data/customer_incoming_pipe.txt @FINANCIAL.PUBLIC.CUSTOMER_STAGE/
    AUTO_COMPRESS = TRUE
    OVERWRITE = TRUE;

-- Upload CSV file to FINANCIAL stage
PUT file://snowflake/data/customer_existing.csv @FINANCIAL.PUBLIC.CUSTOMER_STAGE/
    AUTO_COMPRESS = TRUE
    OVERWRITE = TRUE;

-- Upload pipe-delimited file to TPCH stage
PUT file://snowflake/data/customer_incoming_pipe.txt @TPCH.PUBLIC.CUSTOMER_STAGE/
    AUTO_COMPRESS = TRUE
    OVERWRITE = TRUE;
```

Alternatively, use the Snowflake web UI (Snowsight) to upload files via the stage browser.
