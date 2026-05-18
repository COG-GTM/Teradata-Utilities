-- =============================================================================
-- seed_customer.sql
-- Seeds the FINANCIAL.PUBLIC.CUSTOMER table from customer_existing.csv.
-- This table is the source for all export operations and the conditional load
-- procedure (CUSTOMER_AUG18). Must be run before any exports or conditional
-- logic scripts.
-- =============================================================================

USE DATABASE FINANCIAL;
USE SCHEMA PUBLIC;

-- Step 1: Upload the CSV data file to the internal stage.
PUT file://data/customer_existing.csv @FINANCIAL.PUBLIC.CUSTOMER_STAGE/seed/
    AUTO_COMPRESS = TRUE
    OVERWRITE = TRUE;

-- Step 2: Load data into the CUSTOMER table.
COPY INTO FINANCIAL.PUBLIC.CUSTOMER
    (CUST_ID, INCOME, AGE, YEARS_WITH_BANK, NBR_CHILDREN, GENDER, MARITAL_STATUS)
FROM @FINANCIAL.PUBLIC.CUSTOMER_STAGE/seed/
    FILE_FORMAT = (FORMAT_NAME = 'FINANCIAL.PUBLIC.CSV_WITH_HEADER_FORMAT')
    ON_ERROR = 'CONTINUE'
    PURGE = TRUE;
