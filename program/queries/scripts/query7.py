import argparse
import csv
from getpass import getpass
from pathlib import Path

import psycopg2


QUERY = """
WITH observer_counts AS (
    SELECT
        obs.observer_id,
        obs.country::text AS country,
        COUNT(DISTINCT o.exo_id) AS exoplanets_count
    FROM observer obs
    LEFT JOIN observation o
        ON o.observer_id = obs.observer_id
    GROUP BY obs.observer_id, obs.country
),
target_observer AS (
    SELECT exoplanets_count
    FROM observer_counts
    WHERE observer_id = %s
)
SELECT
    oc.observer_id,
    oc.country,
    oc.exoplanets_count,
    target_observer.exoplanets_count AS target_exoplanets_count
FROM observer_counts oc
CROSS JOIN target_observer
WHERE oc.observer_id <> %s
  AND oc.exoplanets_count > target_observer.exoplanets_count
ORDER BY oc.exoplanets_count DESC, oc.observer_id;
"""


def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Find observers who observed more distinct exoplanets than "
            "a selected observer."
        )
    )
    parser.add_argument("--dbname", default="mydb")
    parser.add_argument("--user", default="postgres")
    parser.add_argument("--host", default=None)
    parser.add_argument("--port", default=None)
    parser.add_argument("--ask-password", action="store_true")
    parser.add_argument("--observer", default="Observer_000001")
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
    output_path = Path(__file__).resolve().parent.parent / "results" / "query7.csv"

    with connect(args) as conn:
        with conn.cursor() as cur:
            cur.execute(QUERY, (args.observer, args.observer))
            rows = cur.fetchall()
            headers = [column[0] for column in cur.description]

    save_csv(output_path, headers, rows)

    print(f"Saved {len(rows)} rows to {output_path}")


if __name__ == "__main__":
    main()
