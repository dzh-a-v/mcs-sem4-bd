-- schema.sql
--
-- Creates the PostgreSQL structure for the coursework database.
-- Run this file first in an empty database.
--
-- It creates:
-- - schema: exoplanet_catalog
-- - enum types for planet and telescope categories
-- - reusable domains for validated identifiers and names
-- - all coursework tables, primary keys, foreign keys, checks, and indexes
-- - helper views for catalog and observation queries

CREATE SCHEMA exoplanet_catalog;
SET search_path TO exoplanet_catalog, public;

CREATE TYPE planet_type AS ENUM (
    'gas_giant',
    'neptunian',
    'superearth',
    'terrestial'
);

CREATE TYPE telescope_type AS ENUM (
    'space',
    'ground'
);

CREATE DOMAIN object_id_30 AS VARCHAR(30)
    CHECK (
        VALUE = btrim(VALUE)
        AND VALUE <> ''
        AND VALUE ~ '^[A-Za-z0-9.+ -]+$'
    );

CREATE DOMAIN observer_id_100 AS VARCHAR(100)
    CHECK (
        VALUE = btrim(VALUE)
        AND VALUE <> ''
        AND VALUE ~ '^[A-Za-z0-9./ -]+$'
    );

CREATE DOMAIN telescope_name_47 AS VARCHAR(47)
    CHECK (
        VALUE = btrim(VALUE)
        AND VALUE <> ''
        AND VALUE ~ '^[A-Za-z0-9./ -]+$'
    );

CREATE DOMAIN operator_name_81 AS VARCHAR(81)
    CHECK (
        VALUE = btrim(VALUE)
        AND VALUE <> ''
        AND VALUE ~ '^[A-Za-z0-9./ -]+$'
    );

CREATE DOMAIN country_name_56 AS VARCHAR(56)
    CHECK (
        VALUE = btrim(VALUE)
        AND VALUE <> ''
        AND VALUE ~ '^[A-Za-z0-9. -]+$'
    );

CREATE DOMAIN spectral_class_code AS VARCHAR(5)
    CHECK (
        VALUE ~ '^[OBAFGKMWLD][0-9](III|II|IV|I|V)$'
    );

CREATE TABLE galaxy (
    id object_id_30 PRIMARY KEY,
    confirmed_planets INT NOT NULL CHECK (confirmed_planets >= 0),
    habitable_planets INT NOT NULL CHECK (habitable_planets >= 0 AND habitable_planets <= confirmed_planets),
    distance DECIMAL(12, 6) NOT NULL CHECK (distance >= 0)
);

