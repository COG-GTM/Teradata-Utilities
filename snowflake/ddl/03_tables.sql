-- =============================================================================
-- 03_tables.sql
-- Create all target tables using the 7-column schema defined in Export.tpt.txt.
-- Replaces: Teradata CREATE TABLE in Condbteq.bteq and implicit table
--           definitions across FastLoad / MultiLoad / TPT scripts.
-- =============================================================================

USE DATABASE FINANCIAL;

-- Main customer table (source for exports)
CREATE TABLE IF NOT EXISTS FINANCIAL.PUBLIC.CUSTOMER (
    CUST_ID      VARCHAR(25)   NOT NULL,
    INCOME       VARCHAR(25),
    AGE          VARCHAR(2),
    YEARS_WITH_BANK VARCHAR(2),
    NBR_CHILDREN VARCHAR(2),
    GENDER       VARCHAR(2),
    MARITAL_STATUS VARCHAR(2)
);

-- FastLoad target table (Customer_fastload.fl.txt)
CREATE TABLE IF NOT EXISTS FINANCIAL.PUBLIC.CUSTOMER_NEW (
    CUST_ID      VARCHAR(25)   NOT NULL,
    INCOME       VARCHAR(25),
    AGE          VARCHAR(2),
    YEARS_WITH_BANK VARCHAR(2),
    NBR_CHILDREN VARCHAR(2),
    GENDER       VARCHAR(2),
    MARITAL_STATUS VARCHAR(2)
);

-- BTEQ conditional-load target (Condbteq.bteq)
CREATE TABLE IF NOT EXISTS FINANCIAL.PUBLIC.CUSTOMER_AUG18 (
    CUST_ID      VARCHAR(25)   NOT NULL,
    INCOME       VARCHAR(25),
    AGE          VARCHAR(2),
    YEARS_WITH_BANK VARCHAR(2),
    NBR_CHILDREN VARCHAR(2),
    GENDER       VARCHAR(2),
    MARITAL_STATUS VARCHAR(2)
);

-- TPT Load target table (mloadtpt.txt)
CREATE TABLE IF NOT EXISTS FINANCIAL.PUBLIC.CUSTOMER_TPT_MLOAD (
    CUST_ID      VARCHAR(25)   NOT NULL,
    INCOME       VARCHAR(25),
    AGE          VARCHAR(2),
    YEARS_WITH_BANK VARCHAR(2),
    NBR_CHILDREN VARCHAR(2),
    GENDER       VARCHAR(2),
    MARITAL_STATUS VARCHAR(2)
);

USE DATABASE TPCH;

-- MultiLoad INSERT target table (Customerinsert.ml.txt)
CREATE TABLE IF NOT EXISTS TPCH.PUBLIC.CUSTOMER_NEW_ML (
    CUST_ID      VARCHAR(25)   NOT NULL,
    INCOME       VARCHAR(25),
    AGE          VARCHAR(2),
    YEARS_WITH_BANK VARCHAR(2),
    NBR_CHILDREN VARCHAR(2),
    GENDER       VARCHAR(2),
    MARITAL_STATUS VARCHAR(2)
);
