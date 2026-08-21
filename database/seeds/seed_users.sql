-- =====================================================================
-- SEED — users (données de test)
-- Projet   : MICR_Project — feature/database
-- Dépend de: migrations/001_create_users.sql
-- Exécution: mysql -u root -p < database/seeds/seed_users.sql
-- ---------------------------------------------------------------------
-- /!\ ENVIRONNEMENT DE DÉVELOPPEMENT UNIQUEMENT.
--     Ne JAMAIS charger ce fichier en production : les mots de passe
--     de test ci-dessous sont publics (ils sont dans le dépôt Git).
--
-- Mots de passe en clair correspondant aux hash bcrypt (cost 12) :
--   admin@micr-togo.org      -> Admin@MICR2026
--   e.tchalla@micr-togo.org  -> Pasteur@MICR2026
--   m.agbeko@micr-togo.org   -> Pasteur@MICR2026
--   tous les autres comptes  -> Membre@MICR2026
--
-- INSERT IGNORE : le fichier est ré-exécutable sans erreur de doublon
-- (email et id sont UNIQUE / PRIMARY KEY).
-- Les id sont fixés en dur car seed_sermons.sql y fait référence.
-- =====================================================================

USE micr_db;

INSERT IGNORE INTO users (id, nom, prenom, email, password_hash, role, actif) VALUES
  (1, 'ADJOVI',   'Kossi',    'admin@micr-togo.org',
      '$2b$12$wsP4Nolrjh8W/y7h1eqhZuUdgkXjNY/Jjesvxqhfm/s9gwPRxE5hu', 'admin',    1),
  (2, 'TCHALLA',  'Emmanuel', 'e.tchalla@micr-togo.org',
      '$2b$12$TbgfCOtMsXngCxq81F7Cw.LYagNhLl3o4rlAqA0w6RgYJPxaQQsO2', 'admin',    1),
  (3, 'AGBEKO',   'Marie',    'm.agbeko@micr-togo.org',
      '$2b$12$TbgfCOtMsXngCxq81F7Cw.LYagNhLl3o4rlAqA0w6RgYJPxaQQsO2', 'membre',   1),
  (4, 'MENSAH',   'Yao',      'yao.mensah@example.tg',
      '$2b$12$NHr3rKZJm1uJF6IzSVCEg.dmG0Z42QP9GhfWavfjpfKo22xMb0xv2', 'membre',   1),
  (5, 'KOUDJO',   'Afi',      'afi.koudjo@example.tg',
      '$2b$12$NHr3rKZJm1uJF6IzSVCEg.dmG0Z42QP9GhfWavfjpfKo22xMb0xv2', 'membre',   1),
  (6, 'ATTIOGBE', 'Komla',    'komla.attiogbe@example.tg',
      '$2b$12$NHr3rKZJm1uJF6IzSVCEg.dmG0Z42QP9GhfWavfjpfKo22xMb0xv2', 'visiteur', 1),
  (7, 'LAWSON',   'Akouvi',   'akouvi.lawson@example.tg',
      '$2b$12$NHr3rKZJm1uJF6IzSVCEg.dmG0Z42QP9GhfWavfjpfKo22xMb0xv2', 'membre',   0);

-- Vérification :
--   SELECT id, email, role, actif FROM users ORDER BY id;
