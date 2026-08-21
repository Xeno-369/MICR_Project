-- =====================================================================
-- SEED — events (données de test)
-- Projet   : MICR_Project — feature/database
-- Dépend de: migrations/003_create_events.sql
-- Exécution: mysql -u root -p < database/seeds/seed_events.sql
-- ---------------------------------------------------------------------
-- /!\ ENVIRONNEMENT DE DÉVELOPPEMENT UNIQUEMENT.
-- Jeu de données calé sur août 2026 : il contient des événements
-- passés (termine), en cours, à venir et annulés, pour que le backend
-- puisse tester tous les filtres de statut et le tri de l'agenda.
-- Toutes les lignes respectent la contrainte chk_events_dates
-- (date_fin >= date_debut, ou date_fin NULL).
-- =====================================================================

USE micr_db;

INSERT IGNORE INTO events
  (id, titre, description, date_debut, date_fin, lieu, type, statut) VALUES
  (1,  'Culte de célébration dominical',
       'Culte hebdomadaire ouvert à tous. Louange, prédication et prière.',
       '2026-08-23 09:00:00', '2026-08-23 12:00:00',
       'Temple MICR, Kara-Kassena', 'culte', 'a_venir'),
  (2,  'Convention annuelle MICR 2026',
       'Trois jours de rassemblement national avec les assemblées du Togo et des pays voisins.',
       '2026-09-11 08:00:00', '2026-09-13 20:00:00',
       'Esplanade du Temple MICR, Kara', 'convention', 'a_venir'),
  (3,  'Séminaire couple et famille',
       'Deux journées de formation pour les couples mariés et les fiancés.',
       '2026-10-03 08:30:00', '2026-10-04 17:00:00',
       'Salle polyvalente, Kara', 'seminaire', 'a_venir'),
  (4,  'Croisade d''évangélisation de Kara',
       'Cinq soirées d''évangélisation en plein air, avec chorale et témoignages.',
       '2026-11-18 17:30:00', '2026-11-22 21:30:00',
       'Place des Fêtes, Kara', 'croisade', 'a_venir'),
  (5,  'Veillée de prière mensuelle',
       'Veillée de prière du dernier vendredi du mois.',
       '2026-08-28 21:00:00', '2026-08-29 05:00:00',
       'Temple MICR, Kara-Kassena', 'culte', 'a_venir'),
  (6,  'Camp biblique de la jeunesse',
       'Camp résidentiel pour les 15-30 ans : enseignements, ateliers et sport.',
       '2026-08-17 08:00:00', '2026-08-24 18:00:00',
       'Centre de formation biblique, Kara', 'seminaire', 'en_cours'),
  (7,  'Conférence sur le leadership chrétien',
       'Conférence destinée aux responsables de départements et aux diacres.',
       '2026-07-04 09:00:00', '2026-07-05 16:00:00',
       'Temple MICR, Kara-Kassena', 'conference', 'termine'),
  (8,  'Culte de reconnaissance de mi-année',
       'Culte spécial de reconnaissance pour le premier semestre 2026.',
       '2026-06-28 09:00:00', '2026-06-28 13:00:00',
       'Temple MICR, Kara-Kassena', 'culte', 'termine'),
  (9,  'Journée portes ouvertes du centre biblique',
       'Annulée faute de disponibilité de la salle. Sert à tester le statut « annule ».',
       '2026-05-30 09:00:00', '2026-05-30 17:00:00',
       'Centre de formation biblique, Kara', 'autre', 'annule'),
  (10, 'Réunion de prière du mercredi',
       'Réunion hebdomadaire sans heure de fin annoncée : sert à tester date_fin NULL.',
       '2026-08-26 18:00:00', NULL,
       'Temple MICR, Kara-Kassena', 'culte', 'a_venir');

-- Vérification :
--   SELECT id, titre, statut, date_debut, date_fin FROM events
--   ORDER BY date_debut;
--
--   -- Agenda public (le cas d'usage principal du frontend) :
--   SELECT id, titre, date_debut, lieu FROM events
--   WHERE statut = 'a_venir' AND date_debut >= NOW()
--   ORDER BY date_debut LIMIT 5;
