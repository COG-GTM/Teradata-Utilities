-- =============================================================================
-- 04_file_formats.sql
-- File formats for ingesting pipe-delimited and CSV data files.
-- Replaces: Teradata SET RECORD VARTEXT '|' (FastLoad),
--           FORMAT VARTEXT'|' (MultiLoad), and TEXTDELIMITER (TPT).
-- =============================================================================

USE DATABASE FINANCIAL;

-- Pipe-delimited format (used by FastLoad, MultiLoad UPSERT, TPT Load)
CREATE FILE FORMAT IF NOT EXISTS FINANCIAL.PUBLIC.PIPE_DELIMITED_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = '|'
    SKIP_HEADER = 0
    FIELD_OPTIONALLY_ENCLOSED_BY = NONE
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

-- CSV format with header (used for customer_existing.csv, customer_incoming.csv)
CREATE FILE FORMAT IF NOT EXISTS FINANCIAL.PUBLIC.CSV_WITH_HEADER_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

-- CSV format without header
CREATE FILE FORMAT IF NOT EXISTS FINANCIAL.PUBLIC.CSV_NO_HEADER_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 0
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

USE DATABASE TPCH;

-- Pipe-delimited format for TPCH database (used by MultiLoad INSERT)
CREATE FILE FORMAT IF NOT EXISTS TPCH.PUBLIC.PIPE_DELIMITED_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = '|'
    SKIP_HEADER = 0
    FIELD_OPTIONALLY_ENCLOSED_BY = NONE
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;
