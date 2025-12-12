---
titre: Attaque Scan de Ports Playbook
description: MITRE T1046 Scan Services Réseau
gravité: moyenne
tags: [reconnaissance, scan, réseau, t1046]

# Détection
- Règle Wazuh 100320: UFW BLOCK ports multiples
- Pattern: Tentatives connexions ports multiples
- Source logs: logs firewall ufw

# Réponse
- Exécuter: firewall-drop.sh
- Bloquer: iptables DROP IP source
- Surveiller: Tentatives scan additionnelles
- Alerte: Notification équipe sécurité

# Récupération
- Vérifier: Aucune activité scan en cours
- Surveiller: Réseau pendant 2h
- Audit: Vérifier services exposés
- Rapport: Analyse incident scan