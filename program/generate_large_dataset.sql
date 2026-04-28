SET search_path TO exoplanet_catalog, public;

INSERT INTO galaxy (id, confirmed_planets, habitable_planets, distance)
SELECT
    'GAL-' || lpad(g::text, 2, '0'),
    5000,
    1000,
    ((g - 1) * 75000)::DECIMAL(12, 6)
FROM generate_series(1, 10) AS g;

INSERT INTO stellar_cluster (id, stars_count, confirmed_planets, distance, galaxy_id)
SELECT
    'CLS-' || lpad(g::text, 2, '0') || '-' || lpad(c::text, 3, '0'),
    20,
    100,
    (((g - 1) * 75000) + (c * 50))::DECIMAL(12, 6),
    'GAL-' || lpad(g::text, 2, '0')
FROM generate_series(1, 10) AS g
CROSS JOIN generate_series(1, 50) AS c;

INSERT INTO stellar_system (id, stars_count, confirmed_planets, habitable_planets, distance, cluster_id)
SELECT
    'SYS-' || lpad((((g - 1) * 1000) + ((c - 1) * 20) + s)::text, 5, '0'),
    1,
    5,
    1,
    ((((g - 1) * 75000) + (c * 50)) + (s * 0.01))::DECIMAL(12, 6),
    'CLS-' || lpad(g::text, 2, '0') || '-' || lpad(c::text, 3, '0')
FROM generate_series(1, 10) AS g
CROSS JOIN generate_series(1, 50) AS c
CROSS JOIN generate_series(1, 20) AS s;

INSERT INTO star (id, spectral_class, mass, radius, temperature, distance)
SELECT
    'STR-' || lpad(n::text, 5, '0'),
    CASE n % 5
        WHEN 0 THEN 'G2V'
        WHEN 1 THEN 'K5V'
        WHEN 2 THEN 'M3V'
        WHEN 3 THEN 'F7V'
        ELSE 'A0V'
    END,
    (0.40 + ((n % 80) * 0.01))::DECIMAL(5, 2),
    (0.35 + ((n % 200) * 0.01))::DECIMAL(10, 4),
    3000 + ((n % 400) * 10),
    ((((CEIL(n / 1000.0) - 1) * 75000) + ((((n - 1) % 1000) / 20) + 1) * 50) + ((((n - 1) % 20) + 1) * 0.01))::DECIMAL(16, 6)
FROM generate_series(1, 10000) AS n;

INSERT INTO planetary_system (id, confirmed_planets, habitable_planets, distance, star_id, stellar_system_id)
SELECT
    'PS-' || lpad(n::text, 5, '0'),
    5,
    1,
    ((((CEIL(n / 1000.0) - 1) * 75000) + ((((n - 1) % 1000) / 20) + 1) * 50) + ((((n - 1) % 20) + 1) * 0.01))::DECIMAL(12, 6),
    'STR-' || lpad(n::text, 5, '0'),
    'SYS-' || lpad(n::text, 5, '0')
FROM generate_series(1, 10000) AS n;

INSERT INTO exoplanet (id, mass, radius, orbital_period, planet_type, distance, discovery_date, last_obs_date, system_id)
SELECT
    'EXP-' || lpad(s::text, 5, '0') || '-' || p::text,
    (0.60 + (p * 0.80) + ((s % 30) * 0.03))::DECIMAL(10, 4),
    (0.70 + (p * 0.40) + ((s % 15) * 0.02))::DECIMAL(10, 4),
    (8 + (p * 35) + ((s % 60) * 1.10))::DECIMAL(10, 4),
    CASE p
        WHEN 1 THEN 'terrestial'::planet_type
        WHEN 2 THEN 'superearth'::planet_type
        WHEN 3 THEN 'neptunian'::planet_type
        WHEN 4 THEN 'gas_giant'::planet_type
        ELSE 'superearth'::planet_type
    END,
    ((((CEIL(s / 1000.0) - 1) * 75000) + ((((s - 1) % 1000) / 20) + 1) * 50) + ((((s - 1) % 20) + 1) * 0.01) + (p * 0.0001))::DECIMAL(12, 6),
    (DATE '1992-01-01' + (((s * 5) + p) % 10592)),
    ((DATE '1992-01-01' + (((s * 5) + p) % 10592)) + (((s + p) % 1800))),
    'PS-' || lpad(s::text, 5, '0')
FROM generate_series(1, 10000) AS s
CROSS JOIN generate_series(1, 5) AS p;

INSERT INTO telescope (name, telescope_type, aperture, comm_year, operator_name, discovered_planets)
SELECT
    'Synthetic Telescope ' || lpad(n::text, 2, '0'),
    CASE WHEN n % 2 = 0 THEN 'ground'::telescope_type ELSE 'space'::telescope_type END,
    (0.80 + (n * 0.55))::DECIMAL(6, 2),
    1980 + n,
    'Synthetic Agency ' || lpad(n::text, 2, '0'),
    5000
FROM generate_series(1, 10) AS n;

INSERT INTO observer (id, birth_date, country, discoveries)
SELECT
    'Observer ' || lpad(n::text, 2, '0'),
    DATE '1960-01-01' + (n * 600),
    'Country ' || lpad(n::text, 2, '0'),
    5000
FROM generate_series(1, 10) AS n;

WITH numbered_exoplanets AS (
    SELECT
        e.id,
        e.discovery_date,
        e.last_obs_date,
        row_number() OVER (ORDER BY e.id) AS rn
    FROM exoplanet AS e
    WHERE e.id LIKE 'EXP-%'
)
INSERT INTO observation (id, exoplanet_id, telescope_name, observer_id, observation_date)
SELECT
    'OBS-' || lpad((((ne.rn - 1) * 4) + obs_no)::text, 7, '0'),
    ne.id,
    'Synthetic Telescope ' || lpad((((ne.rn + obs_no - 1) % 10) + 1)::text, 2, '0'),
    'Observer ' || lpad((((ne.rn + obs_no - 1) % 10) + 1)::text, 2, '0'),
    LEAST(ne.last_obs_date, ne.discovery_date + ((obs_no * 90) + (ne.rn % 30)))
FROM numbered_exoplanets AS ne
CROSS JOIN generate_series(1, 4) AS obs_no;
