---
titre: Attaque DDOS SYN Flood Playbook
description: MITRE T1498 Déni de Service Réseau
gravité: critique
tags: [ddos, réseau, déni-de-service, t1498]

# Détection
- Règle Zeek 100912: DDOS SYN flood détecté
- Seuil: 50+ paquets SYN en 30s
- Source logs: zeek notice.log

# Réponse
- Exécuter: ddos-block.sh
- Bloquer: iptables DROP IP source
- Surveiller: Patterns trafic réseau
- Alerte: Notification équipe sécurité

# Récupération
- Vérifier: Aucun trafic DDOS en cours
- Surveiller: Réseau pendant 1h
- Audit: Vérifier performance système
- Rapport: Analyse incident DDOS