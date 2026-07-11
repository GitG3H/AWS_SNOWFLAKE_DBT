{{
    config(
        materialized = 'ephemeral'
    )
}}

WITH bookings as(
    SELECT
        BOOKING_ID,
        BOOKING_DATE,
        BOOKING_STATUS,
        CREATED_AT
    FROM {{ ref('obt') }}
)
SELECT * FROM bookings