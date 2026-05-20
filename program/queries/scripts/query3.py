import argparse
import csv
from getpass import getpass
from pathlib import Path

import psycopg2


QUERY = """
SELECT
    s.class::text AS star_class,
    COUNT(DISTINCT s.star_id) AS stars_count,
    COUNT(DISTINCT o.observation_id) AS observations_count
FROM star s
LEFT JOIN plan_system ps
    ON ps.system_id = s.sys_id
LEFT JOIN exoplanet e
    ON e.sys_id = ps.system_id
LEFT JOIN observation o
    ON o.exo_id = e.exo_id
GROUP BY s.class
ORDER BY s.class;
"""


def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Count stars and observations for each star class, then save "
            "the table to CSV."
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
    results_dir = Path(__file__).resolve().parent.parent / "results"
    csv_path = results_dir / "query3.csv"

    with connect(args) as conn:
        with conn.cursor() as cur:
            cur.execute(QUERY)
            rows = cur.fetchall()
            headers = [column[0] for column in cur.description]

    save_csv(csv_path, headers, rows)

    print(f"Saved {len(rows)} rows to {csv_path}")


if __name__ == "__main__":
    main()
