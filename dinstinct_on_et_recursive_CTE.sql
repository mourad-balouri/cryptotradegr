
-- INDICATEURS DE MARCHÉ & ANALYSES AVANCÉES
-- Modèle personnel corrigé

SET search_path = public;


--  DERNIER PRIX CONNU PAR PAIRE (DISTINCT ON)

SELECT DISTINCT ON (o.paire_id)
    pt.crypto_base,
    pt.crypto_contre,
    t.trad_prix       AS dernier_prix,
    t.date_execution AS date_maj
FROM trades t
JOIN tbl_ordress o   ON o.id = t.orders_id
JOIN pair_trading pt ON pt.pair_id = o.paire_id
ORDER BY o.paire_id, t.date_execution DESC;


-- STATISTIQUES AVANCÉES PAR UTILISATEUR (LATERAL JOIN)

SELECT
    u.nom,
    stats.dernier_ordre,
    stats.volume_total
FROM tbl_utilisateur u
CROSS JOIN LATERAL (
    SELECT
        MAX(o.date_creation)          AS dernier_ordre,
        SUM(o.prix * o.quantité)      AS volume_total
    FROM tbl_ordress o
    WHERE o.utili_id = u.utili_id
) stats
WHERE u.statut_utilis = 'ACTIF'
LIMIT 10;



--  DÉTECTION DE CHAÎNES DE TRADES SUSPECTES (CTE RÉCURSIVE)

WITH RECURSIVE chaine_suspecte AS (

    --  Trade initial BUY / SELL très rapproché
    SELECT
        t.trades_id,
        t.orders_id,
        o_buy.utili_id  AS acheteur,
        o_sell.utili_id AS vendeur,
        1               AS profondeur
    FROM trades t
    JOIN tbl_ordress o_buy
        ON t.orders_id = o_buy.id
       AND o_buy.type_ordres = 'BUY'
    JOIN tbl_ordress o_sell
        ON o_sell.paire_id = o_buy.paire_id
       AND o_sell.type_ordres = 'SELL'
       AND o_sell.date_creation BETWEEN
           o_buy.date_creation - INTERVAL '1 second'
       AND o_buy.date_creation + INTERVAL '1 second'
    WHERE t.date_execution >= NOW() - INTERVAL '1 hour'

    UNION ALL

    --  Le vendeur rachète ensuite (cycle)
    SELECT
        t2.trades_id,
        t2.orders_id,
        o_buy2.utili_id,
        o_sell2.utili_id,
        cs.profondeur + 1
    FROM trades t2
    JOIN tbl_ordress o_buy2
        ON t2.orders_id = o_buy2.id
       AND o_buy2.type_ordres = 'BUY'
    JOIN tbl_ordress o_sell2
        ON o_sell2.paire_id = o_buy2.paire_id
       AND o_sell2.type_ordres = 'SELL'
    JOIN chaine_suspecte cs
        ON cs.vendeur = o_buy2.utili_id
    WHERE cs.profondeur < 5
)

SELECT *
FROM chaine_suspecte;
