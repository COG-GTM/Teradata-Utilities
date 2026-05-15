-- =============================================================================
-- tpt_export_customer.sql
-- Replaces: Export.tpt.txt, tptscript.txt, FastExport.fexp.txt,
--           FastExport_1.fexp.txt, Export.bteq.txt, csvexport.bteq.txt
--           (All Teradata export/unload operations)
--
-- Mapping:
--   TPT EXPORT operator    -> COPY INTO @stage FROM (SELECT ...)
--   FastExport             -> COPY INTO @stage FROM (SELECT ...)
--   BTEQ .export           -> COPY INTO @stage FROM (SELECT ...)
--   FILE_WRITER            -> GET @stage to local file
--   MAXSESSIONS            -> Snowflake auto-parallelizes
-- =============================================================================

USE DATABASE FINANCIAL;
USE SCHEMA PUBLIC;

-- ---------------------------------------------------------------------------
-- Export 1: Full customer export (pipe-delimited)
-- Replaces: Export.tpt.txt / tptscript.txt
-- ---------------------------------------------------------------------------
COPY INTO @FINANCIAL.PUBLIC.EXPORT_STAGE/customer_export/customer_full.csv
FROM (
    SELECT
        CUST_ID,
        INCOME,
        AGE,
        YEARS_WITH_BANK,
        NBR_CHILDREN,
        GENDER,
        MARITAL_STATUS
    FROM FINANCIAL.PUBLIC.CUSTOMER
)
FILE_FORMAT = (
    TYPE = 'CSV'
    FIELD_DELIMITER = '|'
    COMPRESSION = 'NONE'
)
HEADER = TRUE
OVERWRITE = TRUE
SINGLE = TRUE;

-- Download the exported file locally (run from SnowSQL):
GET @FINANCIAL.PUBLIC.EXPORT_STAGE/customer_export/customer_full.csv
    file://export_output/;

-- ---------------------------------------------------------------------------
-- Export 2: Male customers only
-- Replaces: FastExport_1.fexp.txt (first export block)
-- ---------------------------------------------------------------------------
COPY INTO @FINANCIAL.PUBLIC.EXPORT_STAGE/customer_export/customer_males.csv
FROM (
    SELECT
        CUST_ID,
        INCOME,
        AGE,
        GENDER
    FROM FINANCIAL.PUBLIC.CUSTOMER
    WHERE GENDER = 'M'
)
FILE_FORMAT = (
    TYPE = 'CSV'
    FIELD_DELIMITER = '|'
    COMPRESSION = 'NONE'
)
HEADER = TRUE
OVERWRITE = TRUE
SINGLE = TRUE;

GET @FINANCIAL.PUBLIC.EXPORT_STAGE/customer_export/customer_males.csv
    file://export_output/;

-- ---------------------------------------------------------------------------
-- Export 3: Female customers only
-- Replaces: FastExport_1.fexp.txt (second export block)
-- ---------------------------------------------------------------------------
COPY INTO @FINANCIAL.PUBLIC.EXPORT_STAGE/customer_export/customer_females.csv
FROM (
    SELECT
        CUST_ID,
        INCOME,
        AGE,
        GENDER
    FROM FINANCIAL.PUBLIC.CUSTOMER
    WHERE GENDER = 'F'
)
FILE_FORMAT = (
    TYPE = 'CSV'
    FIELD_DELIMITER = '|'
    COMPRESSION = 'NONE'
)
HEADER = TRUE
OVERWRITE = TRUE
SINGLE = TRUE;

GET @FINANCIAL.PUBLIC.EXPORT_STAGE/customer_export/customer_females.csv
    file://export_output/;

-- ---------------------------------------------------------------------------
-- Export 4: CSV export (comma-delimited)
-- Replaces: csvexport.bteq.txt
-- ---------------------------------------------------------------------------
COPY INTO @FINANCIAL.PUBLIC.EXPORT_STAGE/customer_export/customer_csv.csv
FROM (
    SELECT
        CUST_ID,
        INCOME
    FROM FINANCIAL.PUBLIC.CUSTOMER
)
FILE_FORMAT = (
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    COMPRESSION = 'NONE'
)
HEADER = TRUE
OVERWRITE = TRUE
SINGLE = TRUE;

GET @FINANCIAL.PUBLIC.EXPORT_STAGE/customer_export/customer_csv.csv
    file://export_output/;
