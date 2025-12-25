
-- PORTEFEUILLE
CREATE TABLE portefeuilles (
  id SERIAL PRIMARY KEY,
  utilisateur_id INT NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
  solde_total NUMERIC(24,8) NOT NULL DEFAULT 0,
  solde_bloque NUMERIC(24,8) NOT NULL DEFAULT 0,
  date_maj TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_portefeuille_user ON portefeuilles(utilisateur_id); -- 1:1

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
