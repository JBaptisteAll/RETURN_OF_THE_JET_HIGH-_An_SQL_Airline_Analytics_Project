/* =====================================================
Projet       : flights
Fichier      : 01_eda_flights.sql
Auteur       : JB Allombert
Objet        : Exploration de données 
Date         : 2025-09-10
===================================================== */


-- Calculate the area per employee for each airport and order by this value in order
SELECT
    *,
    airport_size_m2 / airport_employees AS m2_per_employee
FROM airports
ORDER BY m2_per_employee;

SELECT TOP 10
    *
FROM flights;

-- Calculate the total number of delayed departures and average delay time for each airport
-- considering both departures and arrivals, and order by the total number of delays
WITH delayed_flights AS(
    SELECT 
        departure_airport_code AS airport_code,
        COUNT(flight_status) AS num_delays,
        AVG(delay_minutes) AS avg_delay
    FROM flights AS f
    WHERE flight_status = 'delayed'
    GROUP BY departure_airport_code
    
    UNION

    SELECT 
        destination_airport_code AS airport_code,
        COUNT(flight_status) AS num_delays,
        AVG(delay_minutes) AS avg_delay
    FROM flights
    WHERE flight_status = 'delayed'
    GROUP BY destination_airport_code
    )

SELECT 
    df.airport_code,
    a.airport_name,
    a.city,
    SUM(num_delays) AS total_num_delays,
    AVG(avg_delay) AS overall_avg_delay_in_minutes,
    a.airport_size_m2 / a.airport_employees AS m2_per_employee
FROM delayed_flights AS df 
JOIN airports AS a ON df.airport_code = a.airport_code
GROUP BY df.airport_code, a.airport_name, a.city, a.airport_size_m2 / a.airport_employees
ORDER BY total_num_delays DESC
;
-- We can see that the total_num_delays when goes over 300 the avg_delay is above 30 minutes


-- Calculate the total number of delayed departures and average delay time for each airline
-- considering both departures and arrivals, and order by the total number of delays
WITH delayed_flights AS(
    SELECT 
        departure_airport_code AS airport_code,
        COUNT(flight_status) AS num_delays,
        AVG(delay_minutes) AS avg_delay,
        airline_code
    FROM flights AS f
    WHERE flight_status = 'delayed'
    GROUP BY departure_airport_code, airline_code
    
    UNION

    SELECT 
        destination_airport_code AS airport_code,
        COUNT(flight_status) AS num_delays,
        AVG(delay_minutes) AS avg_delay,
        airline_code
    FROM flights
    WHERE flight_status = 'delayed'
    GROUP BY destination_airport_code, airline_code
    )

SELECT 
    df.airline_code,
    a.airline_name,
    SUM(num_delays) AS total_num_delays,
    AVG(avg_delay) AS overall_avg_delay
FROM delayed_flights AS df 
JOIN airlines AS a ON df.airline_code = a.airline_code
GROUP BY df.airline_code, a.airline_name
ORDER BY total_num_delays DESC
;


SELECT TOP 10
    *   
FROM flights;

-- Calculate the total number of passengers and total revenue for each airline,
-- as well as the average revenue per passenger and average revenue per flight
SELECT
    a.airline_name,
    SUM(passenger_count) AS total_passengers,
    SUM(revenue) AS total_revenue,
    ROUND(AVG(revenue / passenger_count),2) AS avg_revenue_per_passenger,
    ROUND(AVG(revenue),2) AS avg_revenue_per_flight
FROM flights AS f
JOIN airlines AS a ON f.airline_code = a.airline_code
GROUP BY a.airline_name
ORDER BY avg_revenue_per_passenger DESC



SELECT TOP 10 
    *
FROM flights

-- Find the top 3 months with the highest total delay time in hours
-- and the top 3 months with the highest number of delays
SELECT TOP 3
    YEAR(departure_time) AS flight_year,
    MONTH(departure_time) AS flight_month,
    SUM(delay_minutes) / 60 AS total_delay
FROM flights
GROUP BY YEAR(departure_time), MONTH(departure_time)
ORDER BY total_delay DESC

-- Find the top 3 months with the highest number of delays
SELECT TOP 3
    YEAR(departure_time) AS flight_year,
    MONTH(departure_time) AS flight_month,
    SUM(delay_minutes) / 60 AS total_delay_in_hours,
    COUNT(*) AS total_num_delays
FROM flights
WHERE flight_status = 'Delayed'
GROUP BY YEAR(departure_time), MONTH(departure_time)
ORDER BY total_num_delays DESC


SELECT TOP 10
    *
FROM passenger_flights

-- Calculate the total revenue for each ticket class
SELECT
    ticket_class,
    SUM(ticket_price) AS total_revenue
FROM passenger_flights
GROUP BY ticket_class

-- Calculate the average ticket price for each ticket class in each month
-- and order by average ticket price in descending order
SELECT 
    DISTINCT MONTH(booking_date),
    ticket_class,
    AVG(ticket_price) AS avg_price
FROM passenger_flights
GROUP BY MONTH(booking_date), ticket_class
ORDER BY avg_price DESC

-- Calculate the average ticket price for each ticket class in each month
-- and find the top 3 months with the highest average ticket price for each ticket class
WITH avg_ticket_price AS (
    SELECT 
        MONTH(booking_date) AS booking_month,
        ticket_class,
        AVG(ticket_price) AS avg_price
    FROM passenger_flights
    GROUP BY MONTH(booking_date), ticket_class
)
SELECT 
    ticket_class,
    booking_month,
    avg_price
