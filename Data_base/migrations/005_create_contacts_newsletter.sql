-- =====================================================================
-- Migration 005 — Tables contacts & newsletter
-- Projet   : MICR_Project — feature/database
-- Dépend de: 001 (uniquement pour l'existence de la base micr_db)
-- Exécution: mysql -u root -p < database/migrations/005_create_contacts_newsletter.sql
-- =====================================================================

USE micr_db;

SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ENGINE_SUBSTITUTION';

-- ---------------------------------------------------------------------
-- contacts — Formulaire de contact & demandes de prière
-- statut_lu : 0 = non lu (badge admin), 1 = traité.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS contacts (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nom        VARCHAR(80)  NOT NULL,
  prenom     VARCHAR(80)  NULL,
  email      VARCHAR(160) NOT NULL,
  sujet      VARCHAR(255) NULL,
  message    TEXT         NOT NULL,
  type       ENUM('contact','priere') NOT NULL DEFAULT 'contact',
  statut_lu  TINYINT(1)   NOT NULL DEFAULT 0,
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_contacts_lu_created (statut_lu, created_at),
  INDEX idx_contacts_type       (type),
  INDEX idx_contacts_email      (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Messages du formulaire de contact et demandes de prière';

-- ---------------------------------------------------------------------
-- newsletter — Abonnés
-- token_desinscription : UUID v4 généré par le backend, sert au lien de
--   désinscription. UNIQUE + NOT NULL.
-- actif : une désinscription passe actif à 0, la ligne n'est PAS supprimée.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS newsletter (
  id                   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email                VARCHAR(160) NOT NULL UNIQUE,
  actif                TINYINT(1)   NOT NULL DEFAULT 1,
  token_desinscription CHAR(36)     NOT NULL UNIQUE COMMENT 'UUID v4 généré par le backend',
  created_at           TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_newsletter_actif (actif)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Abonnés à la newsletter MICR';

-- ROLLBACK (manuel) :
--   DROP TABLE IF EXISTS newsletter;
--   DROP TABLE IF EXISTS contacts;
