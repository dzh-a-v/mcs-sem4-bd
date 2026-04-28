# PostgreSQL Database

This folder contains a PostgreSQL implementation of the coursework database for exoplanet cataloging.

Files:

- `schema.sql` creates the `exoplanet_catalog` schema, all tables, constraints, indexes, and two convenience views.
- `seed.sql` inserts a small readable dataset based on real-looking astronomical objects from the report.
- `generate_large_dataset.sql` inserts a synthetic dataset with `280530` rows in total, which covers the coursework requirement for a database with at least `250000` records.
- `queries.sql` contains example analytical queries you can run after loading either dataset.
- `QUERY_GUIDE_EN.md` and `QUERY_GUIDE_RU.md` explain how to query the database in English and Russian.

Recommended run order:

```bash
createdb exoplanet_coursework
psql -d exoplanet_coursework -f program/schema.sql
psql -d exoplanet_coursework -f program/seed.sql
psql -d exoplanet_coursework -f program/queries.sql
```

If you need the large synthetic dataset instead of the small sample:

```bash
createdb exoplanet_coursework
psql -d exoplanet_coursework -f program/schema.sql
psql -d exoplanet_coursework -f program/generate_large_dataset.sql
psql -d exoplanet_coursework -f program/queries.sql
```

Notes:

- The schema names and table names are kept in lowercase snake_case for PostgreSQL ergonomics.
- The enum value `terrestial` intentionally matches the spelling used in the coursework text.
- The report models the `exoplanet -> star` relation conceptually, while the tables model it through `planetary_system`. The view `v_exoplanet_catalog` resolves that join for convenient querying.
