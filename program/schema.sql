-- schema.sql
--
-- Main SQL file for the coursework table diagram.
-- It creates only the database structure: types, domains, tables,
-- primary keys, foreign keys, and domain checks.
--
-- This file does not insert data and does not execute analytical queries.

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

CREATE DOMAIN object_id AS VARCHAR(30)
    CHECK (
        VALUE = btrim(VALUE)
        AND VALUE <> ''
        AND VALUE ~ '^[A-Za-z0-9.+ _-]+$'
    );

CREATE DOMAIN observer_id AS VARCHAR(100)
    CHECK (
        VALUE = btrim(VALUE)
        AND VALUE <> ''
        AND VALUE ~ '^[A-Za-z0-9.+ _/-]+$'
    );

CREATE DOMAIN operator_name AS VARCHAR(81)
    CHECK (
        VALUE = btrim(VALUE)
        AND VALUE <> ''
        AND VALUE ~ '^[A-Za-z0-9.+ _/-]+$'
    );

CREATE DOMAIN country_name AS VARCHAR(56)
    CHECK (
        VALUE = btrim(VALUE)
        AND VALUE <> ''
        AND VALUE ~ '^[A-Za-z0-9.+ _-]+$'
    );

CREATE DOMAIN spectral_class AS VARCHAR(5)
    CHECK (
        VALUE ~ '^[OBAFGKMWLD][0-9](III|II|IV|I|V)$'
    );

CREATE TABLE galaxy (
    id object_id PRIMARY KEY,
    conf_plan INT NOT NULL CHECK (conf_plan >= 0),
    hab_plan INT NOT NULL CHECK (hab_plan >= 0 AND hab_plan <= conf_plan),
    dist DECIMAL(12, 6) NOT NULL CHECK (dist >= 0)
);

CREATE TABLE stellar_cluster (
    id object_id PRIMARY KEY,
    stars_count INT NOT NULL CHECK (stars_count >= 10),
    conf_plan INT NOT NULL CHECK (conf_plan >= 0),
    hab_plan INT NOT NULL CHECK (hab_plan >= 0 AND hab_plan <= conf_plan),
    dist DECIMAL(12, 6) NOT NULL CHECK (dist >= 0),
    galaxy_id object_id NOT NULL REFERENCES galaxy(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE stellar_system (
    id object_id PRIMARY KEY,
    stars_count INT NOT NULL CHECK (stars_count >= 1),
    conf_plan INT NOT NULL CHECK (conf_plan >= 0),
    hab_plan INT NOT NULL CHECK (hab_plan >= 0 AND hab_plan <= conf_plan),
    dist DECIMAL(12, 6) NOT NULL CHECK (dist >= 0),
    cluster_id object_id NOT NULL REFERENCES stellar_cluster(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE star (
    id object_id PRIMARY KEY,
    class spectral_class NOT NULL,
    mass DECIMAL(5, 2) NOT NULL CHECK (mass > 0),
    radius DECIMAL(10, 4) NOT NULL CHECK (radius > 0),
    temp INT NOT NULL CHECK (temp > 0),
    dist DECIMAL(16, 6) NOT NULL CHECK (dist >= 0)
);

CREATE TABLE planetary_system (
    id object_id PRIMARY KEY,
    conf_plan INT NOT NULL CHECK (conf_plan >= 1),
    hab_plan INT NOT NULL CHECK (hab_plan >= 0 AND hab_plan <= conf_plan),
    distance DECIMAL(12, 6) NOT NULL CHECK (distance >= 0),
    star_id object_id NOT NULL UNIQUE REFERENCES star(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    stell_sys_id object_id NOT NULL REFERENCES stellar_system(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE exoplanet (
    id object_id PRIMARY KEY,
    mass DECIMAL(10, 4) NOT NULL CHECK (mass > 0),
    radius DECIMAL(10, 4) NOT NULL CHECK (radius > 0),
    orb_period DECIMAL(10, 4) NOT NULL CHECK (orb_period > 0),
    type planet_type NOT NULL,
    dist DECIMAL(12, 6) NOT NULL CHECK (dist >= 0),
    discov_date DATE NOT NULL CHECK (discov_date BETWEEN DATE '1992-01-01' AND CURRENT_DATE),
    last_obs_date DATE NOT NULL CHECK (last_obs_date BETWEEN discov_date AND CURRENT_DATE),
    sys_id object_id NOT NULL REFERENCES planetary_system(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE telescope (
    id object_id PRIMARY KEY,
    type telescope_type NOT NULL,
    aper DECIMAL(6, 2) NOT NULL CHECK (aper > 0),
    com_year INT NOT NULL CHECK (com_year BETWEEN 1609 AND EXTRACT(YEAR FROM CURRENT_DATE)::INT),
    oper operator_name NOT NULL,
    discov_plan INT NOT NULL CHECK (discov_plan >= 0)
);

CREATE TABLE observer (
    id observer_id PRIMARY KEY,
    bday DATE NOT NULL CHECK (bday BETWEEN DATE '1609-01-01' AND CURRENT_DATE),
    country country_name NOT NULL,
    discovs INT NOT NULL CHECK (discovs >= 0)
);

CREATE TABLE observation (
    id object_id PRIMARY KEY,
    exo_id object_id NOT NULL REFERENCES exoplanet(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    tele_name object_id NOT NULL REFERENCES telescope(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    obs_id observer_id NOT NULL REFERENCES observer(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    obs_date DATE NOT NULL CHECK (obs_date BETWEEN DATE '1992-01-01' AND CURRENT_DATE),
    CONSTRAINT observation_unique_event UNIQUE (exo_id, tele_name, obs_id, obs_date)
);

CREATE INDEX idx_stellar_cluster_galaxy_id ON stellar_cluster(galaxy_id);
CREATE INDEX idx_stellar_system_cluster_id ON stellar_system(cluster_id);
CREATE INDEX idx_planetary_system_star_id ON planetary_system(star_id);
CREATE INDEX idx_planetary_system_stell_sys_id ON planetary_system(stell_sys_id);
CREATE INDEX idx_exoplanet_sys_id ON exoplanet(sys_id);
CREATE INDEX idx_observation_exo_id ON observation(exo_id);
CREATE INDEX idx_observation_tele_name ON observation(tele_name);
CREATE INDEX idx_observation_obs_id ON observation(obs_id);

COMMENT ON SCHEMA exoplanet_catalog IS 'Coursework database schema for exoplanet cataloging.';
