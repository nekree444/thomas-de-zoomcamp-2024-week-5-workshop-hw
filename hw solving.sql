CREATE MATERIALIZED VIEW avg_min_max AS
    SELECT 
        taxi_zone_pu.Zone as pickup_zone,
        taxi_zone_do.Zone as dropoff_zone,
        avg(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) as avg_time,
        min(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) as min_time,
        max(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) as max_time,
        count(*) as count
    FROM
        trip_data
    JOIN taxi_zone as taxi_zone_pu
        ON trip_data.PULocationID = taxi_zone_pu.location_id
    JOIN taxi_zone as taxi_zone_do
        ON trip_data.DOLocationID = taxi_zone_do.location_id
    GROUP BY
        pickup_zone, dropoff_zone
    HAVING
        avg(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) >= min(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60);

SELECT * FROM avg_min_max ORDER BY avg_time DESC LIMIT 1;



WITH t AS (
    SELECT
        MAX(trip_data.tpep_pickup_datetime) as latest_pickup_time,
        (MAX(trip_data.tpep_pickup_datetime) - INTERVAL '17' HOUR) as seventeen_hours_before
    FROM
        trip_data
)
SELECT
    taxi_zone.Zone as fu, count(*)
FROM t,
    trip_data
JOIN taxi_zone
    ON trip_data.DOLocationID = taxi_zone.location_id
WHERE trip_data.tpep_pickup_datetime BETWEEN t.seventeen_hours_before AND t.latest_pickup_time
GROUP BY fu
ORDER BY count DESC LIMIT 5;





























-- gets highest averages from each zone regardless if it was a pickup or dropoff zone
SELECT 
    zone_name,
    avg(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) as avg_time,
    min(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) as min_time,
    max(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) as max_time
FROM (
    SELECT 
        taxi_zone_pu.Zone as zone_name,
        tpep_pickup_datetime,
        tpep_dropoff_datetime
    FROM 
        trip_data
    JOIN taxi_zone AS taxi_zone_pu
        ON trip_data.PULocationID = taxi_zone_pu.location_id
    UNION ALL
    SELECT 
        taxi_zone_do.Zone as zone_name,
        tpep_pickup_datetime,
        tpep_dropoff_datetime
    FROM 
        trip_data
    JOIN taxi_zone AS taxi_zone_do
        ON trip_data.DOLocationID = taxi_zone_do.location_id
) AS combined_zones
GROUP BY 
    zone_name
ORDER BY 
    zone_name ASC
LIMIT 10;

-- gets highest averages with symmetricity
SELECT 
        LEAST(taxi_zone_pu.Zone, taxi_zone_do.Zone) as zone1,
        GREATEST(taxi_zone_pu.Zone, taxi_zone_do.Zone) as zone2,
        avg(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) as avg_time,
        min(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) as min_time,
        max(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) as max_time
    FROM
        trip_data
    JOIN taxi_zone as taxi_zone_pu
        ON trip_data.PULocationID = taxi_zone_pu.location_id
    JOIN taxi_zone as taxi_zone_do
        ON trip_data.DOLocationID = taxi_zone_do.location_id
    GROUP BY
        1, 2
    ORDER BY 
        avg_time DESC
    LIMIT 10;

-- q3 except the latest time for every station
WITH t AS (
    SELECT 
        taxi_zone.Zone as taxi_zone,
        MAX(trip_data.tpep_pickup_datetime) as latest_pickup_time,
        (MAX(trip_data.tpep_pickup_datetime)- INTERVAL '17' HOUR) as seventeen
    FROM 
        trip_data
    JOIN taxi_zone
        ON trip_data.PULocationID = taxi_zone.location_id
    GROUP BY
        taxi_zone.Zone
)
SELECT t.taxi_zone as taxi_zone, count(*)
FROM trip_data
JOIN taxi_zone
    ON trip_data.PULocationID = taxi_zone.location_id
JOIN t
    ON taxi_zone.Zone = t.taxi_zone
WHERE trip_data.tpep_dropoff_datetime BETWEEN t.seventeen AND t.latest_pickup_time
GROUP BY t.taxi_zone
ORDER BY count DESC;