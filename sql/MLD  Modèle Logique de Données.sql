-- UTILISATEUR
CREATE TABLE utilisateurs (
  id SERIAL PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  date_inscription DATE NOT NULL DEFAULT CURRENT_DATE,
  statut VARCHAR(10) CHECK (statut IN ('actif', 'inactif')) DEFAULT 'actif'
);
CREATE INDEX idx_utilisateurs_email ON utilisateurs(email);

-- CRYPTO
CREATE TABLE cryptomonnaies (
  id SERIAL PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  symbole VARCHAR(10) NOT NULL UNIQUE,
  date_creation DATE,
  statut VARCHAR(10) CHECK (statut IN ('active', 'inactive')) DEFAULT 'active'
);
CREATE UNIQUE INDEX idx_crypto_symbole ON cryptomonnaies(symbole);

-- PAIRE_TRADING
CREATE TABLE paire_trading (
  id SERIAL PRIMARY KEY,
  crypto_base INT REFERENCES cryptomonnaies(id),
  crypto_contre INT REFERENCES cryptomonnaies(id),
  statut VARCHAR(10) CHECK (statut IN ('active', 'inactive')) DEFAULT 'active',
  date_ouverture DATE NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (crypto_base, crypto_contre)
);
CREATE INDEX idx_paire_trading_base_contre ON paire_trading(crypto_base, crypto_contre);

-- PORTEFEUILLE
CREATE TABLE portefeuilles (
  id SERIAL PRIMARY KEY,
  utilisateur_id INT NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
  solde_total NUMERIC(24,8) NOT NULL DEFAULT 0,
  solde_bloque NUMERIC(24,8) NOT NULL DEFAULT 0,
  date_maj TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_portefeuille_user ON portefeuilles(utilisateur_id); -- 1:1

-- ORDRES (partitionnée par date)
CREATE TABLE ordres (
  id BIGSERIAL PRIMARY KEY,
  utilisateur_id INT NOT NULL REFERENCES utilisateurs(id),
  paire_id INT NOT NULL REFERENCES paire_trading(id),
  type_ordre VARCHAR(4) CHECK (type_ordre IN ('Buy', 'Sell')),
  mode VARCHAR(10) CHECK (mode IN ('Market', 'Limit')),
  quantite NUMERIC(24,8) NOT NULL,
  prix NUMERIC(24,8),
  statut VARCHAR(15) CHECK (statut IN ('en_attente', 'execute', 'annule')) DEFAULT 'en_attente',
  date_creation TIMESTAMP NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (date_creation);

-- Création de partitions mensuelles
CREATE TABLE ordres_2025_12 PARTITION OF ordres
  FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');
-- (Ajouter d'autres partitions selon besoin)

-- Index stratégiques
CREATE INDEX idx_ordres_user_statut ON ordres(utilisateur_id, statut) WHERE statut = 'en_attente';
CREATE INDEX idx_ordres_paire_date ON ordres(paire_id, date_creation);
CREATE INDEX CONCURRENTLY idx_ordres_covering ON ordres(id, paire_id, prix, quantite, statut)
  INCLUDE (utilisateur_id, date_creation); -- pour index-only scan

-- TRADES (partitionnée par date_execution)
CREATE TABLE trades (
  id BIGSERIAL PRIMARY KEY,
  ordre_id BIGINT NOT NULL REFERENCES ordres(id) ON DELETE CASCADE,
  prix NUMERIC(24,8) NOT NULL,
  quantite NUMERIC(24,8) NOT NULL,
  date_execution TIMESTAMP NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (date_execution);

CREATE TABLE trades_2025_12 PARTITION OF trades
  FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- Index
CREATE INDEX idx_trades_ordre ON trades(ordre_id);
CREATE INDEX idx_trades_paire_date ON trades(prix, quantite, date_execution);

-- PRIX_MARCHE (partitionnée par date_maj)
CREATE TABLE prix_marche (
  id BIGSERIAL PRIMARY KEY,
  paire_id INT NOT NULL REFERENCES paire_trading(id),
  prix NUMERIC(24,8) NOT NULL,
  volume NUMERIC(30,8) NOT NULL,
  date_maj TIMESTAMP NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (date_maj);

CREATE TABLE prix_marche_2025_12 PARTITION OF prix_marche
  FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

CREATE INDEX idx_prix_paire_date ON prix_marche(paire_id, date_maj DESC);

-- STATISTIQUE_MARCHE
CREATE TABLE statistique_marche (
  id BIGSERIAL PRIMARY KEY,
  paire_id INT NOT NULL REFERENCES paire_trading(id),
  indicateur VARCHAR(20) NOT NULL,
  valeur NUMERIC(24,8) NOT NULL,
  periode VARCHAR(10) NOT NULL, -- ex: '24h', '7j'
  date_maj TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE (paire_id, indicateur, periode)
);
CREATE INDEX idx_stat_marche_paire ON statistique_marche(paire_id, date_maj DESC);

-- DETECTION_ANOMALIE
CREATE TABLE detection_anomalie (
  id BIGSERIAL PRIMARY KEY,
  type VARCHAR(30) NOT NULL,
  ordre_id BIGINT REFERENCES ordres(id),
  utilisateur_id INT REFERENCES utilisateurs(id),
  date_detection TIMESTAMP NOT NULL DEFAULT NOW(),
  commentaire TEXT
);
CREATE INDEX idx_anomalie_user ON detection_anomalie(utilisateur_id);
CREATE INDEX idx_anomalie_ordre ON detection_anomalie(ordre_id);

-- AUDIT_TRAIL (partitionnée par date_action)
CREATE TABLE audit_trail (
  id BIGSERIAL PRIMARY KEY,
  table_cible VARCHAR(50) NOT NULL,
  record_id BIGINT NOT NULL,
  action VARCHAR(10) CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
  utilisateur_id INT REFERENCES utilisateurs(id),
  date_action TIMESTAMP NOT NULL DEFAULT NOW(),
  details JSONB
) PARTITION BY RANGE (date_action);

CREATE TABLE audit_trail_2025_12 PARTITION OF audit_trail
  FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- Index pour audit rapide
CREATE INDEX idx_audit_table_record ON audit_trail(table_cible, record_id);
CREATE INDEX idx_audit_user_date ON audit_trail(utilisateur_id, date_action DESC);