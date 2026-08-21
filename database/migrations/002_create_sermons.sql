-- =====================================================================
-- Migration 002 — Module prédications : categories, orateurs, sermons
-- Projet   : MICR_Project — feature/database
-- Dépend de: 001 (orateurs.user_id -> users.id)
-- Exécution: mysql -u root -p < database/migrations/002_create_sermons.sql
-- ---------------------------------------------------------------------
-- NOTE : les 3 tables sont dans la MÊME migration parce que sermons
-- ne peut pas exister sans orateurs ni categories (clés étrangères).
-- L'ordre à l'intérieur du fichier est imposé par les dépendances.
-- =====================================================================

USE micr_db;

SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ENGINE_SUBSTITUTION';

-- ---------------------------------------------------------------------
-- categories — Catégories de prédications
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nom         VARCHAR(120) NOT NULL,
  slug        VARCHAR(140) NOT NULL UNIQUE,
  description TEXT         NULL,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Catégories de classement des prédications';

-- ---------------------------------------------------------------------
-- orateurs — Pasteurs & intervenants (1-1 optionnel vers users)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orateurs (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nom        VARCHAR(80)  NOT NULL,
  prenom     VARCHAR(80)  NOT NULL,
  photo_url  VARCHAR(512) NULL,
  biographie TEXT         NULL,
  user_id    INT UNSIGNED NULL DEFAULT NULL,
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT uq_orateurs_user UNIQUE (user_id),
  CONSTRAINT fk_orateurs_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Pasteurs et intervenants — relation 1-1 optionnelle vers users';

-- ---------------------------------------------------------------------
-- sermons — Prédications publiées
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sermons (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  titre        VARCHAR(255) NOT NULL,
  description  TEXT         NULL,
  type         ENUM('video','audio','texte') NOT NULL,
  url_media    VARCHAR(512) NULL,
  orateur_id   INT UNSIGNED NULL DEFAULT NULL,
  categorie_id INT UNSIGNED NULL DEFAULT NULL,
  duree        INT UNSIGNED NULL COMMENT 'Durée en minutes',
  vues         INT UNSIGNED NOT NULL DEFAULT 0,
  publie       TINYINT(1)   NOT NULL DEFAULT 0,
  created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_sermons_orateur FOREIGN KEY (orateur_id)
    REFERENCES orateurs(id)   ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_sermons_categorie FOREIGN KEY (categorie_id)
    REFERENCES categories(id) ON DELETE SET NULL ON UPDATE CASCADE,

  INDEX idx_sermons_publie_created (publie, created_at),
  INDEX idx_sermons_type           (type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Prédications vidéo / audio / texte';

-- ROLLBACK (manuel, ordre inverse des dépendances) :
--   DROP TABLE IF EXISTS sermons;
--   DROP TABLE IF EXISTS orateurs;
--   DROP TABLE IF EXISTS categories;
