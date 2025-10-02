/* =====================================================
Projet       : flights
Fichier      : 02_eda_flights.sql
Auteur       : JB Allombert
Objet        : Exploration de données 
Date         : 2025-09-16
===================================================== */


-- 1. Passagers
-- Afficher tous les passagers avec leur prénom et nom. (très facile)
SELECT TOP 10
    first_name,
    last_name
FROM passenger;

-- Compter le nombre total de passagers.
SELECT
    COUNT(*) AS total_passenger
FROM passenger;

-- Lister les 10 passagers les plus jeunes.
SELECT TOP 10
    *
FROM passenger
ORDER BY birthdate DESC;

-- Compter les passagers par genre.
SELECT 
    gender,
    COUNT(*) AS total_passenger_per_gender
FROM passenger
GROUP BY gender;

-- Trouver le nombre de passagers ayant le statut "Frequent Flyer".
SELECT top 10
    passenger_status,
    COUNT(*) AS total_Frequent_Flyer
FROM passenger
WHERE passenger_status = 'Frequent Flyer'
GROUP BY passenger_status;

-- Lister les passagers qui n’ont pris qu’un seul vol.
SELECT 
    p.passenger_id,
    p.first_name,
    p.last_name,
    COUNT(pf.flight_id) AS total_flights
FROM passenger_flights AS pf
JOIN passenger AS p ON p.passenger_id = pf.passenger_id
WHERE check_in_status = 'Checked In'
GROUP BY p.passenger_id, p.first_name, p.last_name
HAVING COUNT(pf.flight_id) <= 1
ORDER BY p.passenger_id



-- Trouver le top 10 des passagers avec le plus de vols.
SELECT 
    first_name + ' ' + last_name AS full_name,
    COUNT(pf.flight_id) AS total_flights
FROM passenger AS p  
JOIN passenger_flights AS pf ON pf.passenger_id = p.passenger_id
GROUP BY first_name, last_name
ORDER BY total_flights DESC



-- 2. Vols
-- Afficher les 10 premiers vols avec leur origine et destination.
SELECT TOP 10
    f.flight_id,
    f.departure_airport_code,
    a.airport_name,
    f.destination_airport_code,
    abis.airport_name
FROM flights AS f
JOIN airports AS a ON a.airport_code = f.departure_airport_code
JOIN airports AS abis ON abis.airport_code = f.destination_airport_code;

-- Compter le nombre total de vols.
SELECT 
    COUNT(*) AS total_flights
FROM flights;

-- Lister les vols ayant un retard.
SELECT TOP 10
    *
FROM flights
WHERE flight_status = 'Delayed'

-- Calculer le taux de vols annulés.
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
CROSS JOIN nb_cancelled AS c;
/*En SQL, quand tu fais une division entre deux entiers (INT), 
le moteur SQL fait une division entière → il tronque le résultat.
Pour forcer une division décimale, il faut que l’un des deux opérandes 
soit de type décimal / float.*/

-- Afficher la durée moyenne des vols. 
SELECT 
    MIN(DATEDIFF(MINUTE, departure_time, arrival_time)) AS shortest_flight_in_min,
    MAX(DATEDIFF(MINUTE, departure_time, arrival_time)) AS longest_flight_in_min,
    AVG(DATEDIFF(MINUTE, departure_time, arrival_time)) AS avg_flying_time_in_min
FROM flights


-- Trouver les vols les plus longs en durée.
SELECT 
    MAX(DATEDIFF(MINUTE, departure_time, arrival_time)) AS longest_flight_in_min, 
    flight_id
FROM flights 
GROUP BY flight_id
ORDER BY longest_flight_in_min DESC;

-- Identifier les vols avec le plus de passagers.
SELECT  
    *
FROM flights
ORDER BY passenger_count DESC


-- 3. Revenus
-- Afficher la somme des revenus pour tous les vols.
SELECT 
    flight_id,
    revenue
