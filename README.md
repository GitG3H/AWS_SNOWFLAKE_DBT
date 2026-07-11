# AWS_SNOWFLAKE_DBT

Architecture:
<img width="1100" height="600" alt="image" src="https://github.com/user-attachments/assets/28e3dd4a-9041-4391-a683-c3b50165054b" />


# Challenges and Solutions
## 1. Snowflake securely access S3
Avoid hardcording credentials in SQL, **Storage Integration + IAM Role**

```sql
-- Step 1: Define file format
CREATE FILE FORMAT csv_format
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1;

-- Step 2: Create Stage (pointing to S3)
CREATE OR REPLACE STAGE snowstage
  FILE_FORMAT = csv_format
  URL = 's3://airbnb-data-lakehouse/source/';

-- Step 3: Load data
COPY INTO staging.hosts
FROM @snowstage
FILES = ('hosts.csv')
CREDENTIALS = (aws_key_id = 'XXX', aws_secret_key = 'YYY');
```
## 2. Incremental load with is_incremental()
```sql
{{ config(materialized='incremental') }}

SELECT *
FROM {{ source('staging', 'bookings') }}
{% if is_incremental() %}
  -- Only fetch records newer than existing data
  WHERE CREATED_AT > (
    SELECT COALESCE(MAX(CREATED_AT), '1900-01-01') 
    FROM {{ this }}  -- {{ this }} refers to current table
  )
{% endif %}
```
## 3. Track Historical Changes (SCD Type 2) Upsert: dbt snapshot
```yaml
# snapshots/dim_hosts.yml
snapshots:
  - name: dim_hosts
    relation: ref('hosts')
    config:
      unique_key: HOST_ID
      strategy: timestamp
      updated_at: HOST_CREATED_AT
      dbt_valid_to_current: "to_date('9999-12-31')"
```
## 4. Prevent JOIN logic by Metadata driven pipelines: Config array + Jinja loops

```sql
{% set configs = [
  {
    "table": "SILVER.SILVER_BOOKINGS",
    "columns": "SILVER_bookings.*",
    "alias": "SILVER_bookings"
  },
  {
    "table": "SILVER.SILVER_LISTINGS",
    "columns": "listing_id, city, price",
    "alias": "SILVER_listings",
    "join_condition": "SILVER_bookings.listing_id = SILVER_listings.listing_id"
  },
  {
    "table": "SILVER.SILVER_HOSTS",
    "columns": "host_name, response_rate",
    "alias": "SILVER_hosts",
    "join_condition": "SILVER_listings.host_id = SILVER_hosts.host_id"
  }
] %}

-- Auto-generate JOIN statements
SELECT 
  {% for config in configs %}
    {{ config['columns'] }}{% if not loop.last %},{% endif %}
  {% endfor %}
FROM
  {% for config in configs %}
    {% if loop.first %}
      {{ config['table'] }} AS {{ config['alias'] }}
    {% else %}
      LEFT JOIN {{ config['table'] }} AS {{ config['alias'] }}
        ON {{ config['join_condition'] }}
    {% endif %}
  {% endfor %}
```

## Medallion Architecture
### 1. Bronze: Historical snapshot => Incremental Table, Append only
```sql
-- bronze_hosts.sql
{{ config(materialized='incremental') }}

SELECT *
FROM {{ source('staging', 'hosts') }}
{% if is_incremental() %}
  WHERE CREATED_AT > (SELECT MAX(CREATED_AT) FROM {{ this }})
{% endif %}
```
### 2. Silver: Business logic => Incremental table (Upsert), macros
```sql
-- silver_hosts.sql
{{ config(
  materialized='incremental',
  unique_key='HOST_ID'
) }}

SELECT 
  HOST_ID,
  REPLACE(HOST_NAME, ' ', '_') AS HOST_NAME,  -- Standardization
  RESPONSE_RATE,
  CASE 
    WHEN RESPONSE_RATE > 95 THEN 'VERY GOOD'
    WHEN RESPONSE_RATE > 80 THEN 'GOOD'
    ELSE 'FAIR'
  END AS RESPONSE_RATE_QUALITY,  -- Business classification
  CREATED_AT
FROM {{ ref('bronze_hosts') }}
```
### 3.  Gold: Analytical ready => Table/ Ephemeral => Star Schema 
Ephemeral models(Ghost models): only in memory not in storage

```sql
-- fact.sql (central fact table)
SELECT 
  b.BOOKING_ID,
  b.LISTING_ID,
  b.HOST_ID,
  b.TOTAL_AMOUNT,      -- Numerical
  b.NIGHTS_BOOKED,     -- Numerical
  b.BOOKING_DATE
FROM {{ ref('obt') }} AS b  -- One Big Table
LEFT JOIN {{ ref('dim_hosts') }} AS h
  ON b.HOST_ID = h.HOST_ID
LEFT JOIN {{ ref('dim_listings') }} AS l
  ON b.LISTING_ID = l.LISTING_ID
```

## Data Quality Assurance: dbt tests
Built in tests (Generic) : unique, null
Custom tests (Singular): config severity (error, warn) 










    
