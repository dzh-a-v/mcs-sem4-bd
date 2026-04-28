# Query Guide

This file explains how to query the coursework database from `psql`, starting from simple requests and moving up to more complex queries with many conditions.

## 0. Create and load the databases

Before querying, create a PostgreSQL database and load the SQL scripts from `program/`.

Small database with readable sample data:

```powershell
$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"

& $psql -U postgres -d postgres -c "CREATE DATABASE exoplanet_coursework;"
& $psql -U postgres -d exoplanet_coursework -f "C:\spbpu\year2\bd\program\schema.sql"
& $psql -U postgres -d exoplanet_coursework -f "C:\spbpu\year2\bd\program\seed.sql"
```

Large database with synthetic data:

```powershell
$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"

& $psql -U postgres -d postgres -c "CREATE DATABASE exoplanet_coursework_big;"
& $psql -U postgres -d exoplanet_coursework_big -f "C:\spbpu\year2\bd\program\schema.sql"
& $psql -U postgres -d exoplanet_coursework_big -f "C:\spbpu\year2\bd\program\generate_large_dataset.sql"
```

If a database already exists and you want to recreate it from scratch, drop it first:

```powershell
& $psql -U postgres -d postgres -c "DROP DATABASE exoplanet_coursework WITH (FORCE);"
& $psql -U postgres -d postgres -c "DROP DATABASE exoplanet_coursework_big WITH (FORCE);"
```

Check that the large database was loaded correctly:

```powershell
& $psql -U postgres -d exoplanet_coursework_big -c "
SELECT
    (SELECT COUNT(*) FROM exoplanet_catalog.galaxy) +
    (SELECT COUNT(*) FROM exoplanet_catalog.stellar_cluster) +
    (SELECT COUNT(*) FROM exoplanet_catalog.stellar_system) +
    (SELECT COUNT(*) FROM exoplanet_catalog.star) +
    (SELECT COUNT(*) FROM exoplanet_catalog.planetary_system) +
    (SELECT COUNT(*) FROM exoplanet_catalog.exoplanet) +
    (SELECT COUNT(*) FROM exoplanet_catalog.telescope) +
    (SELECT COUNT(*) FROM exoplanet_catalog.observer) +
    (SELECT COUNT(*) FROM exoplanet_catalog.observation) AS total_rows;
"
```

Expected result for the large database: `280530`.

## 1. Connect to the database

Small database:

```powershell
$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
& $psql -U postgres -d exoplanet_coursework
```

Large database:

```powershell
$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
& $psql -U postgres -d exoplanet_coursework_big
```

If you are already inside `psql`, switch databases like this:

```sql
\c exoplanet_coursework_big postgres
```

Select the schema:

```sql
SET search_path TO exoplanet_catalog, public;
```

## 2. Useful `psql` commands

Show tables:

```sql
\dt exoplanet_catalog.*
```

Show views:

```sql
\dv exoplanet_catalog.*
```

Show the structure of one table:

```sql
\d exoplanet_catalog.exoplanet
```

Turn on expanded output for wide rows:

```sql
\x auto
```

Exit `psql`:

```sql
\q
```

## 3. Main tables and views

Main tables:

- `galaxy`
- `stellar_cluster`
- `stellar_system`
- `star`
- `planetary_system`
- `exoplanet`
- `telescope`
- `observer`
- `observation`

Useful views:

- `v_exoplanet_catalog`: already joins exoplanet, host star, system, cluster, and galaxy
- `v_observation_details`: already joins observation, exoplanet, telescope, observer, and hierarchy

For many analytical queries, using the views is easier than writing all joins manually.

## 4. Simple queries

Count all exoplanets:

```sql
SELECT COUNT(*) FROM exoplanet;
```

Show the nearest exoplanets:

```sql
SELECT id, planet_type, distance
FROM exoplanet
ORDER BY distance ASC
LIMIT 10;
```

Show only terrestrial planets.
Note: the enum value is spelled `terrestial` because the coursework uses that spelling.

```sql
SELECT id, mass, radius, orbital_period
FROM exoplanet
WHERE planet_type = 'terrestial';
```

Show planets discovered after 2015:

```sql
SELECT id, discovery_date
FROM exoplanet
WHERE discovery_date > DATE '2015-01-01'
ORDER BY discovery_date;
```

## 5. Queries with filters

You can combine conditions with `AND`, `OR`, `IN`, `BETWEEN`, `LIKE`.

Exoplanets that are close and small:

```sql
SELECT id, mass, radius, distance
FROM exoplanet
WHERE distance <= 50
  AND mass < 2
  AND radius < 1.5
ORDER BY distance, mass;
```

Planets of several types:

```sql
SELECT id, planet_type, distance
FROM exoplanet
WHERE planet_type IN ('terrestial', 'superearth')
ORDER BY distance;
```