CREATE TABLE stellar_cluster (
    id object_id_30 PRIMARY KEY,
    stars_count INT NOT NULL CHECK (stars_count >= 10),
    confirmed_planets INT NOT NULL CHECK (confirmed_planets >= 0),
    distance DECIMAL(12, 6) NOT NULL CHECK (distance >= 0),
    galaxy_id object_id_30 NOT NULL REFERENCES galaxy(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE stellar_system (
    id object_id_30 PRIMARY KEY,
    stars_count INT NOT NULL CHECK (stars_count >= 1),
    confirmed_planets INT NOT NULL CHECK (confirmed_planets >= 0),
    habitable_planets INT NOT NULL CHECK (habitable_planets >= 0 AND habitable_planets <= confirmed_planets),
    distance DECIMAL(12, 6) NOT NULL CHECK (distance >= 0),
    cluster_id object_id_30 NOT NULL REFERENCES stellar_cluster(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE star (
    id object_id_30 PRIMARY KEY,
    spectral_class spectral_class_code NOT NULL,
    mass DECIMAL(5, 2) NOT NULL CHECK (mass > 0),
    radius DECIMAL(10, 4) NOT NULL CHECK (radius > 0),
    temperature INT NOT NULL CHECK (temperature > 0),
    distance DECIMAL(16, 6) NOT NULL CHECK (distance >= 0)
);

CREATE TABLE planetary_system (
    id object_id_30 PRIMARY KEY,
    confirmed_planets INT NOT NULL CHECK (confirmed_planets >= 1),
    habitable_planets INT NOT NULL CHECK (habitable_planets >= 0 AND habitable_planets <= confirmed_planets),
    distance DECIMAL(12, 6) NOT NULL CHECK (distance >= 0),
    star_id object_id_30 NOT NULL UNIQUE REFERENCES star(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    stellar_system_id object_id_30 NOT NULL REFERENCES stellar_system(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE exoplanet (
    id object_id_30 PRIMARY KEY,
    mass DECIMAL(10, 4) NOT NULL CHECK (mass > 0),
    radius DECIMAL(10, 4) NOT NULL CHECK (radius > 0),
    orbital_period DECIMAL(10, 4) NOT NULL CHECK (orbital_period > 0),
    planet_type planet_type NOT NULL,
    distance DECIMAL(12, 6) NOT NULL CHECK (distance >= 0),
    discovery_date DATE NOT NULL CHECK (discovery_date BETWEEN DATE '1992-01-01' AND CURRENT_DATE),
    last_obs_date DATE NOT NULL CHECK (last_obs_date BETWEEN discovery_date AND CURRENT_DATE),
    system_id object_id_30 NOT NULL REFERENCES planetary_system(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE telescope (
    name telescope_name_47 PRIMARY KEY,
    telescope_type telescope_type NOT NULL,
    aperture DECIMAL(6, 2) NOT NULL CHECK (aperture > 0),
    comm_year INT NOT NULL CHECK (comm_year BETWEEN 1609 AND EXTRACT(YEAR FROM CURRENT_DATE)::INT),
    operator_name operator_name_81 NOT NULL,
    discovered_planets INT NOT NULL CHECK (discovered_planets >= 0)
);

CREATE TABLE observer (
    id observer_id_100 PRIMARY KEY,
    birth_date DATE NOT NULL CHECK (birth_date BETWEEN DATE '1609-01-01' AND CURRENT_DATE),
    country country_name_56 NOT NULL,
    discoveries INT NOT NULL CHECK (discoveries >= 0)
);

CREATE TABLE observation (
    id object_id_30 PRIMARY KEY,
    exoplanet_id object_id_30 NOT NULL REFERENCES exoplanet(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    telescope_name telescope_name_47 NOT NULL REFERENCES telescope(name) ON UPDATE CASCADE ON DELETE RESTRICT,
    observer_id observer_id_100 NOT NULL REFERENCES observer(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    observation_date DATE NOT NULL CHECK (observation_date BETWEEN DATE '1992-01-01' AND CURRENT_DATE),
    CONSTRAINT observation_unique_event UNIQUE (exoplanet_id, telescope_name, observer_id, observation_date)
);

CREATE INDEX idx_stellar_cluster_galaxy_id ON stellar_cluster(galaxy_id);
CREATE INDEX idx_stellar_system_cluster_id ON stellar_system(cluster_id);
CREATE INDEX idx_planetary_system_stellar_system_id ON planetary_system(stellar_system_id);
CREATE INDEX idx_exoplanet_system_id ON exoplanet(system_id);
CREATE INDEX idx_exoplanet_discovery_date ON exoplanet(discovery_date);
CREATE INDEX idx_observation_exoplanet_id ON observation(exoplanet_id);
CREATE INDEX idx_observation_telescope_name ON observation(telescope_name);
CREATE INDEX idx_observation_observer_id ON observation(observer_id);
CREATE INDEX idx_observation_observation_date ON observation(observation_date);

CREATE VIEW v_exoplanet_catalog AS
SELECT
    e.id AS exoplanet_id,
    e.mass AS exoplanet_mass,
    e.radius AS exoplanet_radius,
    e.orbital_period,
    e.planet_type,
    e.distance AS exoplanet_distance,
    e.discovery_date,
    e.last_obs_date,
    ps.id AS planetary_system_id,
    ps.confirmed_planets AS system_confirmed_planets,
    ps.habitable_planets AS system_habitable_planets,
    s.id AS host_star_id,
    s.spectral_class AS star_spectral_class,
    s.mass AS star_mass,
    s.radius AS star_radius,
    s.temperature AS star_temperature,
    ss.id AS stellar_system_id,
    ss.stars_count AS stellar_system_stars_count,
    sc.id AS stellar_cluster_id,
    g.id AS galaxy_id
FROM exoplanet AS e
JOIN planetary_system AS ps ON ps.id = e.system_id
JOIN star AS s ON s.id = ps.star_id
JOIN stellar_system AS ss ON ss.id = ps.stellar_system_id
JOIN stellar_cluster AS sc ON sc.id = ss.cluster_id
JOIN galaxy AS g ON g.id = sc.galaxy_id;

CREATE VIEW v_observation_details AS
SELECT
    o.id AS observation_id,
    o.observation_date,
    o.exoplanet_id,
    e.planet_type,
    ps.id AS planetary_system_id,
    s.id AS host_star_id,
    s.spectral_class AS host_star_spectral_class,
    ss.id AS stellar_system_id,
    sc.id AS stellar_cluster_id,
    g.id AS galaxy_id,
    o.telescope_name,
    t.telescope_type,
    t.operator_name,
    o.observer_id,
    ob.country AS observer_country
FROM observation AS o
JOIN exoplanet AS e ON e.id = o.exoplanet_id
JOIN planetary_system AS ps ON ps.id = e.system_id
JOIN star AS s ON s.id = ps.star_id
JOIN stellar_system AS ss ON ss.id = ps.stellar_system_id
JOIN stellar_cluster AS sc ON sc.id = ss.cluster_id
JOIN galaxy AS g ON g.id = sc.galaxy_id
JOIN telescope AS t ON t.name = o.telescope_name
JOIN observer AS ob ON ob.id = o.observer_id;

COMMENT ON SCHEMA exoplanet_catalog IS 'Coursework database for exoplanet cataloging.';
COMMENT ON TYPE planet_type IS 'Planet classes from the coursework; "terrestial" keeps the report spelling.';
COMMENT ON VIEW v_exoplanet_catalog IS 'Convenience view that resolves the full hierarchy for each exoplanet.';
COMMENT ON VIEW v_observation_details IS 'Convenience view that resolves observation events together with their hierarchy.';
