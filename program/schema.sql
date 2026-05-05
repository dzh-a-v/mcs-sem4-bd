-- schema.sql

-- ========================
-- ENUM TYPES
-- ========================

CREATE TYPE tele_type_enum AS ENUM ('space', 'ground');

CREATE TYPE exo_type_enum AS ENUM (
    'gas_giant',
    'neptunian',
    'superearth',
    'terrestrial'
);

CREATE TYPE star_class_enum AS ENUM (
    'O','B','A','F','G','K','M','W','L','D'
);

CREATE TYPE country_enum AS ENUM (
'Afghanistan','Albania','Algeria','Andorra','Angola','Antigua and Barbuda',
'Argentina','Armenia','Australia','Austria','Azerbaijan',
'Bahamas','Bahrain','Bangladesh','Barbados','Belarus','Belgium','Belize',
'Benin','Bhutan','Bolivia','Bosnia and Herzegovina','Botswana','Brazil',
'Brunei','Bulgaria','Burkina Faso','Burundi',
'Cabo Verde','Cambodia','Cameroon','Canada','Central African Republic',
'Chad','Chile','China','Colombia','Comoros','Congo (Congo-Brazzaville)',
'Costa Rica','Croatia','Cuba','Cyprus','Czechia',
'Democratic Republic of the Congo','Denmark','Djibouti','Dominica',
'Dominican Republic',
'Ecuador','Egypt','El Salvador','Equatorial Guinea','Eritrea','Estonia',
'Eswatini','Ethiopia',
'Fiji','Finland','France',
'Gabon','Gambia','Georgia','Germany','Ghana','Greece','Grenada',
'Guatemala','Guinea','Guinea-Bissau','Guyana',
'Haiti','Honduras','Hungary',
'Iceland','India','Indonesia','Iran','Iraq','Ireland','Israel','Italy',
'Jamaica','Japan','Jordan',
'Kazakhstan','Kenya','Kiribati','Kuwait','Kyrgyzstan',
'Laos','Latvia','Lebanon','Lesotho','Liberia','Libya','Liechtenstein',
'Lithuania','Luxembourg',
'Madagascar','Malawi','Malaysia','Maldives','Mali','Malta',
'Marshall Islands','Mauritania','Mauritius','Mexico','Micronesia',
'Moldova','Monaco','Mongolia','Montenegro','Morocco','Mozambique',
'Myanmar',
'Namibia','Nauru','Nepal','Netherlands','New Zealand','Nicaragua','Niger',
'Nigeria','North Korea','North Macedonia','Norway',
'Oman',
'Pakistan','Palau','Panama','Papua New Guinea','Paraguay','Peru',
'Philippines','Poland','Portugal',
'Qatar',
'Romania','Russia','Rwanda',
'Saint Kitts and Nevis','Saint Lucia',
'Saint Vincent and the Grenadines','Samoa','San Marino',
'Sao Tome and Principe','Saudi Arabia','Senegal','Serbia','Seychelles',
'Sierra Leone','Singapore','Slovakia','Slovenia','Solomon Islands',
'Somalia','South Africa','South Korea','South Sudan','Spain','Sri Lanka',
'Sudan','Suriname','Sweden','Switzerland','Syria',
'Taiwan','Tajikistan','Tanzania','Thailand','Timor-Leste','Togo','Tonga',
'Trinidad and Tobago','Tunisia','Turkey','Turkmenistan','Tuvalu',
'Uganda','Ukraine','United Arab Emirates','United Kingdom',
'United States','Uruguay','Uzbekistan',
'Vanuatu','Vatican City','Venezuela','Vietnam',
'Yemen',
'Zambia','Zimbabwe'
);

-- ========================
-- CORE TABLES
-- ========================

CREATE TABLE galaxy (
    galaxy_id VARCHAR(30) PRIMARY KEY,
    conf_plan INT NOT NULL CHECK (conf_plan >= 0),
    hab_plan  INT NOT NULL CHECK (hab_plan >= 0 AND hab_plan <= conf_plan),
    dist      DECIMAL(12, 6) NOT NULL CHECK (dist >= 0)
);

CREATE TABLE cluster (
    cluster_id  VARCHAR(30) PRIMARY KEY,
    stars_count INT NOT NULL CHECK (stars_count >= 10),
    conf_plan   INT NOT NULL CHECK (conf_plan >= 0),
    hab_plan    INT NOT NULL CHECK (hab_plan >= 0 AND hab_plan <= conf_plan),
    dist        DECIMAL(12, 6) NOT NULL CHECK (dist >= 0),
    galaxy_id   VARCHAR(30) NOT NULL
        REFERENCES galaxy(galaxy_id) ON DELETE CASCADE
);

