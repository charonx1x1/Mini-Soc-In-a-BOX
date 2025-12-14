# Mini SOC in the Box — Wazuh (SIEM/XDR) + Détection Réseau & Réponse Automatisée

Mini SOC pédagogique conçu pour **détecter**, **corréler** et **réagir automatiquement** à des activités malveillantes sur une petite infra de labo, en combinant **Wazuh** (SIEM/XDR) avec des capteurs **réseau** (Zeek, Suricata) et des sources applicatives (Apache/Teler/DVWA).

## Objectifs
- Mettre en place une plateforme SOC fonctionnelle : **collecte → corrélation → alerting → réponse automatique**
- Simuler des attaques réalistes (web, réseau, SSH, persistance) et **valider** les détections + réponses
- Démontrer une approche **hybride hôte + réseau** (Wazuh + Zeek/Suricata)

---

## Architecture (labo)
- **Host (Docker)** : Wazuh *Manager + Indexer (OpenSearch) + Dashboard*
- **VM Ubuntu (cible supervisée)** : Wazuh Agent + services (Apache/DVWA) + capteurs (Zeek/Suricata) + scripts de réponse
- **VM Debian (attaquant)** : exécution des scripts d’attaque (Hydra, Nikto, Nmap, hping3, etc.)

> Exemple d’IP (modifiable selon votre réseau) :  
> Host `192.168.56.1` — Ubuntu `192.168.56.102` — Debian `192.168.56.104`

---

## Fonctionnalités clés

### Détection & Collecte
- **SSH brute force** via `/var/log/auth.log`
- **Web attacks** : Apache logs + **Teler** (JSON via Syslog) + scans **Nikto** sur **DVWA**
- **Réputation IP** : corrélation `srcip` avec une blacklist AlienVault
- **FIM (File Integrity Monitoring)** : *Realtime* + *WhoData* (auditd) sur répertoires sensibles (`/root`, `/etc/ssh`, `/etc/cron.d`, systemd)
- **Réseau**
  - **Zeek** : logs JSON + script custom de détection **SYN flood**
  - **Suricata** : règles ET Open + `eve.json` remonté dans Wazuh
- **Monitoring Docker** : événements + métriques (CPU/RAM/health), décodeurs + règles custom, dashboard dédié

### Réponse automatisée (Active Response)
- Scripts natifs : `firewall-drop`, `restart-wazuh`, etc.
- Scripts personnalisés (exemples) :
  - **kill-process** : termine un process suspect (PID/nom) depuis les champs de l’alerte
  - **disable-user** : verrouille un compte et kill ses sessions (avec protections sur comptes critiques)
  - **block_ip (nftables)** : ajout/suppression dynamique de règles
  - **cron-revert** : neutralise une backdoor cron, met en quarantaine et relance cron

⚠️ Important : les scripts Active Response doivent être présents sur l’agent, la configuration/règles côté Manager.

---

## Quick start

### 1) Lancer Wazuh (Docker)
```bash
# Dans le dossier wazuh-docker/single-node
docker compose up -d
```

### 2) Modifier correctement la config du Manager (Docker)
Ne pas éditer `/var/ossec/etc/ossec.conf` *dans* le conteneur “en live”. Procédure recommandée :
```bash
docker compose down
# Editer le fichier host:
# wazuh-docker/single-node/config/wazuh_cluster/wazuh_manager.conf
docker compose up -d
```

### 3) Enrôler l’agent Ubuntu
- Installer Wazuh Agent sur la VM Ubuntu
- Enrôler via **clé** générée depuis le Dashboard
- Activer/ajouter la collecte : Apache, Teler, Suricata, Zeek, Docker (localfile / JSON)

### 4) Accéder au Dashboard
- Ouvrir le **Wazuh Dashboard** (OpenSearch Dashboard) depuis le host et vérifier que l’agent est *connected*.

---

## Démo rapide (attaque → alerte → réponse)

### Scénarios de simulation inclus
- **SSH brute-force** (Hydra + wordlist)
- **Recon réseau** (script Nmap : SYN / TCP connect / ACK + ping)
- **Attaques web** (Nikto sur DVWA → détecté par Teler → remonté Wazuh)
- **Persistance**
  - backdoor **cron** (`/etc/cron.d`)
  - backdoor **systemd** (`/etc/systemd/system/*.service`)
- **DoS SYN flood** (hping3)
- **Altération config SSH** (`sshd_config`, `authorized_keys`)

### Où regarder les alertes
- Dashboard → **Threat Hunting** / Security Events : filtrer par `rule.id`, `agent.name`, `srcip`, `data.*`
- Vérifier l’exécution de la réponse (ex: IP bloquée, process tué, fichier en quarantaine).

---

## Contenu du dépôt (typique)
- Config Manager + config Agent
- **Règles locales** (`local_rules.xml`) & **décodeurs**
- Scripts **simulation d’attaques**
- Scripts **Active Response**
- Playbooks : guides analyste (procédure), sans exécution automatique

---

## Stack technique
Wazuh (SIEM/XDR), Docker / Docker Compose, OpenSearch Dashboard, Ubuntu/Debian (VM), DVWA, Apache, Teler, Nikto, Zeek, Suricata (ET Open), Nmap, Hydra, hping3, Syslog, auditd/WhoData, nftables/iptables.

---

## Sécurité & éthique
Projet réalisé **uniquement en environnement isolé et contrôlé** à des fins pédagogiques. Ne pas utiliser ces scripts/outils sur des systèmes sans autorisation.

---

## Auteurs
- Zerrik Marwane  
- Mayas Ould-Kaci  
- Nadya Boussaid  

---

## Références
- Documentation Wazuh 
- Documentation Zeek
- Documentation Docker
- Documentation Suricata
