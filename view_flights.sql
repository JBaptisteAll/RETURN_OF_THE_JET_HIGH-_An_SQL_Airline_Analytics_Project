-- Calculate the total number of delayed departures and average delay time for each airport
-- considering both departures and arrivals, and order by the total number of delays
CREATE OR ALTER VIEW airport_delay_stats AS
    WITH delayed_flights AS(
        SELECT 
            departure_airport_code AS airport_code,
            COUNT(*) AS num_delays,
            CAST(AVG(delay_minutes) AS DECIMAL(10,2)) AS avg_delay
        FROM flights AS f
        WHERE flight_status = 'Delayed'
        GROUP BY departure_airport_code
        
        UNION ALL

        SELECT 
            destination_airport_code AS airport_code,
            COUNT(*) AS num_delays,
            CAST(AVG(delay_minutes) AS DECIMAL(10,2)) AS avg_delay
        FROM flights
        WHERE flight_status = 'Delayed'
        GROUP BY destination_airport_code
        )
    SELECT 
        df.airport_code,
        a.airport_name,
        a.city,
        SUM(num_delays) AS total_num_delays,
        CAST(AVG(avg_delay) AS DECIMAL(10,2)) AS overall_avg_delay_in_minutes,
        a.airport_size_m2 / a.airport_employees AS m2_per_employee
    FROM delayed_flights AS df 
    JOIN airports AS a ON df.airport_code = a.airport_code
    GROUP BY df.airport_code, a.airport_name, a.city, a.airport_size_m2 / a.airport_employees
;



-- Find all flights that are likely to run out of fuel before reaching their 
-- destination
-- assuming that the burn rate is constant throughout the flight
CREATE OR ALTER VIEW flight_out_of_fuel AS 
    WITH flight_duration_in_minutes AS (
        SELECT
            f.flight_id,
            f.departure_time,
            f.arrival_time,
            DATEDIFF(MINUTE, f.departure_time, arrival_time) AS flight_duration_in_minutes,
            a.aircraft_id,
            a.aircraft_type,
            a.fuel_capacity_liters,
            a.burn_rate_liters_per_minute
        FROM flights AS f 
        JOIN aircraft AS a ON a.aircraft_id = f.aircraft_id
    )
    SELECT 
        flight_id,
    departure_time,
    arrival_time,
    flight_duration_in_minutes,
    aircraft_id,
    aircraft_type,
    fuel_capacity_liters,
    burn_rate_liters_per_minute,
    burn_rate_liters_per_minute * flight_duration_in_minutes AS total_fuel_consumed
    FROM flight_duration_in_minutes
    WHERE fuel_capacity_liters < (burn_rate_liters_per_minute * flight_duration_in_minutes)  
;

-- Calculate the average ticket price for different age groups of passengers
CREATE OR ALTER VIEW age_group_avg_price_ticket_at_flight AS
    WITH base AS (
        SELECT
            pf.ticket_price,
            f.departure_time,
            CASE 
                WHEN p.birthdate IS NULL THEN NULL
                ELSE 
                    DATEDIFF(YEAR, p.birthdate, f.departure_time)
                    - CASE 
                        WHEN DATEADD(YEAR, DATEDIFF(YEAR, p.birthdate, f.departure_time), p.birthdate) > f.departure_time
                        THEN 1 ELSE 0
                    END
            END AS age
        FROM passenger_flights AS pf
        JOIN passenger AS p ON p.passenger_id = pf.passenger_id
        JOIN flights   AS f ON f.flight_id = pf.flight_id
    ),
    bucket AS (
        SELECT
            ticket_price,
            CASE
                WHEN age IS NULL THEN 'Unknown'
                WHEN age < 20 THEN 'Under 20'
                WHEN age BETWEEN 20 AND 29 THEN '20 to 29'
                WHEN age BETWEEN 30 AND 39 THEN '30 to 39'
                WHEN age BETWEEN 40 AND 49 THEN '40 to 49'
                WHEN age BETWEEN 50 AND 59 THEN '50 to 59'
                ELSE '60 or over'
            END AS age_group
        FROM base
    )
    SELECT
        age_group,
        CAST(AVG(ticket_price) AS DECIMAL(10,2)) AS avg_ticket_price,
        COUNT(*) AS tickets_count
    FROM bucket
    GROUP BY age_group;
