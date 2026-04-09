-- customer_new.sql
-- Incremental (upsert) model replacing the MultiLoad upsert logic from
-- CustomerUPDATE.ml. Uses merge strategy to INSERT new rows and UPDATE
-- income, age, years_with_bank for existing rows matched on cust_id.
--
-- Original MultiLoad logic (CustomerUPDATE.ml lines 14-29):
--   DO INSERT FOR MISSING UPDATE ROWS
--   UPDATE ... SET YEARS_WITH_BANK, income, age WHERE CUST_ID = :in_cust_id
--   INSERT INTO ... VALUES (all columns)

{{
  config(
    materialized='incremental',
    unique_key='cust_id',
    incremental_strategy='merge',
    merge_update_columns=['income', 'age', 'years_with_bank']
  )
}}

SELECT
    cust_id,
    income,
    age,
    years_with_bank,
    nbr_children,
    gender,
    marital_status
FROM {{ ref('stg_customer') }}
