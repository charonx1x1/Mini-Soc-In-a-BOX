# Mini SOC in a Box — Wazuh + Zeek + Suricata (Docker)

Mini SOC pédagogique : une plateforme de **détection** et **réponse** à incident en labo, basée sur **Wazuh** (SIEM/XDR), enrichie par des capteurs **réseau** (Zeek/Suricata) et des règles/scripts personnalisés.

> Petit glossaire  
> **SIEM** : centralise des logs et déclenche des alertes.  
> **XDR** : détection + réponse sur plusieurs sources (machines, réseau, etc.).  
> **NSM** (Network Security Monitoring) : observation du trafic réseau pour repérer des activités suspectes.

**Dépôt Git :** <LIEN_GIT>

---

## Objectif
- Centraliser les logs (hôte + réseau) et produire des **alertes** exploitables.
- Valider la chaîne complète : **collecte → corrélation → alerte → réponse**.
- Disposer de **scripts de simulation d’attaques** (contrôlés) pour tester les détections.

---

## Architecture (lab)
- **Host Docker** : Wazuh Manager + Indexer + Dashboard
- **VM “victime”** : Wazuh Agent (logs système + FIM)
- **Capteurs réseau** : Zeek / Suricata (génèrent des événements réseau)
- **VM “attaquant” (tests)** : exécute des scripts de simulation (environnement isolé)

---

## Composants
- **Wazuh** : collecte, corrélation, règles, alerting, active response.
- **Zeek** : logs réseau détaillés (connexions, anomalies, métadonnées).
- **Suricata** : IDS (détection par signatures/règles réseau).
- **Active Response** : scripts automatiques (ex. blocage IP) déclenchés par alertes.

---

## Structure du dépôt (exemple)
> Ajuste selon ton repo réel.

- `wazuh-docker/` : déploiement Docker Compose (single-node)
- `config/` : conf Wazuh/agents/capteurs (si versionnée)
- `rules/` : règles custom (`local_rules.xml`, etc.)
- `active-response/` : scripts de réponse (blocage IP, actions de confinement, etc.)
- `simulations/` : scripts de **simulation d’attaques** (tests contrôlés)
  - `ssh_bruteforce/`
  - `scan/`
  - `web/`
  - `dos/` *(labo uniquement, sans détails d’exécution ici)*

---

## Quick Start
### Prérequis
- Docker + Docker Compose
- Réseau de labo isolé (VMs dans un réseau host-only / privé)

### Lancer la stack Wazuh
```bash
docker compose up -d
