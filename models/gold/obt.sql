{% set configs = [
    {
        "table": "AIRBNB.GOLD.OBT",
        "columns": "GOLD_OBT.LISTING_ID, GOLD_OBT.BOOKING_ID, GOLD_OBT.HOST_ID,GOLD_OBT.TOTAL_AMOUNT, GOLD_OBT.CLEANING_FEE, GOLD_OBT.BATHROOMS, GOLD_obt.HOST_ID, GOLD_obt.TOTAL_AMOUNT, GOLD_OBT.PRICE_PER_NIGHT ",
        "alias": "GOLD_OBT"
    },
    {
        "table": "AIRBNB.GOLD.DIM_LISTINGS",
        "columns": "",
        "alias": "GOLD_listings",
        "join_condition": "GOLD_OBT.listing_id = DIM_listings.listing_id"
    },
    {
        "table": "AIRBNB.GOLD.DIM_HOSTS",
        "columns": "",
        "alias": "GOLD_hosts",
        "join_condition": "GOLD_OBT.host_id = DIM_hosts.host_id"
    }
]
%}


SELECT 
       {{ config[0]['columns'] }} 
FROM 
    {% for config in configs %}
    {% if loop.first %}
        {{ config['table'] }} AS {{ config['alias'] }}
    {% else %}
        LEFT JOIN {{ config['table'] }} AS {{ config['alias'] }} 
        ON {{ config['join_condition'] }}
        {% endif %}
        {% endfor %}