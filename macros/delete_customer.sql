-- delete_customer.sql
-- Macro to handle customer delete operations.
-- Replaces the delete logic from Customerdelete.ml.txt.
--
-- Usage examples:
--   dbt run-operation delete_customers --args '{"condition": "cust_id = '\''C0001'\''"}'
--   dbt run-operation delete_customers --args '{"condition": "1=1"}'  (delete all)

{% macro delete_customers(condition) %}
  {% set query %}
    DELETE FROM {{ target.schema }}.customer_new
    WHERE {{ condition }};
  {% endset %}
  {% do run_query(query) %}
  {{ log("Deleted rows from customer_new where " ~ condition, info=True) }}
{% endmacro %}
