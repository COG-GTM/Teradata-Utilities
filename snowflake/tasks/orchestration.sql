-- =============================================================================
-- orchestration.sql
-- Snowflake Task definitions that replace the implicit ordering of the
-- original Teradata BTEQ / TPT scripts.
--
-- Execution order:
--   1. DDL setup (run once manually via the ddl/ scripts)
--   2. TASK_FASTLOAD_CUSTOMER_NEW      - Load raw data via FastLoad pattern
--   3. TASK_MLOAD_INSERT_CUSTOMER      - Load data into TPCH via MultiLoad pattern
--   4. TASK_MLOAD_UPSERT_CUSTOMER      - Upsert data via MERGE pattern
--   5. TASK_TPT_LOAD_CUSTOMER          - Load data via TPT pattern
--   6. TASK_CONDITIONAL_LOAD           - Conditional table setup + data copy
--   7. TASK_EXPORT_CUSTOMER            - Export data to stage files
--
-- Prerequisites:
--   - A warehouse (e.g., ETL_WH) must exist
--   - All DDL scripts (01-05) must have been executed
--   - Data files must be staged via PUT commands
-- =============================================================================

USE DATABASE FINANCIAL;
USE SCHEMA PUBLIC;

-- ---------------------------------------------------------------------------
-- Root task: FastLoad pattern
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TASK FINANCIAL.PUBLIC.TASK_FASTLOAD_CUSTOMER_NEW
    WAREHOUSE = ETL_WH
    SCHEDULE  = 'USING CRON 0 2 * * * America/New_York'  -- Daily at 2 AM ET
AS
    COPY INTO FINANCIAL.PUBLIC.CUSTOMER_NEW
        (CUST_ID, INCOME, AGE, YEARS_WITH_BANK, NBR_CHILDREN, GENDER, MARITAL_STATUS)
    FROM @FINANCIAL.PUBLIC.CUSTOMER_STAGE/fastload/
        FILE_FORMAT = (FORMAT_NAME = 'FINANCIAL.PUBLIC.PIPE_DELIMITED_FORMAT')
        ON_ERROR = 'CONTINUE'
        PURGE = TRUE;

-- ---------------------------------------------------------------------------
-- Child task: MultiLoad INSERT pattern (runs after FastLoad)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TASK TPCH.PUBLIC.TASK_MLOAD_INSERT_CUSTOMER
    WAREHOUSE = ETL_WH
    AFTER FINANCIAL.PUBLIC.TASK_FASTLOAD_CUSTOMER_NEW
AS
    COPY INTO TPCH.PUBLIC.CUSTOMER_NEW_ML
        (CUST_ID, INCOME, AGE, YEARS_WITH_BANK, NBR_CHILDREN, GENDER, MARITAL_STATUS)
    FROM @TPCH.PUBLIC.CUSTOMER_STAGE/mload_insert/
        FILE_FORMAT = (FORMAT_NAME = 'TPCH.PUBLIC.PIPE_DELIMITED_FORMAT')
        ON_ERROR = 'CONTINUE'
        PURGE = TRUE;

-- ---------------------------------------------------------------------------
-- Child task: MultiLoad UPSERT / MERGE pattern (runs after INSERT)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TASK FINANCIAL.PUBLIC.TASK_MLOAD_UPSERT_CUSTOMER
    WAREHOUSE = ETL_WH
    AFTER TPCH.PUBLIC.TASK_MLOAD_INSERT_CUSTOMER
