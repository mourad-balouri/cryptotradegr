# 🚀 CryptoTrade  
## Conception et Optimisation d’une Base de Données PostgreSQL  
### Plateforme de Trading de Cryptomonnaies en Temps Réel

---

## 🔗 Liens du projet

- **Trello – Suivi des tâches et jalons :**  
  👉 https://trello.com/invite/b/694a60301d481ada6a1a2b9f/ATTI3d7d8787e091b04150121dd63b489cb729867C06/crypto

---

## 📅 Informations générales

- **Nom du projet :** CryptoTrade  
- **Domaine :** Trading de cryptomonnaies en temps réel  
- **SGBD :** PostgreSQL  
- **Cadre :** Projet académique – Data & Performance Engineering  
- **Période de réalisation :** 22 → 26 décembre 2025  

---

## 👥 Équipe projet

- Mourad Balouri  
- Chaimaa Maach  
- Hiba Azizi  
- Hassan Issil  

---

## 🧩 1. Contexte du projet

CryptoTrade est une **plateforme de trading de cryptomonnaies en temps réel** permettant aux utilisateurs de :

- Passer des ordres d’achat et de vente (BUY / SELL / LIMIT / MARKET)
- Suivre l’évolution des prix et des volumes du marché
- Gérer des portefeuilles multi-cryptomonnaies
- Accéder à un historique complet des transactions
- Analyser le marché via des indicateurs financiers avancés
- Détecter des comportements suspects ou frauduleux

La plateforme doit supporter **des millions d’ordres par jour**, tout en garantissant une **latence minimale**, une **cohérence forte des données**, et une **traçabilité complète**.

---

## ⚠️ 2. Problèmes identifiés dans le système initial

L’analyse de l’existant a révélé plusieurs limitations critiques :

- Latence élevée pour l’affichage du carnet d’ordres (> 500 ms)
- Requêtes analytiques lentes (> 10 secondes)
- Deadlocks fréquents lors de mises à jour concurrentes
- Génération excessive de fichiers temporaires (temp file spills)
- Mauvaises estimations du planner PostgreSQL
- Retards d’autovacuum sur tables volumineuses
- Faible efficacité des HOT updates

---

## 🎯 3. Objectifs du projet

### Objectifs métier
- Assurer un trading rapide et fiable
- Fournir des indicateurs de marché précis et à jour
- Garantir l’intégrité des portefeuilles utilisateurs
- Faciliter l’audit et la conformité réglementaire
- Identifier les comportements de marché suspects

### Objectifs techniques
- Concevoir une base robuste limitée à **10 tables clés**
- Optimiser les performances transactionnelles et analytiques
- Gérer efficacement la concurrence
- Exploiter les fonctionnalités avancées de PostgreSQL
- Mettre en place un monitoring et un tuning adaptés

---

## 🏗️ 4. Démarche de conception

### Modélisation des données
- **MCD :** identification des entités et règles métier
- **MRD :** normalisation stricte (1FN → 3FN)
- **MLD :** types PostgreSQL, contraintes, index et partitionnement

---

## 📦 5. Tables principales (10)

1. `tbl_utilisateur`  
2. `tbl_cryptomonais`  
3. `pair_trading`  
4. `tbl_portfeuilles`  
5. `tbl_ordress`  
6. `trades`  
7. `prix_marché`  
8. `statique_marché`  
9. `detection_anomalies`  
10. `audit_trail`  

---

## 🛠️ 6. Implémentation PostgreSQL

### Création des tables
**Script :** `creation_des_tables_trade.sql`

- Clés primaires et étrangères
- Contraintes CHECK et UNIQUE
- Application directe des règles métier
- Gestion des dates et statuts

---

## 📂 7. Partitionnement

| Table | Type | Clé |
|------|------|-----|
| `tbl_ordress` | RANGE | `date_creation` |
| `trades` | RANGE | `date_execution` |
| `audit_trail` | LIST | `action` |

Objectifs :
- Améliorer les performances d’insertion
- Accélérer les requêtes historiques
- Simplifier la maintenance

---

## ⚡ 8. Indexation et optimisation

**Script :** `creation_index.sql`

- Index B-tree pour jointures et filtres
- Index partiels pour données actives
- Index couvrants pour dashboards
- Index GIN pour recherche textuelle
- Index temporels pour données récentes

---

## 📊 9. Analyses SQL avancées

### LATERAL joins
**Script :** `LATERAL joins.sql`

Utilisés pour :
- Calculer des statistiques par utilisateur
- Réaliser des analyses dynamiques par paire de trading
- Optimiser les sous-requêtes corrélées

### Indicateurs de marché
**Script :** `indicateurs_marché.sql`

Indicateurs implémentés :
- VWAP
- RSI
- Volatilité

---

## 📈 10. Vues matérialisées

- `mv_vwap`
- `mv_rsi`
- `mv_volatilite`

Rôle :
- Pré-calcul des indicateurs lourds
- Réduction du temps de réponse
- Allègement des tables transactionnelles

---

## 🔒 11. Gestion de la concurrence

- Advisory locks pour sécuriser les mises à jour critiques
- Isolation transactionnelle SERIALIZABLE
- Prévention des deadlocks
- Garantie de cohérence des soldes utilisateurs

---

## 📊 12. Tuning & Monitoring

Afin d’optimiser les performances et la stabilité de la base **CryptoTrade**, plusieurs actions de tuning et de monitoring ont été mises en place.

### Tuning des performances
- Ajustement dynamique du paramètre `work_mem` pour éviter les **temp file spills** lors des requêtes analytiques
- Configuration du `fillfactor` sur les tables à forte mise à jour afin d’optimiser les **HOT updates** et réduire le **vacuum lag**
- Optimisation du comportement sous forte concurrence via advisory locks

### Monitoring
- Activation de `pg_stat_statements` pour identifier les requêtes coûteuses
- Utilisation de `auto_explain` pour analyser les plans d’exécution
- Surveillance de l’activité via `pg_stat_activity`, `pg_locks` et `pg_stat_io`

Ces mécanismes permettent une observation continue des performances et une optimisation proactive.

---

## 🧪 13. Tests et validation

### Tests fonctionnels
- Cycle de vie des ordres
- Cohérence des portefeuilles
- Exactitude des indicateurs
- Détection des anomalies

### Tests de performance
- EXPLAIN ANALYZE
- Comparaison avant / après indexation
- Validation du partitionnement

### Tests de concurrence
- Exécutions parallèles
- Simulation de contention
- Vérification de l’absence de deadlocks

---

## 🏁 14. Conclusion

Ce projet démontre qu’une **base PostgreSQL correctement conçue et optimisée** peut répondre aux exigences élevées d’un système de **trading de cryptomonnaies en temps réel**.

Grâce à une modélisation rigoureuse, une indexation adaptée, l’utilisation de fonctionnalités SQL avancées et un travail approfondi sur les performances et la concurrence, **CryptoTrade** constitue une solution robuste, scalable et cohérente, prête à évoluer vers un environnement de production réel.

---


