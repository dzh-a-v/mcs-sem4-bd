# Exoplanet Catalog — PostgreSQL Database

Coursework project: a PostgreSQL database describing galaxies, clusters,
stellar systems, planetary systems, stars, exoplanets, telescopes, observers,
and observations.

## Files

- `schema.sql` — creates enum types, tables, primary keys, foreign keys, and
  CHECK constraints. Does not insert data.
- `seed.sql` — procedural data generator (PL/pgSQL `DO` block). Truncates the
  tables and fills them with a self-consistent random dataset.
- `queries.sql` — a library of standard analytical queries (the same ones
  documented in §3 below). Run with
  `psql -U postgres -d exoplanet_coursework -f program/queries.sql`.

---

## 1. Launching the database

### 1.1. Create the database (one time)

```bash
createdb exoplanet_coursework
```

### 1.2. Apply the schema

```bash
psql -d exoplanet_coursework -f program/schema.sql
```

This creates all tables and enum types. It is idempotent only on a fresh
database — re-running it on an existing one will fail because the types/tables
already exist. To start over:

```bash
dropdb exoplanet_coursework && createdb exoplanet_coursework
psql -d exoplanet_coursework -f program/schema.sql
```

### 1.3. Generate the data

```bash
psql -d exoplanet_coursework -f program/seed.sql
```

`seed.sql` begins with `TRUNCATE ... RESTART IDENTITY CASCADE`, so it can be
re-run safely on the same database — every run produces a fresh random dataset.

After the run finishes you will see a summary of row counts per table printed
by the final `SELECT`.

---

## 2. Controlling the dataset size

All knobs live at the top of the `DO $$ ... $$` block in `seed.sql`, in the
`DECLARE` section. Edit the numbers, save the file, and re-run
`psql -d exoplanet_coursework -f program/seed.sql`.

| Variable                  | Meaning                                              | Default |
|---------------------------|------------------------------------------------------|---------|
| `n_galaxies`              | Number of galaxies                                    | `5`     |
| `clusters_per_galaxy`     | Clusters inside each galaxy                           | `3`     |
| `systems_per_cluster`     | Stellar systems inside each cluster                   | `4`     |
| `plansys_per_stellar`     | Planetary systems inside each stellar system          | `2`     |
| `stars_per_plansys_min`   | Minimum stars per planetary system                    | `1`     |
| `stars_per_plansys_max`   | Maximum stars per planetary system                    | `3`     |
| `exos_per_plansys_min`    | Minimum exoplanets per planetary system               | `1`     |
| `exos_per_plansys_max`    | Maximum exoplanets per planetary system               | `5`     |
| `n_telescopes`            | Number of telescopes                                  | `15`    |
| `n_observers`             | Number of observers                                   | `30`    |
| `n_observations`          | Number of observations to attempt to insert           | `200`   |

### How counts multiply

With the defaults you get:

- galaxies: `n_galaxies` = **5**
- clusters: `n_galaxies * clusters_per_galaxy` = **15**
- stellar systems: `15 * systems_per_cluster` = **60**
- planetary systems: `60 * plansys_per_stellar` = **120**
- stars: `120 * avg(stars_per_plansys_min..max)` ≈ **240**
- exoplanets: `120 * avg(exos_per_plansys_min..max)` ≈ **360**
- telescopes / observers / observations: the literal values above

### Examples

**Tiny dataset (smoke test):**

```sql
n_galaxies            := 1;
clusters_per_galaxy   := 1;
systems_per_cluster   := 1;
plansys_per_stellar   := 1;
n_telescopes          := 2;
n_observers           := 3;
n_observations        := 5;
```

**Large dataset (~10 000 exoplanets):**

```sql
n_galaxies            := 20;
clusters_per_galaxy   := 10;
systems_per_cluster   := 10;
plansys_per_stellar   := 5;
exos_per_plansys_min  := 3;
exos_per_plansys_max  := 7;
n_telescopes          := 100;
n_observers           := 500;
n_observations        := 50000;
```

### Constraints to keep in mind

The schema enforces these rules; the generator already respects them, but if
you tweak the formulas keep them in mind:

- `cluster.stars_count >= 10`
- `stellar_system.stars_count >= 1`
- `plan_system.conf_plan >= 1`
- `hab_plan <= conf_plan` everywhere
- `discov_date BETWEEN 1992-01-01 AND CURRENT_DATE`
- `last_obs_date BETWEEN discov_date AND CURRENT_DATE`
- `telescope.com_year BETWEEN 1609 AND CURRENT_YEAR`

---

## 3. Querying the database

This section is both a manual (how to use psql) and a library of standard
analytical queries (what to ask). Every query in §3.5–§3.13 is also available
in `queries.sql`, which you can run as a single batch.

### 3.1. Open a psql shell

```bash
psql -U postgres -d exoplanet_coursework
```

