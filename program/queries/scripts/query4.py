# 4.1. Найти страны, из которых наблюдалось максимальное число экзопланет.
# 4.2. Найти страны, из которых наблюдалось минимальное число экзопланет.

import argparse
import csv
from getpass import getpass
from pathlib import Path

import psycopg2


QUERY = """
WITH country_counts AS (
    SELECT
        obs.country::text AS country,
        COUNT(DISTINCT o.exo_id) AS exoplanets_count
    FROM observer obs
    JOIN observation o
        ON o.observer_id = obs.observer_id
    GROUP BY obs.country
),
ranked AS (
    SELECT
        country,
        exoplanets_count,
        MAX(exoplanets_count) OVER () AS max_count,
        MIN(exoplanets_count) OVER () AS min_count
    FROM country_counts
)
SELECT
    'max' AS result_type,
    country,
    exoplanets_count
FROM ranked
WHERE exoplanets_count = max_count

UNION ALL

SELECT
    'min' AS result_type,
    country,
    exoplanets_count
FROM ranked
WHERE exoplanets_count = min_count
ORDER BY result_type, country;
"""


def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Find countries with the maximum and minimum number of distinct "
            "observed exoplanets."
        )
    )
    parser.add_argument("--dbname", default="mydb")
    parser.add_argument("--user", default="postgres")
    parser.add_argument("--host", default=None)
    parser.add_argument("--port", default=None)
    parser.add_argument("--ask-password", action="store_true")
    return parser.parse_args()


def connect(args):
    params = {
        "dbname": args.dbname,
        "user": args.user,
    }

    if args.host:
        params["host"] = args.host
    if args.port:
        params["port"] = args.port
    if args.ask_password:
        params["password"] = getpass("PostgreSQL password: ")

    return psycopg2.connect(**params)


def save_csv(path, headers, rows):
    path.parent.mkdir(parents=True, exist_ok=True)

    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(headers)
        writer.writerows(rows)


def main():
    args = parse_args()
    output_path = Path(__file__).resolve().parent.parent / "results" / "query4.csv"

    with connect(args) as conn:
        with conn.cursor() as cur:
            cur.execute(QUERY)
            rows = cur.fetchall()
            headers = [column[0] for column in cur.description]

    save_csv(output_path, headers, rows)

    print(f"Saved {len(rows)} rows to {output_path}")


if __name__ == "__main__":
    main()
