ROLLBACK;

SET search_path = public;

-- =====================================================
--  NETTOYAGE PROPRE (PARENTS UNIQUEMENT)
-- =====================================================
TRUNCATE TABLE
    audit_trail,
    detection_anomalies,
    statique_marché,
    prix_marché,
    trades,
    tbl_ordress,
    tbl_portfeuilles,
    pair_trading,
    tbl_cryptomonais,
    tbl_utilisateur
RESTART IDENTITY CASCADE;

-- =====================================================
--  UTILISATEURS
-- =====================================================
DO $$
BEGIN
INSERT INTO tbl_utilisateur (nom, email, date_inscription, statut_utilis)
SELECT
    'User_' || g,
    'user' || g || '@mail.com',
    CURRENT_DATE - (random()*365)::int,
    'ACTIF'
FROM generate_series(1,1000) g;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Utilisateurs ignorés';
END;
$$;

-- =====================================================
--  CRYPTOS
-- =====================================================
INSERT INTO tbl_cryptomonais (nom_crypt, symbole, statut_crypt)
VALUES
('Bitcoin','BTC','ACTIVE'),
('Ethereum','ETH','ACTIVE'),
('USDT','USDT','ACTIVE'),
('Solana','SOL','ACTIVE'),
('Cardano','ADA','ACTIVE');

-- =====================================================
--  PAIRS
-- =====================================================
INSERT INTO pair_trading (crypto_base, crypto_contre, pair_statut, date_ouverture)
SELECT
    c1.crypt_id,
    c2.crypt_id,
    'ACTIVE',
    CURRENT_DATE
FROM tbl_cryptomonais c1
JOIN tbl_cryptomonais c2 ON c1.crypt_id < c2.crypt_id;

-- =====================================================
--  PORTFEUILLES (soldes sûrs)
-- =====================================================
INSERT INTO tbl_portfeuilles (utili_id, crypto_id, solde_total, solde_bloque)
SELECT
    u.utili_id,
    c.crypt_id,
    1000000,
    0
FROM tbl_utilisateur u
CROSS JOIN tbl_cryptomonais c;

-- =====================================================
--  ORDRES (SAFE RANGE POUR PARTITIONS)
-- =====================================================
DO $$
BEGIN
INSERT INTO tbl_ordress (
    utili_id, paire_id, type_ordres, mode,
    quantité, prix, ordres_statut, date_creation
)
SELECT
    (SELECT utili_id FROM tbl_utilisateur ORDER BY random() LIMIT 1),
    (SELECT pair_id FROM pair_trading ORDER BY random() LIMIT 1),
    'BUY',
    'LIMIT',
    1,
    30000,
    'EN_ATTENTE',
    TIMESTAMPTZ '2025-12-15'
FROM generate_series(1,200000);
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Ordres partiellement insérés';
END;
$$;

-- =====================================================
-- TRADES (FK SAFE)
-- =====================================================
ALTER TABLE trades DISABLE TRIGGER ALL;

INSERT INTO trades (orders_id, trad_prix, trad_quantite, date_execution)
SELECT
    id,
    prix,
    quantité,
    date_creation + interval '10 seconds'
FROM tbl_ordress
LIMIT 100000;

ALTER TABLE trades ENABLE TRIGGER ALL;

-- =====================================================
--  PRIX MARCHÉ
-- =====================================================
INSERT INTO prix_marché (paire_id, prix_march, volume, date_maj)
SELECT
    pair_id,
    random()*50000+1000,
    random()*1000,
    NOW()
FROM pair_trading;

INSERT INTO statique_marché (paire_id, indicateur, valeur, period, date_maj)
SELECT pair_id, 'RSI', (random()*100), '1D', NOW() FROM pair_trading;
