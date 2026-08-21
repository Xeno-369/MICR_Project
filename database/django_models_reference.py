"""
MICR_Project — Référence Django ORM pour la base micr_db
=========================================================

Fichier    : database/django_models_reference.py
Auteur     : équipe base de données (branche feature/database)
Destinataire : développeur backend Django

CE FICHIER N'EST PAS UNE APPLICATION DJANGO.
C'est la traduction, table par table, du schéma SQL livré dans
`database/schema.sql`. Le backend copie ce contenu dans son propre
`models.py` (ou s'en sert pour vérifier le résultat de `inspectdb`).

Généré à la main pour rester lisible ; `python manage.py inspectdb`
produit l'équivalent brut mais sans les choix, les related_name ni
les commentaires.

---------------------------------------------------------------------
POINTS DE VIGILANCE (à lire AVANT de coder)
---------------------------------------------------------------------
1. managed = False sur tous les modèles.
   Le schéma appartient à la branche feature/database. Django ne doit
   ni créer ni modifier ces tables. Les changements de structure
   passent par un nouveau fichier dans database/migrations/.

   Conséquence : `manage.py test` ne créera PAS ces tables dans la base
   de test. Solution habituelle — un runner de test qui force
   managed=True (voir README §6.4).

2. users est un modèle d'authentification PERSONNALISÉ.
   Il faut déclarer dans settings.py :  AUTH_USER_MODEL = 'core.User'
   AVANT la première migration du projet. Changer cette valeur après
   coup est douloureux.

3. La colonne SQL s'appelle password_hash, l'attribut Django s'appelle
   password (imposé par AbstractBaseUser). Le mapping se fait avec
   db_column — voir la classe User.

4. bcrypt : Django hash en PBKDF2 par défaut. Pour respecter la règle
   « bcrypt uniquement » du document de workflow, configurer
   PASSWORD_HASHERS dans settings.py (voir README §6.3).
"""

from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.db import models


# =====================================================================
# 1. users
# =====================================================================
class UserManager(BaseUserManager):
    """Manager minimal — indispensable pour `manage.py createsuperuser`."""

    def create_user(self, email, nom, prenom, password=None, **extra):
        if not email:
            raise ValueError("L'adresse email est obligatoire.")
        user = self.model(email=self.normalize_email(email), nom=nom, prenom=prenom, **extra)
        user.set_password(password)          # applique le hasher configuré (bcrypt)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, nom, prenom, password=None, **extra):
        extra.setdefault("role", "admin")
        if extra.get("role") != "admin":
            raise ValueError("Un superuser doit avoir le role 'admin'.")
        return self.create_user(email, nom, prenom, password, **extra)


class User(AbstractBaseUser):
    ROLE_CHOICES = [
        ("admin", "Administrateur"),
        ("membre", "Membre"),
        ("visiteur", "Visiteur"),
    ]

    id = models.AutoField(primary_key=True)
    nom = models.CharField(max_length=80)
    prenom = models.CharField(max_length=80)
    email = models.EmailField(max_length=160, unique=True)

    # AbstractBaseUser impose l'attribut `password`.
    # La colonne SQL, elle, s'appelle password_hash (convention du projet).
    password = models.CharField(max_length=255, db_column="password_hash")

    role = models.CharField(max_length=8, choices=ROLE_CHOICES, default="visiteur")

    # Django (ModelBackend) teste `user.is_active` au login.
    # On mappe cet attribut sur la colonne `actif`.
    is_active = models.BooleanField(default=True, db_column="actif")

    # last_login est fourni par AbstractBaseUser -> colonne `last_login`.
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["nom", "prenom"]

    class Meta:
        managed = False
        db_table = "users"
        verbose_name = "Utilisateur"
        verbose_name_plural = "Utilisateurs"

    def __str__(self):
        return f"{self.prenom} {self.nom} <{self.email}>"

    def get_full_name(self):
        return f"{self.prenom} {self.nom}"

    def get_short_name(self):
        return self.prenom

    # --- Accès à l'admin Django, dérivé du champ `role` ---------------
    # (On n'utilise pas PermissionsMixin : le schéma n'a ni is_superuser
    #  ni les tables de permissions Django.)
    @property
    def is_staff(self):
        return self.role == "admin"

    @property
    def is_superuser(self):
        return self.role == "admin"

    def has_perm(self, perm, obj=None):
        return self.is_superuser

    def has_module_perms(self, app_label):
        return self.is_superuser


# =====================================================================
# 2. categories
# =====================================================================
class Categorie(models.Model):
    id = models.AutoField(primary_key=True)
    nom = models.CharField(max_length=120)
    slug = models.SlugField(max_length=140, unique=True)
    description = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = False
        db_table = "categories"
        verbose_name = "Catégorie"
        verbose_name_plural = "Catégories"

    def __str__(self):
        return self.nom


