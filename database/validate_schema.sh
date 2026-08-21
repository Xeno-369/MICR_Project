#!/bin/bash
# =====================================================================
# MICR_Project — Vérification du schéma micr_db
# Fichier : database/validate_schema.sh
# ---------------------------------------------------------------------
# Rejoue migrations + seeds sur une base MySQL, puis vérifie que la
# structure et les contraintes se comportent comme prévu (y compris les
# cas qui DOIVENT échouer : dates incohérentes, doublons, FK invalides).
#
# A lancer avant chaque Pull Request sur feature/database.
#
# USAGE :
#   bash database/validate_schema.sh
#
# Connexion configurable par variables d'environnement :
#   DB_HOST (localhost)  DB_PORT (3306)
#   DB_USER (root)       DB_PASSWORD (vide)
#
#   DB_USER=root DB_PASSWORD=monmdp bash database/validate_schema.sh
#
# /!\ Ce script ECRIT dans la base micr_db (migrations, seeds, insertions
#     de test annulées) et la RECREE a l'etape 20. A ne lancer QUE sur
#     un environnement de developpement.
#
# Sous Windows : lancer depuis Git Bash, le client `mysql` doit etre
# dans le PATH.
# =====================================================================
set -u

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-}"

D="$(cd "$(dirname "$0")" && pwd)"

M=(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --default-character-set=utf8mb4)
[ -n "$DB_PASSWORD" ] && M+=(-p"$DB_PASSWORD")

fail=0
step() { echo ""; echo "=============== $* ==============="; }
ok()   { echo "  [OK]   $*"; }
ko()   { echo "  [FAIL] $*"; fail=1; }

run() {
  if "${M[@]}" < "$1" 2> /tmp/micr_err.txt; then ok "$(basename "$1")"
  else ko "$(basename "$1")"; grep -v "Using a password" /tmp/micr_err.txt | head -5; fi
}
q()   { "${M[@]}" -N -B -e "$1" 2>/dev/null; }
qerr() { "${M[@]}" -e "$1" 2>/tmp/micr_e.txt; }

if ! q "SELECT 1;" > /dev/null; then
  echo "Connexion MySQL impossible sur $DB_HOST:$DB_PORT (user=$DB_USER)."
  echo "Verifiez que MySQL tourne et que DB_USER / DB_PASSWORD sont corrects."
  exit 2
fi

