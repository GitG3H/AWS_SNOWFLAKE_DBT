{% set nights_booked = 1 %}
    
SELECT * FROM {{ ref('bronze_hosts') }}
WHERE NIGHTS_BOOKED >= {{ nights_booked }}