import psycopg2
from datetime import date, timedelta
import random

# ===========================
# Подключение
# ===========================
conn = psycopg2.connect(dbname="mydb", user="postgres")
cur = conn.cursor()

# ===========================
# Очистка таблиц перед генерацией
# ===========================
print("Очистка таблиц...")

cur.execute("""
    TRUNCATE TABLE
        observation,
        exoplanet,
        star,
        telescope,
        observer,
        plan_system,
        stellar_system,
        cluster,
        galaxy
    CASCADE;
""")

# ===========================
# Вспомогательные функции
# ===========================
TODAY = date.today()


def random_date(start_date, end_date):
    days = (end_date - start_date).days
    return start_date + timedelta(days=random.randint(0, days))


def random_decimal(min_value, max_value):
    return random.uniform(min_value, max_value)


def make_id(prefix, number, width=5):
    return f"{prefix}_{number:0{width}d}"


# ===========================
# Случайное количество записей
# с контролем общей суммы 200k–300k
# ===========================
TARGET_MIN = 200_000
TARGET_MAX = 300_000

while True:
    GALAXIES_COUNT = random.randint(30, 70)
    CLUSTERS_COUNT = random.randint(300, 700)
    STELLAR_SYSTEMS_COUNT = random.randint(3000, 7000)
    PLAN_SYSTEMS_COUNT = random.randint(15000, 30000)
    STARS_COUNT = random.randint(25000, 50000)
    EXOPLANETS_COUNT = random.randint(30000, 50000)
    TELESCOPES_COUNT = random.randint(200, 500)
    OBSERVERS_COUNT = random.randint(7000, 15000)

    estimated_observations = EXOPLANETS_COUNT * 4

    estimated_total = (
        GALAXIES_COUNT
        + CLUSTERS_COUNT
        + STELLAR_SYSTEMS_COUNT
        + PLAN_SYSTEMS_COUNT
        + STARS_COUNT
        + EXOPLANETS_COUNT
        + TELESCOPES_COUNT
        + OBSERVERS_COUNT
        + estimated_observations
    )

    if TARGET_MIN <= estimated_total <= TARGET_MAX:
        break

# Гарантия, что хватит звёзд: минимум 10 звёзд на каждое скопление
if STARS_COUNT < CLUSTERS_COUNT * 10:
    STARS_COUNT = CLUSTERS_COUNT * 10

# Гарантия, что хватит планетарных систем: минимум 1 на каждое скопление
if PLAN_SYSTEMS_COUNT < CLUSTERS_COUNT:
    PLAN_SYSTEMS_COUNT = CLUSTERS_COUNT

# Гарантия, что хватит звёздных систем: минимум 1 на каждое скопление
if STELLAR_SYSTEMS_COUNT < CLUSTERS_COUNT:
    STELLAR_SYSTEMS_COUNT = CLUSTERS_COUNT

print("Случайно выбранное количество записей:")
print(f"Галактик: {GALAXIES_COUNT}")
print(f"Скоплений: {CLUSTERS_COUNT}")
print(f"Звёздных систем: {STELLAR_SYSTEMS_COUNT}")
print(f"Планетных систем: {PLAN_SYSTEMS_COUNT}")
print(f"Звёзд: {STARS_COUNT}")
print(f"Экзопланет: {EXOPLANETS_COUNT}")
print(f"Телескопов: {TELESCOPES_COUNT}")
print(f"Наблюдателей: {OBSERVERS_COUNT}")
print(f"Примерная сумма: {estimated_total}")

# ===========================
# ENUM значения
# ===========================
exo_types = [
    'gas_giant',
    'neptunian',
    'superearth',
    'terrestrial'
]

star_classes = [
    'O', 'B', 'A', 'F', 'G', 'K', 'M', 'W', 'L', 'D'
]

tele_types = [
    'space',
    'ground'
]

