-- =============================================================================
-- conditional_load.sql
-- Replaces: Condbteq.bteq and Condbteq2.bteq (Teradata BTEQ conditional logic)
--
-- Mapping:
--   .IF ERRORCODE=0 THEN .GOTO  -> IF ... THEN ... ELSE ... END IF
--   .LABEL INSERT_DEMO           -> Sequential flow in BEGIN...END block
--   .IF ACTIVITYCOUNT=0 THEN .QUIT -> IF (row_count = 0) THEN RETURN
--   .RUN FILE=...                -> CALL statements to other stored procedures
-- =============================================================================

USE DATABASE FINANCIAL;
USE SCHEMA PUBLIC;

-- ---------------------------------------------------------------------------
-- Procedure 1: Conditional table setup and data copy
-- Replaces: Condbteq.bteq
--
-- Logic:
--   1. Try to DELETE FROM customer_aug18
--   2. If the table exists (delete succeeds), skip creation and go to insert
--   3. If the table does not exist, CREATE it, then insert
--   4. INSERT INTO customer_aug18 SELECT * FROM customer
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE FINANCIAL.PUBLIC.CONDITIONAL_LOAD_CUSTOMER_AUG18()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    -- Check if the table already exists
    LET table_exists BOOLEAN := FALSE;

    SELECT COUNT(*) INTO :table_exists
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'PUBLIC'
      AND TABLE_NAME   = 'CUSTOMER_AUG18'
      AND TABLE_CATALOG = 'FINANCIAL';

    IF (table_exists) THEN
        -- Table exists: truncate it (equivalent to DELETE FROM in the BTEQ script)
        TRUNCATE TABLE FINANCIAL.PUBLIC.CUSTOMER_AUG18;
    ELSE
        -- Table does not exist: create it
        CREATE TABLE FINANCIAL.PUBLIC.CUSTOMER_AUG18 (
            CUST_ID          VARCHAR(25)  NOT NULL,
            INCOME           VARCHAR(25),
            AGE              VARCHAR(2),
            YEARS_WITH_BANK  VARCHAR(2),
            NBR_CHILDREN     VARCHAR(2),
            GENDER           VARCHAR(2),
            MARITAL_STATUS   VARCHAR(2)
        );
    END IF;

    -- Insert data from the source table
    INSERT INTO FINANCIAL.PUBLIC.CUSTOMER_AUG18
    SELECT * FROM FINANCIAL.PUBLIC.CUSTOMER;

    RETURN 'SUCCESS: CUSTOMER_AUG18 loaded with ' || SQLROWCOUNT || ' rows';
END;
$$;

-- ---------------------------------------------------------------------------
-- Procedure 2: Conditional execution based on row count
-- Replaces: Condbteq2.bteq
--
-- Logic:
--   1. Check if customer_aug18 has any rows
--   2. If empty, return immediately (mirrors .IF ACTIVITYCOUNT=0 THEN .QUIT)
--   3. If rows exist, call another stored procedure
--      (mirrors .RUN FILE=...\run.bteq.txt)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE FINANCIAL.PUBLIC.CONDITIONAL_RUN_IF_DATA_EXISTS()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    LET row_count INTEGER := 0;

    SELECT COUNT(*) INTO :row_count
    FROM FINANCIAL.PUBLIC.CUSTOMER_AUG18;

    IF (row_count = 0) THEN
        RETURN 'SKIPPED: CUSTOMER_AUG18 is empty, no further processing needed';
    END IF;

    -- Delegate to downstream procedure (replaces .RUN FILE=run.bteq.txt).
    -- Replace the procedure name below with the actual downstream logic.
    -- CALL FINANCIAL.PUBLIC.DOWNSTREAM_PROCESSING();

    RETURN 'SUCCESS: CUSTOMER_AUG18 has ' || row_count || ' rows, downstream processing triggered';
END;
$$;
