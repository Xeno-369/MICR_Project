# Base de données MICR — `micr_db`

Documentation de la couche base de données du site du **Mouvement International du Christ Ressuscité** (Kara, Togo).

| | |
|---|---|
| **SGBD** | MySQL 8.x — moteur InnoDB |
| **Charset / collation** | `utf8mb4` / `utf8mb4_unicode_ci` |
| **Base** | `micr_db` — 8 tables |
| **Branche Git** | `feature/database` |
| **Consommateur** | Backend Django (ORM) |
| **Version** | 1.0 — Août 2026 |

> **Ce dossier `database/` appartient à la branche `feature/database`.**
> Backend et frontend ne modifient aucun fichier ici : toute évolution du
> schéma passe par une nouvelle migration et une Pull Request.

---

## 1. Contenu du dossier

```
database/
├── schema.sql                      Les 8 tables en un seul fichier (installation neuve)
├── migrations/
│   ├── 001_create_users.sql        base micr_db + users
│   ├── 002_create_sermons.sql      categories + orateurs + sermons
│   ├── 003_create_events.sql       events
│   ├── 004_create_donations.sql    donations
│   └── 005_create_contacts_newsletter.sql
├── seeds/
│   ├── seed_users.sql              7 comptes de test
│   ├── seed_sermons.sql            6 catégories, 4 orateurs, 12 prédications
│   ├── seed_events.sql             10 événements
│   └── seed_donations_contacts.sql 8 dons, 6 messages, 7 abonnés
├── django_models_reference.py      Traduction du schéma en modèles Django
├── validate_schema.sh              Vérification automatique (20 contrôles)
├── .env.example                    Modèle des variables de connexion
└── README.md                       Ce fichier
```

**`schema.sql` ou `migrations/` ?** Les deux produisent exactement la même
structure. `schema.sql` sert à monter une base neuve d'un coup ;
`migrations/` sert à suivre l'historique et à rejouer les changements dans
l'ordre. Les fichiers `migrations/` sont la référence : `schema.sql` est
leur consolidation.

---

## 2. Installation

### 2.1 En ligne de commande

```bash
# Structure
mysql -u root -p < database/schema.sql

# Données de test (ordre imposé : users AVANT sermons)
mysql -u root -p < database/seeds/seed_users.sql
mysql -u root -p < database/seeds/seed_sermons.sql
mysql -u root -p < database/seeds/seed_events.sql
mysql -u root -p < database/seeds/seed_donations_contacts.sql
```

### 2.2 Avec phpMyAdmin

1. Onglet **Importer** → choisir `database/schema.sql` → **Exécuter**.
   La base `micr_db` est créée automatiquement, inutile de la créer avant.
2. Sélectionner `micr_db`, puis importer les 4 fichiers de `seeds/`
   **dans l'ordre** ci-dessus.

### 2.3 Vérifier que tout est en place

```bash
bash database/validate_schema.sh
```

Le script rejoue migrations et seeds, contrôle la structure, les clés
étrangères, les index, l'encodage, et vérifie que les insertions
**invalides sont bien refusées**. Il doit se terminer par
`RÉSULTAT : TOUS LES TESTS PASSENT`.

> Sous Windows : lancer depuis Git Bash, avec le client `mysql` dans le PATH.
> Connexion configurable : `DB_HOST DB_PORT DB_USER DB_PASSWORD`.

---

## 3. Les 8 tables

### 3.1 `users` — comptes admin & membres

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | INT UNSIGNED | PK, AUTO_INCREMENT | |
| `nom` | VARCHAR(80) | NOT NULL | |
| `prenom` | VARCHAR(80) | NOT NULL | |
| `email` | VARCHAR(160) | NOT NULL, **UNIQUE** | Sert d'identifiant de connexion |
| `password_hash` | VARCHAR(255) | NOT NULL | **bcrypt uniquement** |
| `role` | ENUM | `admin` / `membre` / `visiteur`, défaut `visiteur` | |
| `actif` | TINYINT(1) | défaut 1 | 0 = compte désactivé |
| `last_login` | DATETIME | NULL | Requis par Django (voir §6.2) |
| `created_at` | TIMESTAMP | défaut `CURRENT_TIMESTAMP` | |
| `updated_at` | TIMESTAMP | `ON UPDATE CURRENT_TIMESTAMP` | |

