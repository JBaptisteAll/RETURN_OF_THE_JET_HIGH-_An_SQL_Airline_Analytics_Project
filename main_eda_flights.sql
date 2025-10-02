/* =====================================================
Projet       : flights
Fichier      : main_eda_flights.sql
Auteur       : JB Allombert
Objet        : Exploration de données 
Date         : 2025-09-16
===================================================== */

-- 1. Passagers

-- Find the top 5 passengers with the highest number of flights
SELECT 
    first_name + ' ' + last_name AS full_name,
    COUNT(pf.flight_id) AS total_flights
FROM passenger AS p  
JOIN passenger_flights AS pf ON pf.passenger_id = p.passenger_id
GROUP BY first_name, last_name
ORDER BY total_flights DESC
;


-- 2. Vols

-- Calculate the total number of flights
SELECT 
    COUNT(*) AS total_flights
FROM flights
;

-- Calculate the total number of cancelled flights
WITH nb_flights AS (
    SELECT 
        COUNT(*) AS total_flights
    FROM flights
), nb_cancelled AS (
    SELECT 
        COUNT(*) AS total_cancelled
    FROM flights
    WHERE flight_status LIKE '_ancel%'
)
SELECT 
    ROUND(CAST(c.total_cancelled AS FLOAT) / f.total_flights * 100,2) AS Cancel_rate_percent
FROM nb_flights AS f
CROSS JOIN nb_cancelled AS c
;

-- Calculate the shortest, longest and average flight duration in minutes
SELECT 
    MIN(DATEDIFF(MINUTE, departure_time, arrival_time)) AS shortest_flight_in_min,
    MAX(DATEDIFF(MINUTE, departure_time, arrival_time)) AS longest_flight_in_min,
    AVG(DATEDIFF(MINUTE, departure_time, arrival_time)) AS avg_flying_time_in_min
FROM flights
;

-- 3. Revenus

-- Calculate the total revenue for each departure airport
SELECT
    ap.airport_name,
    SUM(f.revenue) AS total_revenue
FROM flights AS f
JOIN airports AS ap ON f.departure_airport_code = ap.airport_code
GROUP BY ap.airport_name
;

-- Find the flights with the highest average revenue
SELECT 
    flight_id,
    AVG(revenue) AS avg_revenue
FROM flights
GROUP BY flight_id
ORDER BY avg_revenue DESC
;

-- Calculate the total revenue for each ticket class
SELECT
    ticket_class,
    SUM(ticket_price) AS total_revenue
FROM passenger_flights
GROUP BY ticket_class
;

-- Calculate the average ticket price for each ticket class in each month
-- and order by average ticket price in descending order
SELECT 
    DISTINCT MONTH(booking_date),
    ticket_class,
    AVG(ticket_price) AS avg_price
FROM passenger_flights
GROUP BY MONTH(booking_date), ticket_class
ORDER BY avg_price DESC
;

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

-- Calculate the total revenue for each airline
SELECT
    a.airline_name,
    SUM(f.revenue) AS total_revenue
FROM flights AS f
JOIN airlines AS a ON f.airline_code = a.airline_code
GROUP BY a.airline_name
ORDER BY total_revenue DESC
;

-- Find the flights with the highest average revenue per passenger
SELECT
    flight_id,
    revenue,
    passenger_count,
    ROUND(revenue/passenger_count,2) AS avg_revenue_per_passenger
FROM flights
ORDER BY avg_revenue_per_passenger DESC
;

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
;

-- Calculate the total ticket sales and total revenue for each ticket class
SELECT 
    ticket_class,
    SUM(ticket_price) AS sum_ticket_sold,
    SUM(f.revenue) AS sum_revenue
FROM flights AS f
JOIN passenger_flights AS pf ON f.flight_id = pf.flight_id
GROUP BY ticket_class
;

-- Compare the total number of flights and total revenue for two different airlines
DECLARE @cie_one VARCHAR(50);
DECLARE @cie_two VARCHAR(50);
SET @cie_one = 'Air France';
SET @cie_two = 'Lufthansa';

SELECT
    al.airline_name,
    COUNT(*) AS total_num_of_flights,
    ROUND(SUM(f.revenue),2) AS total_revenue,
    ROUND(AVG(f.revenue),2) AS average_revenue_per_flight,
    ROUND(SUM(f.revenue/f.passenger_count),2) AS avg_revenue_per_passenger    
FROM flights AS f
JOIN airlines AS al ON al.airline_code = f.airline_code
WHERE al.airline_name IN (@cie_one, @cie_two)
GROUP BY al.airline_name
;

-- 4. Appareils

