<h1 align="center">RETURN OF THE JET HIGH: An SQL Airline Analytics Project</h1>  

![Logo](https://github.com/JBaptisteAll/Return-of-the-Jet-High-An-SQL-Airline-Analytics-Project/blob/main/Assets/logo.png)

## 📌 Introduction

RETURN OF THE JET HIGH is the sequel to *Revenge of the Seat*.  
Whereas the first project focused on designing and populating a relational SQL database, this one explores **airline analytics** using advanced SQL queries and views.  

It answers business-driven questions on **revenues, delays, routes, aircraft utilization, and passenger behavior**, while also preparing **views ready to be used in BI tools** such as Power BI.

---

## 📚 Background

This project was created as part of a personal portfolio to demonstrate **SQL analytics capabilities**.  
It builds on the existing airline database to simulate real-world scenarios such as:
- Determining the most profitable routes  
- Measuring punctuality across airports  
- Estimating fuel needs based on aircraft performance  
- Segmenting passengers into meaningful categories  

---

## 🧱 Database Schema

The analysis leverages the same schema introduced in *Revenge of the Seat*, which includes:

| Table               | Description                                                   |
|---------------------|---------------------------------------------------------------|
| `aircraft`          | Stores technical and commercial details about each aircraft.  |
| `airlines`          | Contains airline company data (name, HQ, employees, etc).     |
| `airports`          | Includes global airport data (location, size, capacity).      |
| `passenger`         | Passenger demographics and frequent flyer info.               |
| `flights`           | Central fact table listing flights, delay info, revenue, etc. |
| `passenger_flights` | Join table linking passengers to flights with seat/class.     |

![Merise](https://github.com/JBaptisteAll/Revenge-of-the-Seat-An-SQL-Database/blob/main/Assets/Merise.png)

---

## 🧪 Data Overview

The analytical queries in this project rely on a dataset designed to mimic real-world airline operations.  
It contains **hundreds of thousands of rows** across flights, passengers, aircraft, airlines, and airports, enabling complex scenarios to be explored:


| Table               | # of Rows |
|---------------------|-----------|
| `aircraft`          | 19        |
| `airlines`          | 11        |
| `airports`          | 32        |
| `passenger`         | 100,007   |
| `passenger_flights` | 700,008   |
| `flights`           | 25,001    |


- Each passenger is linked to multiple flights, averaging **7 bookings per person**.  
- Flight statuses include *On Time*, *Delayed*, and *Cancelled*, which drive punctuality analysis.  
- Aircraft carry technical fields such as **fuel capacity** and **burn rate**, supporting operational insights.  

This scale makes the dataset a solid foundation for demonstrating **SQL analytics, KPIs, and BI-ready views**.

---

## 🛠️ Tools Used

- **SQL Server** – to execute and test queries  
- **Visual Studio Code (VS Code)** – for SQL scripting and formatting  
- **Power BI (planned)** – to visualize key KPIs from the SQL views  

---

## 📌 Example SQL Use Cases
All full SQL queries are available in the project scripts.  
Below are selected examples with their corresponding outputs for clarity.

### 🎟️ Pricing & Revenue
```sql
-- Top 3 months with the highest average ticket price per class
```
| ticket_class | booking_month | avg_price |
|--------------|---------------|-----------|
| `Business`   | 12            | 752.46    |
| `Business`   | 1             | 751.52    |
| `Business`   | 3             | 751.37    |
| `Economy`    | 12            | 175.75    |
| `Economy`    | 5             | 175.50    |
| `Economy`    | 1             | 175.37    |
| `First`      | 6             | 3112.16   |
| `First`      | 10            | 3107.25   |
| `First`      | 11            | 3105.67   |
|

### 🛫 Airports & Traffic

```sql
-- Airports with the highest total number of flights (arrivals + departures)
```
| airport_name                   | total_flights |
|--------------------------------|---------------|
| `Haneda Airport`               | 3065          |
| `Charles de Gaulle`            | 3052          |
| `John F. Kennedy International`| 3045          |
|

### ⏳ Booking Behavior
```sql
-- Average reservation delay in days per flight
```
| flight_id | avg_delay_in_days |
|-----------|-------------------|
| `FL40467` | 1148              |
| `FL45461` | 1106              |
| `FL43255` | 1106              |
|

### 👥 Passenger Segmentation
```sql
-- Average ticket price by age groups
```
| age_group   | avg_ticket_price |
|-------------|------------------|
| `Under 20`  | 1339.56          |
| `20 to 29`  | 1336.62          |
| `30 to 39`  | 1346.44          |
| `40 to 49`  | 1339.09          |
| `50 to 59`  | 1340.82          |
| `60 or over`| 1336.88          |
|

### ⏱️ Delays & On-time Performance
```sql
-- Total delayed flights and average delay per airline
```
| airline_name       | total_flights_delays | overall_avg_delay|
|--------------------|----------------------|------------------|
| `American Airlines`| 606              	|27                |
| `United Airlines`  | 586	                | 27               |
| `Qatar Airways`    | 582                  | 29               |
|

### 📊 Airline KPIs
```sql
-- Key performance indicators (KPIs) per airline
DECLARE @cie_to_check VARCHAR(50);
SET @cie_to_check = NULL;

SELECT
    al.airline_name,
    COUNT(*) AS total_num_of_flights,
    ROUND(SUM(f.revenue),2) AS total_pax,
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
```
|airline_name|total_num_of_flights|total_pax|average_revenue_per_flight|global_avg_revenue_per_passenger|average_of_delay_in_min|on_time_rate|Cancel_rate|
|---|---|---|---|---|---|---|---|
|Air France|2556|552546|342816837.43|134122.39|620.43|37|70.85|4.34|
|All Nippon Airways|2503|533120|335544340.64|134056.87|629.40|36|70.00|4.16|
|American Airlines|2505|529720|332665821.26|132800.73|628.00|38|70.02|4.75|
|British Airways|2354|509437|319277020.76|135631.70|626.73|41|67.59|4.55|
|Delta Air Lines|2475|530710|341939728.41|138157.47|644.31|35|70.95|4.44|
|

🔍 Insights

With these queries and views, the project enables analysis of:

✈️ Airline performance: revenues, profitability, and load factors

🛫 Routes: most profitable and busiest flight connections

⏱️ Delays: on-time performance by airline and airport

🛩️ Aircraft usage: fuel consumption estimates vs. capacity

👥 Passengers: segmentation by age and travel frequency

---
## 📈 What I Learned

This project helped me strengthen both my **technical SQL skills** and my **business-oriented thinking**:

- **SQL Engineering**: Designing clean and reusable SQL views that can serve as a foundation for further analysis or BI dashboards.  
- **Advanced Querying**: Applying window functions (`ROW_NUMBER`, `AVG`, `SUM`) to perform ranking, segmentation, and KPI calculations.  
- **Business Metrics**: Translating raw flight data into meaningful indicators such as revenue per passenger, on-time rate, and cancellation rate.  
- **Analytics to BI**: Preparing datasets that can be directly connected to **Power BI**, ensuring a smooth transition from backend SQL to data visualization.  
- **Storytelling with Data**: Moving beyond queries to interpret the results, highlighting profitability drivers, operational inefficiencies, and customer behavior patterns.

---

## 🏗️ Analytics Engineering Perspective

This project is designed following an **Analytics Engineering mindset**, where raw operational data is progressively transformed into **business-ready datasets**.

### 🔄 Data Transformation Layers (dbt-inspired)
- **Raw layer**: Original tables (`flights`, `passenger`, `aircraft`, …) as ingested from the simulation.
- **Staging layer (stg_*)**: Cleaned and standardized views (e.g., handling cancellations, unifying date formats).
- **Analytics layer (dim_ / fct_*)**: Business-oriented datasets, such as:
  - `fct_airline_kpis`: KPIs per airline (revenues, on-time rate, cancellations).
  - `fct_routes`: Most profitable routes with revenue per passenger.
  - `dim_passenger_segments`: Age-based and loyalty-based segmentation.

This layered approach ensures **clarity, modularity, and reusability**.

### 📊 Why it matters
By exposing analytics-ready views:
- BI tools like **Power BI** can connect directly, reducing time-to-insight.
- Analysts no longer need to write complex SQL, ensuring **consistency** of business metrics.
- Business users get **trusted datasets** aligned with company definitions (e.g., on-time rate is always calculated the same way).

### ⚙️ Data Quality & CI/CD
- **Testing**: Simple SQL tests (row counts, null checks, referential integrity) ensure reliable outputs.
- **Versioning**: Queries and views are version-controlled in GitHub.
- **Refresh**: Views can be refreshed on a schedule (daily/weekly), simulating an ELT pipeline.

While I haven’t implemented tools like dbt or Airflow yet, this project was designed with the same mindset, focusing on clarity, modularity, and reusable analytics-ready datasets.

---

## 🥚 Easter Egg Revealed

In *Revenge of the Seat*, a secret was hidden inside the dataset.  
One particular flight stood out: **a fully booked trip to the Death Star** 🚀.  

```SQL
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
```
|flight_id|departure|destination|aircraft_type|airline_name|date_founded|passenger|birthdate|
|---|---|---|---|---|---|---|---|
|SW199999|Mos Eisley Spaceport|Aldera Royal Port|Millennium Falcon|Rebel Alliance|1977-05-25|Han Solo|1990-07-13|
|SW199999|Mos Eisley Spaceport|Aldera Royal Port|Millennium Falcon|Rebel Alliance|1977-05-25|Chewbacca Unknown|1992-05-19|
|SW199999|Mos Eisley Spaceport|Aldera Royal Port|Millennium Falcon|Rebel Alliance|1977-05-25|Leia Organa|2005-10-21|
|SW199999|Mos Eisley Spaceport|Aldera Royal Port|Millennium Falcon|Rebel Alliance|1977-05-25|R2-D2 Droid|1982-08-24|
|SW199999|Mos Eisley Spaceport|Aldera Royal Port|Millennium Falcon|Rebel Alliance|1977-05-25|C-3PO Droid|1946-02-21|
|SW199999|Mos Eisley Spaceport|Aldera Royal Port|Millennium Falcon|Rebel Alliance|1977-05-25|Luke Skywalker|2000-09-25|
|SW199999|Mos Eisley Spaceport|Aldera Royal Port|Millennium Falcon|Rebel Alliance|1977-05-25|Obi-Wan Kenobi|1962-04-14|
|

It was a playful nod to the project’s Star Wars–inspired naming, and a reminder that data can also be fun to explore.  

By revealing it here in *Return of the Jet High*, the saga comes full circle — mixing serious SQL analytics with a touch of creativity.

---
## 🔮 Final Notes

This project transforms the airline database into a **practical analytics playground**,  
bridging the gap between **data modeling** (*Revenge of the Seat*) and **data analysis** (*Return of the Jet High*).  

It demonstrates how far you can go with **SQL alone** — from exploring KPIs to preparing BI-ready datasets.  
Together, the two projects form a complete cycle: one focused on building the database, the other on unlocking its insights.  

Because in the end, as Master Yoda reminds us about the Sith:  
💬 *“Always two there are, no more, no less.”*  
So too must this SQL saga be told — in pairs.

---
Designed by JB as part of a portfolio to demonstrate SQL analytics and business intelligence readiness.