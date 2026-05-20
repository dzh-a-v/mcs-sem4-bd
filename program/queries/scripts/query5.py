# Посчитать число экзопланет с равным числом наблюдений,
# построить 2D-гистограмму.

import argparse
import csv
from getpass import getpass
from pathlib import Path

import psycopg2


QUERY = """
WITH exoplanet_observations AS (
    SELECT
        e.exo_id,
        COUNT(o.observation_id) AS observations_count
    FROM exoplanet e
    LEFT JOIN observation o
        ON o.exo_id = e.exo_id
    GROUP BY e.exo_id
)
SELECT
    observations_count,
    COUNT(*) AS exoplanets_count
FROM exoplanet_observations
GROUP BY observations_count
ORDER BY observations_count;
"""


def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Count how many exoplanets have the same number of observations."
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
    output_path = Path(__file__).resolve().parent.parent / "results" / "query5.csv"

    with connect(args) as conn:
        with conn.cursor() as cur:
            cur.execute(QUERY)
            rows = cur.fetchall()
            headers = [column[0] for column in cur.description]

    save_csv(output_path, headers, rows)

    print(f"Saved {len(rows)} rows to {output_path}")


if __name__ == "__main__":
    main()