FROM flights
ORDER BY revenue DESC;

-- Calculer le revenu moyen par vol.
SELECT 
    flight_id,
    AVG(revenue) AS avg_revenue
FROM flights
GROUP BY flight_id
ORDER BY avg_revenue DESC;

-- Lister le revenu total par compagnie.
SELECT
    a.airline_name,
    SUM(f.revenue) AS total_revenue
FROM flights AS f
JOIN airlines AS a ON f.airline_code = a.airline_code
GROUP BY a.airline_name
ORDER BY total_revenue DESC

-- Calculer le revenu moyen par passager.
SELECT
    flight_id,
    revenue,
    passenger_count,
    ROUND(revenue/passenger_count,2) AS avg_revenue_per_passenger
FROM flights
ORDER BY avg_revenue_per_passenger DESC

-- Lister le revenu total par classe (économique, business, première).
SELECT 
    ticket_class,
    SUM(ticket_price) AS sum_ticket_sold,
    SUM(f.revenue) AS sum_revenue
FROM flights AS f
JOIN passenger_flights AS pf ON f.flight_id = pf.flight_id
GROUP BY ticket_class

-- Identifier le vol avec le revenu le plus élevé.
SELECT 
    f.flight_id,
    MAX(f.revenue) AS revenue,
    SUM(pf.ticket_price) AS sum_of_ticket_price
FROM flights AS f 
JOIN passenger_flights AS pf ON pf.flight_id = f.flight_id
GROUP BY f.flight_id
ORDER BY revenue DESC

-- 4. Appareils
-- Afficher la liste des appareils avec leur type.
SELECT 
    manufacturer,
    aircraft_type
FROM aircraft

-- Compter le nombre d’appareils par compagnie.
SELECT 
    al.airline_name AS total_aircraft_type,
    COUNT(DISTINCT(ac.aircraft_type))
FROM flights AS f
JOIN aircraft AS ac ON f.aircraft_id = ac.aircraft_id
JOIN airlines AS al ON f.airline_code = al.airline_code
GROUP BY al.airline_name

-- Trouver l’avion ayant la plus grande capacité de passagers.
SELECT TOP 1
    *
FROM aircraft
ORDER BY capacity DESC

-- Calculer l’âge moyen de la flotte.
SELECT 
    YEAR(GETDATE()) AS current_year,
    AVG(YEAR(GETDATE()) - year_built) AS avg_fleet_age,
    /* La colonne "year_built" contient des INT avec seulement l'année
    la fonction DATEDIFF ne peut pas fonctionner car elle s'attend
    à une date compléte, et donc renvoie "0"*/
    AVG(DATEDIFF(YEAR, year_built, (YEAR(GETDATE())))) AS wrong_method
FROM aircraft


-- Identifier les avions utilisés sur le plus de vols.
SELECT
    ac.aircraft_type,
    COUNT(*) AS total_of_flights
FROM flights AS f
JOIN aircraft AS ac ON f.aircraft_id = ac.aircraft_id
GROUP BY ac.aircraft_type
ORDER BY total_of_flights DESC

-- Trouver le type d’avion le plus fréquent par compagnie.
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


-- 5. Aéroports
-- Lister tous les aéroports avec leur ville et pays.
SELECT 
    airport_name,
    city,
    country
FROM airports

-- Compter le nombre total d’aéroports.
SELECT
    COUNT(*)
FROM airports

-- Identifier l’aéroport avec la plus grande superficie.
SELECT 
    *
FROM airports
ORDER BY airport_size_m2 DESC

-- Compter les vols par aéroport d’origine.
SELECT
    ap.airport_name,
    COUNT(DISTINCT(flight_id)) AS total_num_of_departure
FROM flights AS f
JOIN airports AS ap ON f.departure_airport_code = ap.airport_code
GROUP BY ap.airport_name
ORDER BY total_num_of_departure DESC

