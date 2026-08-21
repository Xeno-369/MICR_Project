/* =====================================================================
   MICR — Ministère International Christ est la Réponse
   Fichier : Frontend/assets/js/main.js
   ---------------------------------------------------------------------
   Comportement du site vitrine. Aucune dépendance, aucun build.
   Le HTML ne contient plus aucun `onclick` : tout est branché ici via
   les attributs `data-*`.
   ===================================================================== */
(function () {
  'use strict';

  /* ─────────────────────────────────────────────────────────────────
     Navigation entre les "pages"
     Le site est une page unique : toutes les sections sont dans le DOM
     et on n'affiche que celle qui porte la classe .active.
     L'état est reflété dans l'URL (#media, #dons…) pour que les liens
     soient partageables et que le bouton Retour du navigateur marche.
     ───────────────────────────────────────────────────────────────── */
  var PAGES = ['accueil', 'media', 'calendrier', 'contact', 'dons', 'admin'];

  function showPage(name, updateHash) {
    if (PAGES.indexOf(name) === -1) name = 'accueil';

    document.querySelectorAll('.page').forEach(function (p) {
      p.classList.remove('active');
    });
    document.querySelectorAll('.nav a').forEach(function (a) {
      a.classList.remove('active');
      a.removeAttribute('aria-current');
    });

    var page = document.getElementById('page-' + name);
    if (page) page.classList.add('active');

    var navLink = document.getElementById('nav-' + name);
    if (navLink) {
      navLink.classList.add('active');
      navLink.setAttribute('aria-current', 'page');
    }

    if (updateHash !== false && window.location.hash !== '#' + name) {
      window.location.hash = name;
    }
    window.scrollTo(0, 0);
  }

  // Tout élément portant data-page navigue : liens du menu, boutons du
  // hero, liens du footer, "← Retour site" de l'admin.
  document.addEventListener('click', function (e) {
    var trigger = e.target.closest('[data-page]');
    if (!trigger) return;
    e.preventDefault();
    showPage(trigger.dataset.page);
  });

  window.addEventListener('hashchange', function () {
    showPage(window.location.hash.slice(1), false);
  });

  /* ─────────────────────────────────────────────────────────────────
     Groupes à sélection unique (un seul élément actif à la fois)
     ───────────────────────────────────────────────────────────────── */
  function singleSelect(container, items, clicked) {
    items.forEach(function (item) {
      var isActive = item === clicked;
      item.classList.toggle('active', isActive);
      if (item.hasAttribute('role')) {
        item.setAttribute('aria-checked', String(isActive));
      }
    });
    return container;
  }

  function wireSingleSelect(selector, scopeSelector, onSelect) {
    document.addEventListener('click', function (e) {
      var btn = e.target.closest(selector);
      if (!btn) return;
      var scope = scopeSelector ? btn.closest(scopeSelector) : document;
      if (!scope) scope = document;
      singleSelect(scope, Array.prototype.slice.call(scope.querySelectorAll(selector)), btn);
      if (onSelect) onSelect(btn);
    });
  }

  /* ─────────────────────────────────────────────────────────────────
     Médiathèque — filtre par type + recherche par titre
     ───────────────────────────────────────────────────────────────── */
  var currentFilter = 'tous';
  var currentSearch = '';

  // Recherche insensible aux accents : « priere » doit trouver « Prière ».
  function normalise(texte) {
    return texte
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase();
  }

  function applyMediaFilters() {
    var cards = document.querySelectorAll('#media-grid .media-card');
    var visible = 0;

    cards.forEach(function (card) {
      var matchType = currentFilter === 'tous' || card.dataset.type === currentFilter;
      var titre = (card.querySelector('h3') || {}).textContent || '';
      var matchSearch = currentSearch === '' ||
        normalise(titre).indexOf(currentSearch) !== -1;

      var show = matchType && matchSearch;
      card.hidden = !show;
      if (show) visible++;
    });

    var empty = document.getElementById('media-empty');
    if (empty) empty.hidden = visible !== 0;
  }

  wireSingleSelect('.filter-btn', '.filters-bar', function (btn) {
    if (btn.dataset.filter) {
      currentFilter = btn.dataset.filter;
      applyMediaFilters();
    }
  });

  var searchInput = document.getElementById('media-search');
  if (searchInput) {
    searchInput.addEventListener('input', function () {
      currentSearch = normalise(this.value.trim());
      applyMediaFilters();
    });
  }

  /* ─────────────────────────────────────────────────────────────────
     Dons — montants prédéfinis et méthodes de paiement
     ───────────────────────────────────────────────────────────────── */
  var montantInput = document.getElementById('don-montant');
  var methodeSelect = document.getElementById('don-methode');

  wireSingleSelect('.montant-btn', '.montant-grid', function (btn) {
    if (montantInput && btn.dataset.montant) montantInput.value = btn.dataset.montant;
  });

  // Les cartes de gauche et le menu déroulant du formulaire décrivent le
  // même choix : on les garde synchronisés dans les deux sens.
  wireSingleSelect('.methode-card', '.methodes-grid', function (card) {
    if (methodeSelect && card.dataset.methode) methodeSelect.value = card.dataset.methode;
  });

  if (methodeSelect) {
    methodeSelect.addEventListener('change', function () {
      var card = document.querySelector('.methode-card[data-methode="' + this.value + '"]');
      if (!card) return;
      var grid = card.closest('.methodes-grid');
      singleSelect(grid, Array.prototype.slice.call(grid.querySelectorAll('.methode-card')), card);
    });
  }

  /* ─────────────────────────────────────────────────────────────────
     Contact — type de demande / Admin — sidebar
     ───────────────────────────────────────────────────────────────── */
  wireSingleSelect('.radio-btn', '.radio-group');
  wireSingleSelect('.sidebar-link:not([data-page])', '.admin-sidebar');

  /* ─────────────────────────────────────────────────────────────────
     Formulaires — pas encore branchés sur le backend
     On bloque l'envoi pour éviter un rechargement de page trompeur.
     TODO backend : remplacer par un appel à l'API (tables donations,
     contacts, newsletter).
     ───────────────────────────────────────────────────────────────── */
  document.querySelectorAll('[data-form]').forEach(function (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      window.alert(
        'Maquette : le formulaire « ' + form.dataset.form + ' » n\'est pas ' +
        'encore relié au serveur. Aucune donnée n\'a été envoyée.'
      );
    });
  });

  /* ─────────────────────────────────────────────────────────────────
     Démarrage — on respecte le #hash présent dans l'URL
     ───────────────────────────────────────────────────────────────── */
  showPage(window.location.hash.slice(1) || 'accueil', false);
  applyMediaFilters();
})();
