DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
SET search_path = public;

-- 1. TABLE UTILISATEUR

CREATE TABLE tbl_utilisateur (
    utili_id            BIGSERIAL PRIMARY KEY,
    nom                 VARCHAR(50) NOT NULL,
    email               VARCHAR(100) UNIQUE NOT NULL,
    date_inscription    DATE NOT NULL DEFAULT CURRENT_DATE,
    statut_utilis       VARCHAR(20) NOT NULL
        CHECK (statut_utilis IN ('ACTIF', 'INACTIF'))
);


-- 2. TABLE CRYPTOMONNAIE

CREATE TABLE tbl_cryptomonais (
    crypt_id        SERIAL PRIMARY KEY,
    nom_crypt       VARCHAR(50) NOT NULL,
    symbole         VARCHAR(10) UNIQUE NOT NULL,
    date_création   DATE,
    statut_crypt    VARCHAR(20) NOT NULL
        CHECK (statut_crypt IN ('ACTIVE', 'DESACTIVE'))
);

-
-- 3. TABLE PORTFEUILLE

CREATE TABLE tbl_portfeuilles (
    port_id         BIGSERIAL PRIMARY KEY,
    utili_id        BIGINT NOT NULL REFERENCES tbl_utilisateur(utili_id),
    crypto_id       INT NOT NULL REFERENCES tbl_cryptomonais(crypt_id),
    solde_total     NUMERIC(20,8) NOT NULL CHECK (solde_total >= 0),
    solde_bloque    NUMERIC(20,8) NOT NULL CHECK (solde_bloque >= 0),
    date_maj        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_portefeuille UNIQUE (utili_id, crypto_id),
    CONSTRAINT chk_solde CHECK (solde_total >= solde_bloque)
);

-- 4. TABLE PAIR TRADING

CREATE TABLE pair_trading (
    pair_id         SERIAL PRIMARY KEY,
    crypto_base     INT NOT NULL REFERENCES tbl_cryptomonais(crypt_id),
    crypto_contre   INT NOT NULL REFERENCES tbl_cryptomonais(crypt_id),
    pair_statut     VARCHAR(20) NOT NULL
        CHECK (pair_statut IN ('ACTIVE', 'SUSPENDUE')),
    date_ouverture  DATE NOT NULL,
    CONSTRAINT uq_pair UNIQUE (crypto_base, crypto_contre),
    CONSTRAINT chk_crypto_diff CHECK (crypto_base <> crypto_contre)
);


-- 5. TABLE ORDRES (PARTITIONNÉE)

CREATE TABLE tbl_ordress (
    id              BIGSERIAL,
    utili_id        BIGINT NOT NULL REFERENCES tbl_utilisateur(utili_id),
    paire_id        INT NOT NULL REFERENCES pair_trading(pair_id),
    type_ordres     VARCHAR(10) NOT NULL
        CHECK (type_ordres IN ('BUY', 'SELL')),
    mode            VARCHAR(10) NOT NULL
        CHECK (mode IN ('MARKET', 'LIMIT')),
    quantité        NUMERIC(20,8) NOT NULL CHECK (quantité > 0),
    prix            NUMERIC(20,8),
    ordres_statut   VARCHAR(20) NOT NULL
        CHECK (ordres_statut IN ('EN_ATTENTE', 'EXECUTE', 'ANNULE')),
    date_creation   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id, date_creation),
    CONSTRAINT chk_prix_mode CHECK (
        (mode = 'LIMIT' AND prix IS NOT NULL)
        OR
        (mode = 'MARKET' AND prix IS NULL)
    )
) PARTITION BY RANGE (date_creation);

CREATE TABLE tbl_ordress_2025_12
PARTITION OF tbl_ordress
FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

CREATE TABLE tbl_ordress_2026_01
PARTITION OF tbl_ordress
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE tbl_ordress_default
PARTITION OF tbl_ordress DEFAULT;


-- 6. TABLE TRADES (PARTITIONNÉE)

CREATE TABLE trades (
    trades_id       BIGSERIAL,
    orders_id       BIGINT NOT NULL,
    trad_prix       NUMERIC(20,8) NOT NULL CHECK (trad_prix > 0),
    trad_quantite   NUMERIC(20,8) NOT NULL CHECK (trad_quantite > 0),
    date_execution  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (trades_id, date_execution)
) PARTITION BY RANGE (date_execution);

CREATE TABLE trades_2025_12
PARTITION OF trades
FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

CREATE TABLE trades_default
PARTITION OF trades DEFAULT;


-- 7. PRIX MARCHÉ

CREATE TABLE prix_marché (
    march_id    BIGSERIAL PRIMARY KEY,
    paire_id    INT NOT NULL REFERENCES pair_trading(pair_id),
    prix_march  NUMERIC(20,8) NOT NULL CHECK (prix_march > 0),
    volume      NUMERIC(20,8) NOT NULL CHECK (volume >= 0),
    date_maj    TIMESTAMPTZ NOT NULL
);


-- 8. STATISTIQUES MARCHÉ

CREATE TABLE statique_marché (
    stat_id     BIGSERIAL PRIMARY KEY,
    paire_id    INT NOT NULL REFERENCES pair_trading(pair_id),
    indicateur  VARCHAR(50) NOT NULL,
    valeur      NUMERIC(20,8) NOT NULL,
    period      VARCHAR(20) NOT NULL,
    date_maj    TIMESTAMPTZ NOT NULL
);


-- 9. DÉTECTION ANOMALIES

CREATE TABLE detection_anomalies (
    det_id          BIGSERIAL PRIMARY KEY,
    type_detec      VARCHAR(50) NOT NULL,
    id_orders       BIGINT,
    utili_id        BIGINT REFERENCES tbl_utilisateur(utili_id),
    date_detection  TIMESTAMPTZ NOT NULL DEFAULT now(),
    commentaire     TEXT
);


-- 10. AUDIT TRAIL (PARTITIONNÉE PAR ACTION)

CREATE TABLE audit_trail (
    audit_id        BIGSERIAL,
    table_cible     VARCHAR(50) NOT NULL,
    id_orders       BIGINT NOT NULL,
    action          VARCHAR(10) NOT NULL
        CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    utili_id        BIGINT REFERENCES tbl_utilisateur(utili_id),
    date_action     TIMESTAMPTZ NOT NULL DEFAULT now(),
    details         TEXT,
    PRIMARY KEY (audit_id, action)
) PARTITION BY LIST (action);

CREATE TABLE audit_insert
PARTITION OF audit_trail FOR VALUES IN ('INSERT');

CREATE TABLE audit_update
PARTITION OF audit_trail FOR VALUES IN ('UPDATE');

CREATE TABLE audit_delete
PARTITION OF audit_trail FOR VALUES IN ('DELETE');
