# Найти все телескопы, которые наблюдали тип экзопланет "terrestrial"
# в галактике GAL_0001 вокруг звёзд класса G.

import argparse
import csv
from getpass import getpass
from pathlib import Path

import psycopg2


QUERY = """
SELECT
    t.tele_id,
    t.tele_type::text AS tele_type,
    t.aper,
    t.com_year,
    t.oper,
    t.discov_plan,
    COUNT(DISTINCT o.observation_id) AS observations_count,
    COUNT(DISTINCT e.exo_id) AS exoplanets_count
FROM telescope t
JOIN observation o
    ON o.tele_id = t.tele_id
JOIN exoplanet e
    ON e.exo_id = o.exo_id
JOIN plan_system ps
    ON ps.system_id = e.sys_id
JOIN star s
    ON s.sys_id = ps.system_id
JOIN stellar_system ss
    ON ss.stellar_id = ps.stell_sys_id
JOIN cluster c
    ON c.cluster_id = ss.cluster_id
JOIN galaxy g
    ON g.galaxy_id = c.galaxy_id
WHERE e.exo_type = %s::exo_type_enum
  AND g.galaxy_id = %s
  AND s.class = %s::star_class_enum
GROUP BY
    t.tele_id,
    t.tele_type,
    t.aper,
    t.com_year,
    t.oper,
    t.discov_plan
ORDER BY t.tele_id;
"""


def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Save telescopes that observed terrestrial exoplanets in a given "
            "galaxy around stars of a given class."
        )
    )
    parser.add_argument("--dbname", default="mydb")
    parser.add_argument("--user", default="postgres")
    parser.add_argument("--host", default=None)
    parser.add_argument("--port", default=None)
    parser.add_argument("--ask-password", action="store_true")
    parser.add_argument("--exo-type", default="terrestrial")
    parser.add_argument("--galaxy", default="GAL_0001")
    parser.add_argument("--star-class", default="G")
    parser.add_argument("--output", default=None)
    return parser.parse_args()


def make_output_path(args):
    if args.output:
        return Path(args.output)

    filename = (
        f"telescopes_{args.exo_type}_{args.galaxy}_star_{args.star_class}.csv"
    )
    return Path(__file__).resolve().parent / "queries" / filename


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
    output_path = make_output_path(args)

    with connect(args) as conn:
        with conn.cursor() as cur:
            cur.execute(QUERY, (args.exo_type, args.galaxy, args.star_class))
            rows = cur.fetchall()
            headers = [column[0] for column in cur.description]

    save_rows(output_path, headers, rows)

    print(f"Saved {len(rows)} rows to {output_path}")


if __name__ == "__main__":
    main()
