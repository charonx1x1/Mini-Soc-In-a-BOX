---
titre: Backdoor Systemd Playbook
description: MITRE T1543.002 Créer ou Modifier Processus Système
gravité: élevé
tags: [persistance, systemd, backdoor, t1543.002]

# Détection
- Règle Wazuh 100520: Modification /systemd/system/*.service
- Alerte FIM sur création fichier service
- Source logs: syscheck

# Réponse
- Exécuter: systemd-disable.sh evil
- Quarantaine: /etc/systemd/system/evil.service -> /var/ossec/quarantine/
- Recharger: systemctl daemon-reload
- Bloquer: IP source si applicable

# Récupération
- Vérifier: Aucun service systemd malveillant
- Surveiller: /etc/systemd/system/ pendant 24h
- Audit: Vérifier services activés
- Rapport: Documentation incident