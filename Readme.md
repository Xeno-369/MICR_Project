<p align="center">
  <img src="Frontend/Accueil_MICR/logo.png" width="400" alt="MICR Project Logo">
</p>

# 🕊️ MICR Project : Digitaliser la Foi

![Status](https://img.shields.io/badge/Status-En_D%C3%A9veloppement-gold)
![Frontend](https://img.shields.io/badge/Frontend-Page_d'accueil_livr%C3%A9e-blue)
![Database](https://img.shields.io/badge/Database-Sch%C3%A9ma_v1.0_livr%C3%A9-brightgreen)
![Backend](https://img.shields.io/badge/Backend-Hors_d%C3%A9p%C3%B4t-lightgrey)

> **"Le Christ Ressuscité, au cœur du monde."**
> Une plateforme immersive conçue pour transformer l'évangélisation à l'ère du numérique.

---

## ✨ À propos du projet

Le **MICR Hub** n'est pas qu'un simple site web. C'est un écosystème multimédia complet
dédié à la communauté du *Mouvement International du Christ Ressuscité*. Situé à Kara
(Togo) mais à portée mondiale, ce projet fusionne spiritualité et technologie pour
l'évangélisation.

Le cahier des charges complet est dans [`docs/MICR_CahierDesCharges.pdf`](docs/MICR_CahierDesCharges.pdf).

---

## 🗂️ Architecture du dépôt

```
MICR_Project/
├── index.html                  Point d'entrée — redirige vers la page d'accueil
├── Readme.md                   Ce fichier
├── .gitignore                  Protège .env et les dumps SQL
│
├── Frontend/                   Interface publique (HTML / CSS / JS)
│   └── Accueil_MICR/
│       ├── MICR_accueil.html   Page d'accueil
│       ├── MICR_accueil.css
│       ├── MICR_accueil.js
│       ├── logo.png            Logo MICR (aussi utilisé par ce README)
│       ├── jesus.jpeg          Visuel de la section héro
│       └── jesusLogo.jpeg      Visuel de l'écran de chargement
│
├── database/                   Couche base de données — MySQL 8 / micr_db
│   ├── README.md               ⭐ Documentation complète de la BDD (à lire avant d'y toucher)
│   ├── schema.sql              Les 8 tables en un seul fichier (installation neuve)
│   ├── migrations/             001 → 005 — historique des changements de schéma
│   ├── seeds/                  4 jeux de données de test
│   ├── django_models_reference.py   Traduction du schéma en modèles Django
│   ├── validate_schema.sh      20 contrôles automatiques
│   └── .env.example            Modèle des variables de connexion
│
└── docs/
    └── MICR_CahierDesCharges.pdf
```

> **Le backend ne figure pas dans ce dépôt.** Il est développé séparément par un autre
> membre de l'équipe. Ce que la base de données attend de lui est décrit dans
> [`database/README.md` §13](database/README.md).

---

## 📦 État des modules

| Module | Périmètre | État |
|---|---|---|
| **Frontend** | Page d'accueil responsive (prédications, agenda, dons, contact) | ✅ Livrée |
| **Database** | Schéma `micr_db` — 8 tables, migrations, seeds, validation, modèles Django | ✅ Livré (v1.0) |
| **Backend** | API, authentification, upload média, paiements | ⏳ Hors dépôt — autre développeur |
| **Déploiement** | VPS, nom de domaine, HTTPS, sauvegardes | ⏳ À venir |

---

## 🎨 Identité Visuelle

* **Bleu Nuit (#0D1B2A)** — profondeur, sérieux, sérénité.
* **Or (#E09F3E)** — lumière, divin, préciosité.

---

## 🛠️ Stack Technique

| Couche | Technologies |
|---|---|
| **Frontend** | HTML5, CSS3 (Flexbox / Grid), JavaScript (ES6+) |
| **Database** | MySQL 8.x, moteur InnoDB, charset `utf8mb4` |
| **Backend** | Django (ORM) — hors dépôt |

**Convention de branches :** `main` pour l'intégration, `feature/<module>` pour le
travail en cours (`feature/database`, `feature/frontend`, `feature/backend`).
Toute évolution arrive sur `main` par Pull Request.

---

## 📥 Installation

### 1. Cloner le dépôt

```bash
git clone https://github.com/Xeno-369/MICR_Project.git
cd MICR_Project
```

### 2. Visualiser le frontend

Ouvrir `index.html` dans un navigateur — il redirige vers la page d'accueil.
Directement : `Frontend/Accueil_MICR/MICR_accueil.html`.

### 3. Monter la base de données

```bash
# Structure (crée micr_db automatiquement)
mysql -u root -p < database/schema.sql

# Données de test — ordre imposé : users AVANT sermons
mysql -u root -p < database/seeds/seed_users.sql
mysql -u root -p < database/seeds/seed_sermons.sql
mysql -u root -p < database/seeds/seed_events.sql
mysql -u root -p < database/seeds/seed_donations_contacts.sql

# Vérifier (20 contrôles, doit finir sur "TOUS LES TESTS PASSENT")
bash database/validate_schema.sh
```

Puis copier le modèle de configuration :

```bash
cp database/.env.example .env
```

Les seeds sont réservés au **développement** : leurs mots de passe sont publics
puisqu'ils sont dans le dépôt. Détails, schéma table par table, index, intégration
Django et règles de sécurité : **[`database/README.md`](database/README.md)**.

---

## 👥 Équipe

Projet développé par une équipe de 4 personnes, un module par personne
(frontend, base de données, backend, déploiement).
