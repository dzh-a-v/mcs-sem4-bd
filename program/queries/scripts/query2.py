import argparse
import csv
from getpass import getpass
from pathlib import Path

import psycopg2


QUERY = """
SELECT
    o.observer_id,
    t.tele_type::text AS tele_type,
    COUNT(DISTINCT s.star_id) AS stars_count
FROM observation o
JOIN telescope t
    ON t.tele_id = o.tele_id
JOIN exoplanet e
    ON e.exo_id = o.exo_id
JOIN plan_system ps
    ON ps.system_id = e.sys_id
JOIN star s
    ON s.sys_id = ps.system_id
WHERE o.observer_id = %s
  AND t.tele_type = %s::tele_type_enum
GROUP BY o.observer_id, t.tele_type;
"""


def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Count stars observed by an observer through telescopes "
            "of a selected type."
        )
    )
    parser.add_argument("--dbname", default="mydb")
    parser.add_argument("--user", default="postgres")
    parser.add_argument("--host", default=None)
    parser.add_argument("--port", default=None)
    parser.add_argument("--ask-password", action="store_true")
    parser.add_argument("--observer", default="Observer_000001")
    parser.add_argument("--tele-type", default="ground")
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


def save_rows(path, headers, rows):
    path.parent.mkdir(parents=True, exist_ok=True)

    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(headers)
        writer.writerows(rows)


def main():
    args = parse_args()
    output_path = Path(__file__).resolve().parent.parent / "results" / "query2.csv"

    with connect(args) as conn:
        with conn.cursor() as cur:
            cur.execute(QUERY, (args.observer, args.tele_type))
            rows = cur.fetchall()
            headers = [column[0] for column in cur.description]

    if not rows:
        rows = [(args.observer, args.tele_type, 0)]

    save_rows(output_path, headers, rows)

    print(f"Saved {len(rows)} rows to {output_path}")


if __name__ == "__main__":
    main()
