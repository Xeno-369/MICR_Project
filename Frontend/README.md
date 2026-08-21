# Frontend MICR

Site vitrine du **Ministère International Christ est la Réponse** (Lomé, Togo).
HTML / CSS / JavaScript natifs — aucun build, aucune dépendance à installer.

## Lancer

Ouvrir `Frontend/index.html` dans un navigateur, ou depuis la racine du dépôt
`index.html` (qui redirige ici).

Pour tester le routage par `#hash` dans de bonnes conditions, servir le dossier :

```bash
python3 -m http.server 8000
# puis http://localhost:8000/Frontend/
```

## Structure

```
Frontend/
├── index.html              Les 6 vues du site
└── assets/
    ├── css/styles.css      Toute la mise en forme
    ├── js/main.js          Navigation + interactions
    └── img/logo.png        Logo MICR
```

**Page unique.** Les 6 vues (accueil, médiathèque, événements, dons, contact,
admin) sont toutes dans `index.html` ; `main.js` n'affiche que celle qui
correspond au `#hash` de l'URL. `#dons` est donc un lien partageable, et le
bouton Retour du navigateur fonctionne.

**Aucun `onclick` dans le HTML.** La navigation passe par `data-page`, les
groupes de boutons par `data-filter`, `data-montant`, `data-methode`,
`data-type`. Tout est branché dans `main.js`.

## Ce qui reste à faire

| Sujet | Détail |
|---|---|
| Photos | Le hero, la section Bienvenue et le portrait du pasteur pointent encore sur Unsplash. Déposer les vraies photos dans `assets/img/` et corriger les chemins (cherchez `TODO photo`). |
| Coordonnées | Téléphone et réseaux sociaux sont des placeholders (`TODO`). |
| Données | Prédications, agenda et tableau de bord admin sont statiques. À brancher sur la base `micr_db` (voir `../database/README.md`). |
| Formulaires | Don, contact et newsletter affichent une alerte au lieu d'envoyer. À relier à l'API. |
| Calendrier | Figé sur mai 2026, les flèches ‹ › ne changent pas de mois. |
| Sécurité | La vue `#admin` est publique. Elle devra être protégée par authentification (`users.role = 'admin'`) avant toute mise en ligne. |
| Accessibilité | Les groupes `.radio-btn` et `.methode-card` sont des boutons stylés, pas de vrais `<input type="radio">`. À reprendre lors du passage à un framework. |
