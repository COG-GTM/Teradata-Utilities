-- =============================================================================
-- mload_upsert_customer.sql
-- Replaces: CustomerUPDATE.ml and data_files/CustomerUPDATE.ml
--           (Teradata MultiLoad UPSERT with DO INSERT FOR MISSING UPDATE ROWS)
--
-- Mapping:
--   .LOGTABLE                       -> Not needed
--   .DML LABEL UPDCUST              -> MERGE statement
--   DO INSERT FOR MISSING UPDATE ROWS -> WHEN NOT MATCHED THEN INSERT
--   UPDATE ... WHERE CUST_ID=       -> WHEN MATCHED THEN UPDATE
--   FORMAT VARTEXT'|'               -> PIPE_DELIMITED_FORMAT
-- =============================================================================

USE DATABASE FINANCIAL;
USE SCHEMA PUBLIC;

-- Step 1: Upload the data file to the internal stage.
PUT file://data/customer_incoming_pipe.txt @FINANCIAL.PUBLIC.CUSTOMER_STAGE/mload_upsert/
    AUTO_COMPRESS = TRUE
    OVERWRITE = TRUE;

-- Step 2: Create a temporary staging table for the incoming data.
CREATE TEMPORARY TABLE FINANCIAL.PUBLIC.CUSTOMER_UPSERT_STG (
    CUST_ID          VARCHAR(25)  NOT NULL,
    INCOME           VARCHAR(25),
    AGE              VARCHAR(2),
    YEARS_WITH_BANK  VARCHAR(2),
    NBR_CHILDREN     VARCHAR(2),
    GENDER           VARCHAR(2),
    MARITAL_STATUS   VARCHAR(2)
);

-- Step 3: Load data into the staging table.
COPY INTO FINANCIAL.PUBLIC.CUSTOMER_UPSERT_STG
    (CUST_ID, INCOME, AGE, YEARS_WITH_BANK, NBR_CHILDREN, GENDER, MARITAL_STATUS)
FROM @FINANCIAL.PUBLIC.CUSTOMER_STAGE/mload_upsert/
    FILE_FORMAT = (FORMAT_NAME = 'FINANCIAL.PUBLIC.PIPE_DELIMITED_FORMAT')
    ON_ERROR = 'CONTINUE'
    PURGE = TRUE;

-- Step 4: MERGE into the target table.
-- WHEN MATCHED: update YEARS_WITH_BANK, INCOME, AGE
--   (matches CustomerUPDATE.ml lines 16-18:
--    SET YEARS_WITH_BANK=:in_years_with_bank, income=:in_income, age=:in_age)
-- WHEN NOT MATCHED: insert all 7 columns
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

-- Step 5: Clean up the staging table.
DROP TABLE IF EXISTS FINANCIAL.PUBLIC.CUSTOMER_UPSERT_STG;