-- Calculate the average age of the aircraft fleet
SELECT 
    YEAR(GETDATE()) AS current_year,
    AVG(YEAR(GETDATE()) - year_built) AS avg_fleet_age,
    AVG(DATEDIFF(YEAR, year_built, (YEAR(GETDATE())))) AS wrong_method
FROM aircraft
;

-- Find the most common aircraft type used in flights
SELECT
    ac.aircraft_type,
    COUNT(*) AS total_of_flights
FROM flights AS f
JOIN aircraft AS ac ON f.aircraft_id = ac.aircraft_id
GROUP BY ac.aircraft_type
ORDER BY total_of_flights DESC
;

-- Find the most popular aircraft type for each airline
WITH popular_aircraft AS (
    SELECT  
        al.airline_name,
        ac.aircraft_type,
        COUNT(f.flight_id) AS total_of_flights,
        RANK() OVER (PARTITION BY al.airline_name ORDER BY COUNT(f.flight_id) DESC) AS rn
    FROM flights AS f  
    JOIN aircraft AS ac ON ac.aircraft_id = f.aircraft_id
    JOIN airlines AS al ON al.airline_code = f.airline_code
    GROUP BY ac.aircraft_type, al.airline_name
)
SELECT *
FROM popular_aircraft
WHERE rn = 1
;

-- 5. Aéroports

-- Calculate the area per employee for each airport
SELECT
    *,
    airport_size_m2 / airport_employees AS m2_per_employee
FROM airports
ORDER BY m2_per_employee
;

-- Find the airports with the highest number of departures
SELECT
    ap.airport_name,
    COUNT(DISTINCT(flight_id)) AS total_num_of_departure
FROM flights AS f
JOIN airports AS ap ON f.departure_airport_code = ap.airport_code
GROUP BY ap.airport_name
ORDER BY total_num_of_departure DESC
;

-- Find the airports with the highest number of arrivals
SELECT
    ap.airport_name,
    COUNT(DISTINCT(flight_id)) AS total_num_of_arrivals
FROM flights AS f
JOIN airports AS ap ON f.destination_airport_code = ap.airport_code
GROUP BY ap.airport_name
ORDER BY total_num_of_arrivals DESC
;

-- Find the airports with the highest total number of flights (arrivals + departures)
WITH departure AS (
    SELECT
        ap.airport_name AS airport_name,
        COUNT(DISTINCT(flight_id)) AS total_num_of_departure
    FROM flights AS f
    JOIN airports AS ap ON f.departure_airport_code = ap.airport_code
    GROUP BY ap.airport_name
), arrival AS (
    SELECT
        ap.airport_name AS airport_name,
        COUNT(DISTINCT(flight_id)) AS total_num_of_arrivals
    FROM flights AS f
    JOIN airports AS ap ON f.destination_airport_code = ap.airport_code
    GROUP BY ap.airport_name
)
SELECT
    a.airport_name,
    total_num_of_arrivals + total_num_of_departure AS total_flights
FROM arrival AS a
JOIN departure AS d ON a.airport_name = d.airport_name
ORDER BY total_flights DESC
;

-- Find the airports with the highest total delay time in minutes
SELECT
    ap.airport_name,
    SUM(f.delay_minutes) AS total_delay_in_minutes
FROM flights AS f
JOIN airports AS ap ON f.departure_airport_code = ap.airport_code
GROUP BY ap.airport_name
;


-- 6. Comportement de réservation

-- Calculate the total number of bookings for each month and year
-- and order by total number of bookings in ascending order
SELECT
    MONTH(booking_date) AS booking_month,
    YEAR(booking_date) AS booking_year,
    COUNT(*) AS total_bookings
FROM passenger_flights
GROUP BY MONTH(booking_date), YEAR(booking_date)
ORDER BY total_bookings;
-- We can see that the months 6 and 7 2025 have only 1 and 7 bookings respectively

-- Find the passengers with the highest number of flights
SELECT 
    p.passenger_id,
    p.first_name,
    p.last_name,
    COUNT(pf.flight_id) AS total_flights,
    ROUND(AVG(COUNT(pf.flight_id)) OVER (),2) AS avg_flights_per_pax
FROM passenger AS p
JOIN passenger_flights AS pf ON pf.passenger_id = p.passenger_id
GROUP BY p.passenger_id, p.first_name, p.last_name
ORDER BY total_flights DESC
;

-- Find the passengers who book their flights the earliest before departure
SELECT 
    pf.flight_id,
    p.first_name + ' ' + p.last_name AS full_name,
    DATEDIFF(DAY, pf.booking_date, f.departure_time) AS bookingVsDeparture_in_days,
    pf.booking_date,
    f.departure_time
FROM passenger_flights AS pf 
JOIN passenger AS p ON p.passenger_id = pf.passenger_id
JOIN flights AS f ON f.flight_id = pf.flight_id
ORDER BY bookingVsDeparture_in_days DESC
;

