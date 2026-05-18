-- =============================================================================
-- tpt_load_customer.sql
-- Replaces: mloadtpt.txt (Teradata Parallel Transporter Load operator)
--
-- Mapping:
--   TPT DEFINE JOB            -> Not needed; Snowflake handles parallelism
--   DEFINE OPERATOR LOAD      -> COPY INTO
--   DEFINE OPERATOR FILE_READER -> PUT + stage
--   TEXTDELIMITER = '|'       -> PIPE_DELIMITED_FORMAT
--   LOGTABLE / MAXSESSIONS    -> Managed automatically by Snowflake
--   TARGETTABLE               -> COPY INTO target
-- =============================================================================

USE DATABASE FINANCIAL;
USE SCHEMA PUBLIC;

-- Step 1: Upload the pipe-delimited data file to the internal stage.
PUT file://data/customer_incoming_pipe.txt @FINANCIAL.PUBLIC.CUSTOMER_STAGE/tpt_load/
    AUTO_COMPRESS = TRUE
    OVERWRITE = TRUE;

-- Step 2: Load data into the target table.
-- Snowflake parallelizes the load automatically; no operator definitions needed.
COPY INTO FINANCIAL.PUBLIC.CUSTOMER_TPT_MLOAD
    (CUST_ID, INCOME, AGE, YEARS_WITH_BANK, NBR_CHILDREN, GENDER, MARITAL_STATUS)
FROM @FINANCIAL.PUBLIC.CUSTOMER_STAGE/tpt_load/
    FILE_FORMAT = (FORMAT_NAME = 'FINANCIAL.PUBLIC.PIPE_DELIMITED_FORMAT')
    ON_ERROR = 'CONTINUE'
    PURGE = TRUE;