countries = [
    'Russia',
    'United States',
    'China',
    'Japan',
    'Germany',
    'France',
    'United Kingdom',
    'Italy',
    'Spain',
    'Canada',
    'Australia',
    'Netherlands',
    'Sweden',
    'Switzerland',
    'India',
    'Brazil',
    'South Korea',
    'Poland',
    'Czechia',
    'Finland',
    'Norway',
    'Austria',
    'Belgium',
    'Portugal',
    'Argentina',
    'Mexico',
    'Chile',
    'South Africa',
    'Ukraine'
]

operators = [
    'NASA',
    'ESA',
    'Roscosmos',
    'JAXA',
    'CNSA',
    'ESO',
    'ISRO',
    'DLR',
    'CNES',
    'Private Observatory Network',
    'International Space Research Group',
    'Global Telescope Association'
]

# ===========================
# 1. Галактики
# ===========================
print("Галактики...")

galaxy_ids = []

for i in range(1, GALAXIES_COUNT + 1):
    galaxy_id = make_id("GAL", i, 4)

    conf_plan = random.randint(10, 5000)
    hab_plan = random.randint(0, conf_plan)

    cur.execute("""
        INSERT INTO galaxy
        (galaxy_id, conf_plan, hab_plan, dist)
        VALUES (%s, %s, %s, %s);
    """, (
        galaxy_id,
        conf_plan,
        hab_plan,
        random_decimal(0, 1000000)
    ))

    galaxy_ids.append(galaxy_id)

# ===========================
# 2. Скопления
# ===========================
print("Скопления...")

cluster_ids = []

for i in range(1, CLUSTERS_COUNT + 1):
    cluster_id = make_id("CLS", i, 5)

    conf_plan = random.randint(5, 2000)
    hab_plan = random.randint(0, conf_plan)

    cur.execute("""
        INSERT INTO cluster
        (cluster_id, stars_count, conf_plan, hab_plan, dist, galaxy_id)
        VALUES (%s, %s, %s, %s, %s, %s);
    """, (
        cluster_id,
        random.randint(10, 100000),
        conf_plan,
        hab_plan,
        random_decimal(0, 500000),
        random.choice(galaxy_ids)
    ))

    cluster_ids.append(cluster_id)

# ===========================
# 3. Звёздные системы
# ===========================
print("Звёздные системы...")

stellar_ids = []
stellar_to_cluster = {}
cluster_stellar_ids = {cluster_id: [] for cluster_id in cluster_ids}

stellar_counter = 1

# Минимум 1 звёздная система на каждое скопление
for cluster_id in cluster_ids:
    stellar_id = make_id("STELLAR", stellar_counter, 5)
    stellar_counter += 1

    conf_plan = random.randint(1, 300)
    hab_plan = random.randint(0, conf_plan)

    cur.execute("""
        INSERT INTO stellar_system
        (stellar_id, stars_count, conf_plan, hab_plan, dist, cluster_id)
        VALUES (%s, %s, %s, %s, %s, %s);
    """, (
        stellar_id,
        random.randint(1, 8),
        conf_plan,
        hab_plan,
        random_decimal(0, 100000),
        cluster_id
    ))

    stellar_ids.append(stellar_id)
    stellar_to_cluster[stellar_id] = cluster_id
    cluster_stellar_ids[cluster_id].append(stellar_id)

# Остальные звёздные системы случайно
while stellar_counter <= STELLAR_SYSTEMS_COUNT:
    stellar_id = make_id("STELLAR", stellar_counter, 5)
    stellar_counter += 1

    cluster_id = random.choice(cluster_ids)

    conf_plan = random.randint(1, 300)
    hab_plan = random.randint(0, conf_plan)

    cur.execute("""
        INSERT INTO stellar_system
        (stellar_id, stars_count, conf_plan, hab_plan, dist, cluster_id)
        VALUES (%s, %s, %s, %s, %s, %s);
    """, (
        stellar_id,
        random.randint(1, 8),
        conf_plan,
        hab_plan,
        random_decimal(0, 100000),
        cluster_id
    ))

    stellar_ids.append(stellar_id)
    stellar_to_cluster[stellar_id] = cluster_id
    cluster_stellar_ids[cluster_id].append(stellar_id)