Index : `idx_users_role_actif (role, actif)`, `idx_users_created_at (created_at)`.

### 3.2 `categories` — catégories de prédications

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | INT UNSIGNED | PK | |
| `nom` | VARCHAR(120) | NOT NULL | Libellé affiché |
| `slug` | VARCHAR(140) | NOT NULL, **UNIQUE** | Identifiant d'URL |
| `description` | TEXT | NULL | |
| `created_at` | TIMESTAMP | défaut `CURRENT_TIMESTAMP` | |

### 3.3 `orateurs` — pasteurs & intervenants

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | INT UNSIGNED | PK | |
| `nom` / `prenom` | VARCHAR(80) | NOT NULL | |
| `photo_url` | VARCHAR(512) | NULL | Chemin ou URL de la photo |
| `biographie` | TEXT | NULL | |
| `user_id` | INT UNSIGNED | NULL, **UNIQUE**, FK → `users.id` | Compte associé, optionnel |
| `created_at` | TIMESTAMP | défaut `CURRENT_TIMESTAMP` | |

`user_id` est **UNIQUE** : c'est ce qui matérialise la relation 1→1 annoncée
dans le document de workflow. Il est **NULL** pour les orateurs invités qui
n'ont pas de compte sur le site.

### 3.4 `sermons` — prédications

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | INT UNSIGNED | PK | |
| `titre` | VARCHAR(255) | NOT NULL | |
| `description` | TEXT | NULL | |
| `type` | ENUM | `video` / `audio` / `texte`, NOT NULL | |
| `url_media` | VARCHAR(512) | NULL | Lien YouTube, fichier audio ou PDF |
| `orateur_id` | INT UNSIGNED | NULL, FK → `orateurs.id` | |
| `categorie_id` | INT UNSIGNED | NULL, FK → `categories.id` | |
| `duree` | INT UNSIGNED | NULL | En minutes (NULL pour `texte`) |
| `vues` | INT UNSIGNED | défaut 0 | Compteur de lectures |
| `publie` | TINYINT(1) | défaut 0 | **0 = brouillon**, invisible côté public |
| `created_at` | TIMESTAMP | défaut `CURRENT_TIMESTAMP` | |

Index : `idx_sermons_publie_created (publie, created_at)` — dessiné pour la
requête principale du site : *les prédications publiées, de la plus récente
à la plus ancienne*.

### 3.5 `events` — événements & programmes

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | INT UNSIGNED | PK | |
| `titre` | VARCHAR(255) | NOT NULL | |
| `description` | TEXT | NULL | |
| `date_debut` | DATETIME | NOT NULL | |
| `date_fin` | DATETIME | NULL | NULL = événement d'une journée |
| `lieu` | VARCHAR(255) | NULL | |
| `type` | ENUM | `culte` / `conference` / `seminaire` / `convention` / `croisade` / `autre` | défaut `culte` |
| `statut` | ENUM | `a_venir` / `en_cours` / `termine` / `annule` | défaut `a_venir` |
| `created_at` | TIMESTAMP | défaut `CURRENT_TIMESTAMP` | |

Contrainte `chk_events_dates` : `date_fin IS NULL OR date_fin >= date_debut`.
Un événement qui finirait avant d'avoir commencé est **refusé par la base**,
sans dépendre du code applicatif.

