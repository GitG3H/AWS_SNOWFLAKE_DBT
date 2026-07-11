{{ config(materialized='incremental', unique_key='listing_id') }}

SELECT 
    listing_id,
    host_id,
    property_type,
    room_type,
    city,
    country,
    price_per_night,
    {{ tag('CAST(price_per_night AS INT)') }} AS price_per_night_tag,
    created_at
FROM {{ ref('bronze_listings') }}
