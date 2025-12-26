-- =====================================================
-- VUES MATÉRIALISÉES POUR INDICATEURS DE MARCHÉ
-- =====================================================

--  VWAP (Volume Weighted Average Price) par paire
CREATE MATERIALIZED VIEW mv_vwap AS
SELECT
    o.paire_id,
    SUM(t.trad_prix * t.trad_quantite) / NULLIF(SUM(t.trad_quantite),0) AS vwap,
    MAX(t.date_execution) AS date_maj
FROM trades t
JOIN tbl_ordress o ON t.orders_id = o.id
WHERE t.date_execution >= NOW() - INTERVAL '24 hours'
GROUP BY o.paire_id;

-- Index unique requis pour REFRESH CONCURRENTLY
CREATE UNIQUE INDEX idx_mv_vwap_paire_unique
ON mv_vwap(paire_id);

-- Index supplémentaire pour accès rapide
CREATE INDEX idx_mv_vwap_paire ON mv_vwap(paire_id);


--  RSI (Relative Strength Index) par paire
CREATE MATERIALIZED VIEW mv_rsi AS
WITH base AS (
    SELECT
        o.paire_id,
        t.date_execution,
        t.trad_prix - LAG(t.trad_prix) OVER (
            PARTITION BY o.paire_id
            ORDER BY t.date_execution
        ) AS variation
    FROM trades t
    JOIN tbl_ordress o ON t.orders_id = o.id
)
SELECT
    paire_id,
    100 - (100 / (1 +
        AVG(CASE WHEN variation > 0 THEN variation ELSE 0 END)
        /
        NULLIF(AVG(CASE WHEN variation < 0 THEN ABS(variation) ELSE 0 END), 0)
    )) AS rsi
FROM base
GROUP BY paire_id;
CREATE UNIQUE INDEX idx_mv_rsi_paire_unique
ON mv_rsi(paire_id);






--  Volatilité par heure et par paire
CREATE MATERIALIZED VIEW mv_volatilite AS
SELECT
    o.paire_id,
    date_trunc('hour', t.date_execution) AS heure,
    STDDEV(t.trad_prix) AS volatilite
FROM trades t
JOIN tbl_ordress o ON t.orders_id = o.id
GROUP BY o.paire_id, date_trunc('hour', t.date_execution);

-- Index unique requis pour REFRESH CONCURRENTLY
CREATE UNIQUE INDEX idx_mv_volatilite_unique
ON mv_volatilite(paire_id, heure);




-- =====================================================
-- RAFRAÎCHISSEMENT DES VUES MATÉRIALISÉES
-- =====================================================
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_vwap;
REFRESH MATERIALIZED VIEW concurrently mv_rsi;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_volatilite;

