CREATE TABLE stellar_system (
    stellar_id  VARCHAR(30) PRIMARY KEY,
    stars_count INT NOT NULL CHECK (stars_count >= 1),
    conf_plan   INT NOT NULL CHECK (conf_plan >= 0),
    hab_plan    INT NOT NULL CHECK (hab_plan >= 0 AND hab_plan <= conf_plan),
    dist        DECIMAL(12, 6) NOT NULL CHECK (dist >= 0),
    cluster_id  VARCHAR(30) NOT NULL
        REFERENCES cluster(cluster_id) ON DELETE CASCADE
);

CREATE TABLE plan_system (
    system_id    VARCHAR(30) PRIMARY KEY,
    conf_plan    INT NOT NULL CHECK (conf_plan >= 1),
    hab_plan     INT NOT NULL CHECK (hab_plan >= 0 AND hab_plan <= conf_plan),
    distance     DECIMAL(12, 6) NOT NULL CHECK (distance >= 0),
    stell_sys_id VARCHAR(30) NOT NULL
        REFERENCES stellar_system(stellar_id) ON DELETE CASCADE
);

-- ========================
-- OBJECTS
-- ========================

CREATE TABLE star (
    star_id  VARCHAR(30) PRIMARY KEY,
    class    star_class_enum NOT NULL,
    mass     DECIMAL(5, 2) NOT NULL CHECK (mass > 0),
    radius   DECIMAL(10, 4) NOT NULL CHECK (radius > 0),
    temp     INT NOT NULL CHECK (temp > 0),
    dist     DECIMAL(16, 6) NOT NULL CHECK (dist >= 0),
    sys_id   VARCHAR(30) NOT NULL
        REFERENCES plan_system(system_id) ON DELETE CASCADE
);

CREATE TABLE exoplanet (
    exo_id        VARCHAR(30) PRIMARY KEY,
    mass          DECIMAL(10, 4) NOT NULL CHECK (mass > 0),
    radius        DECIMAL(10, 4) NOT NULL CHECK (radius > 0),
    orb_period    DECIMAL(10, 4) NOT NULL CHECK (orb_period > 0),
    exo_type      exo_type_enum NOT NULL,
    dist          DECIMAL(12, 6) NOT NULL CHECK (dist >= 0),
    discov_date   DATE NOT NULL CHECK (
        discov_date BETWEEN DATE '1992-01-01' AND CURRENT_DATE
    ),
    last_obs_date DATE NOT NULL CHECK (
        last_obs_date BETWEEN discov_date AND CURRENT_DATE
    ),
    sys_id        VARCHAR(30) NOT NULL
        REFERENCES plan_system(system_id) ON DELETE CASCADE
);

CREATE TABLE telescope (
    tele_id VARCHAR(47) PRIMARY KEY,
    tele_type tele_type_enum NOT NULL,
    aper DECIMAL(6,2) NOT NULL CHECK (aper > 0),
    com_year INT NOT NULL CHECK (
        com_year BETWEEN 1609 AND EXTRACT(YEAR FROM CURRENT_DATE)::INT
    ),
    oper VARCHAR(81) NOT NULL,
    discov_plan INT NOT NULL CHECK (discov_plan >= 0)
);

CREATE TABLE observer (
    observer_id VARCHAR(100) PRIMARY KEY,
    bday        DATE NOT NULL CHECK (
        bday BETWEEN DATE '1609-01-01' AND CURRENT_DATE
    ),
    country     country_enum NOT NULL,
    discovs     INT NOT NULL CHECK (discovs >= 0)
);

CREATE TABLE observation (
    observation_id VARCHAR(30) PRIMARY KEY,
    exo_id         VARCHAR(30) NOT NULL
        REFERENCES exoplanet(exo_id) ON DELETE CASCADE,
    tele_id        VARCHAR(47) NOT NULL
        REFERENCES telescope(tele_id) ON DELETE CASCADE,
    observer_id    VARCHAR(100) NOT NULL
        REFERENCES observer(observer_id) ON DELETE CASCADE,
    obs_date       DATE NOT NULL CHECK (
        obs_date BETWEEN DATE '1992-01-01' AND CURRENT_DATE
    ),
    CONSTRAINT observation_unique_event
        UNIQUE (exo_id, tele_id, observer_id, obs_date)
);
