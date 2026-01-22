# redmine-plugins
Dépôt pour plugins à partir de la version 6
How to guide mise en place du mapping des groupes via les groupes, puis les rôles
L’objectif est de garantir que les droits administrateur Redmine ne soient jamais attribués manuellement, mais pilotés exclusivement par Keycloak.
________________________________________
MODE D’EMPLOI
Gestion des administrateurs Redmine via Keycloak
________________________________________
1. Principe fondamental
Dans Redmine, le statut Administrateur est :
•	un flag global utilisateur
•	distinct des rôles projet
•	extrêmement sensible
Il doit donc être :
•	attribué uniquement par Keycloak
•	traçable
•	révocable immédiatement
•	jamais modifié à la main
________________________________________
2. Modèle cible
Côté Keycloak
Groupes fonctionnels
kc-redmine-users
kc-redmine-dev
kc-redmine-pm
kc-redmine-admin
Ces groupes peuvent :
•	contenir des utilisateurs
•	contenir des groupes AD fédérés
•	porter des rôles composites
________________________________________
Rôles Keycloak associés
Groupe Keycloak	Rôle Keycloak
kc-redmine-users	redmine_user
kc-redmine-dev	redmine_dev
kc-redmine-pm	redmine_pm
kc-redmine-admin	redmine_admin
Recommandation :
•	les groupes Keycloak sont la couche d’assignation
•	les rôles sont le contrat applicatif
________________________________________
3. Exposition dans le token
Le token doit contenir uniquement les rôles :
"roles": [
  "redmine_user",
  "redmine_dev",
  "redmine_pm",
  "redmine_admin"
]
Redmine ne consomme jamais directement les groupes Keycloak.
________________________________________
4. Comportement attendu dans Redmine
Rôle Keycloak	Effet Redmine
redmine_user	accès applicatif
redmine_dev	rôle projet Developer
redmine_pm	rôle Manager
redmine_admin	flag administrateur global
________________________________________
 
5. Configuration du plugin — mode B étendu
Fichier :
/opt/redmine/plugins/redmine_keycloak_group_mapper/config/group_mapping.yml
________________________________________
Exemple complet
keycloak:
  claim: roles

sync:
  mode: strict

mappings:

  redmine_user:
    redmine_group: Users

  redmine_dev:
    redmine_group: Developpeurs
    projects:
      core:
        roles:
          - Developpeur

  redmine_pm:
    redmine_group: ProjectManagers
    projects:
      core:
        roles:
          - Manager

  redmine_admin:
    admin: true
    redmine_group: Administrateurs
________________________________________
6. Fonctionnement détaillé
Lors de la connexion utilisateur
Le plugin effectue :
1.	Lecture du claim roles
2.	Comparaison avec la configuration
3.	Application stricte :
 
Si redmine_admin présent
user.admin = true
Si absent
user.admin = false
(sauf compte local de secours)
________________________________________
7. Compte administrateur de secours (OBLIGATOIRE)
Indispensable en production.
Créer un compte local :
login : redmine-root
auth  : locale
admin : true
Ne jamais l’inclure dans l’OAuth.
Usage :
•	panne Keycloak
•	erreur de mapping
•	rollback IAM
________________________________________
8. Sécurité en mode strict
En mode strict :
Action	Résultat
Retrait groupe Keycloak admin	perte immédiate admin Redmine
Ajout groupe admin	admin à la reconnexion
Modification manuelle Redmine	écrasée
Accès non déclaré	supprimé
Keycloak devient source d’autorité unique.
________________________________________
9. Exploitation (RUN)
Vérification rapide
grep redmine_admin /opt/redmine/log/production.log
Logs attendus :
IAM: role redmine_admin detected → admin enabled
________________________________________
Test de révocation
1.	Retirer utilisateur du groupe kc-redmine-admin
2.	Déconnexion / reconnexion
3.	Vérifier :
o	plus accès admin
o	menus disparus
________________________________________
10. Gouvernance recommandée
Règles organisationnelles
•	seuls les admins Keycloak gèrent kc-redmine-admin
•	double validation obligatoire
•	journalisation Keycloak activée
•	revue trimestrielle des membres
________________________________________
11. Schéma logique simplifié
AD Group
   ↓
Keycloak Group (kc-redmine-admin)
   ↓
Keycloak Role (redmine_admin)
   ↓
OIDC Token (roles)
   ↓
Redmine admin=true
________________________________________
 
12. Migration depuis le modèle AD
Étape	Action
Phase 1	groupes AD → groupes Keycloak
Phase 2	groupes KC → rôles
Phase 3	Redmine consomme rôles
Phase 4	suppression AD
Phase 5	verrouillage strict
________________________________________
13. Bonnes pratiques critiques
✔ un seul rôle admin
✔ jamais d’admin projet utilisé comme admin global
✔ aucun admin manuel
✔ toujours un compte de secours
✔ toujours le mode strict après migration
________________________________________
14. Résumé exécutif
L’administration Redmine doit être un rôle Keycloak, jamais une décision applicative.
Avec cette architecture :
•	AD peut évoluer ou disparaître
•	Keycloak reste le cœur de la sécurité
•	Redmine devient un consommateur passif
•	les audits sont simples
•	les révocations sont immédiates
________________________________________
