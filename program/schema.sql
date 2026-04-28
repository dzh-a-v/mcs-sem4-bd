-- schema.sql
--
-- Creates the coursework database structure shown in
-- docs/report/bd-tables-diagram.png. The script defines domains, lookup
-- tables, fixed lookup values, entity tables, keys, foreign keys, and checks.

CREATE SCHEMA exoplanet_catalog;

SET search_path TO exoplanet_catalog, public;

CREATE DOMAIN object_id AS VARCHAR(30)
    CHECK (
        VALUE = btrim(VALUE)
        AND VALUE <> ''
        AND VALUE ~ '^[A-Za-z0-9.+ _-]+$'
    );

CREATE DOMAIN telescope_id AS VARCHAR(47)
    CHECK (
        VALUE = btrim(VALUE)
        AND VALUE <> ''
        AND VALUE ~ '^[A-Za-z0-9.+ _/-]+$'
    );

CREATE DOMAIN observer_id AS VARCHAR(100)
    CHECK (
        VALUE = btrim(VALUE)
        AND VALUE <> ''
        AND VALUE ~ '^[A-Za-z0-9.+ _/-]+$'
    );

CREATE DOMAIN exoplanet_type_code AS VARCHAR(20)
    CHECK (VALUE IN ('gas_giant', 'neptunian', 'superearth', 'terrestial'));

CREATE DOMAIN telescope_type_code AS VARCHAR(20)
    CHECK (VALUE IN ('space', 'ground'));

CREATE DOMAIN spectral_class_code AS CHAR(1)
    CHECK (VALUE IN ('O', 'B', 'A', 'F', 'G', 'K', 'M', 'W', 'L', 'D'));

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

CREATE TABLE exo_type (
    exo_type_id exoplanet_type_code PRIMARY KEY,
    exo_type VARCHAR(20) NOT NULL UNIQUE CHECK (
        exo_type = btrim(exo_type)
        AND exo_type <> ''
    )
);

CREATE TABLE telescope_type (
    tele_type_id telescope_type_code PRIMARY KEY,
    tele_type VARCHAR(20) NOT NULL UNIQUE CHECK (
        tele_type = btrim(tele_type)
        AND tele_type <> ''
    )
);

CREATE TABLE country (
    country_id country_name PRIMARY KEY,
    country country_name NOT NULL UNIQUE
);

CREATE TABLE spectral_class (
    spectral_class_id spectral_class_code PRIMARY KEY,
    spectral_class spectral_class_code NOT NULL UNIQUE
);

INSERT INTO exo_type (exo_type_id, exo_type) VALUES
    ('gas_giant', 'Gas Giant'),
    ('neptunian', 'Neptunian'),
    ('superearth', 'Superearth'),
    ('terrestial', 'Terrestial');

INSERT INTO telescope_type (tele_type_id, tele_type) VALUES
    ('space', 'космический'),
    ('ground', 'наземный');

INSERT INTO country (country_id, country)
SELECT country_name, country_name
FROM (
    VALUES
        ('Afghanistan'),
        ('Albania'),
        ('Algeria'),
        ('Andorra'),
        ('Angola'),
        ('Antigua and Barbuda'),
        ('Argentina'),
        ('Armenia'),
        ('Australia'),
        ('Austria'),
        ('Azerbaijan'),
        ('Bahamas'),
        ('Bahrain'),
        ('Bangladesh'),
        ('Barbados'),
        ('Belarus'),
        ('Belgium'),
        ('Belize'),
        ('Benin'),
        ('Bhutan'),
        ('Bolivia'),
        ('Bosnia and Herzegovina'),
        ('Botswana'),
        ('Brazil'),
        ('Brunei'),
        ('Bulgaria'),
        ('Burkina Faso'),
        ('Burundi'),
        ('Cabo Verde'),
        ('Cambodia'),
        ('Cameroon'),
        ('Canada'),
        ('Central African Republic'),
        ('Chad'),
        ('Chile'),
        ('China'),
        ('Colombia'),
        ('Comoros'),
        ('Congo'),
        ('Costa Rica'),
        ('Cote d Ivoire'),
        ('Croatia'),
        ('Cuba'),
        ('Cyprus'),
        ('Czechia'),
        ('Democratic Republic of the Congo'),
        ('Denmark'),
        ('Djibouti'),
        ('Dominica'),
        ('Dominican Republic'),
        ('Ecuador'),
        ('Egypt'),
        ('El Salvador'),
        ('Equatorial Guinea'),
        ('Eritrea'),
        ('Estonia'),
        ('Eswatini'),
        ('Ethiopia'),
        ('Fiji'),
        ('Finland'),
        ('France'),
        ('Gabon'),
        ('Gambia'),
        ('Georgia'),
        ('Germany'),
        ('Ghana'),
        ('Greece'),
        ('Grenada'),
        ('Guatemala'),
        ('Guinea'),
        ('Guinea-Bissau'),
        ('Guyana'),
        ('Haiti'),
        ('Honduras'),
        ('Hungary'),
        ('Iceland'),
        ('India'),
        ('Indonesia'),
        ('Iran'),
        ('Iraq'),
        ('Ireland'),
        ('Israel'),
        ('Italy'),
        ('Jamaica'),
        ('Japan'),
        ('Jordan'),
        ('Kazakhstan'),
        ('Kenya'),
        ('Kiribati'),
        ('Kuwait'),
        ('Kyrgyzstan'),
        ('Laos'),
        ('Latvia'),
        ('Lebanon'),
        ('Lesotho'),
        ('Liberia'),
        ('Libya'),
        ('Liechtenstein'),
        ('Lithuania'),
        ('Luxembourg'),
        ('Madagascar'),
        ('Malawi'),
        ('Malaysia'),
        ('Maldives'),
        ('Mali'),
        ('Malta'),
        ('Marshall Islands'),
        ('Mauritania'),
        ('Mauritius'),
        ('Mexico'),
        ('Micronesia'),
        ('Moldova'),
        ('Monaco'),
        ('Mongolia'),
        ('Montenegro'),
        ('Morocco'),
        ('Mozambique'),
        ('Myanmar'),
        ('Namibia'),
        ('Nauru'),
        ('Nepal'),
        ('Netherlands'),
        ('New Zealand'),
        ('Nicaragua'),
        ('Niger'),
        ('Nigeria'),
        ('North Korea'),
        ('North Macedonia'),
        ('Norway'),
        ('Oman'),
        ('Pakistan'),
        ('Palau'),
        ('Palestine'),
        ('Panama'),
        ('Papua New Guinea'),
        ('Paraguay'),
        ('Peru'),
        ('Philippines'),
        ('Poland'),
        ('Portugal'),
        ('Qatar'),
        ('Romania'),
        ('Russia'),
        ('Rwanda'),
        ('Saint Kitts and Nevis'),
        ('Saint Lucia'),
        ('Saint Vincent and the Grenadines'),
        ('Samoa'),
        ('San Marino'),
        ('Sao Tome and Principe'),
        ('Saudi Arabia'),
        ('Senegal'),
        ('Serbia'),
        ('Seychelles'),
        ('Sierra Leone'),
        ('Singapore'),
        ('Slovakia'),
        ('Slovenia'),
        ('Solomon Islands'),
        ('Somalia'),
        ('South Africa'),
        ('South Korea'),
        ('South Sudan'),
        ('Spain'),
        ('Sri Lanka'),
        ('Sudan'),
        ('Suriname'),
        ('Sweden'),
        ('Switzerland'),
        ('Syria'),
        ('Tajikistan'),
        ('Tanzania'),
        ('Thailand'),
        ('Timor-Leste'),
        ('Togo'),
        ('Tonga'),
        ('Trinidad and Tobago'),
        ('Tunisia'),
        ('Turkey'),
        ('Turkmenistan'),
        ('Tuvalu'),
        ('Uganda'),
        ('Ukraine'),
        ('United Arab Emirates'),
        ('United Kingdom of Great Britain and Northern Ireland'),
        ('United States'),
        ('Uruguay'),
        ('Uzbekistan'),
        ('Vanuatu'),
        ('Venezuela'),
        ('Vietnam'),
        ('Yemen'),
        ('Zambia'),
        ('Zimbabwe'),
        ('Holy See')
) AS countries(country_name);

