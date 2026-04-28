# Руководство По Запросам

Этот файл объясняет, как выполнять запросы к базе данных курсовой работы через `psql`, начиная с простых примеров и заканчивая более сложными запросами с большим количеством условий.

## 0. Создание и загрузка баз данных

Перед выполнением запросов нужно создать базу данных PostgreSQL и загрузить SQL-скрипты из папки `program/`.

Малая база данных с читаемыми демонстрационными данными:

```powershell
$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"

& $psql -U postgres -d postgres -c "CREATE DATABASE exoplanet_coursework;"
& $psql -U postgres -d exoplanet_coursework -f "C:\spbpu\year2\bd\program\schema.sql"
& $psql -U postgres -d exoplanet_coursework -f "C:\spbpu\year2\bd\program\seed.sql"
```

Большая база данных с синтетическими данными:

```powershell
$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"

& $psql -U postgres -d postgres -c "CREATE DATABASE exoplanet_coursework_big;"
& $psql -U postgres -d exoplanet_coursework_big -f "C:\spbpu\year2\bd\program\schema.sql"
& $psql -U postgres -d exoplanet_coursework_big -f "C:\spbpu\year2\bd\program\generate_large_dataset.sql"
```

Если база уже существует и её нужно пересоздать с нуля, сначала удалите её:

```powershell
& $psql -U postgres -d postgres -c "DROP DATABASE exoplanet_coursework WITH (FORCE);"
& $psql -U postgres -d postgres -c "DROP DATABASE exoplanet_coursework_big WITH (FORCE);"
```

Проверка корректной загрузки большой базы данных:

```powershell
& $psql -U postgres -d exoplanet_coursework_big -c "
SELECT
    (SELECT COUNT(*) FROM exoplanet_catalog.galaxy) +
    (SELECT COUNT(*) FROM exoplanet_catalog.stellar_cluster) +
    (SELECT COUNT(*) FROM exoplanet_catalog.stellar_system) +
    (SELECT COUNT(*) FROM exoplanet_catalog.star) +
    (SELECT COUNT(*) FROM exoplanet_catalog.planetary_system) +
    (SELECT COUNT(*) FROM exoplanet_catalog.exoplanet) +
    (SELECT COUNT(*) FROM exoplanet_catalog.telescope) +
    (SELECT COUNT(*) FROM exoplanet_catalog.observer) +
    (SELECT COUNT(*) FROM exoplanet_catalog.observation) AS total_rows;
"
```

Ожидаемый результат для большой базы данных: `280530`.

## 1. Подключение к базе данных

Малая база данных:

```powershell
$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
& $psql -U postgres -d exoplanet_coursework
```

Большая база данных:

```powershell
$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
& $psql -U postgres -d exoplanet_coursework_big
```

Если вы уже находитесь внутри `psql`, переключиться на другую базу можно так:

```sql
\c exoplanet_coursework_big postgres
```

Выберите схему:

```sql
SET search_path TO exoplanet_catalog, public;
```

## 2. Полезные команды `psql`

Показать таблицы:

```sql
\dt exoplanet_catalog.*
```

Показать представления:

```sql
\dv exoplanet_catalog.*
```

Показать структуру одной таблицы:

```sql
\d exoplanet_catalog.exoplanet
```

Включить расширенный вывод для широких строк:

```sql
\x auto
```

Выйти из `psql`:

```sql
\q
```

## 3. Основные таблицы и представления

Основные таблицы:

- `galaxy`
- `stellar_cluster`
- `stellar_system`
- `star`
- `planetary_system`
- `exoplanet`
- `telescope`
- `observer`
- `observation`

Полезные представления:

- `v_exoplanet_catalog`: уже объединяет экзопланету, звезду, систему, скопление и галактику
- `v_observation_details`: уже объединяет наблюдение, экзопланету, телескоп, наблюдателя и иерархию

Для многих аналитических запросов использовать представления проще, чем вручную писать все `JOIN`.