# ===========================
# 4. Планетные системы
# ===========================
print("Планетные системы...")

plan_system_ids = []
plan_system_to_cluster = {}
cluster_plan_system_ids = {cluster_id: [] for cluster_id in cluster_ids}

system_counter = 1

# Минимум 1 планетарная система на каждое звёздное скопление
for cluster_id in cluster_ids:
    system_id = make_id("SYS", system_counter, 6)
    system_counter += 1

    stellar_id = random.choice(cluster_stellar_ids[cluster_id])

    conf_plan = random.randint(1, 20)
    hab_plan = random.randint(0, conf_plan)

    cur.execute("""
        INSERT INTO plan_system
        (system_id, conf_plan, hab_plan, distance, stell_sys_id)
        VALUES (%s, %s, %s, %s, %s);
    """, (
        system_id,
        conf_plan,
        hab_plan,
        random_decimal(0, 100000),
        stellar_id
    ))

    plan_system_ids.append(system_id)
    plan_system_to_cluster[system_id] = cluster_id
    cluster_plan_system_ids[cluster_id].append(system_id)

# Остальные планетарные системы случайно
while system_counter <= PLAN_SYSTEMS_COUNT:
    system_id = make_id("SYS", system_counter, 6)
    system_counter += 1

    stellar_id = random.choice(stellar_ids)
    cluster_id = stellar_to_cluster[stellar_id]

    conf_plan = random.randint(1, 20)
    hab_plan = random.randint(0, conf_plan)

    cur.execute("""
        INSERT INTO plan_system
        (system_id, conf_plan, hab_plan, distance, stell_sys_id)
        VALUES (%s, %s, %s, %s, %s);
    """, (
        system_id,
        conf_plan,
        hab_plan,
        random_decimal(0, 100000),
        stellar_id
    ))

    plan_system_ids.append(system_id)
    plan_system_to_cluster[system_id] = cluster_id
    cluster_plan_system_ids[cluster_id].append(system_id)

# ===========================
# 5. Звёзды
# ===========================
print("Звёзды...")


def generate_star_params():
    star_class = random.choice(star_classes)

    if star_class == 'O':
        mass = random_decimal(16, 90)
        radius = random_decimal(6, 20)
        temp = random.randint(30000, 50000)

    elif star_class == 'B':
        mass = random_decimal(2.1, 16)
        radius = random_decimal(1.8, 6)
        temp = random.randint(10000, 30000)

    elif star_class == 'A':
        mass = random_decimal(1.4, 2.1)
        radius = random_decimal(1.4, 2.5)
        temp = random.randint(7500, 10000)

    elif star_class == 'F':
        mass = random_decimal(1.04, 1.4)
        radius = random_decimal(1.15, 1.4)
        temp = random.randint(6000, 7500)

    elif star_class == 'G':
        mass = random_decimal(0.8, 1.04)
        radius = random_decimal(0.9, 1.15)
        temp = random.randint(5200, 6000)

    elif star_class == 'K':
        mass = random_decimal(0.45, 0.8)
        radius = random_decimal(0.7, 0.9)
        temp = random.randint(3700, 5200)

    elif star_class == 'M':
        mass = random_decimal(0.08, 0.45)
        radius = random_decimal(0.1, 0.7)
        temp = random.randint(2400, 3700)

    else:
        mass = random_decimal(0.1, 10)
        radius = random_decimal(0.01, 5)
        temp = random.randint(1000, 100000)

    return star_class, mass, radius, temp


def insert_star(star_id, system_id):
    star_class, mass, radius, temp = generate_star_params()

    cur.execute("""
        INSERT INTO star
        (star_id, class, mass, radius, temp, dist, sys_id)
        VALUES (%s, %s, %s, %s, %s, %s, %s);
    """, (
        star_id,
        star_class,
        mass,
        radius,
        temp,
        random_decimal(0, 100000),
        system_id
    ))


