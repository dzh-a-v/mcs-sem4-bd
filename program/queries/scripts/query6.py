# Найти галактику, в которой не наблюдалось ни одной звезды
# выбранным типом телескопа.

import argparse
import csv
from getpass import getpass
from pathlib import Path

import psycopg2


QUERY = """
SELECT
    g.galaxy_id,
    g.conf_plan,
    g.hab_plan,
    g.dist,
    %s::text AS tele_type,
    COUNT(DISTINCT CASE WHEN t.tele_id IS NOT NULL THEN s.star_id END)
        AS observed_stars_count
FROM galaxy g
LEFT JOIN cluster c
    ON c.galaxy_id = g.galaxy_id
LEFT JOIN stellar_system ss
    ON ss.cluster_id = c.cluster_id
LEFT JOIN plan_system ps
    ON ps.stell_sys_id = ss.stellar_id
LEFT JOIN star s
    ON s.sys_id = ps.system_id
LEFT JOIN exoplanet e
    ON e.sys_id = ps.system_id
LEFT JOIN observation o
    ON o.exo_id = e.exo_id
LEFT JOIN telescope t
    ON t.tele_id = o.tele_id
   AND t.tele_type = %s::tele_type_enum
GROUP BY
    g.galaxy_id,
    g.conf_plan,
    g.hab_plan,
    g.dist
HAVING COUNT(DISTINCT CASE WHEN t.tele_id IS NOT NULL THEN s.star_id END) = 0
ORDER BY g.galaxy_id;
"""


def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Find galaxies where no stars were observed through telescopes "
            "of a selected type."
        )
    )
    parser.add_argument("--dbname", default="mydb")
    parser.add_argument("--user", default="postgres")
    parser.add_argument("--host", default=None)
    parser.add_argument("--port", default=None)
    parser.add_argument("--ask-password", action="store_true")
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


def save_csv(path, headers, rows):
    path.parent.mkdir(parents=True, exist_ok=True)

    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(headers)
        writer.writerows(rows)


def main():
    args = parse_args()
    output_path = Path(__file__).resolve().parent.parent / "results" / "query6.csv"

    with connect(args) as conn:
        with conn.cursor() as cur:
            cur.execute(QUERY, (args.tele_type, args.tele_type))
            rows = cur.fetchall()
            headers = [column[0] for column in cur.description]

    save_csv(output_path, headers, rows)

    print(f"Saved {len(rows)} rows to {output_path}")


if __name__ == "__main__":
    main()