INSERT INTO spectral_class (spectral_class_id, spectral_class) VALUES
    ('O', 'O'),
    ('B', 'B'),
    ('A', 'A'),
    ('F', 'F'),
    ('G', 'G'),
    ('K', 'K'),
    ('M', 'M'),
    ('W', 'W'),
    ('L', 'L'),
    ('D', 'D');

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
    class spectral_class_code NOT NULL REFERENCES spectral_class(spectral_class_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
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
    star_id object_id NOT NULL REFERENCES star(id)
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
    exo_type_id exoplanet_type_code NOT NULL REFERENCES exo_type(exo_type_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    dist DECIMAL(12, 6) NOT NULL CHECK (dist >= 0),
    discov_date DATE NOT NULL CHECK (
        discov_date BETWEEN DATE '1992-01-01' AND CURRENT_DATE
    ),
    last_obs_date DATE NOT NULL CHECK (
        last_obs_date BETWEEN discov_date AND CURRENT_DATE
    ),
    sys_id object_id NOT NULL REFERENCES planetary_system(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE telescope (
    tele_id telescope_id PRIMARY KEY,
    tele_type_id telescope_type_code NOT NULL REFERENCES telescope_type(tele_type_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    aper DECIMAL(6, 2) NOT NULL CHECK (aper > 0),
    com_year INT NOT NULL CHECK (
        com_year BETWEEN 1609 AND EXTRACT(YEAR FROM CURRENT_DATE)::INT
    ),
    oper operator_name NOT NULL,
    discov_plan INT NOT NULL CHECK (discov_plan >= 0)
);

CREATE TABLE observer (
    id observer_id PRIMARY KEY,
    bday DATE NOT NULL CHECK (bday BETWEEN DATE '1609-01-01' AND CURRENT_DATE),
    country country_name NOT NULL REFERENCES country(country_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    discovs INT NOT NULL CHECK (discovs >= 0)
);

CREATE TABLE observation (
    id object_id PRIMARY KEY,
    exo_id object_id NOT NULL REFERENCES exoplanet(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    tele_name telescope_id NOT NULL REFERENCES telescope(tele_id)
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
CREATE INDEX idx_star_class ON star(class);
CREATE INDEX idx_planetary_system_star_id ON planetary_system(star_id);
CREATE INDEX idx_planetary_system_stell_sys_id ON planetary_system(stell_sys_id);
CREATE INDEX idx_exoplanet_exo_type_id ON exoplanet(exo_type_id);
CREATE INDEX idx_exoplanet_sys_id ON exoplanet(sys_id);
CREATE INDEX idx_telescope_tele_type_id ON telescope(tele_type_id);
CREATE INDEX idx_observer_country ON observer(country);
CREATE INDEX idx_observation_exo_id ON observation(exo_id);
CREATE INDEX idx_observation_tele_name ON observation(tele_name);
CREATE INDEX idx_observation_obs_id ON observation(obs_id);

COMMENT ON SCHEMA exoplanet_catalog IS 'Coursework database schema for exoplanet cataloging.';
