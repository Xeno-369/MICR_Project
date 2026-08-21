-- =====================================================================
-- Migration 001 — Création de la base micr_db + table users
-- Projet   : MICR_Project — feature/database
-- Dépend de: rien (première migration)
-- Exécution: mysql -u root -p < database/migrations/001_create_users.sql
-- =====================================================================

CREATE DATABASE IF NOT EXISTS micr_db
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE micr_db;

SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ENGINE_SUBSTITUTION';

-- ---------------------------------------------------------------------
-- users — Comptes admin & membres
-- password_hash : bcrypt uniquement.
-- last_login    : requis par Django AbstractBaseUser.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nom           VARCHAR(80)  NOT NULL,
  prenom        VARCHAR(80)  NOT NULL,
  email         VARCHAR(160) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role          ENUM('admin','membre','visiteur') NOT NULL DEFAULT 'visiteur',
  actif         TINYINT(1)   NOT NULL DEFAULT 1,
  last_login    DATETIME     NULL DEFAULT NULL COMMENT 'Requis par Django AbstractBaseUser',
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_users_role_actif (role, actif),
  INDEX idx_users_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Comptes admin et membres du site MICR';

-- ROLLBACK (manuel, à ne PAS exécuter en production) :
--   DROP TABLE IF EXISTS users;
