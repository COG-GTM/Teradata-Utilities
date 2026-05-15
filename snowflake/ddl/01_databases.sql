-- =============================================================================
-- 01_databases.sql
-- Create the databases used by the customer ETL pipeline.
-- Replaces: Teradata DATABASE statements found across all scripts.
-- =============================================================================

USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS FINANCIAL;
CREATE DATABASE IF NOT EXISTS TPCH;