The prompt should change from your shell to `exoplanet_coursework=#`. That is
how you confirm you are connected to the right database.

### 3.2. psql meta-commands cheat sheet

These are commands of the psql client itself (they all start with `\`), not
SQL. You type them at the `exoplanet_coursework=#` prompt.

| Command            | Effect                                                 |
|--------------------|--------------------------------------------------------|
| `\dt`              | List all tables                                         |
| `\d galaxy`        | Describe one table (columns, types, constraints, FKs)   |
| `\d+ galaxy`       | Same, plus storage / extra metadata                     |
| `\dT+`             | List custom types (the enums in this schema)            |
| `\df`              | List user-defined functions                             |
| `\di`              | List indexes                                            |
| `\x`               | Toggle expanded output (one column per line, useful for wide rows) |
| `\x auto`          | Auto-expand only when output is too wide                |
| `\timing`          | Toggle "show how long each query took"                  |
| `\pset null '<NULL>'` | Print NULLs as `<NULL>` instead of empty space      |
| `\e`               | Open the last query in your `$EDITOR`, then run it      |
| `\i path/to.sql`   | Run a SQL file                                          |
| `\copy ... TO ...` | Export query results to a local file                    |
| `\watch 5`         | Re-run the last query every 5 seconds                   |
| `\?`               | List **all** psql meta-commands                         |
| `\h CREATE TABLE`  | SQL reference for any statement                         |
| `\q`               | Quit                                                    |

### 3.3. Three ways to run a query

**A. Interactively** — open psql and type SQL ending in `;`:

```bash
psql -U postgres -d exoplanet_coursework
```
```sql
SELECT COUNT(*) FROM exoplanet;
```

**B. One-off from the shell** — useful for scripting:

```bash
psql -U postgres -d exoplanet_coursework -c "SELECT COUNT(*) FROM exoplanet;"
```

**C. From a SQL file** — for query libraries like `queries.sql`:

```bash
psql -U postgres -d exoplanet_coursework -f program/queries.sql
```

### 3.4. Running the standard query library

```bash
psql -U postgres -d exoplanet_coursework -f program/queries.sql
```

This runs every query in §3.5–§3.13 in order, prints each result, and exits.
For more readable output, prefix with `\timing` or use `\pset` settings inside
`queries.sql`.

---

### 3.5. Inventory queries (basic counts)

**Q1. Row counts across the whole database:**

```sql
SELECT 'galaxy'         AS table, COUNT(*) FROM galaxy
UNION ALL SELECT 'cluster',        COUNT(*) FROM cluster
UNION ALL SELECT 'stellar_system', COUNT(*) FROM stellar_system
UNION ALL SELECT 'plan_system',    COUNT(*) FROM plan_system
UNION ALL SELECT 'star',           COUNT(*) FROM star
UNION ALL SELECT 'exoplanet',      COUNT(*) FROM exoplanet
UNION ALL SELECT 'telescope',      COUNT(*) FROM telescope
UNION ALL SELECT 'observer',       COUNT(*) FROM observer
UNION ALL SELECT 'observation',    COUNT(*) FROM observation;
```

**Q2. Distribution of exoplanet types:**

```sql
SELECT exo_type,
       COUNT(*)                                      AS n_planets,
       ROUND(AVG(mass)::numeric, 2)                  AS avg_mass,
       ROUND(AVG(radius)::numeric, 2)                AS avg_radius
FROM exoplanet
GROUP BY exo_type
ORDER BY n_planets DESC;
```

**Q3. Distribution of star spectral classes:**

```sql
SELECT class,
       COUNT(*)                          AS n_stars,
       ROUND(AVG(temp)::numeric, 0)      AS avg_temp_k,
       ROUND(AVG(mass)::numeric, 2)      AS avg_mass
FROM star
GROUP BY class
ORDER BY n_stars DESC;
```

---

### 3.6. Distance / proximity queries

**Q4. Top 10 closest exoplanets:**

```sql
SELECT exo_id, exo_type, dist, discov_date
FROM exoplanet
ORDER BY dist ASC
LIMIT 10;
```

**Q5. Top 10 closest galaxies and their habitability statistics:**

```sql
SELECT galaxy_id, dist, conf_plan, hab_plan
FROM galaxy
ORDER BY dist ASC
LIMIT 10;
```

**Q6. Distance histogram of exoplanets (10 bands):**

```sql
SELECT width_bucket(dist, 0, 1000, 10) AS band,
       COUNT(*)                         AS n_planets,
       MIN(dist)                        AS min_dist,
       MAX(dist)                        AS max_dist
FROM exoplanet
GROUP BY band
ORDER BY band;
```

---

### 3.7. Habitability queries

**Q7. Habitable-planet ratio per galaxy:**

```sql
SELECT galaxy_id,
       conf_plan,
       hab_plan,
       ROUND(100.0 * hab_plan / NULLIF(conf_plan, 0), 2) AS hab_pct
FROM galaxy
ORDER BY hab_pct DESC NULLS LAST;
```

**Q8. Top 10 most-habitable clusters:**

```sql
SELECT c.cluster_id,
       c.galaxy_id,
       c.conf_plan,
       c.hab_plan,
       ROUND(100.0 * c.hab_plan / NULLIF(c.conf_plan, 0), 2) AS hab_pct
FROM cluster c
WHERE c.conf_plan > 0
ORDER BY hab_pct DESC, c.hab_plan DESC
LIMIT 10;
```

**Q9. Planetary systems with ALL planets potentially habitable:**

```sql
SELECT system_id, conf_plan, hab_plan
FROM plan_system
WHERE conf_plan = hab_plan
ORDER BY conf_plan DESC;
```

---

### 3.8. Hierarchy traversal (joins)

**Q10. Trace each exoplanet up to its galaxy:**

```sql
SELECT g.galaxy_id,
       c.cluster_id,
       ss.stellar_id,
       ps.system_id,
       e.exo_id,
       e.exo_type
FROM galaxy g
JOIN cluster        c  ON c.galaxy_id     = g.galaxy_id
JOIN stellar_system ss ON ss.cluster_id   = c.cluster_id
JOIN plan_system    ps ON ps.stell_sys_id = ss.stellar_id
JOIN exoplanet      e  ON e.sys_id        = ps.system_id
ORDER BY g.galaxy_id, c.cluster_id, ss.stellar_id, ps.system_id, e.exo_id
LIMIT 20;
```

**Q11. Number of exoplanets per galaxy (computed via joins, not the cached counter):**

```sql
SELECT g.galaxy_id, COUNT(e.exo_id) AS planets_in_galaxy
FROM galaxy g
LEFT JOIN cluster        c  ON c.galaxy_id     = g.galaxy_id
LEFT JOIN stellar_system ss ON ss.cluster_id   = c.cluster_id
LEFT JOIN plan_system    ps ON ps.stell_sys_id = ss.stellar_id
LEFT JOIN exoplanet      e  ON e.sys_id        = ps.system_id
GROUP BY g.galaxy_id
ORDER BY planets_in_galaxy DESC;
```

**Q12. Verify that cached `conf_plan` matches the actual exoplanet count
(integrity check):**

```sql
SELECT g.galaxy_id,
       g.conf_plan          AS stored,
       COUNT(e.exo_id)      AS actual,
       g.conf_plan - COUNT(e.exo_id) AS diff
FROM galaxy g
LEFT JOIN cluster        c  ON c.galaxy_id     = g.galaxy_id
LEFT JOIN stellar_system ss ON ss.cluster_id   = c.cluster_id
LEFT JOIN plan_system    ps ON ps.stell_sys_id = ss.stellar_id
LEFT JOIN exoplanet      e  ON e.sys_id        = ps.system_id
GROUP BY g.galaxy_id, g.conf_plan
ORDER BY g.galaxy_id;
```

---

### 3.9. Telescope and observation queries

**Q13. Most productive telescopes (by observations made):**

```sql
SELECT t.tele_id,
       t.tele_type,
       t.oper,
       t.aper,
       COUNT(o.observation_id) AS observations
FROM telescope t
LEFT JOIN observation o ON o.tele_id = t.tele_id
GROUP BY t.tele_id, t.tele_type, t.oper, t.aper
ORDER BY observations DESC
LIMIT 10;
```

**Q14. Space vs. ground telescopes — comparative summary:**

```sql
SELECT tele_type,
       COUNT(*)                          AS n_telescopes,
       ROUND(AVG(aper)::numeric, 2)      AS avg_aperture,
       SUM(discov_plan)                  AS total_discoveries
FROM telescope
GROUP BY tele_type;
```

**Q15. Most-observed exoplanets:**

```sql
SELECT e.exo_id,
       e.exo_type,
       COUNT(o.observation_id) AS times_observed
FROM exoplanet e
LEFT JOIN observation o ON o.exo_id = e.exo_id
GROUP BY e.exo_id, e.exo_type
ORDER BY times_observed DESC
LIMIT 10;
```

**Q16. Observations per year:**

```sql
SELECT EXTRACT(YEAR FROM obs_date)::INT AS year,
       COUNT(*)                          AS n_observations
FROM observation
GROUP BY year
ORDER BY year;
```

---

### 3.10. Observer queries

**Q17. Observers by country (people and total discoveries):**

```sql
SELECT country,
       COUNT(*)        AS people,
       SUM(discovs)    AS total_discoveries
FROM observer
GROUP BY country
ORDER BY total_discoveries DESC;
```

**Q18. Top 10 individual observers by personal discoveries:**

```sql
SELECT observer_id, country, discovs, bday
FROM observer
ORDER BY discovs DESC
LIMIT 10;
```

**Q19. Observers active in the last 5 years:**

```sql
SELECT DISTINCT o.observer_id, o.country, o.discovs
FROM observer  o
JOIN observation obs ON obs.observer_id = o.observer_id
WHERE obs.obs_date >= CURRENT_DATE - INTERVAL '5 years'
ORDER BY o.discovs DESC;
```

---

### 3.11. Star physics queries

**Q20. Stars hotter than the Sun (≈5778 K):**

```sql
SELECT star_id, class, temp, mass, radius
FROM star
WHERE temp > 5778
ORDER BY temp DESC
LIMIT 20;
```

**Q21. Most massive stars per spectral class:**

```sql
SELECT DISTINCT ON (class)
       class, star_id, mass, radius, temp
FROM star
ORDER BY class, mass DESC;
```

**Q22. Average star properties grouped by spectral class:**

```sql
SELECT class,
       COUNT(*)                              AS n,
       ROUND(AVG(mass)::numeric, 2)          AS avg_mass,
       ROUND(AVG(radius)::numeric, 2)        AS avg_radius,
       ROUND(AVG(temp)::numeric, 0)          AS avg_temp_k
FROM star
GROUP BY class
ORDER BY avg_temp_k DESC;
```

---

### 3.12. Discovery-timeline queries

**Q23. Exoplanet discoveries per year:**

```sql
SELECT EXTRACT(YEAR FROM discov_date)::INT AS year,
       COUNT(*) AS discovered
FROM exoplanet
GROUP BY year
ORDER BY year;
```

**Q24. Cumulative exoplanet discoveries over time:**

```sql
SELECT year, discovered,
       SUM(discovered) OVER (ORDER BY year) AS cumulative
FROM (
    SELECT EXTRACT(YEAR FROM discov_date)::INT AS year,
           COUNT(*) AS discovered
    FROM exoplanet
    GROUP BY year
) t
ORDER BY year;
```

**Q25. Exoplanets discovered but not observed since their discovery date:**

```sql
SELECT e.exo_id, e.discov_date, e.last_obs_date,
       (e.last_obs_date - e.discov_date) AS days_after_discovery
FROM exoplanet e
WHERE e.last_obs_date - e.discov_date < 30
ORDER BY days_after_discovery, e.discov_date;
```

---

### 3.13. Window functions and rankings

**Q26. Rank exoplanets within each system by mass:**

```sql
SELECT sys_id, exo_id, exo_type, mass,
       RANK() OVER (PARTITION BY sys_id ORDER BY mass DESC) AS mass_rank
FROM exoplanet
ORDER BY sys_id, mass_rank;
```

**Q27. For each galaxy, the closest cluster:**

```sql
SELECT galaxy_id, cluster_id, dist
FROM (
    SELECT c.galaxy_id, c.cluster_id, c.dist,
           ROW_NUMBER() OVER (PARTITION BY c.galaxy_id ORDER BY c.dist ASC) AS rn
    FROM cluster c
) ranked
WHERE rn = 1
ORDER BY galaxy_id;
```

**Q28. Exoplanets above the average mass of their type:**

```sql
SELECT exo_id, exo_type, mass, avg_mass
FROM (
    SELECT exo_id, exo_type, mass,
           ROUND(AVG(mass) OVER (PARTITION BY exo_type)::numeric, 2) AS avg_mass
    FROM exoplanet
) t
WHERE mass > avg_mass
ORDER BY exo_type, mass DESC;
```

---

### 3.14. Exporting results

From inside a psql session, use `\copy` (it writes a file on **your** computer,
not on the server):

```sql
\copy (SELECT * FROM exoplanet) TO 'C:/Users/dzhav/exoplanets.csv' CSV HEADER
\copy (SELECT * FROM observation) TO 'C:/Users/dzhav/observations.csv' CSV HEADER
```

From the shell:

```bash
psql -U postgres -d exoplanet_coursework ^
     -c "\copy (SELECT * FROM exoplanet) TO 'C:/Users/dzhav/exoplanets.csv' CSV HEADER"
```

(The `^` is the Windows command-line line continuation; on Linux/macOS use `\`.)

---

## 4. Troubleshooting

- **`type "xxx_enum" already exists`** when re-running `schema.sql` — drop and
  recreate the database (see §1.2).
- **`new row violates check constraint`** in `seed.sql` — usually means you
  edited the tunables and made `conf_plan` smaller than `hab_plan`, or set a
  per-cluster star count below 10. Restore the defaults or relax your edit.
- **Slow `seed.sql`** at large scales — most of the time is spent in
  `ORDER BY random() LIMIT 1` for observations. For very large runs, lower
  `n_observations` or rewrite that block to use `OFFSET floor(random() * N)`.