AS
BEGIN
    CREATE TEMPORARY TABLE IF NOT EXISTS FINANCIAL.PUBLIC.CUSTOMER_UPSERT_STG (
        CUST_ID          VARCHAR(25)  NOT NULL,
        INCOME           VARCHAR(25),
        AGE              VARCHAR(2),
        YEARS_WITH_BANK  VARCHAR(2),
        NBR_CHILDREN     VARCHAR(2),
        GENDER           VARCHAR(2),
        MARITAL_STATUS   VARCHAR(2)
    );

    COPY INTO FINANCIAL.PUBLIC.CUSTOMER_UPSERT_STG
        (CUST_ID, INCOME, AGE, YEARS_WITH_BANK, NBR_CHILDREN, GENDER, MARITAL_STATUS)
    FROM @FINANCIAL.PUBLIC.CUSTOMER_STAGE/mload_upsert/
        FILE_FORMAT = (FORMAT_NAME = 'FINANCIAL.PUBLIC.PIPE_DELIMITED_FORMAT')
        ON_ERROR = 'CONTINUE'
        PURGE = TRUE;

    MERGE INTO FINANCIAL.PUBLIC.CUSTOMER_NEW AS tgt
    USING FINANCIAL.PUBLIC.CUSTOMER_UPSERT_STG AS src
        ON tgt.CUST_ID = src.CUST_ID
    WHEN MATCHED THEN UPDATE SET
        tgt.YEARS_WITH_BANK = src.YEARS_WITH_BANK,
        tgt.INCOME          = src.INCOME,
        tgt.AGE             = src.AGE
    WHEN NOT MATCHED THEN INSERT
        (CUST_ID, INCOME, AGE, YEARS_WITH_BANK, NBR_CHILDREN, GENDER, MARITAL_STATUS)
    VALUES
        (src.CUST_ID, src.INCOME, src.AGE, src.YEARS_WITH_BANK,
         src.NBR_CHILDREN, src.GENDER, src.MARITAL_STATUS);

    DROP TABLE IF EXISTS FINANCIAL.PUBLIC.CUSTOMER_UPSERT_STG;
END;

-- ---------------------------------------------------------------------------
-- Child task: TPT Load pattern (runs after UPSERT)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TASK FINANCIAL.PUBLIC.TASK_TPT_LOAD_CUSTOMER
    WAREHOUSE = ETL_WH
    AFTER FINANCIAL.PUBLIC.TASK_MLOAD_UPSERT_CUSTOMER
AS
    COPY INTO FINANCIAL.PUBLIC.CUSTOMER_TPT_MLOAD
        (CUST_ID, INCOME, AGE, YEARS_WITH_BANK, NBR_CHILDREN, GENDER, MARITAL_STATUS)
    FROM @FINANCIAL.PUBLIC.CUSTOMER_STAGE/tpt_load/
        FILE_FORMAT = (FORMAT_NAME = 'FINANCIAL.PUBLIC.PIPE_DELIMITED_FORMAT')
        ON_ERROR = 'CONTINUE'
        PURGE = TRUE;

-- ---------------------------------------------------------------------------
-- Child task: Conditional load (runs after TPT Load)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TASK FINANCIAL.PUBLIC.TASK_CONDITIONAL_LOAD
    WAREHOUSE = ETL_WH
    AFTER FINANCIAL.PUBLIC.TASK_TPT_LOAD_CUSTOMER
AS
    CALL FINANCIAL.PUBLIC.CONDITIONAL_LOAD_CUSTOMER_AUG18();

-- ---------------------------------------------------------------------------
-- Child task: Export data (runs after Conditional Load)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TASK FINANCIAL.PUBLIC.TASK_EXPORT_CUSTOMER
    WAREHOUSE = ETL_WH
    AFTER FINANCIAL.PUBLIC.TASK_CONDITIONAL_LOAD
AS
    COPY INTO @FINANCIAL.PUBLIC.EXPORT_STAGE/customer_export/customer_full.csv
    FROM (
        SELECT CUST_ID, INCOME, AGE, YEARS_WITH_BANK, NBR_CHILDREN, GENDER, MARITAL_STATUS
        FROM FINANCIAL.PUBLIC.CUSTOMER
    )
    FILE_FORMAT = (TYPE = 'CSV' FIELD_DELIMITER = '|' COMPRESSION = 'NONE')
    HEADER = TRUE
    OVERWRITE = TRUE
    SINGLE = TRUE;

-- ---------------------------------------------------------------------------
-- Resume tasks (tasks are created in suspended state by default)
-- ---------------------------------------------------------------------------
ALTER TASK FINANCIAL.PUBLIC.TASK_EXPORT_CUSTOMER       RESUME;
ALTER TASK FINANCIAL.PUBLIC.TASK_CONDITIONAL_LOAD       RESUME;
ALTER TASK FINANCIAL.PUBLIC.TASK_TPT_LOAD_CUSTOMER      RESUME;
ALTER TASK FINANCIAL.PUBLIC.TASK_MLOAD_UPSERT_CUSTOMER  RESUME;
ALTER TASK TPCH.PUBLIC.TASK_MLOAD_INSERT_CUSTOMER       RESUME;
ALTER TASK FINANCIAL.PUBLIC.TASK_FASTLOAD_CUSTOMER_NEW  RESUME;
