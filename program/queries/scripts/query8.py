import argparse
import csv
from getpass import getpass
from pathlib import Path

import psycopg2

# Запрос с CROSS JOIN для первых 20 телескопов и 20 стран
QUERY = """
SELECT
    t.tele_id,
    c.country::text AS country,
    COUNT(o.observation_id) AS observation_count
FROM (
    SELECT tele_id
    FROM telescope
    ORDER BY tele_id
    LIMIT 20
) AS t
CROSS JOIN (
    SELECT UNNEST(ENUM_RANGE(NULL::country_enum)) AS country
    ORDER BY country
    LIMIT 20
) AS c
LEFT JOIN observation AS o ON o.tele_id = t.tele_id
LEFT JOIN observer AS obs ON o.observer_id = obs.observer_id AND obs.country = c.country
GROUP BY t.tele_id, c.country
ORDER BY t.tele_id, c.country;
"""

def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Count observations for first 20 telescopes and first 20 countries."
        )
    )
    parser.add_argument("--dbname", default="mydb", help="Database name")
    parser.add_argument("--user", default="postgres", help="Database user")
    parser.add_argument("--host", default=None, help="Database host")
    parser.add_argument("--port", default=None, help="Database port")
    parser.add_argument("--ask-password", action="store_true", help="Prompt for password")
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
    # Путь к файлу: папка results рядом со скриптом
    output_path = Path(__file__).resolve().parent / "results" / "telescope_country_observations.csv"

    with connect(args) as conn:
        with conn.cursor() as cur:
            cur.execute(QUERY)
            rows = cur.fetchall()
            headers = [column[0] for column in cur.description]

    save_csv(output_path, headers, rows)

    print(f"Saved {len(rows)} rows to {output_path}")

if __name__ == "__main__":
    main()