;

-- Airline KPI
CREATE OR ALTER VIEW airline_kpi AS
    WITH base AS (
        SELECT
            al.airline_name,
            f.revenue,
            f.passenger_count,
            f.delay_minutes,
            f.flight_status
        FROM flights AS f
        JOIN airlines AS al ON al.airline_code = f.airline_code
    ),
    agg AS (
        SELECT
            airline_name,
            COUNT(*)                                   AS total_num_of_flights,
            SUM(CASE WHEN flight_status <> 'Cancelled' THEN passenger_count END)                  AS total_pax_completed,
            SUM(CASE WHEN flight_status <> 'Cancelled' THEN revenue END)                          AS total_revenue_completed,
            SUM(CASE WHEN flight_status <> 'Cancelled' THEN 1 ELSE 0 END)                         AS completed_flights,
            -- Moyenne de retard uniquement sur vols complétés
            AVG(CASE WHEN flight_status <> 'Cancelled' THEN TRY_CONVERT(float, delay_minutes) END) AS avg_delay_completed,
            -- Taux on-time sur vols complétés
            AVG(CASE WHEN flight_status <> 'Cancelled'
                    THEN CASE WHEN delay_minutes <= 0 THEN 1.0 ELSE 0.0 END END)                 AS on_time_rate_raw,
            -- Taux d'annulation
            AVG(CASE WHEN flight_status = 'Cancelled' THEN 1.0 ELSE 0.0 END)                      AS cancel_rate_raw
        FROM base
        GROUP BY airline_name
    )
    SELECT
        airline_name,
        total_num_of_flights,
        COALESCE(total_pax_completed, 0) AS total_pax,
        CAST(COALESCE(total_revenue_completed, 0) AS DECIMAL(18,2)) AS total_revenue,
        CAST(COALESCE(total_revenue_completed, 0) 
            / NULLIF(completed_flights * 1.0, 0) AS DECIMAL(18,2)) AS average_revenue_per_flight,
        CAST(COALESCE(total_revenue_completed, 0) 
            / NULLIF(total_pax_completed * 1.0, 0) AS DECIMAL(18,2)) AS avg_revenue_per_passenger,
        CAST(COALESCE(avg_delay_completed, 0.0) AS DECIMAL(10,2)) AS average_of_delay_in_min,
        CAST(COALESCE(on_time_rate_raw, 0.0) * 100.0 AS DECIMAL(5,2)) AS on_time_rate_pct,
        CAST(COALESCE(cancel_rate_raw, 0.0) * 100.0 AS DECIMAL(5,2)) AS cancel_rate_pct
    FROM agg;
;

-- For each airline, find the route (departure to destination airport) that generates the highest total revenue
-- and provide various statistics about that route
CREATE OR ALTER VIEW most_profitable_routes AS 
    WITH routes AS (
        SELECT
            al.airline_name AS airline_name,
            f.departure_airport_code, 
            f.destination_airport_code,
            COUNT(*) AS total_num_of_flights,
            ROUND(SUM(f.revenue),2) AS total_revenue,
            ROUND(AVG(f.revenue),2) AS average_revenue_per_flight,
            ROUND(SUM(f.revenue)/SUM(f.passenger_count),2) AS avg_revenue_per_passenger,
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
        r.average_of_delay_in_min,
        rn AS ranked
    from ranked AS r
    JOIN airports AS ad ON ad.airport_code = r.departure_airport_code
    JOIN airports AS aa ON aa.airport_code = r.destination_airport_code
;