SET search_path = public;

-- -------------------------- tbl_ordress (ORDRES)---------------------------------


--  B-tree : Recherche des ordres par utilisateur
CREATE INDEX idx_ordres_utilisateur
ON public.tbl_ordress (utili_id);

--  B-tree : Recherche des ordres par paire de trading
CREATE INDEX idx_ordres_paire
ON public.tbl_ordress (paire_id);

--  B-tree : Tri et filtrage par date de création
CREATE INDEX idx_ordres_date_creation
ON public.tbl_ordress (date_creation);

--  Index PARTIAL B-tree : Carnet d’ordres (ordres actifs uniquement)
CREATE INDEX idx_ordres_en_attente
ON public.tbl_ordress (paire_id, date_creation)
WHERE ordres_statut = 'EN_ATTENTE';

--  Index COVERING (Index-only scan) : Dashboard utilisateur
CREATE INDEX idx_ordres_covering_utilisateur
ON public.tbl_ordress (utili_id, date_creation DESC)
INCLUDE (type_ordres, quantité, prix, ordres_statut);

--  Index GIN (optionnel / avancé) : Recherche textuelle sur type d’ordre
-- Utile si des recherches analytiques ou futures extensions textuelles sont prévues
CREATE INDEX idx_ordres_type_gin
ON public.tbl_ordress
USING GIN (to_tsvector('french', type_ordres));

---------------------- LES INDEX SUR LA TABLE PRIX_MARCHé------------------------------

-- B-tree : accès par paire
CREATE INDEX idx_prix_marche_paire
ON prix_marché (paire_id);

-- B-tree : accès temporel
CREATE INDEX idx_prix_marche_date
ON prix_marché (date_maj);

-- Partial index : données marché récentes (24h)
CREATE INDEX idx_prix_marche_recent
ON prix_marché (paire_id, date_maj DESC)
WHERE date_maj >= now() - INTERVAL '24 hours';

-- Covering index : dashboard prix temps réel
CREATE INDEX idx_prix_marche_covering
ON prix_marché (paire_id, date_maj DESC)
INCLUDE (prix_march, volume);

-- GIN (optionnel / analytique avancé)
CREATE INDEX idx_prix_marche_gin
ON prix_marché
USING GIN (to_tsvector('french', prix_march::text))


-- --------------------table TRADES-----------------------------

--  B-tree : retrouver rapidement les trades liés à un ordre
CREATE INDEX idx_trades_ordre_id
ON trades USING BTREE (ordre_id);

--  B-tree : requêtes temporelles (historique, backtesting)
CREATE INDEX idx_trades_date_execution
ON trades USING BTREE (date_execution);

-------------------------

--  Ajouter une colonne bool pour signaler si le trade est récent
ALTER TABLE trades ADD COLUMN is_recent_24h BOOLEAN DEFAULT FALSE;

--  Trigger pour mettre à jour la colonne
CREATE OR REPLACE FUNCTION update_recent_flag()
RETURNS TRIGGER AS $$
BEGIN
    NEW.is_recent_24h := NEW.date_execution >= now() - INTERVAL '24 hours';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_recent
BEFORE INSERT OR UPDATE ON trades
FOR EACH ROW EXECUTE FUNCTION update_recent_flag();

--  Index partiel basé sur la colonne booléenne
CREATE INDEX idx_trades_recent_24h
ON trades(date_execution DESC)
WHERE is_recent_24h = TRUE;


--  Covering index : lecture rapide sans accès table (index-only scan)
CREATE INDEX idx_trades_covering_dashboard
ON trades USING BTREE (ordre_id, date_execution DESC)
INCLUDE (prix, quantite);


----------------------Table Audit-trail-------------------------------- 


--  B-tree : retrouver rapidement les audits par utilisateur
CREATE INDEX idx_audit_trail_utilisateur
ON audit_trail USING BTREE (utili_id);

--  B-tree : requêtes temporelles (audit par période)
CREATE INDEX idx_audit_trail_date_action
ON audit_trail USING BTREE (date_action DESC);

--  B-tree : audit d’un enregistrement précis
CREATE INDEX idx_audit_trail_table_record
ON audit_trail USING BTREE (table_cible, audit_id);

--  Partial B-tree : accès rapide aux actions critiques (DELETE)
CREATE INDEX idx_audit_trail_delete_only
ON audit_trail USING BTREE (date_action DESC)
WHERE action = 'DELETE';

--  Covering index : lecture rapide des journaux sans accès table
CREATE INDEX idx_audit_trail_covering
ON audit_trail USING BTREE (utili_id, date_action DESC)
INCLUDE (action, table_cible, audit_id);

--  GIN : recherche full-text dans les détails d’audit
CREATE INDEX idx_audit_trail_details_gin
ON audit_trail USING GIN (to_tsvector('simple', details));


 




