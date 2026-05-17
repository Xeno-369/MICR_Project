// 1. SPLASH SCREEN / PAGE DE GARDE
document.addEventListener('DOMContentLoaded', function() {
  const splashScreen = document.getElementById('splashScreen');
  const mainSite = document.getElementById('mainSite');
  const discoverBtn = document.getElementById('discoverBtn');

  // Fonction pour fermer l'écran de garde et révéler le site principal
  function dismissSplash() {
    if (!splashScreen || !mainSite) return;
    
    // Animation de disparition du splash
    splashScreen.style.opacity = '0';
    
    // Après l'animation, cacher le splash et afficher le site
    setTimeout(function() {
      splashScreen.style.display = 'none';
      mainSite.classList.add('visible');
      
      // Stocker dans localStorage pour ne pas revoir le splash au rechargement (optionnel)
      localStorage.setItem('splashShown', 'true');
    }, 1200);
  }

  // Événement au clic sur le bouton "Découvrir"
  if (discoverBtn) {
    discoverBtn.addEventListener('click', dismissSplash);
  }

  // Optionnel : Si l'utilisateur a déjà vu le splash, on le supprime immédiatement
  // Décommentez la ligne suivante si vous voulez éviter le splash après la première visite
  // if (localStorage.getItem('splashShown') === 'true') { dismissSplash(); }
});


// 2. NAVBAR SCROLL EFFECT
window.addEventListener('scroll', function() {
  const navbar = document.getElementById('navbar');
  if (navbar && window.scrollY > 20) {
    navbar.classList.add('scrolled');
  } else if (navbar) {
    navbar.classList.remove('scrolled');
  }
});

// 3. MENU MOBILE (HAMBURGER)
const hamburger = document.getElementById('hamburger');
const mobileMenu = document.getElementById('mobileMenu');

function closeMobile() {
  if (mobileMenu) {
    mobileMenu.classList.remove('open');
    document.body.style.overflow = '';
  }
}

function openMobile() {
  if (mobileMenu) {
    mobileMenu.classList.add('open');
    document.body.style.overflow = 'hidden';
  }
}

if (hamburger) {
  hamburger.addEventListener('click', function() {
    if (mobileMenu && mobileMenu.classList.contains('open')) {
      closeMobile();
    } else {
      openMobile();
    }
  });
}

// Fermer le menu mobile lors du clic sur un lien
const mobileLinks = document.querySelectorAll('.mobile-menu a, .mobile-menu button');
mobileLinks.forEach(function(link) {
  link.addEventListener('click', closeMobile);
});

// 4. FONCTIONS DE SCROLL (pour les boutons)
function scrollToPredications() {
  const element = document.getElementById('predications');
  if (element) {
    element.scrollIntoView({ behavior: 'smooth' });
  }
}

function scrollToAgenda() {
  const element = document.getElementById('agenda');
  if (element) {
    element.scrollIntoView({ behavior: 'smooth' });
  }
}

function scrollToContact() {
  const element = document.getElementById('contact');
  if (element) {
    element.scrollIntoView({ behavior: 'smooth' });
  }
}

// Rendre ces fonctions accessibles globalement (pour les onclick dans le HTML)
window.scrollToPredications = scrollToPredications;
window.scrollToAgenda = scrollToAgenda;
window.scrollToContact = scrollToContact;

// 5. INTERSECTION OBSERVER (Révélation au scroll)
const revealElements = document.querySelectorAll('.reveal');

const observer = new IntersectionObserver(function(entries) {
  entries.forEach(function(entry) {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.1 });

revealElements.forEach(function(element) {
  observer.observe(element);
});

// 6. GESTION DES DONS (montants)
function selectAmt(btn) {
  // Retirer la classe active de tous les boutons
  const allBtns = document.querySelectorAll('.amount-btn');
  allBtns.forEach(function(b) {
    b.classList.remove('active');
  });
  
  // Ajouter la classe active au bouton cliqué
  btn.classList.add('active');
  
  const donInput = document.getElementById('donAmt');
  if (!donInput) return;
  
  // Si le bouton n'est pas "Autre", remplir le champ avec la valeur
  if (btn.textContent !== 'Autre') {
    donInput.value = btn.textContent + ' FCFA';
  } else {
    // Si "Autre", vider le champ et le focus pour que l'utilisateur entre un montant
    donInput.value = '';
    donInput.focus();
  }
}

// Rendre selectAmt accessible globalement
window.selectAmt = selectAmt;

// 7. GESTION DU FORMULAIRE DE CONTACT
const formBtn = document.getElementById('formBtn');
if (formBtn) {
  formBtn.addEventListener('click', function() {
    const originalText = this.textContent;
    this.textContent = 'Message envoyé ✓';
    this.style.background = '#166534';
    
    setTimeout(function() {
      if (formBtn) {
        formBtn.textContent = originalText;
        formBtn.style.background = '';
      }
    }, 3000);
  });
}

// 8. ACTIVE LINK HIGHLIGHT (sur le scroll)
const sections = document.querySelectorAll('section[id]');
const navLinks = document.querySelectorAll('.nav-links a');

function updateActiveLink() {
  const scrollPosition = window.scrollY + 150;
  
  sections.forEach(function(section) {
    const sectionTop = section.offsetTop;
    const sectionBottom = sectionTop + section.offsetHeight;
    const sectionId = section.getAttribute('id');
    
    if (scrollPosition >= sectionTop && scrollPosition < sectionBottom) {
      navLinks.forEach(function(link) {
        link.classList.remove('active');
        if (link.getAttribute('href') === '#' + sectionId) {
          link.classList.add('active');
        }
      });
    }
  });
  
  // Cas spécial pour la hero (accueil)
  const hero = document.getElementById('hero');
  if (hero && window.scrollY < hero.offsetHeight - 200) {
    navLinks.forEach(function(link) {
      link.classList.remove('active');
      if (link.getAttribute('href') === '#') {
        link.classList.add('active');
      }
    });
  }
}

window.addEventListener('scroll', updateActiveLink);
updateActiveLink(); // Appel initial

// 9. FERMETURE DU MENU MOBILE SI CLIC À L'EXTÉRIEUR
document.addEventListener('click', function(event) {
  if (!mobileMenu) return;
  
  const isClickInsideMenu = mobileMenu.contains(event.target);
  const isClickOnHamburger = hamburger && hamburger.contains(event.target);
  
  if (mobileMenu.classList.contains('open') && !isClickInsideMenu && !isClickOnHamburger) {
    closeMobile();
  }
});

// 10. PRÉVENTION DU SCROLL DU CORPS QUAND MENU OUVERT

if (mobileMenu) {
  const observerBody = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.attributeName === 'class') {
        if (mobileMenu.classList.contains('open')) {
          document.body.style.overflow = 'hidden';
        } else {
          document.body.style.overflow = '';
        }
      }
    });
  });
  observerBody.observe(mobileMenu, { attributes: true });
}