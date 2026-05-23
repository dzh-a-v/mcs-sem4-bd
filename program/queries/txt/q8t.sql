SELECT t.tele_id, c.country, COUNT(o.observation_id)
FROM
    (SELECT tele_id
     FROM telescope
     ORDER BY tele_id
     LIMIT 20) t
CROSS JOIN
    (SELECT DISTINCT country
     FROM observer
     ORDER BY country
     LIMIT 20) c
LEFT JOIN observer ob
    ON ob.country = c.country
LEFT JOIN observation o
    ON o.observer_id = ob.observer_id
   AND o.tele_id = t.tele_id
GROUP BY t.tele_id, c.country
ORDER BY t.tele_id, c.country;