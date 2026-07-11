{{ config(materialized='incremental', unique_key='host_id') }}

SELECT
    HOST_ID,
    REPLACE(HOST_NAME, ' ', '_') AS HOST_NAME,
    HOST_SINCE AS HOST_SINCE,
    IS_SUPERHOST AS IS_SUPERHOST,
    RESPONSE_RATE AS RESPONSE_RATE,
    CASE 
        WHEN RESPONSE_RATE > 95 THEN 'VERY GOOD'
        WHEN RESPONSE_RATE BETWEEN 80 AND 95 THEN 'GOOD'
        WHEN RESPONSE_RATE > 60  THEN 'FAIR'
        ELSE 'POOR'
    END AS RESPONSE_RATE_QUALITY,
    created_at
FROM {{ ref('bronze_hosts') }}