### 3.6 `donations` — dons reçus

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | INT UNSIGNED | PK | |
| `montant` | DECIMAL(10,2) | NOT NULL, **> 0** | `DECIMAL`, jamais `FLOAT` |
| `devise` | VARCHAR(10) | défaut `XOF` | Franc CFA |
| `methode` | ENUM | `flooz` / `mix_by_yas` / `carte_bancaire` / `virement` | NOT NULL |
| `reference` | VARCHAR(100) | NULL, **UNIQUE** | Référence de l'opérateur |
| `statut` | ENUM | `en_attente` / `confirme` / `echoue` | défaut `en_attente` |
| `donateur_nom` | VARCHAR(160) | NULL | Don anonyme possible |
| `donateur_email` | VARCHAR(160) | NULL | |
| `created_at` | TIMESTAMP | défaut `CURRENT_TIMESTAMP` | |

Deux protections à connaître côté backend :

- **`reference` UNIQUE** : quand un opérateur Mobile Money rejoue son callback
  (cela arrive), le second `INSERT` est refusé par la base. Le don n'est pas
  compté deux fois. `reference` accepte `NULL` (don en espèces saisi
  manuellement) et MySQL autorise plusieurs `NULL` sur un index UNIQUE.
- **`montant > 0`** : contrainte `chk_donations_montant`.

Un total de dons ne doit compter **que** les lignes `statut = 'confirme'`.

### 3.7 `contacts` — formulaire de contact & prières

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | INT UNSIGNED | PK | |
| `nom` | VARCHAR(80) | NOT NULL | |
| `prenom` | VARCHAR(80) | NULL | |
| `email` | VARCHAR(160) | NOT NULL | |
| `sujet` | VARCHAR(255) | NULL | |
| `message` | TEXT | NOT NULL | |
| `type` | ENUM | `contact` / `priere` | défaut `contact` |
| `statut_lu` | TINYINT(1) | défaut 0 | 0 = non lu (badge admin) |
| `created_at` | TIMESTAMP | défaut `CURRENT_TIMESTAMP` | |

### 3.8 `newsletter` — abonnés

| Colonne | Type | Contraintes | Rôle |
|---|---|---|---|
| `id` | INT UNSIGNED | PK | |
| `email` | VARCHAR(160) | NOT NULL, **UNIQUE** | |
| `actif` | TINYINT(1) | défaut 1 | 0 = désinscrit |
| `token_desinscription` | CHAR(36) | NOT NULL, **UNIQUE** | UUID v4, généré par le backend |
| `created_at` | TIMESTAMP | défaut `CURRENT_TIMESTAMP` | |

Une désinscription passe `actif` à 0 : **la ligne n'est pas supprimée**, pour
garder la trace de la demande.

---

## 4. Relations

```
users ──1:1(opt)──> orateurs ──1:N──> sermons <──N:1── categories

events        (indépendante)
donations     (indépendante)
contacts      (indépendante)
newsletter    (indépendante)
```

| Contrainte | De → Vers | Suppression |
|---|---|---|
| `fk_orateurs_user` | `orateurs.user_id` → `users.id` | `SET NULL` |
| `fk_sermons_orateur` | `sermons.orateur_id` → `orateurs.id` | `SET NULL` |
| `fk_sermons_categorie` | `sermons.categorie_id` → `categories.id` | `SET NULL` |

**Pourquoi `SET NULL` et jamais `CASCADE` :** supprimer un compte utilisateur
ou une catégorie ne doit jamais faire disparaître des prédications. Le
contenu éditorial survit à la suppression d'un compte ; il se retrouve
simplement sans orateur ou sans catégorie rattachée. Le frontend doit donc
gérer l'affichage quand `orateur_id` ou `categorie_id` vaut `NULL`
(le jeu de test contient exprès le sermon n°12 dans ce cas).

---

## 5. Index

| Table | Index | Requête visée |
|---|---|---|
| `users` | `idx_users_role_actif` | Lister les administrateurs actifs |
| `users` | `idx_users_created_at` | Inscriptions récentes |
| `sermons` | `idx_sermons_publie_created` | Prédications publiées, triées par date |
| `sermons` | `idx_sermons_type` | Filtre vidéo / audio / texte |
| `events` | `idx_events_statut_debut` | Agenda des événements à venir |
| `events` | `idx_events_date_debut` | Tri chronologique |
| `donations` | `idx_donations_statut_created` | Dons confirmés sur une période |
| `donations` | `idx_donations_methode` | Répartition par moyen de paiement |
| `contacts` | `idx_contacts_lu_created` | Messages non lus, plus récents d'abord |
| `contacts` | `idx_contacts_type` / `idx_contacts_email` | Filtre prière / recherche |
| `newsletter` | `idx_newsletter_actif` | Liste d'envoi |

