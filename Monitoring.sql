
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    o.paire_id,
    AVG(t.trad_prix) OVER (
        PARTITION BY o.paire_id
        ORDER BY t.date_execution
    ) AS avg_prix
FROM trades t
JOIN tbl_ordress o ON t.orders_id = o.id;

ALTER TABLE tbl_ordress SET (fillfactor = 80);
ALTER TABLE tbl_portfeuilles SET (fillfactor = 85);

VACUUM FULL tbl_ordress;



