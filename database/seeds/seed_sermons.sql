-- =====================================================================
-- SEED — categories, orateurs, sermons (données de test)
-- Projet   : MICR_Project — feature/database
-- Dépend de: migrations/002_create_sermons.sql ET seeds/seed_users.sql
--            (orateurs.user_id référence users.id 2 et 3)
-- Exécution: mysql -u root -p < database/seeds/seed_sermons.sql
-- ---------------------------------------------------------------------
-- /!\ ENVIRONNEMENT DE DÉVELOPPEMENT UNIQUEMENT.
-- Les URL media sont fictives : elles servent à tester le rendu du
-- lecteur côté frontend, pas à diffuser du vrai contenu.
--
-- Le texte est volontairement ACCENTUÉ : c'est ce qui valide réellement
-- le choix utf8mb4 du document de workflow. Dans une chaîne SQL,
-- l'apostrophe se double ('' ) — voir « l''adoration » plus bas.
-- =====================================================================

USE micr_db;

-- ---------------------------------------------------------------------
-- categories
-- ---------------------------------------------------------------------
INSERT IGNORE INTO categories (id, nom, slug, description) VALUES
  (1, 'Enseignement biblique', 'enseignement-biblique',
      'Études verset par verset et exposés doctrinaux.'),
  (2, 'Louange et Adoration',  'louange-adoration',
      'Messages centrés sur la louange, l''adoration et la vie de prière.'),
  (3, 'Évangélisation',        'evangelisation',
      'Messages d''appel au salut et de formation à l''évangélisation.'),
  (4, 'Vie chrétienne',        'vie-chretienne',
      'Marche quotidienne du croyant, éthique et sanctification.'),
  (5, 'Jeunesse',              'jeunesse',
      'Messages adressés aux jeunes de l''assemblée.'),
  (6, 'Famille et Couple',     'famille-couple',
      'Enseignements sur le mariage, la parentalité et le foyer.');

-- ---------------------------------------------------------------------
-- orateurs
-- Les orateurs 1 et 2 ont un compte utilisateur (relation 1-1).
-- Les orateurs 3 et 4 sont des invités sans compte (user_id NULL).
-- ---------------------------------------------------------------------
INSERT IGNORE INTO orateurs (id, nom, prenom, photo_url, biographie, user_id) VALUES
  (1, 'TCHALLA', 'Emmanuel', '/media/orateurs/e-tchalla.jpg',
      'Pasteur principal du MICR Kara. Enseigne la Parole depuis 1998, fondateur du centre de formation biblique de Kara.',
      2),
  (2, 'AGBEKO',  'Marie',    '/media/orateurs/m-agbeko.jpg',
      'Responsable du département Femmes et Famille. Animatrice des séminaires couple et parentalité.',
      3),
  (3, 'SODJI',   'Bernard',  '/media/orateurs/b-sodji.jpg',
      'Pasteur invité de Lomé, missionnaire en Afrique de l''Ouest.',
      NULL),
  (4, 'OURO-BANG', 'Ismaël', '/media/orateurs/i-ouro-bang.jpg',
      'Responsable du département Jeunesse du MICR Kara.',
      NULL);

-- ---------------------------------------------------------------------
-- sermons
-- Mélange volontaire : vidéo / audio / texte, publiés et brouillons,
-- pour que le backend puisse tester ses filtres et sa pagination.
-- ---------------------------------------------------------------------
INSERT IGNORE INTO sermons
  (id, titre, description, type, url_media, orateur_id, categorie_id, duree, vues, publie, created_at) VALUES
  (1,  'La puissance de la résurrection',
       'Étude sur Romains 6 : ce que la résurrection du Christ change concrètement dans la vie du croyant.',
       'video', 'https://www.youtube.com/watch?v=MICR-DEMO-001', 1, 1,  52, 1240, 1, '2026-03-08 10:00:00'),
  (2,  'Marcher par la foi et non par la vue',
       'Message d''encouragement tiré de 2 Corinthiens 5.',
       'video', 'https://www.youtube.com/watch?v=MICR-DEMO-002', 1, 4,  47,  876, 1, '2026-03-22 10:00:00'),
  (3,  'Le fondement du mariage chrétien',
       'Première partie du séminaire couple : les bases bibliques de l''engagement.',
       'audio', '/media/sermons/2026-04-05-mariage-chretien.mp3',  2, 6,  61,  432, 1, '2026-04-05 15:30:00'),
  (4,  'Une jeunesse consacrée',
       'Message adressé aux jeunes lors de la convention de la jeunesse de Kara.',
       'video', 'https://www.youtube.com/watch?v=MICR-DEMO-004', 4, 5,  38, 1590, 1, '2026-04-19 16:00:00'),
  (5,  'L''adoration en esprit et en vérité',
       'Étude de Jean 4 : ce que Dieu recherche chez ceux qui l''adorent.',
       'audio', '/media/sermons/2026-05-03-adoration.mp3',         1, 2,  44,  298, 1, '2026-05-03 10:00:00'),
  (6,  'Aller vers les perdus',
       'Formation pratique à l''évangélisation de proximité dans le quartier.',
       'texte', '/media/sermons/2026-05-17-evangelisation.pdf',    3, 3, NULL, 156, 1, '2026-05-17 10:00:00'),
  (7,  'La prière qui déplace les montagnes',
       'Enseignement sur la prière persévérante, tiré de Luc 18.',
       'video', 'https://www.youtube.com/watch?v=MICR-DEMO-007', 1, 2,  55,  721, 1, '2026-06-07 10:00:00'),
  (8,  'Éduquer ses enfants dans la crainte de Dieu',
       'Deuxième partie du séminaire famille : la transmission de la foi aux enfants.',
       'audio', '/media/sermons/2026-06-21-education.mp3',         2, 6,  49,  344, 1, '2026-06-21 15:30:00'),
  (9,  'Le combat spirituel du croyant',
       'Éphésiens 6 : identifier le combat et revêtir l''armure de Dieu.',
       'video', 'https://www.youtube.com/watch?v=MICR-DEMO-009', 3, 1,  58,  512, 1, '2026-07-12 10:00:00'),
  (10, 'Série Actes des Apôtres — épisode 1',
       'Ouverture d''une série d''études sur le livre des Actes. BROUILLON, non publié.',
       'texte', NULL,                                              1, 1, NULL,   0, 0, '2026-08-09 09:00:00'),
  (11, 'Convention 2026 — message d''ouverture',
       'Message d''ouverture de la convention annuelle. BROUILLON en attente du montage vidéo.',
       'video', NULL,                                              1, 1,  63,   0, 0, '2026-08-16 09:00:00'),
  (12, 'Prédication d''archive sans orateur référencé',
       'Ancienne prédication numérisée : l''orateur n''a pas été identifié. Sert à tester l''affichage quand orateur_id est NULL.',
       'audio', '/media/sermons/archive-001.mp3',                NULL, NULL, 41, 87, 1, '2026-01-11 10:00:00');

-- Vérification :
--   SELECT s.id, s.titre, s.type, s.publie, o.nom AS orateur, c.nom AS categorie
--   FROM sermons s
--   LEFT JOIN orateurs   o ON o.id = s.orateur_id
--   LEFT JOIN categories c ON c.id = s.categorie_id
--   ORDER BY s.created_at DESC;
