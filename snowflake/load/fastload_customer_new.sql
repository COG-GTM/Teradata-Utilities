-- =============================================================================
-- fastload_customer_new.sql
-- Replaces: Customer_fastload.fl.txt (Teradata FastLoad)
--
-- Mapping:
--   FastLoad BEGIN LOADING  -> PUT + COPY INTO
--   ERRORFILES              -> ON_ERROR = 'CONTINUE'
--   CHECKPOINT 100          -> Snowflake built-in transaction handling
--   SET RECORD VARTEXT '|'  -> FILE_FORMAT = PIPE_DELIMITED_FORMAT
--   FILE=...\Customer.txt   -> PUT file to @CUSTOMER_STAGE
-- =============================================================================

USE DATABASE FINANCIAL;
USE SCHEMA PUBLIC;

-- Step 1: Upload the pipe-delimited data file to the internal stage.
-- Run this from SnowSQL or the Snowflake CLI:
PUT file://data/customer_incoming_pipe.txt @FINANCIAL.PUBLIC.CUSTOMER_STAGE/fastload/
    AUTO_COMPRESS = TRUE
    OVERWRITE = TRUE;

-- Step 2: Load data into the target table.
-- ON_ERROR = 'CONTINUE' mirrors Teradata ERRORFILES behavior (skip bad rows).
-- Snowflake handles parallelism and checkpointing automatically.
COPY INTO FINANCIAL.PUBLIC.CUSTOMER_NEW
    (CUST_ID, INCOME, AGE, YEARS_WITH_BANK, NBR_CHILDREN, GENDER, MARITAL_STATUS)
FROM @FINANCIAL.PUBLIC.CUSTOMER_STAGE/fastload/
    FILE_FORMAT = (FORMAT_NAME = 'FINANCIAL.PUBLIC.PIPE_DELIMITED_FORMAT')
    ON_ERROR = 'CONTINUE'
    PURGE = TRUE;