## 4. Простые запросы

Посчитать количество всех экзопланет:

```sql
SELECT COUNT(*) FROM exoplanet;
```

Показать ближайшие экзопланеты:

```sql
SELECT id, planet_type, distance
FROM exoplanet
ORDER BY distance ASC
LIMIT 10;
```

Показать только планеты земного типа.
Обратите внимание: значение enum записано как `terrestial`, потому что в тексте курсовой используется именно такое написание.

```sql
SELECT id, mass, radius, orbital_period
FROM exoplanet
WHERE planet_type = 'terrestial';
```

Показать планеты, открытые после 2015 года:

```sql
SELECT id, discovery_date
FROM exoplanet
WHERE discovery_date > DATE '2015-01-01'
ORDER BY discovery_date;
```

## 5. Запросы с фильтрами

Условия можно комбинировать через `AND`, `OR`, `IN`, `BETWEEN`, `LIKE`.

Экзопланеты, которые находятся близко и имеют небольшие размеры:

```sql
SELECT id, mass, radius, distance
FROM exoplanet
WHERE distance <= 50
  AND mass < 2
  AND radius < 1.5
ORDER BY distance, mass;
```

Планеты нескольких типов:

```sql
SELECT id, planet_type, distance
FROM exoplanet
WHERE planet_type IN ('terrestial', 'superearth')
ORDER BY distance;
```

Звезды спектральных классов, начинающихся с `M`:

```sql
SELECT id, spectral_class, temperature
FROM star
WHERE spectral_class LIKE 'M%'
ORDER BY temperature;
```

## 6. Запросы с соединениями

### 6.1. Использование готового представления каталога

```sql
SELECT
    exoplanet_id,
    planet_type,
    host_star_id,
    star_spectral_class,
    stellar_system_id,
    stellar_cluster_id,
    galaxy_id
FROM v_exoplanet_catalog
ORDER BY exoplanet_id;
```

### 6.2. Написание `JOIN` вручную

```sql
SELECT
    e.id AS exoplanet_id,
    e.planet_type,
    s.id AS host_star_id,
    s.spectral_class,
    ps.id AS planetary_system_id
FROM exoplanet AS e
JOIN planetary_system AS ps ON ps.id = e.system_id
JOIN star AS s ON s.id = ps.star_id
ORDER BY e.id;
```

### 6.3. Детали наблюдений

```sql
SELECT
    observation_id,
    exoplanet_id,
    telescope_name,
    observer_id,
    observation_date
FROM v_observation_details
ORDER BY observation_date DESC;
```

## 7. Агрегация и группировка

Сколько экзопланет приходится на каждый спектральный класс:

```sql
SELECT
    star_spectral_class,
    COUNT(*) AS exoplanet_count
FROM v_exoplanet_catalog
GROUP BY star_spectral_class
ORDER BY exoplanet_count DESC, star_spectral_class;
```

Сколько наблюдений у каждого телескопа:

```sql
SELECT
    telescope_name,
    COUNT(*) AS observations_count
FROM v_observation_details
GROUP BY telescope_name
ORDER BY observations_count DESC, telescope_name;
```

Только группы, в которых не меньше двух экзопланет:

```sql
SELECT
    star_spectral_class,
    COUNT(*) AS exoplanet_count
FROM v_exoplanet_catalog
GROUP BY star_spectral_class
HAVING COUNT(*) >= 2
ORDER BY exoplanet_count DESC;
```

## 8. Сложные запросы с большим количеством условий

Этот раздел особенно полезен для аналитических запросов в рамках курсовой работы.

### 8.1. Сложный фильтр с большим количеством условий в `WHERE`

Найти близкие кандидаты на обитаемые миры, которые:

- имеют тип `terrestial` или `superearth`
- находятся на расстоянии не более `50`
- обращаются вокруг звезд класса `M`
- наблюдались космическими телескопами
- наблюдались начиная с `2020-01-01`
- наблюдались исследователями из выбранных стран

