SET search_path TO exoplanet_catalog, public;

INSERT INTO galaxy (id, confirmed_planets, habitable_planets, distance) VALUES
    ('The Milky Way', 8, 5, 0.000000),
    ('Andromeda', 0, 0, 780000.000000);

INSERT INTO stellar_cluster (id, stars_count, confirmed_planets, distance, galaxy_id) VALUES
    ('Local Neighborhood', 18, 6, 0.000000, 'The Milky Way'),
    ('Cygnus Survey Cluster', 12, 2, 100.000000, 'The Milky Way');

INSERT INTO stellar_system (id, stars_count, confirmed_planets, habitable_planets, distance, cluster_id) VALUES
    ('TRAPPIST-1', 1, 3, 2, 12.429020, 'Local Neighborhood'),
    ('Proxima Centauri', 1, 1, 1, 1.301200, 'Local Neighborhood'),
    ('Kepler-186', 1, 1, 1, 177.000000, 'Local Neighborhood'),
    ('TOI-700', 1, 1, 1, 31.127000, 'Local Neighborhood'),
    ('Kepler-16', 2, 1, 0, 75.000000, 'Cygnus Survey Cluster'),
    ('TOI-1338', 2, 1, 0, 124.500000, 'Cygnus Survey Cluster');

INSERT INTO star (id, spectral_class, mass, radius, temperature, distance) VALUES
    ('TRAPPIST-1', 'M8V', 0.09, 0.1210, 2559, 12.429020),
    ('Proxima Centauri', 'M5V', 0.12, 0.1542, 3042, 1.301200),
    ('Kepler-186', 'M1V', 0.54, 0.5230, 3755, 177.000000),
    ('TOI-700', 'M2V', 0.42, 0.4200, 3480, 31.127000),
    ('Kepler-16 A', 'K6V', 0.69, 0.6490, 4450, 75.000000),
    ('Kepler-16 B', 'M4V', 0.20, 0.2260, 3311, 75.000000),
    ('TOI-1338 A', 'F7V', 1.30, 1.3300, 6300, 124.500000),
    ('TOI-1338 B', 'M3V', 0.29, 0.3200, 3400, 124.500000);

INSERT INTO planetary_system (id, confirmed_planets, habitable_planets, distance, star_id, stellar_system_id) VALUES
    ('TRAPPIST-1', 3, 2, 12.429020, 'TRAPPIST-1', 'TRAPPIST-1'),
    ('Proxima Centauri', 1, 1, 1.301200, 'Proxima Centauri', 'Proxima Centauri'),
    ('Kepler-186', 1, 1, 177.000000, 'Kepler-186', 'Kepler-186'),
    ('TOI-700', 1, 1, 31.127000, 'TOI-700', 'TOI-700'),
    ('Kepler-16', 1, 0, 75.000000, 'Kepler-16 A', 'Kepler-16'),
    ('TOI-1338', 1, 0, 124.500000, 'TOI-1338 A', 'TOI-1338');

INSERT INTO exoplanet (id, mass, radius, orbital_period, planet_type, distance, discovery_date, last_obs_date, system_id) VALUES
    ('TRAPPIST-1e', 0.6920, 0.9200, 6.0990, 'terrestial', 12.429020, DATE '2017-02-22', DATE '2025-11-03', 'TRAPPIST-1'),
    ('TRAPPIST-1f', 1.0390, 1.0450, 9.2067, 'terrestial', 12.429020, DATE '2017-02-22', DATE '2025-09-19', 'TRAPPIST-1'),
    ('TRAPPIST-1g', 1.3210, 1.1270, 12.3529, 'superearth', 12.429020, DATE '2017-02-22', DATE '2025-08-07', 'TRAPPIST-1'),
    ('Proxima Centauri b', 1.2700, 1.0800, 11.1860, 'terrestial', 1.301200, DATE '2016-08-24', DATE '2025-06-12', 'Proxima Centauri'),
    ('Kepler-186f', 1.4000, 1.1100, 129.9450, 'terrestial', 177.000000, DATE '2014-04-17', DATE '2024-10-15', 'Kepler-186'),
    ('TOI-700 d', 1.7200, 1.1900, 37.4260, 'superearth', 31.127000, DATE '2020-01-06', DATE '2025-08-09', 'TOI-700'),
    ('Kepler-16b', 105.0000, 8.4500, 228.7760, 'gas_giant', 75.000000, DATE '2011-09-15', DATE '2024-07-30', 'Kepler-16'),
    ('TOI-1338 b', 33.9000, 6.8500, 95.1650, 'neptunian', 124.500000, DATE '2020-08-06', DATE '2025-02-11', 'TOI-1338');

INSERT INTO telescope (name, telescope_type, aperture, comm_year, operator_name, discovered_planets) VALUES
    ('Hubble', 'space', 2.40, 1990, 'NASA', 2),
    ('James Webb Space Telescope', 'space', 6.50, 2021, 'NASA', 1),
    ('Kepler', 'space', 0.95, 2009, 'NASA', 3),
    ('Transiting Exoplanet Survey Satellite', 'space', 0.10, 2018, 'NASA', 2),
    ('Very Large Telescope', 'ground', 8.20, 1998, 'European Southern Observatory', 2);

INSERT INTO observer (id, birth_date, country, discoveries) VALUES
    ('NASA', DATE '1958-07-29', 'United States', 4),
    ('European Southern Observatory', DATE '1962-10-05', 'Germany', 2),
    ('Michael Gillon', DATE '1974-01-10', 'Belgium', 3),
    ('Elisa Quintana', DATE '1973-01-01', 'United States', 1),
    ('TESS Science Team', DATE '2018-04-18', 'United States', 2);

INSERT INTO observation (id, exoplanet_id, telescope_name, observer_id, observation_date) VALUES
    ('OBS-0001', 'TRAPPIST-1e', 'Kepler', 'Michael Gillon', DATE '2017-02-23'),
    ('OBS-0002', 'TRAPPIST-1f', 'Kepler', 'Michael Gillon', DATE '2017-02-23'),
    ('OBS-0003', 'TRAPPIST-1g', 'Kepler', 'Michael Gillon', DATE '2017-02-23'),
    ('OBS-0004', 'Proxima Centauri b', 'Very Large Telescope', 'European Southern Observatory', DATE '2016-08-24'),
    ('OBS-0005', 'Kepler-186f', 'Kepler', 'Elisa Quintana', DATE '2014-04-17'),
    ('OBS-0006', 'TOI-700 d', 'Transiting Exoplanet Survey Satellite', 'TESS Science Team', DATE '2020-01-06'),
    ('OBS-0007', 'TOI-700 d', 'James Webb Space Telescope', 'NASA', DATE '2024-07-14'),
    ('OBS-0008', 'Kepler-16b', 'Kepler', 'NASA', DATE '2011-09-15'),
    ('OBS-0009', 'TOI-1338 b', 'Transiting Exoplanet Survey Satellite', 'NASA', DATE '2020-08-06'),
    ('OBS-0010', 'Proxima Centauri b', 'James Webb Space Telescope', 'NASA', DATE '2025-06-12');
