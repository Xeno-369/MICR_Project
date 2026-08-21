-- =====================================================================
-- SEED — donations, contacts, newsletter (données de test)
-- Projet   : MICR_Project — feature/database
-- Dépend de: migrations/004_create_donations.sql
--            migrations/005_create_contacts_newsletter.sql
-- Exécution: mysql -u root -p < database/seeds/seed_donations_contacts.sql
-- ---------------------------------------------------------------------
-- NOTE : ce fichier ne figure pas dans la liste initiale du document de
-- workflow (qui prévoyait 3 seeds : users, sermons, events). Il est
-- ajouté parce que le backend a besoin de lignes de test pour les APIs
-- dons, contact et newsletter — 3 des 8 tables seraient sinon vides.
--
-- /!\ ENVIRONNEMENT DE DÉVELOPPEMENT UNIQUEMENT.
-- Aucune donnée réelle de donateur ne doit se retrouver dans Git.
-- Les références de paiement sont fictives.
-- =====================================================================

USE micr_db;

-- ---------------------------------------------------------------------
-- donations
-- Les 4 méthodes et les 3 statuts sont représentés, pour que le backend
-- teste ses filtres et le calcul des totaux (qui ne doit compter QUE
-- les dons au statut 'confirme').
-- La ligne 8 a reference = NULL : cas d'un don en espèces saisi à la main.
-- ---------------------------------------------------------------------
INSERT IGNORE INTO donations
  (id, montant, devise, methode, reference, statut, donateur_nom, donateur_email, created_at) VALUES
  (1,  25000.00, 'XOF', 'flooz',          'FLZ-2026-0001', 'confirme',
       'Yao MENSAH',        'yao.mensah@example.tg',      '2026-07-02 08:14:00'),
  (2,  10000.00, 'XOF', 'mix_by_yas',     'MIX-2026-0002', 'confirme',
       'Afi KOUDJO',        'afi.koudjo@example.tg',      '2026-07-05 19:41:00'),
  (3,   5000.00, 'XOF', 'flooz',          'FLZ-2026-0003', 'echoue',
       'Komla ATTIOGBE',    'komla.attiogbe@example.tg',  '2026-07-09 12:03:00'),
  (4, 150000.00, 'XOF', 'virement',       'VIR-2026-0004', 'confirme',
       'Famille LAWSON',    'akouvi.lawson@example.tg',   '2026-07-15 10:00:00'),
  (5,     50.00, 'EUR', 'carte_bancaire', 'CB-2026-0005',  'confirme',
       'Diaspora MICR France', 'diaspora@example.fr',     '2026-07-21 21:17:00'),
  (6,  20000.00, 'XOF', 'mix_by_yas',     'MIX-2026-0006', 'en_attente',
       NULL,                NULL,                          '2026-08-18 07:52:00'),
  (7,   2000.00, 'XOF', 'flooz',          'FLZ-2026-0007', 'confirme',
       NULL,                NULL,                          '2026-08-19 16:35:00'),
  (8,  75000.00, 'XOF', 'virement',       NULL,            'confirme',
       'Don anonyme (espèces, saisi par le trésorier)', NULL, '2026-08-20 11:00:00');

-- ---------------------------------------------------------------------
-- contacts
-- Mélange de messages lus / non lus et des 2 types (contact / priere).
-- Le message 5 contient un émoji : il vérifie concrètement que la base
-- est bien en utf8mb4 (4 octets) et non en utf8mb3.
-- ---------------------------------------------------------------------
INSERT IGNORE INTO contacts
  (id, nom, prenom, email, sujet, message, type, statut_lu, created_at) VALUES
  (1, 'MENSAH',   'Yao',    'yao.mensah@example.tg',
      'Horaires des cultes',
      'Bonjour, pourriez-vous me confirmer l''heure du culte du dimanche ? Merci.',
      'contact', 1, '2026-08-10 09:12:00'),
  (2, 'KOUDJO',   'Afi',    'afi.koudjo@example.tg',
      'Demande de prière pour ma famille',
      'Je souhaite que l''assemblée prie pour la santé de ma mère hospitalisée à Kara.',
      'priere',  1, '2026-08-12 20:05:00'),
  (3, 'ATTIOGBE', 'Komla',  'komla.attiogbe@example.tg',
      'Inscription au camp de la jeunesse',
      'Bonjour, est-il encore possible de s''inscrire au camp biblique de la jeunesse ?',
      'contact', 0, '2026-08-15 14:47:00'),
  (4, 'SODJI',    NULL,     'bernard.sodji@example.tg',
      NULL,
      'Message sans sujet ni prénom : sert à tester l''affichage des champs NULL côté frontend.',
      'contact', 0, '2026-08-17 08:00:00'),
  (5, 'LAWSON',   'Akouvi', 'akouvi.lawson@example.tg',
      'Requête de prière 🙏',
      'Merci de prier pour mon examen de fin d''année et pour mon orientation professionnelle. 🙏 Que Dieu vous bénisse ! 🇹🇬',
      'priere',  0, '2026-08-19 06:30:00'),
  (6, 'ADEKAMBI', 'Rafiou', 'rafiou.adekambi@example.tg',
      'Partenariat association',
      'Notre association souhaite collaborer avec le MICR pour une action sociale à Kara.',
      'contact', 0, '2026-08-20 17:22:00');

-- ---------------------------------------------------------------------
-- newsletter
-- token_desinscription : UUID v4 figés ici pour que le seed reste
-- rejouable à l'identique (la colonne est UNIQUE).
-- En production, c'est le backend qui génère le token à l'inscription.
-- L'abonné 5 est inactif : il s'est désinscrit, sa ligne est conservée.
-- ---------------------------------------------------------------------
INSERT IGNORE INTO newsletter (id, email, actif, token_desinscription, created_at) VALUES
  (1, 'yao.mensah@example.tg',       1, 'f8383f27-068d-4e50-811e-476b5ae1bcc0', '2026-05-02 10:00:00'),
  (2, 'afi.koudjo@example.tg',       1, '94cb6b3f-77f6-464e-bf15-9e7265868c19', '2026-05-14 18:20:00'),
  (3, 'komla.attiogbe@example.tg',   1, '78e99ed1-f4ec-4378-bc27-8468f8459084', '2026-06-01 09:05:00'),
  (4, 'akouvi.lawson@example.tg',    1, '738e43b7-c05f-41ae-90d1-7c561ae833d4', '2026-06-23 21:40:00'),
  (5, 'ancien.abonne@example.tg',    0, '290368ac-3085-45c4-b2ce-6e42b3a3b8f2', '2026-02-11 08:15:00'),
  (6, 'diaspora@example.fr',         1, '0277d90e-7ac4-4c50-955d-d4f5437c891a', '2026-07-21 21:18:00'),
  (7, 'rafiou.adekambi@example.tg',  1, '476474f9-6cda-4144-94fd-ea8e8454cc12', '2026-08-20 17:23:00');

-- Vérification :
--   -- Total des dons RÉELLEMENT encaissés (statut confirme uniquement) :
--   SELECT devise, SUM(montant) AS total, COUNT(*) AS nb
--   FROM donations WHERE statut = 'confirme' GROUP BY devise;
--
--   -- Badge admin : nombre de messages non lus :
--   SELECT type, COUNT(*) FROM contacts WHERE statut_lu = 0 GROUP BY type;
--
--   -- Liste d'envoi de la newsletter :
--   SELECT email FROM newsletter WHERE actif = 1;