```sql
SELECT
    vc.exoplanet_id,
    vc.planet_type,
    vc.exoplanet_distance,
    vc.host_star_id,
    vc.star_spectral_class,
    COUNT(*) AS observation_count,
    COUNT(DISTINCT vod.telescope_name) AS telescope_count
FROM v_exoplanet_catalog AS vc
JOIN v_observation_details AS vod
    ON vod.exoplanet_id = vc.exoplanet_id
WHERE vc.planet_type IN ('terrestial', 'superearth')
  AND vc.exoplanet_distance <= 50
  AND vc.star_spectral_class LIKE 'M%'
  AND vod.telescope_type = 'space'
  AND vod.observation_date >= DATE '2020-01-01'
  AND vod.observer_country IN ('United States', 'Belgium')
GROUP BY
    vc.exoplanet_id,
    vc.planet_type,
    vc.exoplanet_distance,
    vc.host_star_id,
    vc.star_spectral_class
HAVING COUNT(*) >= 1
ORDER BY observation_count DESC, vc.exoplanet_distance ASC;
```

### 8.2. Системы с обитаемыми планетами, но без недавних наземных наблюдений

В этом запросе используются `EXISTS` и `NOT EXISTS`.

```sql
SELECT
    ps.id AS planetary_system_id,
    ps.habitable_planets,
    ps.distance
FROM planetary_system AS ps
WHERE ps.habitable_planets > 0
  AND EXISTS (
      SELECT 1
      FROM exoplanet AS e
      WHERE e.system_id = ps.id
  )
  AND NOT EXISTS (
      SELECT 1
      FROM exoplanet AS e
      JOIN observation AS o ON o.exoplanet_id = e.id
      JOIN telescope AS t ON t.name = o.telescope_name
      WHERE e.system_id = ps.id
        AND t.telescope_type = 'ground'
        AND o.observation_date >= DATE '2023-01-01'
  )
ORDER BY ps.distance;
```

### 8.3. Лучшие звезды по числу планет с использованием `WITH`

Здесь используется Common Table Expression (`CTE`), чтобы разбить сложную задачу на шаги.

```sql
WITH star_stats AS (
    SELECT
        s.id AS star_id,
        s.spectral_class,
        COUNT(e.id) AS exoplanet_count,
        AVG(e.mass) AS avg_planet_mass,
        AVG(e.radius) AS avg_planet_radius
    FROM star AS s
    JOIN planetary_system AS ps ON ps.star_id = s.id
    JOIN exoplanet AS e ON e.system_id = ps.id
    GROUP BY s.id, s.spectral_class
)
SELECT
    star_id,
    spectral_class,
    exoplanet_count,
    ROUND(avg_planet_mass, 4) AS avg_planet_mass,
    ROUND(avg_planet_radius, 4) AS avg_planet_radius
FROM star_stats
WHERE exoplanet_count >= 1
ORDER BY exoplanet_count DESC, avg_planet_mass DESC
LIMIT 10;
```

### 8.4. Ранжирование звезд с помощью оконной функции

Это полезно, когда нужно построить упорядоченный рейтинг.

```sql
WITH star_stats AS (
    SELECT
        s.id AS star_id,
        COUNT(e.id) AS exoplanet_count
    FROM star AS s
    JOIN planetary_system AS ps ON ps.star_id = s.id
    JOIN exoplanet AS e ON e.system_id = ps.id
    GROUP BY s.id
)
SELECT
    star_id,
    exoplanet_count,
    ROW_NUMBER() OVER (ORDER BY exoplanet_count DESC, star_id) AS rank_position
FROM star_stats
ORDER BY rank_position
LIMIT 10;
```

### 8.5. Многотабличный аналитический запрос без использования представлений

Это хороший пример, если преподавателю важно увидеть явные `JOIN`.

