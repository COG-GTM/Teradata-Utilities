-- =============================================================================
-- 05_stages.sql
-- Internal stages for staging data files before COPY INTO.
-- Replaces: Teradata FILE= paths and INFILE references.
-- =============================================================================

USE DATABASE FINANCIAL;

-- Stage for customer data files loaded into FINANCIAL tables
CREATE STAGE IF NOT EXISTS FINANCIAL.PUBLIC.CUSTOMER_STAGE
    FILE_FORMAT = FINANCIAL.PUBLIC.PIPE_DELIMITED_FORMAT;

-- Stage for export/unload operations
CREATE STAGE IF NOT EXISTS FINANCIAL.PUBLIC.EXPORT_STAGE
    FILE_FORMAT = FINANCIAL.PUBLIC.CSV_WITH_HEADER_FORMAT;

USE DATABASE TPCH;

-- Stage for customer data files loaded into TPCH tables
CREATE STAGE IF NOT EXISTS TPCH.PUBLIC.CUSTOMER_STAGE
    FILE_FORMAT = TPCH.PUBLIC.PIPE_DELIMITED_FORMAT;