# =====================================================================
# 3. orateurs
# =====================================================================
class Orateur(models.Model):
    id = models.AutoField(primary_key=True)
    nom = models.CharField(max_length=80)
    prenom = models.CharField(max_length=80)
    photo_url = models.CharField(max_length=512, blank=True, null=True)
    biographie = models.TextField(blank=True, null=True)

    # Relation 1-1 optionnelle : OneToOneField reflète la contrainte
    # uq_orateurs_user (UNIQUE sur user_id) côté SQL.
    user = models.OneToOneField(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_column="user_id",
        related_name="orateur",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = False
        db_table = "orateurs"
        verbose_name = "Orateur"
        verbose_name_plural = "Orateurs"

    def __str__(self):
        return f"{self.prenom} {self.nom}"


# =====================================================================
# 4. sermons
# =====================================================================
class Sermon(models.Model):
    TYPE_CHOICES = [("video", "Vidéo"), ("audio", "Audio"), ("texte", "Texte")]

    id = models.AutoField(primary_key=True)
    titre = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    type = models.CharField(max_length=5, choices=TYPE_CHOICES)
    url_media = models.CharField(max_length=512, blank=True, null=True)

    orateur = models.ForeignKey(
        Orateur, on_delete=models.SET_NULL, null=True, blank=True,
        db_column="orateur_id", related_name="sermons",
    )
    categorie = models.ForeignKey(
        Categorie, on_delete=models.SET_NULL, null=True, blank=True,
        db_column="categorie_id", related_name="sermons",
    )

    duree = models.PositiveIntegerField(null=True, blank=True, help_text="Durée en minutes")
    vues = models.PositiveIntegerField(default=0)
    publie = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = False
        db_table = "sermons"
        ordering = ["-created_at"]
        verbose_name = "Prédication"
        verbose_name_plural = "Prédications"

    def __str__(self):
        return self.titre


# =====================================================================
# 5. events
# =====================================================================
class Event(models.Model):
    TYPE_CHOICES = [
        ("culte", "Culte"),
        ("conference", "Conférence"),
        ("seminaire", "Séminaire"),
        ("convention", "Convention"),
        ("croisade", "Croisade"),
        ("autre", "Autre"),
    ]
    STATUT_CHOICES = [
        ("a_venir", "À venir"),
        ("en_cours", "En cours"),
        ("termine", "Terminé"),
        ("annule", "Annulé"),
    ]

    id = models.AutoField(primary_key=True)
    titre = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    date_debut = models.DateTimeField()
    date_fin = models.DateTimeField(null=True, blank=True)
    lieu = models.CharField(max_length=255, blank=True, null=True)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES, default="culte")
    statut = models.CharField(max_length=8, choices=STATUT_CHOICES, default="a_venir")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = False
        db_table = "events"
        ordering = ["date_debut"]
        verbose_name = "Événement"
        verbose_name_plural = "Événements"

    def __str__(self):
        return self.titre

    def clean(self):
        # Double du CHECK SQL chk_events_dates, côté formulaire.
        from django.core.exceptions import ValidationError
        if self.date_fin and self.date_fin < self.date_debut:
            raise ValidationError("La date de fin ne peut pas précéder la date de début.")


# =====================================================================
# 6. donations
# =====================================================================
class Donation(models.Model):
    METHODE_CHOICES = [
        ("flooz", "Flooz"),
        ("mix_by_yas", "Mix by Yas"),
        ("carte_bancaire", "Carte bancaire"),
        ("virement", "Virement"),
    ]
    STATUT_CHOICES = [
        ("en_attente", "En attente"),
        ("confirme", "Confirmé"),
        ("echoue", "Échoué"),
    ]

    id = models.AutoField(primary_key=True)
    montant = models.DecimalField(max_digits=10, decimal_places=2)
    devise = models.CharField(max_length=10, default="XOF")
    methode = models.CharField(max_length=14, choices=METHODE_CHOICES)

    # UNIQUE côté SQL : protège contre le double-encaissement quand
    # l'opérateur Mobile Money rejoue son callback.
    reference = models.CharField(max_length=100, unique=True, null=True, blank=True)

    statut = models.CharField(max_length=10, choices=STATUT_CHOICES, default="en_attente")
    donateur_nom = models.CharField(max_length=160, blank=True, null=True)
    donateur_email = models.EmailField(max_length=160, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = False
        db_table = "donations"
        ordering = ["-created_at"]
        verbose_name = "Don"
        verbose_name_plural = "Dons"

    def __str__(self):
        return f"{self.montant} {self.devise} — {self.get_statut_display()}"


# =====================================================================
# 7. contacts
# =====================================================================
class Contact(models.Model):
    TYPE_CHOICES = [("contact", "Contact"), ("priere", "Demande de prière")]

    id = models.AutoField(primary_key=True)
    nom = models.CharField(max_length=80)
    prenom = models.CharField(max_length=80, blank=True, null=True)
    email = models.EmailField(max_length=160)
    sujet = models.CharField(max_length=255, blank=True, null=True)
    message = models.TextField()
    type = models.CharField(max_length=7, choices=TYPE_CHOICES, default="contact")
    statut_lu = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = False
        db_table = "contacts"
        ordering = ["-created_at"]
        verbose_name = "Message de contact"
        verbose_name_plural = "Messages de contact"

    def __str__(self):
        return f"[{self.get_type_display()}] {self.nom} — {self.sujet or 'sans sujet'}"


# =====================================================================
# 8. newsletter
# =====================================================================
class NewsletterAbonne(models.Model):
    id = models.AutoField(primary_key=True)
    email = models.EmailField(max_length=160, unique=True)
    actif = models.BooleanField(default=True)

    # UUID v4 généré à l'inscription — sert au lien de désinscription.
    token_desinscription = models.CharField(max_length=36, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = False
        db_table = "newsletter"
        verbose_name = "Abonné newsletter"
        verbose_name_plural = "Abonnés newsletter"

    def __str__(self):
        return self.email

    def save(self, *args, **kwargs):
        # Le token est obligatoire (NOT NULL UNIQUE en base).
        if not self.token_desinscription:
            import uuid
            self.token_desinscription = str(uuid.uuid4())
        super().save(*args, **kwargs)