```sql
SELECT
    e.id AS exoplanet_id,
    e.planet_type,
    e.discovery_date,
    s.id AS star_id,
    s.spectral_class,
    ss.id AS stellar_system_id,
    sc.id AS cluster_id,
    g.id AS galaxy_id,
    t.name AS telescope_name,
    o.observation_date,
    ob.id AS observer_id,
    ob.country
FROM exoplanet AS e
JOIN planetary_system AS ps ON ps.id = e.system_id
JOIN star AS s ON s.id = ps.star_id
JOIN stellar_system AS ss ON ss.id = ps.stellar_system_id
JOIN stellar_cluster AS sc ON sc.id = ss.cluster_id
JOIN galaxy AS g ON g.id = sc.galaxy_id
JOIN observation AS o ON o.exoplanet_id = e.id
JOIN telescope AS t ON t.name = o.telescope_name
JOIN observer AS ob ON ob.id = o.observer_id
WHERE e.planet_type IN ('terrestial', 'superearth')
  AND e.discovery_date BETWEEN DATE '2010-01-01' AND DATE '2025-12-31'
  AND s.spectral_class LIKE 'M%'
  AND t.telescope_type = 'space'
  AND ob.country = 'United States'
ORDER BY e.discovery_date DESC, e.id;
```

## 9. Выполнение запросов к большой базе данных

Большая база данных удобнее для проверки агрегации, группировки, ранжирования и сложной фильтрации, потому что в ней намного больше строк.

Переключение:

```sql
\c exoplanet_coursework_big postgres
SET search_path TO exoplanet_catalog, public;
```

Быстрые проверки:

```sql
SELECT COUNT(*) FROM exoplanet;
SELECT COUNT(*) FROM observation;
SELECT COUNT(*) FROM stellar_system;
```

Ожидаемые значения в большой базе:

- `exoplanet`: `50000`
- `observation`: `200000`
- `stellar_system`: `10000`

## 10. Выполнение одного запроса напрямую из PowerShell

Не обязательно каждый раз входить в интерактивный режим.

```powershell
$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
& $psql -U postgres -d exoplanet_coursework_big -c "SELECT COUNT(*) FROM exoplanet_catalog.exoplanet;"
```

Для более длинного запроса:

```powershell
& $psql -U postgres -d exoplanet_coursework_big -c "
SELECT star_spectral_class, COUNT(*) AS exoplanet_count
FROM exoplanet_catalog.v_exoplanet_catalog
GROUP BY star_spectral_class
ORDER BY exoplanet_count DESC;
"
```

## 11. Экспорт результатов запроса

Экспорт в CSV из `psql`:

```sql
\copy (
    SELECT exoplanet_id, host_star_id, star_spectral_class
    FROM v_exoplanet_catalog
    ORDER BY exoplanet_id
) TO 'C:/spbpu/year2/bd/program/exoplanets_export.csv' CSV HEADER
```

## 12. Советы по написанию собственных сложных запросов

Если запрос становится большим, удобно строить его в таком порядке:

1. Начните с `SELECT ... FROM ...`
2. Добавьте нужные `JOIN`
3. Добавляйте условия `WHERE` по одному
4. Проверяйте промежуточный результат
5. Добавьте `GROUP BY`, если нужны количества или средние значения
6. Добавьте `HAVING` только для условий на сгруппированные результаты
7. В конце добавьте `ORDER BY` и `LIMIT`

Полезный шаблон:

```sql
SELECT
    ...
FROM table_a AS a
JOIN table_b AS b ON ...
JOIN table_c AS c ON ...
WHERE condition_1
  AND condition_2
  AND condition_3
GROUP BY ...
HAVING ...
ORDER BY ...
LIMIT ...;
```

Если вы не уверены, какие таблицы нужно соединять, начните с представлений:

- `v_exoplanet_catalog`
- `v_observation_details`

Это самый простой вход для большинства запросов в рамках курсовой работы.
