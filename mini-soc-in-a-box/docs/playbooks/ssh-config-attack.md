---
titre: Attaque Configuration SSH Playbook
description: MITRE T1562.001 Affaiblir Défenses: Modifier Configuration SSH
gravité: élevé
tags: [persistance, ssh, configuration, t1562.001]

# Détection
- Règles Wazuh 100210-100211: Modification configuration SSH
- Pattern: Changements sshd_config ou authorized_keys
- Source logs: syscheck FIM

# Réponse
- Exécuter: disable-user.py
- Bloquer: IP source si applicable
- Surveiller: Intégrité configuration SSH
- Alerte: Notification équipe sécurité

# Récupération
- Vérifier: Intégrité configuration SSH rétablie
- Surveiller: Logs SSH pendant 24h
- Audit: Vérifier permissions accès utilisateurs
- Rapport: Analyse incident modification configuration