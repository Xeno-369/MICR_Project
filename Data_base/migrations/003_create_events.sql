-- =====================================================================
-- Migration 003 — Table events (événements & programmes)
-- Projet   : MICR_Project — feature/database
-- Dépend de: 001 (uniquement pour l'existence de la base micr_db)
-- Exécution: mysql -u root -p < database/migrations/003_create_events.sql
-- =====================================================================

USE micr_db;

SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ENGINE_SUBSTITUTION';

-- ---------------------------------------------------------------------
-- events
-- date_fin NULL = événement d'une journée / sans fin annoncée.
-- CHECK : la fin ne peut jamais précéder le début (MySQL 8+).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS events (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  titre       VARCHAR(255) NOT NULL,
  description TEXT         NULL,
  date_debut  DATETIME     NOT NULL,
  date_fin    DATETIME     NULL DEFAULT NULL,
  lieu        VARCHAR(255) NULL,
  type        ENUM('culte','conference','seminaire','convention','croisade','autre')
               NOT NULL DEFAULT 'culte',
  statut      ENUM('a_venir','en_cours','termine','annule')
               NOT NULL DEFAULT 'a_venir',
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT chk_events_dates CHECK (date_fin IS NULL OR date_fin >= date_debut),

  INDEX idx_events_statut_debut (statut, date_debut),
  INDEX idx_events_date_debut   (date_debut)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Événements, cultes et programmes de l''église';

-- ROLLBACK (manuel) :
--   DROP TABLE IF EXISTS events;
