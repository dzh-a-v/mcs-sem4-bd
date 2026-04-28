-- queries.sql
--
-- Contains ready-to-run analytical SELECT queries for the coursework
-- database. It does not create, update, or delete data.
--
-- Run this after loading either seed.sql or generate_large_dataset.sql.
-- The queries demonstrate hierarchy lookup, filters, grouping, aggregation,
-- and observation summaries.

SET search_path TO exoplanet_catalog, public;

-- 1. Full catalog slice with hierarchy and host-star metadata.
SELECT
    exoplanet_id,
    planet_type,
    host_star_id,
    star_spectral_class,
    planetary_system_id,
    stellar_system_id,
    stellar_cluster_id,
    galaxy_id,
    discovery_date
FROM v_exoplanet_catalog
ORDER BY discovery_date, exoplanet_id;

-- 2. Nearby systems that still contain habitable-zone planets.
SELECT
    ps.id AS planetary_system_id,
    ss.id AS stellar_system_id,
    ps.confirmed_planets,
    ps.habitable_planets,
    ps.distance
FROM planetary_system AS ps
JOIN stellar_system AS ss ON ss.id = ps.stellar_system_id
WHERE ps.habitable_planets > 0
  AND ps.distance <= 50
ORDER BY ps.habitable_planets DESC, ps.distance ASC;

-- 3. Distribution of discovered exoplanets by host-star spectral class.
SELECT
    star_spectral_class,
    COUNT(*) AS exoplanet_count
FROM v_exoplanet_catalog
GROUP BY star_spectral_class
ORDER BY exoplanet_count DESC, star_spectral_class;

-- 4. Telescope activity summary.
SELECT
    telescope_name,
    telescope_type,
    COUNT(*) AS observations_count,
    COUNT(DISTINCT exoplanet_id) AS unique_exoplanets
FROM v_observation_details
GROUP BY telescope_name, telescope_type
ORDER BY unique_exoplanets DESC, observations_count DESC, telescope_name;

-- 5. Most active observers by observation count.
SELECT
    observer_id,
    observer_country,
    COUNT(*) AS observations_count
FROM v_observation_details
GROUP BY observer_id, observer_country
ORDER BY observations_count DESC, observer_id;