-- Trouver les 5 aéroports les plus utilisés comme destination.
SELECT TOP 5
    ap.airport_name,
    COUNT(DISTINCT(flight_id)) AS total_num_of_arrivals
FROM flights AS f
JOIN airports AS ap ON f.destination_airport_code = ap.airport_code
GROUP BY ap.airport_name
ORDER BY total_num_of_arrivals DESC

-- Calculer le trafic total (arrivées + départs) par aéroport.
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


-- Lister les aéroports avec le plus de retards cumulés.
SELECT
    ap.airport_name,
    SUM(f.delay_minutes) AS total_delay_in_minutes
FROM flights AS f
JOIN airports AS ap ON f.departure_airport_code = ap.airport_code
GROUP BY ap.airport_name

-- Trouver l’aéroport générant le plus de revenus.
SELECT
    ap.airport_name,
    SUM(f.revenue) AS total_revenue
FROM flights AS f
JOIN airports AS ap ON f.departure_airport_code = ap.airport_code
GROUP BY ap.airport_name


-- 6. Comportement de réservation
-- Compter le nombre de réservations totales.
SELECT
    COUNT(*) AS total_num_of_reservations
FROM passenger_flights

-- Trouver combien de vols en moyenne un passager réserve.
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

-- Trouver la distribution des délais de réservation (jours avant le vol).
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

-- Trouver le délai moyen de réservation avant le vol.
SELECT 
    pf.flight_id,
    AVG(DATEDIFF(DAY, pf.booking_date, f.departure_time)) AS avg_reservation_delay_in_days
FROM passenger_flights AS pf
JOIN flights AS f ON f.flight_id = pf.flight_id
GROUP BY pf.flight_id
ORDER BY avg_reservation_delay_in_days

-- Identifier les passagers qui réservent toujours en dernière minute.
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

