SELECT g.galaxy_id
FROM galaxy g
WHERE NOT EXISTS (
    SELECT 1
    FROM cluster c
    JOIN stellar_system s ON s.cluster_id = c.cluster_id
    JOIN plan_system ps ON ps.stell_sys_id = s.stellar_id
    JOIN exoplanet e ON e.sys_id = ps.system_id
    JOIN observation o ON o.exo_id = e.exo_id
    JOIN telescope t ON t.tele_id = o.tele_id
    WHERE c.galaxy_id = g.galaxy_id
      AND t.tele_type = 'ground'
);




-- SELECT DISTINCT g.galaxy_id
-- FROM galaxy g
-- LEFT JOIN cluster c 
--     ON c.galaxy_id = g.galaxy_id
-- LEFT JOIN stellar_system s 
--     ON s.cluster_id = c.cluster_id
-- LEFT JOIN plan_system ps 
--     ON ps.stell_sys_id = s.stellar_id
-- LEFT JOIN exoplanet e 
--     ON e.sys_id = ps.system_id
-- LEFT JOIN observation o 
--     ON o.exo_id = e.exo_id
-- LEFT JOIN telescope t 
--     ON t.tele_id = o.tele_id
--    AND t.tele_type = 'ground'
-- WHERE t.tele_id IS NULL;