star_ids = []
star_counter = 1

# Минимум 10 звёзд в каждом звёздном скоплении
for cluster_id in cluster_ids:
    for _ in range(10):
        star_id = make_id("STAR", star_counter, 6)
        star_counter += 1

        system_id = random.choice(cluster_plan_system_ids[cluster_id])

        insert_star(star_id, system_id)
        star_ids.append(star_id)

# Остальные звёзды случайно
while star_counter <= STARS_COUNT:
    star_id = make_id("STAR", star_counter, 6)
    star_counter += 1

    system_id = random.choice(plan_system_ids)

    insert_star(star_id, system_id)
    star_ids.append(star_id)

# ===========================
# 6. Экзопланеты
# ===========================
print("Экзопланеты...")

exo_ids = []
exo_discovery_dates = {}

for i in range(1, EXOPLANETS_COUNT + 1):
    exo_id = make_id("EXO", i, 6)
    exo_type = random.choice(exo_types)

    if exo_type == 'gas_giant':
        mass = random_decimal(50, 5000)
        radius = random_decimal(5, 20)

    elif exo_type == 'neptunian':
        mass = random_decimal(10, 50)
        radius = random_decimal(2, 6)

    elif exo_type == 'superearth':
        mass = random_decimal(2, 10)
        radius = random_decimal(1.2, 2.5)

    else:
        mass = random_decimal(0.1, 2)
        radius = random_decimal(0.3, 1.5)

    discov_date = random_date(date(1992, 1, 1), TODAY)
    last_obs_date = random_date(discov_date, TODAY)

    cur.execute("""
        INSERT INTO exoplanet
        (exo_id, mass, radius, orb_period, exo_type, dist,
         discov_date, last_obs_date, sys_id)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s);
    """, (
        exo_id,
        mass,
        radius,
        random_decimal(0.5, 5000),
        exo_type,
        random_decimal(0, 100000),
        discov_date,
        last_obs_date,
        random.choice(plan_system_ids)
    ))

    exo_ids.append(exo_id)
    exo_discovery_dates[exo_id] = discov_date

# ===========================
# 7. Телескопы
# ===========================
print("Телескопы...")

tele_ids = []

for i in range(1, TELESCOPES_COUNT + 1):
    tele_id = make_id("TELE", i, 5)

    tele_type = random.choice(tele_types)

    if tele_type == 'space':
        aper = random_decimal(0.2, 10)
        com_year = random.randint(1960, TODAY.year)
    else:
        aper = random_decimal(0.5, 40)
        com_year = random.randint(1609, TODAY.year)

    cur.execute("""
        INSERT INTO telescope
        (tele_id, tele_type, aper, com_year, oper, discov_plan)
        VALUES (%s, %s, %s, %s, %s, %s);
    """, (
        tele_id,
        tele_type,
        aper,
        com_year,
        random.choice(operators),
        0
    ))

    tele_ids.append(tele_id)

# ===========================
# 8. Наблюдатели
# ===========================
print("Наблюдатели...")

observer_ids = []

for i in range(1, OBSERVERS_COUNT + 1):
    observer_id = f"Observer_{i:06d}"

    cur.execute("""
        INSERT INTO observer
        (observer_id, bday, country, discovs)
        VALUES (%s, %s, %s, %s);
    """, (
        observer_id,
        random_date(date(1930, 1, 1), date(2005, 12, 31)),
        random.choice(countries),
        0
    ))

    observer_ids.append(observer_id)

# ===========================
# 9. Наблюдения
# ===========================
print("Наблюдения...")

observation_ids = []
used_observations = set()

telescope_discovs = {tele_id: 0 for tele_id in tele_ids}
observer_discovs = {observer_id: 0 for observer_id in observer_ids}