Les colonnes `UNIQUE` (`email`, `slug`, `reference`, `token_desinscription`)
sont déjà indexées par MySQL. InnoDB crée aussi automatiquement un index sur
chaque colonne de clé étrangère — inutile d'en rajouter.

---

## 6. Intégration Django

Le fichier [`django_models_reference.py`](django_models_reference.py) contient
les 8 modèles prêts à copier. Les points ci-dessous expliquent **pourquoi**
ils sont écrits ainsi.

### 6.1 Connexion (`settings.py`)

```python
import os

DATABASES = {
    'default': {
        'ENGINE':   'django.db.backends.mysql',
        'NAME':     os.environ['DB_NAME'],       # micr_db
        'USER':     os.environ['DB_USER'],
        'PASSWORD': os.environ['DB_PASSWORD'],
        'HOST':     os.environ.get('DB_HOST', 'localhost'),
        'PORT':     os.environ.get('DB_PORT', '3306'),
        'OPTIONS': {
            'charset': 'utf8mb4',
            'init_command': "SET sql_mode='STRICT_TRANS_TABLES'",
        },
    }
}
```

`charset: utf8mb4` n'est **pas** optionnel : sans lui, le pilote peut
négocier `utf8mb3` et les emojis reçus par le formulaire de contact
déclencheront une erreur d'insertion.

Copier `database/.env.example` vers `.env` à la racine du projet et le
remplir. `.env` doit être dans `.gitignore`.

### 6.2 `users` est un modèle d'authentification personnalisé

À déclarer **avant la première migration** du projet :

```python
AUTH_USER_MODEL = 'core.User'   # adapter au nom de l'app
```

Trois écarts entre le schéma SQL et ce que Django attend, tous absorbés
dans le modèle de référence :

| Django attend | Le schéma fournit | Solution |
|---|---|---|
| `password` | colonne `password_hash` | `db_column='password_hash'` |
| `is_active` | colonne `actif` | `db_column='actif'` |
| `last_login` | colonne `last_login` | **présente dans le schéma** |

`last_login` mérite un mot : `AbstractBaseUser` la définit et Django y écrit
à **chaque** connexion réussie. Sans cette colonne, le login plante avec une
`OperationalError`. Elle a donc été ajoutée au schéma alors qu'elle ne
figurait pas dans le document initial.

Le schéma n'a ni `is_superuser` ni les tables de permissions Django : l'accès
à l'admin est dérivé de `role == 'admin'` via des propriétés Python
(`is_staff`, `is_superuser`). Si le projet a besoin du système de permissions
complet de Django, il faudra ajouter `PermissionsMixin` **et** les tables
`auth_permission` / `auth_group` — à décider ensemble, c'est un changement
de schéma.

### 6.3 bcrypt

Le document de workflow impose bcrypt. Django hash en PBKDF2 par défaut :

```bash
pip install bcrypt
```

```python
PASSWORD_HASHERS = [
    'django.contrib.auth.hashers.BCryptSHA256PasswordHasher',
    'django.contrib.auth.hashers.PBKDF2PasswordHasher',   # relecture de l'existant
]
```

`user.set_password(...)` produit alors un hash bcrypt, et `VARCHAR(255)` est
largement suffisant pour le stocker.

### 6.4 `managed = False`

Tous les modèles portent `managed = False` : Django ne crée, ne modifie et ne
supprime **aucune** de ces tables. Le schéma appartient à `feature/database`.

