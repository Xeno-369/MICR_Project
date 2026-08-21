-- =====================================================================
-- Migration 004 — Table donations (dons reçus)
-- Projet   : MICR_Project — feature/database
-- Dépend de: 001 (uniquement pour l'existence de la base micr_db)
-- Exécution: mysql -u root -p < database/migrations/004_create_donations.sql
-- =====================================================================

USE micr_db;

SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ENGINE_SUBSTITUTION';

-- ---------------------------------------------------------------------
-- donations
-- Aucune clé étrangère : un don peut être totalement anonyme.
-- reference UNIQUE : bloque le double-encaissement quand l'opérateur
--   Mobile Money rejoue son callback. NULLABLE (MySQL accepte
--   plusieurs NULL sur un index UNIQUE).
-- devise : XOF par défaut (Franc CFA, Togo).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS donations (
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  montant        DECIMAL(10,2) NOT NULL,
  devise         VARCHAR(10)   NOT NULL DEFAULT 'XOF',
  methode        ENUM('flooz','mix_by_yas','carte_bancaire','virement') NOT NULL,
  reference      VARCHAR(100)  NULL DEFAULT NULL UNIQUE,
  statut         ENUM('en_attente','confirme','echoue') NOT NULL DEFAULT 'en_attente',
  donateur_nom   VARCHAR(160)  NULL,
  donateur_email VARCHAR(160)  NULL,
  created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT chk_donations_montant CHECK (montant > 0),

  INDEX idx_donations_statut_created (statut, created_at),
  INDEX idx_donations_methode        (methode)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Dons — Mobile Money, carte bancaire, virement';

-- ROLLBACK (manuel) :
--   DROP TABLE IF EXISTS donations;