obs_counter = 1

for exo_id in exo_ids:
    observations_for_planet = random.randint(1, 7)

    for _ in range(observations_for_planet):
        tele_id = random.choice(tele_ids)
        observer_id = random.choice(observer_ids)

        obs_date = random_date(exo_discovery_dates[exo_id], TODAY)

        unique_key = (exo_id, tele_id, observer_id, obs_date)

        attempts = 0
        while unique_key in used_observations and attempts < 20:
            tele_id = random.choice(tele_ids)
            observer_id = random.choice(observer_ids)
            obs_date = random_date(exo_discovery_dates[exo_id], TODAY)

            unique_key = (exo_id, tele_id, observer_id, obs_date)
            attempts += 1

        if unique_key in used_observations:
            continue

        used_observations.add(unique_key)

        observation_id = make_id("OBS", obs_counter, 7)
        obs_counter += 1

        cur.execute("""
            INSERT INTO observation
            (observation_id, exo_id, tele_id, observer_id, obs_date)
            VALUES (%s, %s, %s, %s, %s);
        """, (
            observation_id,
            exo_id,
            tele_id,
            observer_id,
            obs_date
        ))

        observation_ids.append(observation_id)

        telescope_discovs[tele_id] += 1
        observer_discovs[observer_id] += 1

# ===========================
# 10. Обновление статистики
# ===========================
print("Обновление статистики...")

for tele_id, count in telescope_discovs.items():
    cur.execute("""
        UPDATE telescope
        SET discov_plan = %s
        WHERE tele_id = %s;
    """, (
        count,
        tele_id
    ))

for observer_id, count in observer_discovs.items():
    cur.execute("""
        UPDATE observer
        SET discovs = %s
        WHERE observer_id = %s;
    """, (
        count,
        observer_id
    ))

# ===========================
# Завершение
# ===========================
conn.commit()
cur.close()
conn.close()

total_records = (
    len(galaxy_ids)
    + len(cluster_ids)
    + len(stellar_ids)
    + len(plan_system_ids)
    + len(star_ids)
    + len(exo_ids)
    + len(tele_ids)
    + len(observer_ids)
    + len(observation_ids)
)

print("Готово!")
print(f"Галактик: {len(galaxy_ids)}")
print(f"Скоплений: {len(cluster_ids)}")
print(f"Звёздных систем: {len(stellar_ids)}")
print(f"Планетных систем: {len(plan_system_ids)}")
print(f"Звёзд: {len(star_ids)}")
print(f"Экзопланет: {len(exo_ids)}")
print(f"Телескопов: {len(tele_ids)}")
print(f"Наблюдателей: {len(observer_ids)}")
print(f"Наблюдений: {len(observation_ids)}")
print(f"Всего записей: {total_records}")

# print()
# print("Проверочные SQL-запросы:")
# print("""
# 1. Проверка, что в каждом скоплении есть минимум 1 планетарная система:

# SELECT 
#     c.cluster_id,
#     COUNT(DISTINCT ps.system_id) AS planet_systems_count
# FROM cluster c
# LEFT JOIN stellar_system ss 
#     ON ss.cluster_id = c.cluster_id
# LEFT JOIN plan_system ps 
#     ON ps.stell_sys_id = ss.stellar_id
# GROUP BY c.cluster_id
# HAVING COUNT(DISTINCT ps.system_id) < 1;

# 2. Проверка, что в каждом скоплении есть минимум 10 звёзд:

# SELECT 
#     c.cluster_id,
#     COUNT(s.star_id) AS stars_count
# FROM cluster c
# LEFT JOIN stellar_system ss 
#     ON ss.cluster_id = c.cluster_id
# LEFT JOIN plan_system ps 
#     ON ps.stell_sys_id = ss.stellar_id
# LEFT JOIN star s 
#     ON s.sys_id = ps.system_id
# GROUP BY c.cluster_id
# HAVING COUNT(s.star_id) < 10;
# """)