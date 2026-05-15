-- =============================================================================
-- 02_schemas.sql
-- Create schemas within each database.
-- Snowflake creates a PUBLIC schema by default; these statements ensure it
-- exists explicitly for clarity.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS FINANCIAL.PUBLIC;
CREATE SCHEMA IF NOT EXISTS TPCH.PUBLIC;