FROM (
    SELECT
        ticket_class,
        booking_month,
        avg_price,
        ROW_NUMBER() OVER (PARTITION BY ticket_class ORDER BY avg_price DESC) AS rn
    FROM avg_ticket_price
) AS ranked
WHERE rn <= 3
ORDER BY ticket_class, avg_price DESC
;

-- Calculate the total number of bookings for each month and year
-- and order by total number of bookings in ascending order
SELECT
    MONTH(booking_date) AS booking_month,
    YEAR(booking_date) AS booking_year,
    COUNT(*) AS total_bookings
FROM passenger_flights
GROUP BY MONTH(booking_date), YEAR(booking_date)
ORDER BY total_bookings
-- We can see that the months 6 and 7 2025 have only 1 and 7 bookings respectively

SELECT
    YEAR(booking_date) AS booking_year,
    COUNT(*) AS total_bookings
FROM passenger_flights
GROUP BY YEAR(booking_date)
ORDER BY total_bookings


SELECT
    ticket_class,
    MONTH(booking_date) AS booking_month,
    YEAR(booking_date) AS booking_year,
    COUNT(*) AS total_bookings
FROM passenger_flights
GROUP BY MONTH(booking_date), YEAR(booking_date), ticket_class
ORDER BY total_bookings

-- Find all bookings made in the year 2025
SELECT
    *
FROM passenger_flights
WHERE YEAR(booking_date) = 2025


SELECT
    *
FROM passenger_flights AS pf
JOIN passenger AS p ON p.passenger_id = pf.passenger_id
WHERE YEAR(pf.booking_date) = 2025


SELECT *
FROM aircraft
-- Find all flights that are likely to run out of fuel before reaching their 
-- destination
-- assuming that the burn rate is constant throughout the flight
WITH flight_duration_in_minutes AS (
    SELECT
        f.departure_time,
        f.arrival_time,
        DATEDIFF(MINUTE, f.departure_time, arrival_time) AS flight_duration_in_minutes,
        f.flight_id,
        a.aircraft_id,
        a.aircraft_type,
        a.fuel_capacity_liters,
        a.burn_rate_liters_per_minute
    FROM flights AS f 
    JOIN aircraft AS a ON a.aircraft_id = f.aircraft_id
)
SELECT 
    *,
    burn_rate_liters_per_minute * flight_duration_in_minutes AS total_fuel_consumed
FROM flight_duration_in_minutes
WHERE fuel_capacity_liters < (burn_rate_liters_per_minute * flight_duration_in_minutes)
ORDER BY total_fuel_consumed DESC


-- Find all Aircrafts that are likely to run out of fuel before reaching their 
-- destination
-- Assuming constant burn rate during the flight
WITH flight_duration_in_minutes AS (
    SELECT
        f.flight_id,
        a.aircraft_type,
        a.fuel_capacity_liters,
        a.burn_rate_liters_per_minute,
        DATEDIFF(MINUTE, f.departure_time, f.arrival_time) AS flight_duration_in_minutes
    FROM flights AS f 
    JOIN aircraft AS a 
      ON a.aircraft_id = f.aircraft_id
    WHERE f.departure_time IS NOT NULL
      AND f.arrival_time   IS NOT NULL
      AND a.burn_rate_liters_per_minute IS NOT NULL
      AND a.fuel_capacity_liters        IS NOT NULL
)
SELECT
    fd.aircraft_type,
    COUNT(*) AS total_flights,
    SUM(
        CASE 
          WHEN fd.burn_rate_liters_per_minute * fd.flight_duration_in_minutes > fd.fuel_capacity_liters 
          THEN 1 ELSE 0 
        END
    ) AS out_of_fuel_flights,
    CAST(
      100.0 * SUM(
        CASE 
          WHEN fd.burn_rate_liters_per_minute * fd.flight_duration_in_minutes > fd.fuel_capacity_liters 
          THEN 1 ELSE 0 
        END
      ) / NULLIF(COUNT(*), 0) 
      AS DECIMAL(5,2)
    ) AS out_of_fuel_pct
FROM flight_duration_in_minutes AS fd
GROUP BY fd.aircraft_type
ORDER BY out_of_fuel_flights DESC, fd.aircraft_type;



WITH fm AS (
    SELECT
        a.aircraft_type,
        DATEDIFF(MINUTE, f.departure_time, f.arrival_time) AS mins,
        a.fuel_capacity_liters AS cap,
        a.burn_rate_liters_per_minute AS burn
    FROM flights f
    JOIN aircraft a ON a.aircraft_id = f.aircraft_id
    WHERE f.departure_time IS NOT NULL
      AND f.arrival_time   IS NOT NULL
      AND a.burn_rate_liters_per_minute IS NOT NULL
      AND a.fuel_capacity_liters        IS NOT NULL
),
agg AS (
    SELECT
      aircraft_type,
      COUNT(*) AS total_flights,
      SUM(CASE WHEN burn * mins > cap THEN 1 ELSE 0 END) AS out_of_fuel_flights
    FROM fm
    GROUP BY aircraft_type
)
SELECT
  aircraft_type,
  total_flights,
  out_of_fuel_flights,
  CAST(100.0 * out_of_fuel_flights / NULLIF(total_flights, 0) AS DECIMAL(5,2)) AS out_of_fuel_pct,
  RANK() OVER (ORDER BY out_of_fuel_flights DESC, aircraft_type) AS risk_rank
FROM agg
ORDER BY risk_rank;

