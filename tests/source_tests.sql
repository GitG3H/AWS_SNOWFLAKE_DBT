{{ config(
    severity='warn')}}

select 
1
FROM
{{source('staging', 'bookings')}}
WHERE
    booking_amount < 200