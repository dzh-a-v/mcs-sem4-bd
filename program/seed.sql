-- seed.sql
-- Procedural data generator for the exoplanet database described in schema.sql.
--
-- Filling levels (top-down):
--   1. tele_type, country, star_class, exo_type (ENUMs from schema), galaxy
--   2. telescope, observer, cluster
--   3. stellar_system
--   4. plan_system
--   5. star, exoplanet
--   6. observation
--
-- Aggregate counters (conf_plan / hab_plan / stars_count) cannot be known at
-- the moment a parent is inserted (its children do not exist yet). Each level
-- inserts parents with placeholder counters that satisfy the CHECK constraints,
-- and after the children of a level are generated we UPDATE the parents with
-- the real aggregated values.

-- ========================================================================
-- CLEAN UP (so the script is re-runnable)
-- ========================================================================
TRUNCATE TABLE
    observation, observer, telescope,
    exoplanet, star,
    plan_system, stellar_system, cluster, galaxy
RESTART IDENTITY CASCADE;

-- ========================================================================
-- MAIN GENERATOR
-- ========================================================================
DO $$
DECLARE
    -- Tunables: change these to scale the dataset.
    n_galaxies            INT := 5;
    clusters_per_galaxy   INT := 3;
    systems_per_cluster   INT := 4;       -- stellar systems per cluster
    plansys_per_stellar   INT := 2;       -- planetary systems per stellar system
    stars_per_plansys_min INT := 1;
    stars_per_plansys_max INT := 3;
    exos_per_plansys_min  INT := 1;
    exos_per_plansys_max  INT := 5;
    n_telescopes          INT := 15;
    n_observers           INT := 30;
    n_observations        INT := 200;

    -- Loop variables
    g_i INT; c_i INT; s_i INT; p_i INT; k INT;

    -- IDs
    g_id  VARCHAR(30);
    c_id  VARCHAR(30);
    s_id  VARCHAR(30);
    p_id  VARCHAR(30);
    st_id VARCHAR(30);
    ex_id VARCHAR(30);
    t_id  VARCHAR(47);
    o_id  VARCHAR(100);
    obs_id VARCHAR(30);

    -- Distances
    g_dist  DECIMAL(12,6);
    c_dist  DECIMAL(12,6);
    ss_dist DECIMAL(12,6);
    ps_dist DECIMAL(12,6);

    n_stars INT;
    n_exos  INT;

    p_conf INT; p_hab INT;

    discov DATE;
    last_obs DATE;

    star_classes TEXT[] := ARRAY['O','B','A','F','G','K','M','W','L','D'];
    exo_types    TEXT[] := ARRAY['gas_giant','neptunian','superearth','terrestrial'];
    tele_types   TEXT[] := ARRAY['space','ground'];
    countries    TEXT[] := ARRAY[
        'United States','Russia','China','Germany','France','United Kingdom',
        'Japan','Canada','Australia','Italy','Spain','Brazil','India',
        'Netherlands','Sweden','Switzerland','Poland','Mexico','South Korea',
        'Argentina','Chile','South Africa','Norway','Finland','Belgium'
    ];
    operators TEXT[] := ARRAY[
        'NASA','ESA','Roscosmos','JAXA','CNSA','ISRO','CSA',
        'ESO','NAOJ','Caltech','MIT','Harvard-Smithsonian',
        'Max Planck Institute','SETI Institute','Las Cumbres Observatory'
    ];

    rand_class TEXT;
    rand_exo   TEXT;
    rand_tele  TEXT;