Conséquence à connaître : `manage.py test` ne créera pas ces tables dans la
base de test, et les tests échoueront. La parade habituelle est un runner de
test qui bascule `managed` à `True` uniquement pendant les tests :

```python
# core/test_runner.py
from django.test.runner import DiscoverRunner

class ManagedModelTestRunner(DiscoverRunner):
    def setup_test_environment(self, *args, **kwargs):
        from django.apps import apps
        self.unmanaged = [m for m in apps.get_models() if not m._meta.managed]
        for m in self.unmanaged:
            m._meta.managed = True
        super().setup_test_environment(*args, **kwargs)

    def teardown_test_environment(self, *args, **kwargs):
        super().teardown_test_environment(*args, **kwargs)
        for m in self.unmanaged:
            m._meta.managed = False
```

```python
TEST_RUNNER = 'core.test_runner.ManagedModelTestRunner'
```

### 6.5 Vérifier la correspondance

```bash
python manage.py inspectdb --database=default > /tmp/inspected.py
```

Comparer avec `django_models_reference.py`. Les différences attendues :
`inspectdb` ne devine ni les `choices`, ni les `related_name`, ni le modèle
d'authentification personnalisé.

### 6.6 Pagination

```python
Sermon.objects.filter(publie=True).order_by('-created_at')[:20]
```

Cette requête utilise `idx_sermons_publie_created`. Même logique pour
`Event.objects.filter(statut='a_venir').order_by('date_debut')`.

---

## 7. Comptes de test

Chargés par `seeds/seed_users.sql`. **Développement uniquement** — ces mots
de passe sont publics puisqu'ils sont dans le dépôt Git.

| Email | Mot de passe | Rôle |
|---|---|---|
| `admin@micr-togo.org` | `Admin@MICR2026` | admin |
| `e.tchalla@micr-togo.org` | `Pasteur@MICR2026` | admin |
| `m.agbeko@micr-togo.org` | `Pasteur@MICR2026` | membre |
| `yao.mensah@example.tg` | `Membre@MICR2026` | membre |
| `afi.koudjo@example.tg` | `Membre@MICR2026` | membre |
| `komla.attiogbe@example.tg` | `Membre@MICR2026` | visiteur |
| `akouvi.lawson@example.tg` | `Membre@MICR2026` | membre (désactivé) |

Les hash sont du vrai bcrypt en cost 12.

**Ne jamais charger `seeds/` en production.**

---

## 8. Ajouter une évolution du schéma

1. Créer `migrations/006_<description>.sql` — numéro suivant, jamais réutilisé.
2. Écrire uniquement le **changement** (`ALTER TABLE`, `CREATE TABLE`…), pas
   le schéma entier. Commencer par `USE micr_db;`.
3. Répercuter le changement dans `schema.sql` pour que les installations
   neuves restent identiques.
4. Mettre à jour le tableau de la table concernée dans ce README.
5. Mettre à jour `django_models_reference.py`.
6. Lancer `bash database/validate_schema.sh` — doit rester au vert.
7. Commit et Pull Request :

```bash
git add database/
git commit -m "feat(db): ajout du champ X sur la table Y"
git push origin feature/database
```

8. **Prévenir le backend** : un changement de colonne casse ses modèles.

Ne jamais modifier une migration déjà mergée : elle a peut-être déjà été
exécutée sur un autre poste ou sur le VPS.

---

## 9. Sécurité

- **Mots de passe** : bcrypt uniquement, jamais en clair, jamais en MD5/SHA1.
- **Credentials MySQL** : dans `.env`, jamais dans le code, jamais sur Git.
  Vérifier que `.env` figure bien dans `.gitignore`.
- **Utilisateur applicatif dédié en production** — pas de `root` :

```sql
CREATE USER 'micr_user'@'localhost' IDENTIFIED BY '<mot de passe fort>';
GRANT SELECT, INSERT, UPDATE, DELETE ON micr_db.* TO 'micr_user'@'localhost';
FLUSH PRIVILEGES;
```

  Volontairement **sans** `DROP` ni `ALTER` : l'application n'a aucune raison
  de modifier la structure. Les migrations se lancent avec un compte
  d'administration séparé.