-- Calculate the average reservation delay in days for each flight
SELECT 
    pf.flight_id,
    AVG(DATEDIFF(DAY, pf.booking_date, f.departure_time)) AS avg_reservation_delay_in_days
FROM passenger_flights AS pf
JOIN flights AS f ON f.flight_id = pf.flight_id
GROUP BY pf.flight_id
ORDER BY avg_reservation_delay_in_days DESC
;

-- Find all passengers who booked their flights less than 30 days before departure
WITH days_count AS (    
    SELECT 
        pf.passenger_id,
        pf.booking_date,
        f.departure_time,
        DATEDIFF(DAY, pf.booking_date, f.departure_time) AS bookingVsDeparture_in_days
    FROM passenger_flights AS pf 
    JOIN flights AS f ON f.flight_id = pf.flight_id
)
SELECT 
    *
FROM days_count AS d
JOIN passenger AS p ON p.passenger_id = d.passenger_id
WHERE bookingVsDeparture_in_days < 30
;

-- Calculate the no-show rate for each ticket class
SELECT 
    pf.ticket_class,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN pf.check_in_status = 'No Show' THEN 1 ELSE 0 END) AS total_no_show,
    ROUND(CAST(SUM(CASE WHEN pf.check_in_status = 'No Show' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100,2) AS no_show_rate_percent
FROM passenger_flights AS pf
GROUP BY pf.ticket_class
ORDER BY no_show_rate_percent DESC
;

-- 7. Analyse temporelle

-- Calculate the number of flights for each day
SELECT 
    COUNT(flight_id) AS nb_flight,
    CAST(departure_time AS DATE) as flight_date
FROM flights
GROUP BY CAST(departure_time AS DATE)
ORDER BY nb_flight DESC
;

-- Calculate the number of flights for each month
SELECT 
    COUNT(flight_id) AS nb_flight,
    FORMAT(departure_time, 'yyyy-MM') AS flight_month
FROM flights
GROUP BY FORMAT(departure_time, 'yyyy-MM')
ORDER BY flight_month
;

-- Find the month with the highest number of flights
SELECT top 1
    COUNT(flight_id) AS nb_flight,
    FORMAT(departure_time, 'yyyy-MM') AS flight_month
FROM flights
GROUP BY FORMAT(departure_time, 'yyyy-MM')
ORDER BY flight_month DESC
;

-- 8. Segmentation démographique

-- Calculate the total number of passengers per gender
SELECT 
    gender,
    COUNT(*) AS total_pax
FROM passenger
GROUP BY  gender
;

-- Calculate the average age of passengers
SELECT
    AVG(DATEDIFF(YEAR, birthdate, GETDATE())) avg_pax_age
FROM passenger
;

-- Find all passengers over 60 years old
WITH pax AS (    
    SELECT
        *,
        DATEDIFF(YEAR, birthdate, GETDATE()) AS pax_age
    FROM passenger 
)
SELECT *
FROM pax
WHERE pax_age > 60
;

-- Calculate the average ticket price for different age groups of passengers
WITH age_group_view AS (
    SELECT
        pf.ticket_price,
    CASE
        WHEN DATEDIFF(YEAR, p.birthdate, GETDATE()) < 20 THEN 'Under 20'
        WHEN DATEDIFF(YEAR, p.birthdate, GETDATE()) < 30 THEN '20 to 29'
        WHEN DATEDIFF(YEAR, p.birthdate, GETDATE()) < 40 THEN '30 to 39'
        WHEN DATEDIFF(YEAR, p.birthdate, GETDATE()) < 50 THEN '40 to 49'
        WHEN DATEDIFF(YEAR, p.birthdate, GETDATE()) < 60 THEN '50 to 59'
        WHEN DATEDIFF(YEAR, p.birthdate, GETDATE()) >= 60 THEN '60 or over'
        ELSE 'Unknown'
    END AS age_group
    FROM passenger_flights AS pf
    JOIN passenger AS p ON p.passenger_id = pf.passenger_id
)
SELECT 
    age_group,
    ROUND(AVG(ticket_price), 2) AS avg_ticket_price
FROM age_group_view
GROUP BY age_group
ORDER BY age_group
;

-- 9. Qualité de service

-- Find the top 3 months with the highest total delay time in hours
-- and the top 3 months with the highest number of delays
SELECT TOP 3
    YEAR(departure_time) AS flight_year,
    MONTH(departure_time) AS flight_month,
    SUM(delay_minutes) / 60 AS total_delay
FROM flights
GROUP BY YEAR(departure_time), MONTH(departure_time)
ORDER BY total_delay DESC
;

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
;

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
;

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
-- We can see that the total_num_delays when goes over 300 
-- the avg_delay is above 30 minutes

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
    SUM(num_delays) AS total_flights_delays,
    AVG(avg_delay) AS overall_avg_delay
FROM delayed_flights AS df 
JOIN airlines AS a ON df.airline_code = a.airline_code
GROUP BY df.airline_code, a.airline_name
ORDER BY total_flights_delays DESC
;


--10. Performance globale

-- Calculate the total number of flights for each airline
SELECT
    al.airline_name,
    COUNT(*) AS total_num_of_flights
FROM flights AS f
JOIN airlines AS al ON al.airline_code = f.airline_code
GROUP BY al.airline_name
ORDER BY total_num_of_flights DESC
;

-- Find the most profitable route for each airline
WITH routes AS (
    SELECT
        al.airline_name AS airline_name,
        f.departure_airport_code, 
        f.destination_airport_code,
        COUNT(*) AS total_num_of_flights,
        ROUND(SUM(f.revenue),2) AS total_revenue,
        ROUND(AVG(f.revenue),2) AS average_revenue_per_flight,
        ROUND(SUM(f.revenue/f.passenger_count),2) AS avg_revenue_per_passenger,
        AVG(f.delay_minutes) AS average_of_delay_in_min,
        CONCAT(f.departure_airport_code, ' - ', f.destination_airport_code) AS flying_route
    FROM flights AS f
    JOIN airlines AS al ON al.airline_code = f.airline_code
    WHERE f.flight_status <> 'Cancelled'
    GROUP BY al.airline_name, 
        CONCAT(f.departure_airport_code, ' - ', f.destination_airport_code),
        f.departure_airport_code, f.destination_airport_code
),
ranked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY airline_name ORDER BY total_revenue DESC) AS rn
    FROM routes
)
SELECT 
    r.airline_name,
    ad.airport_name AS depart,
    aa.airport_name AS arrival,
    r.total_num_of_flights,
    r.total_revenue,
    r.average_revenue_per_flight,
    r.avg_revenue_per_passenger,
    r.average_of_delay_in_min