Stars of spectral classes starting with `M`:

```sql
SELECT id, spectral_class, temperature
FROM star
WHERE spectral_class LIKE 'M%'
ORDER BY temperature;
```

## 6. Queries with joins

### 6.1. Using the ready-made catalog view

```sql
SELECT
    exoplanet_id,
    planet_type,
    host_star_id,
    star_spectral_class,
    stellar_system_id,
    stellar_cluster_id,
    galaxy_id
FROM v_exoplanet_catalog
ORDER BY exoplanet_id;
```

### 6.2. Writing joins manually

```sql
SELECT
    e.id AS exoplanet_id,
    e.planet_type,
    s.id AS host_star_id,
    s.spectral_class,
    ps.id AS planetary_system_id
FROM exoplanet AS e
JOIN planetary_system AS ps ON ps.id = e.system_id
JOIN star AS s ON s.id = ps.star_id
ORDER BY e.id;
```

### 6.3. Observation details

```sql
SELECT
    observation_id,
    exoplanet_id,
    telescope_name,
    observer_id,
    observation_date
FROM v_observation_details
ORDER BY observation_date DESC;
```

## 7. Aggregation and grouping

How many exoplanets each spectral class has:

```sql
SELECT
    star_spectral_class,
    COUNT(*) AS exoplanet_count
FROM v_exoplanet_catalog
GROUP BY star_spectral_class
ORDER BY exoplanet_count DESC, star_spectral_class;
```

How many observations each telescope has:

```sql
SELECT
    telescope_name,
    COUNT(*) AS observations_count
FROM v_observation_details
GROUP BY telescope_name
ORDER BY observations_count DESC, telescope_name;
```

Only groups with at least 2 exoplanets:

```sql
SELECT
    star_spectral_class,
    COUNT(*) AS exoplanet_count
FROM v_exoplanet_catalog
GROUP BY star_spectral_class
HAVING COUNT(*) >= 2
ORDER BY exoplanet_count DESC;
```

## 8. Complicated queries with many conditions

This section is the most useful for coursework-style analytical requests.

### 8.1. Complex filter with many `WHERE` conditions

Find nearby habitable-zone style candidates that:

- are `terrestial` or `superearth`
- are at distance at most `50`
- orbit `M`-class stars
- were observed by space telescopes
- were observed on or after `2020-01-01`
- were observed by observers from selected countries

```sql
SELECT
    vc.exoplanet_id,
    vc.planet_type,
    vc.exoplanet_distance,
    vc.host_star_id,
    vc.star_spectral_class,
    COUNT(*) AS observation_count,
    COUNT(DISTINCT vod.telescope_name) AS telescope_count
FROM v_exoplanet_catalog AS vc
JOIN v_observation_details AS vod
    ON vod.exoplanet_id = vc.exoplanet_id
WHERE vc.planet_type IN ('terrestial', 'superearth')
  AND vc.exoplanet_distance <= 50
  AND vc.star_spectral_class LIKE 'M%'
  AND vod.telescope_type = 'space'
  AND vod.observation_date >= DATE '2020-01-01'
  AND vod.observer_country IN ('United States', 'Belgium')
GROUP BY
    vc.exoplanet_id,
    vc.planet_type,
    vc.exoplanet_distance,
    vc.host_star_id,
    vc.star_spectral_class
HAVING COUNT(*) >= 1
ORDER BY observation_count DESC, vc.exoplanet_distance ASC;
```

### 8.2. Systems with habitable planets but no recent ground-based observations

This query uses `EXISTS` and `NOT EXISTS`.

```sql
SELECT
    ps.id AS planetary_system_id,
    ps.habitable_planets,
    ps.distance
FROM planetary_system AS ps
WHERE ps.habitable_planets > 0
  AND EXISTS (
      SELECT 1
      FROM exoplanet AS e
      WHERE e.system_id = ps.id
  )
  AND NOT EXISTS (
      SELECT 1
      FROM exoplanet AS e
      JOIN observation AS o ON o.exoplanet_id = e.id
      JOIN telescope AS t ON t.name = o.telescope_name
      WHERE e.system_id = ps.id
        AND t.telescope_type = 'ground'
        AND o.observation_date >= DATE '2023-01-01'
  )
ORDER BY ps.distance;
```

### 8.3. Top stars by number of planets using `WITH`

This uses a Common Table Expression (`CTE`) to break a complex task into steps.

