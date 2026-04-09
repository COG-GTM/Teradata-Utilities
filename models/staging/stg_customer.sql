-- stg_customer.sql
-- Staging model: selects from the raw customer source and applies type casting.
-- Replaces the CAST expressions from Export.tpt.txt (lines 35-42) and
-- tptscript.txt (lines 33-43).

WITH source AS (
    SELECT * FROM {{ source('financial', 'customer') }}
)

SELECT
    CAST(cust_id AS CHAR(25))          AS cust_id,
    CAST(income AS CHAR(25))           AS income,
    CAST(age AS CHAR(2))               AS age,
    CAST(years_with_bank AS CHAR(2))   AS years_with_bank,
    CAST(nbr_children AS CHAR(2))      AS nbr_children,
    CAST(gender AS CHAR(2))            AS gender,
    CAST(marital_status AS CHAR(2))    AS marital_status
FROM source