step "1. MIGRATIONS dans l'ordre"
for f in "$D"/migrations/*.sql; do run "$f"; done

step "2. Les 8 tables existent"
tables=$(q "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='micr_db';")
[ "$tables" = "8" ] && ok "8 tables" || ko "attendu 8 tables, obtenu: $tables"
q "SELECT table_name, engine, table_collation FROM information_schema.tables WHERE table_schema='micr_db' ORDER BY table_name;"

step "3. InnoDB + utf8mb4 sur toutes les tables"
bad=$(q "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='micr_db' AND (engine<>'InnoDB' OR table_collation NOT LIKE 'utf8mb4%');")
[ "$bad" = "0" ] && ok "toutes InnoDB / utf8mb4" || ko "$bad table(s) non conforme(s)"

step "4. Clés étrangères"
q "SELECT constraint_name, table_name, column_name, referenced_table_name FROM information_schema.key_column_usage WHERE table_schema='micr_db' AND referenced_table_name IS NOT NULL ORDER BY constraint_name;"
fks=$(q "SELECT COUNT(*) FROM information_schema.referential_constraints WHERE constraint_schema='micr_db';")
[ "$fks" = "3" ] && ok "3 FK attendues" || ko "attendu 3 FK, obtenu: $fks"

step "5. Contraintes CHECK"
q "SELECT constraint_name, check_clause FROM information_schema.check_constraints WHERE constraint_schema='micr_db';"

step "6. Index"
q "SELECT table_name, index_name, GROUP_CONCAT(column_name ORDER BY seq_in_index) AS cols FROM information_schema.statistics WHERE table_schema='micr_db' GROUP BY table_name, index_name ORDER BY table_name, index_name;"

step "7. SEEDS dans l'ordre (users AVANT sermons : dépendance FK)"
run "$D/seeds/seed_users.sql"
run "$D/seeds/seed_sermons.sql"
run "$D/seeds/seed_events.sql"
run "$D/seeds/seed_donations_contacts.sql"

step "8. Aucune table vide"
for t in users categories orateurs sermons events donations contacts newsletter; do
  n=$(q "SELECT COUNT(*) FROM micr_db.$t;")
  printf "  %-12s %s\n" "$t" "$n"
  [ "${n:-0}" -gt 0 ] || ko "table $t vide"
done

step "9. Intégrité relationnelle"
q "SELECT s.id, LEFT(s.titre,38), s.type, s.publie, COALESCE(o.nom,'(aucun)'), COALESCE(c.nom,'(aucune)') FROM micr_db.sermons s LEFT JOIN micr_db.orateurs o ON o.id=s.orateur_id LEFT JOIN micr_db.categories c ON c.id=s.categorie_id ORDER BY s.id;"
orph=$(q "SELECT COUNT(*) FROM micr_db.sermons s LEFT JOIN micr_db.orateurs o ON o.id=s.orateur_id WHERE s.orateur_id IS NOT NULL AND o.id IS NULL;")
[ "$orph" = "0" ] && ok "aucun sermon orphelin" || ko "$orph sermon(s) orphelin(s)"

step "10. utf8mb4 — accents et emoji (aller-retour réel)"
q "SELECT sujet, message FROM micr_db.contacts WHERE id = 5;"
acc=$(q "SELECT COUNT(*) FROM micr_db.categories WHERE nom = 'Évangélisation';")
[ "$acc" = "1" ] && ok "accents conservés" || ko "accents perdus ou transformés"
apo=$(q "SELECT COUNT(*) FROM micr_db.sermons WHERE titre = \"L'adoration en esprit et en vérité\";")
[ "$apo" = "1" ] && ok "apostrophe correctement stockée" || ko "problème d'apostrophe"
emo=$(q "SELECT COUNT(*) FROM micr_db.contacts WHERE message LIKE '%🙏%';")
[ "$emo" = "1" ] && ok "emoji 4 octets conservé (utf8mb4, pas utf8mb3)" || ko "emoji perdu — la base n'est pas en utf8mb4"
q "SELECT CHAR_LENGTH(nom) AS caracteres, LENGTH(nom) AS octets, nom FROM micr_db.categories WHERE id = 3;"

step "11. Requêtes métier du site"
echo "-- Dons confirmés par devise :"
q "SELECT devise, SUM(montant), COUNT(*) FROM micr_db.donations WHERE statut='confirme' GROUP BY devise;"
echo "-- Messages non lus :"
q "SELECT type, COUNT(*) FROM micr_db.contacts WHERE statut_lu=0 GROUP BY type;"
echo "-- Agenda à venir :"
q "SELECT id, LEFT(titre,40), date_debut FROM micr_db.events WHERE statut='a_venir' ORDER BY date_debut LIMIT 5;"
echo "-- Sermons publiés (page 1) :"
q "SELECT id, LEFT(titre,40) FROM micr_db.sermons WHERE publie=1 ORDER BY created_at DESC LIMIT 5;"

# ---------------------------------------------------------------------
# Tests NEGATIFS : ces insertions DOIVENT échouer. Si l'une passe,
# c'est qu'une contrainte a disparu du schéma.
# ---------------------------------------------------------------------
step "12. NÉGATIF — date_fin < date_debut doit être REJETÉ"
if qerr "INSERT INTO micr_db.events (titre,date_debut,date_fin) VALUES ('bad','2026-09-10 10:00:00','2026-09-01 10:00:00');"; then
  ko "date incohérente ACCEPTÉE (CHECK chk_events_dates inactif)"
else ok "rejeté: $(grep -o 'ERROR [0-9]*' /tmp/micr_e.txt | head -1)"; fi

step "13. NÉGATIF — montant de don <= 0 doit être REJETÉ"
if qerr "INSERT INTO micr_db.donations (montant,methode) VALUES (0,'flooz');"; then
  ko "montant 0 ACCEPTÉ (CHECK chk_donations_montant inactif)"
else ok "rejeté: $(grep -o 'ERROR [0-9]*' /tmp/micr_e.txt | head -1)"; fi

step "14. NÉGATIF — référence de don en double doit être REJETÉE"
if qerr "INSERT INTO micr_db.donations (montant,methode,reference) VALUES (1000,'flooz','FLZ-2026-0001');"; then
  ko "référence dupliquée ACCEPTÉE — double encaissement possible"
else ok "rejeté: $(grep -o 'ERROR [0-9]*' /tmp/micr_e.txt | head -1)"; fi

step "15. NÉGATIF — orateur_id inexistant doit être REJETÉ"
if qerr "INSERT INTO micr_db.sermons (titre,type,orateur_id) VALUES ('bad','video',9999);"; then
  ko "FK inactive"
else ok "rejeté: $(grep -o 'ERROR [0-9]*' /tmp/micr_e.txt | head -1)"; fi

step "16. NÉGATIF — deux orateurs sur le même compte doit être REJETÉ (1-1)"
if qerr "INSERT INTO micr_db.orateurs (nom,prenom,user_id) VALUES ('X','Y',2);"; then
  ko "relation 1-1 non respectée (uq_orateurs_user manquante)"
else ok "rejeté: $(grep -o 'ERROR [0-9]*' /tmp/micr_e.txt | head -1)"; fi

step "17. NÉGATIF — email utilisateur en double doit être REJETÉ"
if qerr "INSERT INTO micr_db.users (nom,prenom,email,password_hash) VALUES ('A','B','admin@micr-togo.org','x');"; then
  ko "email dupliqué ACCEPTÉ"
else ok "rejeté: $(grep -o 'ERROR [0-9]*' /tmp/micr_e.txt | head -1)"; fi

step "18. ON DELETE SET NULL — supprimer un compte ne casse rien (annulé par ROLLBACK)"
"${M[@]}" -e "START TRANSACTION; DELETE FROM micr_db.users WHERE id=2; SELECT COUNT(*) AS orateurs_restants FROM micr_db.orateurs; SELECT user_id AS user_id_orateur_1 FROM micr_db.orateurs WHERE id=1; SELECT COUNT(*) AS sermons_restants FROM micr_db.sermons; ROLLBACK;" 2>/dev/null
ok "orateur et sermons conservés, user_id passé à NULL"

step "19. IDEMPOTENCE — tout rejouer une 2e fois ne doit rien casser"
for f in "$D"/migrations/*.sql; do run "$f"; done
for f in "$D"/seeds/seed_users.sql "$D"/seeds/seed_sermons.sql "$D"/seeds/seed_events.sql "$D"/seeds/seed_donations_contacts.sql; do run "$f"; done
run "$D/schema.sql"
n=$(q "SELECT COUNT(*) FROM micr_db.sermons;")
[ "$n" = "12" ] && ok "aucun doublon après rejeu (12 sermons)" || ko "doublons: $n sermons au lieu de 12"

step "20. schema.sql SEUL sur une base vierge"
q "DROP DATABASE micr_db;" > /dev/null
run "$D/schema.sql"
t2=$(q "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='micr_db';")
[ "$t2" = "8" ] && ok "schema.sql recrée les 8 tables tout seul" || ko "attendu 8, obtenu $t2"
echo "  (la base est maintenant VIDE : relancer les seeds si besoin)"

echo ""
echo "======================================================"
if [ $fail -eq 0 ]; then echo "RÉSULTAT : TOUS LES TESTS PASSENT"
else echo "RÉSULTAT : ÉCHECS DÉTECTÉS — voir les [FAIL] ci-dessus"; fi
echo "======================================================"
exit $fail