```sql
WITH star_stats AS (
    SELECT
        s.id AS star_id,
        s.spectral_class,
        COUNT(e.id) AS exoplanet_count,
        AVG(e.mass) AS avg_planet_mass,
        AVG(e.radius) AS avg_planet_radius
    FROM star AS s
    JOIN planetary_system AS ps ON ps.star_id = s.id
    JOIN exoplanet AS e ON e.system_id = ps.id
    GROUP BY s.id, s.spectral_class
)
SELECT
    star_id,
    spectral_class,
    exoplanet_count,
    ROUND(avg_planet_mass, 4) AS avg_planet_mass,
    ROUND(avg_planet_radius, 4) AS avg_planet_radius
FROM star_stats
WHERE exoplanet_count >= 1
ORDER BY exoplanet_count DESC, avg_planet_mass DESC
LIMIT 10;
```

### 8.4. Rank stars with a window function

This is useful when you need ordered rankings.

```sql
WITH star_stats AS (
    SELECT
        s.id AS star_id,
        COUNT(e.id) AS exoplanet_count
    FROM star AS s
    JOIN planetary_system AS ps ON ps.star_id = s.id
    JOIN exoplanet AS e ON e.system_id = ps.id
    GROUP BY s.id
)
SELECT
    star_id,
    exoplanet_count,
    ROW_NUMBER() OVER (ORDER BY exoplanet_count DESC, star_id) AS rank_position
FROM star_stats
ORDER BY rank_position
LIMIT 10;
```

### 8.5. Multi-table analytical query without using the views

This is a good example if your teacher wants to see explicit joins.

```sql
SELECT
    e.id AS exoplanet_id,
    e.planet_type,
    e.discovery_date,
    s.id AS star_id,
    s.spectral_class,
    ss.id AS stellar_system_id,
    sc.id AS cluster_id,
    g.id AS galaxy_id,
    t.name AS telescope_name,
    o.observation_date,
    ob.id AS observer_id,
    ob.country
FROM exoplanet AS e
JOIN planetary_system AS ps ON ps.id = e.system_id
JOIN star AS s ON s.id = ps.star_id
JOIN stellar_system AS ss ON ss.id = ps.stellar_system_id
JOIN stellar_cluster AS sc ON sc.id = ss.cluster_id
JOIN galaxy AS g ON g.id = sc.galaxy_id
JOIN observation AS o ON o.exoplanet_id = e.id
JOIN telescope AS t ON t.name = o.telescope_name
JOIN observer AS ob ON ob.id = o.observer_id
WHERE e.planet_type IN ('terrestial', 'superearth')
  AND e.discovery_date BETWEEN DATE '2010-01-01' AND DATE '2025-12-31'
  AND s.spectral_class LIKE 'M%'
  AND t.telescope_type = 'space'
  AND ob.country = 'United States'
ORDER BY e.discovery_date DESC, e.id;
```

## 9. Querying the large database

The large database is better for testing aggregation, grouping, ranking, and heavy filtering because it contains many more rows.

Switch to it:

```sql
\c exoplanet_coursework_big postgres
SET search_path TO exoplanet_catalog, public;
```

Quick checks:

```sql
SELECT COUNT(*) FROM exoplanet;
SELECT COUNT(*) FROM observation;
SELECT COUNT(*) FROM stellar_system;
```

Expected values in the large database:

- `exoplanet`: `50000`
- `observation`: `200000`
- `stellar_system`: `10000`

## 10. Running one query directly from PowerShell

You do not need to enter interactive mode every time.

```powershell
$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
& $psql -U postgres -d exoplanet_coursework_big -c "SELECT COUNT(*) FROM exoplanet_catalog.exoplanet;"
```

For a longer query:

```powershell
& $psql -U postgres -d exoplanet_coursework_big -c "
SELECT star_spectral_class, COUNT(*) AS exoplanet_count
FROM exoplanet_catalog.v_exoplanet_catalog
GROUP BY star_spectral_class
ORDER BY exoplanet_count DESC;
"
```

## 11. Exporting query results

Export a query to CSV from inside `psql`:

```sql
\copy (
    SELECT exoplanet_id, host_star_id, star_spectral_class
    FROM v_exoplanet_catalog
    ORDER BY exoplanet_id
) TO 'C:/spbpu/year2/bd/program/exoplanets_export.csv' CSV HEADER
```

## 12. Tips for writing your own complicated queries

When a query becomes large, build it in this order:

1. Start with `SELECT ... FROM ...`
2. Add the required `JOIN`s
3. Add one `WHERE` condition at a time
4. Check the intermediate result
5. Add `GROUP BY` if you need counts or averages
6. Add `HAVING` only for conditions on grouped results
7. Add `ORDER BY` and `LIMIT` at the end

A useful template:

```sql
SELECT
    ...
FROM table_a AS a
JOIN table_b AS b ON ...
JOIN table_c AS c ON ...
WHERE condition_1
  AND condition_2
  AND condition_3
GROUP BY ...
HAVING ...
ORDER BY ...
LIMIT ...;
```

If you are unsure which tables to join, start with the views:

- `v_exoplanet_catalog`
- `v_observation_details`

They are the easiest entry point for most coursework queries.
