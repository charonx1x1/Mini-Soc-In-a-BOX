---
titre: Backdoor Cron Playbook
description: MITRE T1053.003 Tâche Planifiée/Job
gravité: élevé
tags: [persistance, cron, backdoor, t1053.003]

# Détection
- Règle Wazuh 100410: Modification /etc/cron.d/
- Alerte FIM sur création fichier cron
- Source logs: syscheck

# Réponse
- Exécuter: cron-revert.sh
- Quarantaine: /etc/cron.d/z99-backdoor -> /var/ossec/quarantine/
- Recharger: systemctl reload cron
- Bloquer: IP source si applicable

# Récupération
- Vérifier: Aucun fichier backdoor cron
- Surveiller: /etc/cron.d/ pendant 24h
- Audit: Vérifier persistance système
- Rapport: Documentation incident