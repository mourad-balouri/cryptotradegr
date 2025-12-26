--- CAS 1 — Statistiques par UTILISATEUR

SELECT
    u.utili_id,
    u.nom,
    t_stats.nb_trades,
    t_stats.volume_total
FROM tbl_utilisateur u
LEFT JOIN LATERAL (
    SELECT
        COUNT(*) AS nb_trades,
        SUM(trad_quantite) AS volume_total
    FROM trades t
    JOIN tbl_ordress o ON o.id = t.orders_id
    WHERE o.utili_id = u.utili_id
) t_stats ON TRUE;

---CAS 2 — Statistiques par PAIRE
SELECT
    p.pair_id,
    s.dernier_prix,
    s.volume_recent
FROM pair_trading p
JOIN LATERAL (
    SELECT
        trad_prix AS dernier_prix,
        SUM(trad_quantite) AS volume_recent
    FROM trades
    WHERE paire_id = p.pair_id
    ORDER BY date_execution DESC
    LIMIT 10
) s ON TRUE;