-- Comparer taux de no-show entre classes de voyage.
SELECT 
    pf.ticket_class,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN pf.check_in_status = 'No Show' THEN 1 ELSE 0 END) AS total_no_show,
    ROUND(CAST(SUM(CASE WHEN pf.check_in_status = 'No Show' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100,2) AS no_show_rate_percent
FROM passenger_flights AS pf
GROUP BY pf.ticket_class
ORDER BY no_show_rate_percent DESC


-- 7. Analyse temporelle
-- Compter le nombre de vols par jour.
SELECT 
    COUNT(flight_id) AS nb_flight,
    CAST(departure_time AS DATE) as flight_date
FROM flights
GROUP BY CAST(departure_time AS DATE)
ORDER BY nb_flight DESC

-- Compter le nombre de vols par mois.
SELECT 
    COUNT(flight_id) AS nb_flight,
    FORMAT(departure_time, 'yyyy-MM') AS flight_month
FROM flights
GROUP BY FORMAT(departure_time, 'yyyy-MM')
ORDER BY flight_month

-- Identifier le mois avec le plus de vols.
SELECT top 1
    COUNT(flight_id) AS nb_flight,
    FORMAT(departure_time, 'yyyy-MM') AS flight_month
FROM flights
GROUP BY FORMAT(departure_time, 'yyyy-MM')
ORDER BY flight_month DESC


-- 8. Segmentation démographique
-- Compter le nombre de passagers par genre.
SELECT 
    gender,
    COUNT(*) AS total_pax
FROM passenger
GROUP BY  gender

-- Trouver l’âge moyen des passagers.
SELECT
    AVG(DATEDIFF(YEAR, birthdate, GETDATE())) avg_pax_age
FROM passenger

-- Lister les passagers ayant plus de 60 ans.
WITH pax AS (    
    SELECT
        *,
        DATEDIFF(YEAR, birthdate, GETDATE()) AS pax_age
    FROM passenger 
)
SELECT *
FROM pax
WHERE pax_age > 60

-- Calculer le revenu moyen par tranche d’âge.
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

-- 9. Qualité de service
-- Compter le nombre total de vols annulés.
SELECT 
    COUNT(*) AS total_num_of_cancel
FROM flights
WHERE flight_status = 'Cancelled'

-- Calculer le pourcentage de no-shows.
-- Identifier la compagnie avec le moins d’annulations.
SELECT
    al.airline_name,
    COUNT(*) AS total_cancelation
FROM flights AS f
JOIN airlines AS al ON al.airline_code = f.airline_code
WHERE flight_status = 'Cancelled'
GROUP BY al.airline_name
ORDER BY total_cancelation 


--10. Performance globale
-- Lister toutes les compagnies aériennes.
SELECT
    *
FROM airlines

-- Compter le nombre de vols par compagnie.
SELECT
    al.airline_name,
    COUNT(*) AS total_num_of_flights
FROM flights AS f
JOIN airlines AS al ON al.airline_code = f.airline_code
GROUP BY al.airline_name
ORDER BY total_num_of_flights DESC

-- Calculer le revenu total par compagnie.
SELECT
    al.airline_name,
    SUM(f.revenue) AS total_ca
FROM flights AS f
JOIN airlines AS al ON al.airline_code = f.airline_code
GROUP BY al.airline_name
ORDER BY total_ca DESC

-- Calculer le revenu moyen par vol pour chaque compagnie.
SELECT
    al.airline_name,
    ROUND(AVG(f.revenue),2) AS average_revenue_per_flight
FROM flights AS f
JOIN airlines AS al ON al.airline_code = f.airline_code
WHERE f.flight_status <> 'Cancelled'
GROUP BY al.airline_name
ORDER BY average_revenue_per_flight

-- Identifier la compagnie la plus rentable.
SELECT TOP 1
    al.airline_name,
    ROUND(SUM(f.revenue),2) AS total_revenue
FROM flights AS f
JOIN airlines AS al ON al.airline_code = f.airline_code
GROUP BY al.airline_name
ORDER BY total_revenue DESC 

-- Comparer la performance entre 2 compagnies choisies.
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
GROUP BY al.airline_name;

-- Identifier la meilleure route de chaque compagnie.
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

-- Calculer la productivité (revenu / avion) par compagnie.
SELECT
    al.airline_name,
    SUM(f.revenue) AS total_revenue,
    COUNT(f.flight_id) AS total_num_of_flights,
    ROUND(SUM(f.revenue) / COUNT(DISTINCT(f.aircraft_id)),2) AS productivity
FROM flights AS f
JOIN airlines AS al ON al.airline_code = f.airline_code
GROUP BY al.airline_name

-- Créer un tableau de bord SQL : trafic + revenu + ponctualité par compagnie.
DECLARE @cie_to_check VARCHAR(50);
SET @cie_to_check = NULL;

SELECT
    al.airline_name,
    COUNT(*) AS total_num_of_flights,
    SUM(f.passenger_count) AS total_pax,
    ROUND(SUM(f.revenue),2) AS total_revenue,
    ROUND(AVG(f.revenue),2) AS average_revenue_per_flight,
    ROUND(SUM(f.revenue)/SUM(f.passenger_count),2) AS avg_revenue_per_passenger,
    AVG(f.delay_minutes) AS average_of_delay_in_min,
    CAST(AVG(CASE WHEN f.delay_minutes <= 0 THEN 1.0 ELSE 0.0 END) * 100.0 AS DECIMAL(10,2)) AS on_time_rate,
    CAST(AVG(CASE WHEN f.flight_status = 'Cancelled' THEN 1.0 ELSE 0.0 END) *100.0 AS DECIMAL(10,2)) AS Cancel_rate
FROM flights AS f
JOIN airlines AS al ON al.airline_code = f.airline_code
WHERE (@cie_to_check IS NULL OR al.airline_name = @cie_to_check)
GROUP BY al.airline_name

