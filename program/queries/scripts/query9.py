# Для всех наблюдений через телескоп TELE_00056, в которых наблюдается
# экзопланета EXO_021009, поменять наблюдателя на Observer_000001.

import argparse
import csv
from getpass import getpass
from pathlib import Path

import psycopg2


QUERY = """
WITH rows_to_update AS (
    SELECT
        o.observation_id,
        o.observer_id AS old_observer_id
    FROM observation o
    WHERE o.tele_id = %s
      AND o.exo_id = %s
      AND o.observer_id <> %s
      AND NOT EXISTS (
          SELECT 1
          FROM observation duplicate
          WHERE duplicate.exo_id = o.exo_id
            AND duplicate.tele_id = o.tele_id
            AND duplicate.observer_id = %s
            AND duplicate.obs_date = o.obs_date
      )
)
UPDATE observation o
SET observer_id = %s
FROM rows_to_update old
WHERE o.observation_id = old.observation_id
RETURNING
    o.observation_id,
    o.exo_id,
    o.tele_id,
    old.old_observer_id,
    o.observer_id AS new_observer_id,
    o.obs_date;
"""


def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Change the observer for observations of a selected exoplanet "
            "through a selected telescope."
        )
    )
    parser.add_argument("--dbname", default="mydb")
    parser.add_argument("--user", default="postgres")
    parser.add_argument("--host", default=None)
    parser.add_argument("--port", default=None)
    parser.add_argument("--ask-password", action="store_true")
    parser.add_argument("--tele-id", default="TELE_00056")
    parser.add_argument("--exo-id", default="EXO_021009")
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
    output_path = Path(__file__).resolve().parent.parent / "results" / "query9.csv"

    query_params = (
        args.tele_id,
        args.exo_id,
        args.observer,
        args.observer,
        args.observer,
    )

    with connect(args) as conn:
        with conn.cursor() as cur:
            cur.execute(QUERY, query_params)
            rows = cur.fetchall()
            headers = [column[0] for column in cur.description]

    save_csv(output_path, headers, rows)

    print(f"Updated {len(rows)} rows and saved result to {output_path}")


if __name__ == "__main__":
    main()
