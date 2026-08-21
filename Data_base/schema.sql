-- =====================================================================
-- MICR_Project — Mouvement International du Christ Ressuscité (Kara, Togo)
-- Fichier    : database/schema.sql
-- Rôle       : Schéma complet de la base micr_db (8 tables)
-- SGBD       : MySQL 8.x — moteur InnoDB — charset utf8mb4
-- Branche    : feature/database
-- Version    : 1.0 — Août 2026
-- ---------------------------------------------------------------------
-- EXECUTION :
--   mysql -u root -p < database/schema.sql
--   (ou : phpMyAdmin > Importer > schema.sql)
--
-- Ce fichier est IDEMPOTENT : il peut être ré-exécuté sans erreur.
-- Il ne SUPPRIME jamais de données (aucun DROP).
-- Pour repartir de zéro, voir la section "Reset" du README.md.
--
-- ORDRE DE CREATION (dépendances de clés étrangères) :
--   1. users        (aucune FK)
--   2. categories   (aucune FK)
--   3. orateurs     -> users
--   4. sermons      -> orateurs, categories
--   5. events       (aucune FK)
--   6. donations    (aucune FK)
--   7. contacts     (aucune FK)
--   8. newsletter   (aucune FK)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS micr_db
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE micr_db;

-- Sécurité d'exécution : pas de troncature silencieuse des données.
SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ENGINE_SUBSTITUTION';


-- =====================================================================
-- 1. users — Comptes admin & membres
-- ---------------------------------------------------------------------
-- password_hash : bcrypt UNIQUEMENT (jamais de mot de passe en clair).
-- last_login    : REQUIS par Django AbstractBaseUser (voir README section 6).
-- =====================================================================
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


-- =====================================================================
-- 2. categories — Catégories de prédications
-- ---------------------------------------------------------------------
-- slug : identifiant URL (ex: /sermons/enseignement-biblique)
-- =====================================================================
CREATE TABLE IF NOT EXISTS categories (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nom         VARCHAR(120) NOT NULL,
  slug        VARCHAR(140) NOT NULL UNIQUE,
  description TEXT         NULL,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Catégories de classement des prédications';


-- =====================================================================
-- 3. orateurs — Pasteurs & intervenants
-- ---------------------------------------------------------------------
-- Relation 1->1 vers users : user_id est UNIQUE (un compte = un orateur max).
-- user_id NULLABLE : un orateur invité n'a pas forcément de compte.
-- ON DELETE SET NULL : supprimer un compte ne supprime ni l'orateur
-- ni ses prédications (le contenu éditorial est conservé).
-- =====================================================================
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


-- =====================================================================
-- 4. sermons — Prédications publiées
-- ---------------------------------------------------------------------
-- publie : 0 = brouillon (invisible côté public), 1 = en ligne.
-- duree  : en minutes (NULL pour le type 'texte').
-- =====================================================================
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

  -- Requête principale du site : sermons publiés, du plus récent au plus ancien.
  INDEX idx_sermons_publie_created (publie, created_at),
  INDEX idx_sermons_type           (type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Prédications vidéo / audio / texte';


-- =====================================================================
-- 5. events — Événements & programmes
-- ---------------------------------------------------------------------
-- date_fin NULL = événement d'une seule journée / sans fin annoncée.
-- CHECK : garantit que la fin ne précède jamais le début (MySQL 8+).
-- =====================================================================
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

  -- Requête principale : agenda à venir, trié par date.
  INDEX idx_events_statut_debut (statut, date_debut),
  INDEX idx_events_date_debut   (date_debut)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Événements, cultes et programmes de l''église';


-- =====================================================================
-- 6. donations — Dons reçus
-- ---------------------------------------------------------------------
-- Table volontairement SANS clé étrangère : un don peut être anonyme.
-- reference : identifiant fourni par l'opérateur (Flooz, Mix by Yas...).
--   UNIQUE pour bloquer le double-encaissement d'un même paiement
--   (callback rejoué par l'opérateur).
--   NULLABLE : MySQL autorise plusieurs NULL sur un index UNIQUE.
-- devise : XOF par défaut (Franc CFA, Togo).
-- =====================================================================
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

  -- Requête principale du tableau de bord : dons confirmés par période.
  INDEX idx_donations_statut_created (statut, created_at),
  INDEX idx_donations_methode        (methode)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Dons — Mobile Money, carte bancaire, virement';


-- =====================================================================
-- 7. contacts — Formulaire de contact & demandes de prière
-- ---------------------------------------------------------------------
-- statut_lu : 0 = non lu (badge admin), 1 = traité.
-- =====================================================================
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

  -- Requête principale de l'admin : messages non lus, plus récents d'abord.
  INDEX idx_contacts_lu_created (statut_lu, created_at),
  INDEX idx_contacts_type       (type),
  INDEX idx_contacts_email      (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Messages du formulaire de contact et demandes de prière';


-- =====================================================================
-- 8. newsletter — Abonnés newsletter
-- ---------------------------------------------------------------------
-- token_desinscription : UUID v4 généré côté backend, utilisé dans le lien
--   de désinscription (obligation légale). UNIQUE + NOT NULL.
-- actif : désinscription = passage à 0, la ligne n'est PAS supprimée
--   (preuve de la demande de désinscription conservée).
-- =====================================================================
CREATE TABLE IF NOT EXISTS newsletter (
  id                   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email                VARCHAR(160) NOT NULL UNIQUE,
  actif                TINYINT(1)   NOT NULL DEFAULT 1,
  token_desinscription CHAR(36)     NOT NULL UNIQUE COMMENT 'UUID v4 généré par le backend',
  created_at           TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_newsletter_actif (actif)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Abonnés à la newsletter MICR';


-- =====================================================================
-- Fin du schéma — 8 tables.
-- Vérification :  SHOW TABLES;  puis  SHOW CREATE TABLE sermons;
-- =====================================================================
