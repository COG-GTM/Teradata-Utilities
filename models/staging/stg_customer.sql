-- stg_customer.sql
-- Staging model: selects from the raw customer source and passes through
-- columns with their native types (INTEGER, SMALLINT, CHAR).
--
-- Note: The legacy TPT export scripts (Export.tpt.txt, tptscript.txt) applied
-- CAST(...AS CHAR) for flat-file formatting only. Those casts are NOT applied
-- here so that the marts layer retains correct numeric types. The companion
-- export script (scripts/export_customer_data.py) handles formatting at export time.

SELECT
    cust_id,
    income,
    age,
    years_with_bank,
    nbr_children,
    gender,
    marital_status
FROM {{ source('financial', 'customer') }}
