# Для каждого телескопа и для каждой страны посчитать число наблюдений.
# Построить 3D-гистограмму.
# Данный Python-скрипт сохраняет данные в CSV; интерактивная гистограмма
# строится отдельным R-скриптом query8_histogram.R.

import argparse
import csv
from getpass import getpass
from pathlib import Path

import psycopg2


QUERY = """
WITH observed_counts AS MATERIALIZED (
    SELECT
        o.tele_id,
        obs.country,
        COUNT(*) AS observations_count
    FROM observation o
    JOIN observer obs
        ON obs.observer_id = o.observer_id
    GROUP BY o.tele_id, obs.country
)
SELECT
    t.tele_id,
    t.tele_type::text AS tele_type,
    t.oper,
    countries.country::text AS country,
    COALESCE(oc.observations_count, 0) AS observations_count
FROM telescope t
CROSS JOIN unnest(enum_range(NULL::country_enum)) AS countries(country)
LEFT JOIN observed_counts oc
    ON oc.tele_id = t.tele_id
   AND oc.country = countries.country
ORDER BY observations_count DESC, t.tele_id, country;
"""


def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Count observations for every telescope and observer country pair."
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
    output_path = Path(__file__).resolve().parent.parent / "results" / "query8.csv"

    with connect(args) as conn:
        with conn.cursor() as cur:
            cur.execute(QUERY)
            rows = cur.fetchall()
            headers = [column[0] for column in cur.description]

    save_csv(output_path, headers, rows)

    print(f"Saved {len(rows)} rows to {output_path}")


if __name__ == "__main__":
    main()