BEGIN
    -- =====================================================================
    -- LEVEL 1: ENUM types (tele_type, country, star_class, exo_type) are
    -- already defined in schema.sql. At this level we only insert GALAXIES.
    -- IDs must fit VARCHAR(30). Leaf IDs (star/exoplanet) include all
    -- ancestor levels, so prefixes are kept short:
    --   galaxy:   G{4}                    -> 5
    --   cluster:  G{4}C{3}                -> 8
    --   stellar:  G{4}C{3}S{3}            -> 11
    --   plansys:  G{4}C{3}S{3}P{3}        -> 14
    --   star:     G{4}C{3}S{3}P{3}T{02}   -> 17  (T = sTar)
    --   exo:      G{4}C{3}S{3}P{3}E{02}   -> 17
    -- Counters are inserted as 0 placeholders and updated at the end.
    -- =====================================================================
    FOR g_i IN 1..n_galaxies LOOP
        g_id   := 'G' || lpad(g_i::text, 4, '0');
        -- galaxy.dist is DECIMAL(12,6) -> abs value must be < 10^6
        g_dist := round((random() * 900000 + 1000)::numeric, 6);  -- ly

        INSERT INTO galaxy(galaxy_id, conf_plan, hab_plan, dist)
        VALUES (g_id, 0, 0, g_dist);
    END LOOP;

    -- =====================================================================
    -- LEVEL 2: TELESCOPES, OBSERVERS, CLUSTERS
    -- Cluster.stars_count must be >= 10; we insert with placeholder = 10
    -- and UPDATE later once the real star count is known.
    -- =====================================================================

    -- ---- TELESCOPES ----
    FOR k IN 1..n_telescopes LOOP
        t_id      := 'TEL-' || lpad(k::text, 5, '0');
        rand_tele := tele_types[1 + floor(random() * array_length(tele_types,1))::INT];
        INSERT INTO telescope(tele_id, tele_type, aper, com_year, oper, discov_plan)
        VALUES (
            t_id,
            rand_tele::tele_type_enum,
            round((random() * 1000 + 1)::numeric, 2),
            1609 + floor(random() * (EXTRACT(YEAR FROM CURRENT_DATE)::INT - 1609 + 1))::INT,
            operators[1 + floor(random() * array_length(operators,1))::INT],
            floor(random() * 5000)::INT
        );
    END LOOP;

    -- ---- OBSERVERS ----
    FOR k IN 1..n_observers LOOP
        o_id := 'OBS-' || lpad(k::text, 5, '0');
        INSERT INTO observer(observer_id, bday, country, discovs)
        VALUES (
            o_id,
            DATE '1940-01-01'
                + (floor(random() *
                         (DATE '2005-12-31' - DATE '1940-01-01')))::INT,
            countries[1 + floor(random() * array_length(countries,1))::INT]::country_enum,
            floor(random() * 200)::INT
        );
    END LOOP;

    -- ---- CLUSTERS ----
    FOR g_i IN 1..n_galaxies LOOP
        g_id := 'G' || lpad(g_i::text, 4, '0');
        FOR c_i IN 1..clusters_per_galaxy LOOP
            c_id   := g_id || 'C' || lpad(c_i::text, 3, '0');
            -- cluster.dist is DECIMAL(12,6) -> abs value must be < 10^6
            c_dist := round((random() * 500000 + 100)::numeric, 6);

            INSERT INTO cluster(cluster_id, stars_count, conf_plan, hab_plan, dist, galaxy_id)
            VALUES (c_id, 10, 0, 0, c_dist, g_id);  -- temp stars_count=10 (min)
        END LOOP;
    END LOOP;

    -- =====================================================================
    -- LEVEL 3: STELLAR SYSTEMS
    -- stellar_system.stars_count must be >= 1; placeholder = 1.
    -- =====================================================================
    FOR g_i IN 1..n_galaxies LOOP
        g_id := 'G' || lpad(g_i::text, 4, '0');
        FOR c_i IN 1..clusters_per_galaxy LOOP
            c_id := g_id || 'C' || lpad(c_i::text, 3, '0');
            FOR s_i IN 1..systems_per_cluster LOOP
                s_id    := c_id || 'S' || lpad(s_i::text, 3, '0');
                ss_dist := round((random() * 1.0e4 + 1.0)::numeric, 6);

                INSERT INTO stellar_system(stellar_id, stars_count, conf_plan, hab_plan, dist, cluster_id)
                VALUES (s_id, 1, 0, 0, ss_dist, c_id);
            END LOOP;
        END LOOP;
    END LOOP;

    -- =====================================================================
    -- LEVEL 4: PLANETARY SYSTEMS
    -- plan_system.conf_plan must be >= 1, so we pre-decide here how many
    -- exoplanets each plan_system will have (n_exos >= 1) and use that as
    -- the conf_plan immediately. hab_plan is a random subset of conf_plan.
    -- We stash n_exos and n_stars into temporary columns? No -- we simply
    -- recompute them deterministically by storing them via setseed?
    -- Simpler: we recompute by RE-GENERATING n_stars/n_exos at level 5
    -- using the exact same logic. To keep it correct, we record per-system
    -- counts in a temporary table.
    -- =====================================================================
    CREATE TEMP TABLE _tmp_plansys_counts (
        system_id VARCHAR(30) PRIMARY KEY,
        n_stars   INT NOT NULL,
        n_exos    INT NOT NULL
    ) ON COMMIT DROP;

    FOR g_i IN 1..n_galaxies LOOP
        g_id := 'G' || lpad(g_i::text, 4, '0');
        FOR c_i IN 1..clusters_per_galaxy LOOP
            c_id := g_id || 'C' || lpad(c_i::text, 3, '0');
            FOR s_i IN 1..systems_per_cluster LOOP
                s_id := c_id || 'S' || lpad(s_i::text, 3, '0');
                FOR p_i IN 1..plansys_per_stellar LOOP
                    p_id    := s_id || 'P' || lpad(p_i::text, 3, '0');
                    ps_dist := round((random() * 1.0e3 + 1.0)::numeric, 6);

                    n_stars := stars_per_plansys_min
                             + floor(random() * (stars_per_plansys_max - stars_per_plansys_min + 1))::INT;
                    n_exos  := exos_per_plansys_min
                             + floor(random() * (exos_per_plansys_max - exos_per_plansys_min + 1))::INT;

                    p_conf := n_exos;                                  -- >= 1
                    p_hab  := floor(random() * (p_conf + 1))::INT;     -- 0..p_conf

                    INSERT INTO plan_system(system_id, conf_plan, hab_plan, distance, stell_sys_id)
                    VALUES (p_id, p_conf, p_hab, ps_dist, s_id);

                    INSERT INTO _tmp_plansys_counts(system_id, n_stars, n_exos)
                    VALUES (p_id, n_stars, n_exos);
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;

    -- =====================================================================
    -- LEVEL 5: STARS and EXOPLANETS
    -- Iterate through every plan_system and create its stars and exoplanets
    -- using the counts we recorded in _tmp_plansys_counts.
    -- =====================================================================
    FOR p_id, n_stars, n_exos IN
        SELECT system_id, n_stars, n_exos
          FROM _tmp_plansys_counts
          ORDER BY system_id
    LOOP
        -- ---- STARS ----
        FOR k IN 1..n_stars LOOP
            st_id := p_id || 'T' || lpad(k::text, 2, '0');
            rand_class := star_classes[1 + floor(random() * array_length(star_classes,1))::INT];
            INSERT INTO star(star_id, class, mass, radius, temp, dist, sys_id)
            VALUES (
                st_id,
                rand_class::star_class_enum,
                round((random() * 50 + 0.1)::numeric, 2),
                round((random() * 100 + 0.1)::numeric, 4),
                (random() * 49000 + 1000)::INT,
                round((random() * 1000 + 1)::numeric, 6),
                p_id
            );
        END LOOP;

        -- ---- EXOPLANETS ----
        FOR k IN 1..n_exos LOOP
            ex_id := p_id || 'E' || lpad(k::text, 2, '0');
            rand_exo := exo_types[1 + floor(random() * array_length(exo_types,1))::INT];
            discov := DATE '1992-01-01'
                      + (floor(random() *
                               (CURRENT_DATE - DATE '1992-01-01')))::INT;
            last_obs := discov
                      + (floor(random() *
                               GREATEST(1,(CURRENT_DATE - discov))))::INT;
            IF last_obs > CURRENT_DATE THEN
                last_obs := CURRENT_DATE;
            END IF;

            INSERT INTO exoplanet(
                exo_id, mass, radius, orb_period, exo_type,
                dist, discov_date, last_obs_date, sys_id
            )
            VALUES (
                ex_id,
                round((random() * 5000 + 0.01)::numeric, 4),
                round((random() * 30 + 0.05)::numeric, 4),
                round((random() * 10000 + 0.1)::numeric, 4),
                rand_exo::exo_type_enum,
                round((random() * 1000 + 1)::numeric, 6),
                discov,
                last_obs,
                p_id
            );
        END LOOP;
    END LOOP;

    -- ---------------------------------------------------------------------
    -- BACK-FILL aggregated counters (bottom-up) now that all children exist.
    -- ---------------------------------------------------------------------

    -- stellar_system: sum over its plan_systems' conf_plan/hab_plan and count
    -- the actual stars belonging to those plan_systems.
    UPDATE stellar_system ss
       SET stars_count = GREATEST(agg.n_stars, 1),
           conf_plan   = agg.conf_plan,
           hab_plan    = agg.hab_plan
      FROM (
            SELECT ps.stell_sys_id            AS stellar_id,
                   COALESCE(SUM(ps.conf_plan),0) AS conf_plan,
                   COALESCE(SUM(ps.hab_plan), 0) AS hab_plan,
                   COALESCE((SELECT COUNT(*) FROM star s
                              WHERE s.sys_id IN (
                                  SELECT system_id FROM plan_system
                                   WHERE stell_sys_id = ps.stell_sys_id
                              )), 0)            AS n_stars
              FROM plan_system ps
             GROUP BY ps.stell_sys_id
           ) agg
     WHERE ss.stellar_id = agg.stellar_id;

    -- cluster: sum over its stellar_systems.
    UPDATE cluster cl
       SET stars_count = GREATEST(agg.n_stars, 10),
           conf_plan   = agg.conf_plan,
           hab_plan    = agg.hab_plan
      FROM (
            SELECT ss.cluster_id,
                   COALESCE(SUM(ss.stars_count), 0) AS n_stars,
                   COALESCE(SUM(ss.conf_plan),   0) AS conf_plan,
                   COALESCE(SUM(ss.hab_plan),    0) AS hab_plan
              FROM stellar_system ss
             GROUP BY ss.cluster_id
           ) agg
     WHERE cl.cluster_id = agg.cluster_id;

    -- galaxy: sum over its clusters.
    UPDATE galaxy g
       SET conf_plan = agg.conf_plan,
           hab_plan  = agg.hab_plan
      FROM (
            SELECT cl.galaxy_id,
                   COALESCE(SUM(cl.conf_plan), 0) AS conf_plan,
                   COALESCE(SUM(cl.hab_plan),  0) AS hab_plan
              FROM cluster cl
             GROUP BY cl.galaxy_id
           ) agg
     WHERE g.galaxy_id = agg.galaxy_id;

    -- =====================================================================
    -- LEVEL 6: OBSERVATIONS
    -- Pick random existing exoplanet/telescope/observer triples + date.
    -- Use ON CONFLICT DO NOTHING to dodge the UNIQUE(exo_id, tele_id,
    -- observer_id, obs_date) constraint on duplicates.
    -- =====================================================================
    FOR k IN 1..n_observations LOOP
        obs_id := 'OBSV-' || lpad(k::text, 6, '0');

        INSERT INTO observation(observation_id, exo_id, tele_id, observer_id, obs_date)
        SELECT
            obs_id,
            (SELECT exo_id     FROM exoplanet  ORDER BY random() LIMIT 1),
            (SELECT tele_id    FROM telescope  ORDER BY random() LIMIT 1),
            (SELECT observer_id FROM observer  ORDER BY random() LIMIT 1),
            DATE '1992-01-01'
                + (floor(random() *
                         (CURRENT_DATE - DATE '1992-01-01')))::INT
        ON CONFLICT ON CONSTRAINT observation_unique_event DO NOTHING;
    END LOOP;

    RAISE NOTICE 'Seed generation complete.';
END $$;

-- ========================================================================
-- QUICK SUMMARY
-- ========================================================================
SELECT 'galaxy'         AS table, COUNT(*) FROM galaxy
UNION ALL SELECT 'cluster',         COUNT(*) FROM cluster
UNION ALL SELECT 'stellar_system',  COUNT(*) FROM stellar_system
UNION ALL SELECT 'plan_system',     COUNT(*) FROM plan_system
UNION ALL SELECT 'star',            COUNT(*) FROM star
UNION ALL SELECT 'exoplanet',       COUNT(*) FROM exoplanet
UNION ALL SELECT 'telescope',       COUNT(*) FROM telescope
UNION ALL SELECT 'observer',        COUNT(*) FROM observer
UNION ALL SELECT 'observation',     COUNT(*) FROM observation;