- **phpMyAdmin** : accès `root` en local seulement, jamais exposé sur
  Internet en production.
- **Données personnelles** : `contacts`, `donations` et `newsletter`
  contiennent des données de vraies personnes. Aucun `mysqldump` de
  production ne doit atterrir dans le dépôt Git.
- **Sauvegarde quotidienne** (cron sur le VPS) :

```bash
0 2 * * * mysqldump -u backup_user -p"$MYSQL_BACKUP_PWD" \
  --single-transaction --routines micr_db \
  | gzip > /var/backups/micr_db_$(date +\%F).sql.gz
```

  `--single-transaction` évite de verrouiller les tables pendant le dump.
  Une sauvegarde jamais restaurée ne vaut rien : tester la restauration.

---

## 10. Reset & sauvegarde en développement

```bash
# Sauvegarde manuelle
mysqldump -u root -p micr_db > backup_micr_$(date +%F).sql

# Restauration
mysql -u root -p micr_db < backup_micr_2026-08-21.sql
```

**Repartir de zéro** — détruit toutes les données de la base locale :

```sql
DROP DATABASE micr_db;
```

Puis rejouer `schema.sql` et les `seeds/`. Aucun fichier de ce dossier ne
contient de `DROP` : la destruction est toujours une action manuelle et
volontaire.

---

## 11. Écarts assumés par rapport au document de workflow initial

Le document d'architecture décrivait la structure ; ces points ont été
précisés ou complétés à l'écriture du SQL. Ils sont à valider en réunion.

| Ajout / choix | Raison |
|---|---|
| Colonne `users.last_login` | Sans elle, le login Django lève une `OperationalError` (§6.2) |
| `created_at` sur `categories` et `orateurs` | Cohérence avec les 6 autres tables et traçabilité |
| `CHECK chk_events_dates` | Empêche `date_fin < date_debut` au niveau de la base |
| `CHECK chk_donations_montant` | Empêche un don de montant nul ou négatif |
| `UNIQUE` sur `orateurs.user_id` | Matérialise la relation 1→1 annoncée dans le document |
| Valeurs de `events.type` et `events.statut` | Le document citait les colonnes sans lister les valeurs |
| `newsletter.token_desinscription` en `CHAR(36) NOT NULL UNIQUE` | Un lien de désinscription doit être unique et toujours présent |
| Fichier `seeds/seed_donations_contacts.sql` | Le document prévoyait 3 seeds ; 3 tables sur 8 seraient restées vides pour les tests d'API |
| `validate_schema.sh` | Rendre l'étape ⑤ « validation avec le backend » reproductible |

---

## 12. État de la livraison

| Étape | Livrable | Fichier | État |
|---|---|---|---|
| ① | `schema.sql` complet | `schema.sql` | Livré |
| ② | Documentation BDD | `README.md` | Livré |
| ③ | Migrations SQL | `migrations/001` → `005` | Livré |
| ④ | Seeds de test | `seeds/` (4 fichiers) | Livré |
| ⑤ | Validation avec le backend | `django_models_reference.py` + `validate_schema.sh` | Prêt — reste la revue commune |

Le schéma a été exécuté et vérifié sur **MySQL 8.0.46** : 20 contrôles au
vert, dont les insertions invalides correctement refusées et la conservation
des accents et emojis (`utf8mb4`).

---

## 13. Ce qui est attendu des autres branches

| De | Quoi | Pourquoi |
|---|---|---|
| Backend | Liste des données lues / écrites par chaque vue | Vérifier qu'aucun champ ne manque |
| Backend | Confirmation de l'usage de Django ORM (pas de SQL brut) | Compatibilité des modèles et de `managed=False` |
| Frontend | Liste des formulaires et des champs affichés | Anticiper les colonnes du formulaire de contact |
| Tous | Ne pas modifier `database/` sur vos branches | Éviter les conflits Git sur les fichiers SQL |