from ranked AS r
JOIN airports AS ad ON ad.airport_code = r.departure_airport_code
JOIN airports AS aa ON aa.airport_code = r.destination_airport_code
WHERE rn = 1
;

-- Calculate the productivity of each airline
SELECT
    al.airline_name,
    SUM(f.revenue) AS total_revenue,
    COUNT(f.flight_id) AS total_num_of_flights,
    ROUND(SUM(f.revenue) / COUNT(DISTINCT(f.aircraft_id)),2) AS productivity
FROM flights AS f
JOIN airlines AS al ON al.airline_code = f.airline_code
GROUP BY al.airline_name
;

-- Calculate key performance indicators (KPIs) for each airline
DECLARE @cie_to_check VARCHAR(50);
SET @cie_to_check = NULL;

SELECT
    al.airline_name,
    COUNT(*) AS total_num_of_flights,
    SUM(f.passenger_count) AS total_pax,
    ROUND(SUM(f.revenue),2) AS total_revenue,
    ROUND(AVG(f.revenue),2) AS average_revenue_per_flight,
    ROUND(SUM(f.revenue)/SUM(f.passenger_count),2) AS global_avg_revenue_per_passenger,
    AVG(f.delay_minutes) AS average_of_delay_in_min,
    CAST(AVG(CASE WHEN f.delay_minutes <= 0 THEN 1.0 ELSE 0.0 END) * 100.0 AS DECIMAL(10,2)) AS on_time_rate,
    CAST(AVG(CASE WHEN f.flight_status = 'Cancelled' THEN 1.0 ELSE 0.0 END) *100.0 AS DECIMAL(10,2)) AS Cancel_rate
FROM flights AS f
JOIN airlines AS al ON al.airline_code = f.airline_code
WHERE (@cie_to_check IS NULL OR al.airline_name = @cie_to_check)
GROUP BY al.airline_name
;

-- Easter Egg revealed
SELECT 
    f.flight_id,
    ap.airport_name AS departure,
    ap2.airport_name AS destination,
    ac.aircraft_type,
    al.airline_name,
    al.date_founded,
    CONCAT(p.first_name,' ',p.last_name) AS passenger,
    p.birthdate
FROM flights AS f  
JOIN passenger_flights AS pf ON pf.flight_id = f.flight_id
JOIN passenger AS p ON p.passenger_id = pf.passenger_id
JOIN aircraft AS ac ON ac.aircraft_id = f.aircraft_id
JOIN airlines AS al ON al.airline_code = f.airline_code
JOIN airports AS ap ON ap.airport_code = f.departure_airport_code
JOIN airports AS ap2 ON ap2.airport_code = f.destination_airport_code
WHERE f.flight_id LIKE 'SW%'