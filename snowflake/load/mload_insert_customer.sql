-- =============================================================================
-- mload_insert_customer.sql
-- Replaces: Customerinsert.ml.txt (Teradata MultiLoad INSERT)
--
-- Mapping:
--   .LOGTABLE              -> Not needed; Snowflake tracks load metadata
--   .BEGIN MLOAD TABLES     -> COPY INTO
--   .LAYOUT / .FIELD        -> FILE_FORMAT definition
--   FORMAT VARTEXT'|'       -> PIPE_DELIMITED_FORMAT
--   .DML LABEL INSTCUST     -> Simple COPY INTO (no label needed)
--   INFILE ...              -> PUT file to @CUSTOMER_STAGE
-- =============================================================================

USE DATABASE TPCH;
USE SCHEMA PUBLIC;

-- Step 1: Upload the pipe-delimited data file to the internal stage.
PUT file://data/customer_incoming_pipe.txt @TPCH.PUBLIC.CUSTOMER_STAGE/mload_insert/
    AUTO_COMPRESS = TRUE
    OVERWRITE = TRUE;

-- Step 2: Load data into the target table.
COPY INTO TPCH.PUBLIC.CUSTOMER_NEW_ML
    (CUST_ID, INCOME, AGE, YEARS_WITH_BANK, NBR_CHILDREN, GENDER, MARITAL_STATUS)
FROM @TPCH.PUBLIC.CUSTOMER_STAGE/mload_insert/
    FILE_FORMAT = (FORMAT_NAME = 'TPCH.PUBLIC.PIPE_DELIMITED_FORMAT')
    ON_ERROR = 'CONTINUE'
    PURGE = TRUE;
