# PostgreSQL Schema

Current coursework checkpoint: show the updated table diagram and the SQL schema file.

Main file:

- `schema.sql` creates the `exoplanet_catalog` schema, enum types, domains, tables, primary keys, foreign keys, checks, and indexes.

The schema file does not insert data and does not execute queries.

To create the empty database structure:

```bash
createdb exoplanet_coursework
psql -d exoplanet_coursework -f program/schema.sql
```

Older helper files from the previous stage:

- `seed.sql` inserts a small dataset.
- `generate_large_dataset.sql` inserts a synthetic large dataset.
- `queries.sql` contains example analytical queries.
- `QUERY_GUIDE_EN.md` and `QUERY_GUIDE_RU.md` explain how to query the database.

For the current teacher check, these files are not required. Because `schema.sql`
now follows the updated table diagram with shortened column names, the older
data and query scripts should be updated before running them again.
