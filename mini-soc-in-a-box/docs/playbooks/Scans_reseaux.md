# Détection Scan Réseau (Netcat / Nmap / TCP Scan)

## Objectif

Identifier, analyser et répondre à une activité de scan réseau menée via
**Netcat (nc)** ou outil similaire, détectée par Wazuh.

------------------------------------------------------------------------

# 1 Déclencheur (Trigger)

Wazuh génère une alerte liée à un scan réseau :

-   **Rule ID typiques :**
    -   5716 : Suspicious network connection\
    -   8801/8802 : Port scanning activity\
    -   81610 : Unusual connection attempt\
-   **Symptômes dans les journaux :**
    -   Multiples connexions sur des ports fermés
    -   Connexions rapides et séquentielles
    -   Tentatives provenant d'une même IP source\
-   **Messages types :**
    -   "Port scan detected"
    -   "Multiple connections to disallowed ports"
    -   "Possible reconnaissance activity"

------------------------------------------------------------------------

# 2 Triage (Validation de l'alerte)

### Étape 1 --- Vérifier l'IP source

-   Est‑elle interne ou externe ?
-   Est‑elle légitime (scanner interne, monitoring...) ?

### Étape 2 --- Vérifier le volume d'événements

-   Nombre de ports testés\
-   Nombre de destinations\
-   Durée du scan (rapide → ping sweep / stealth scan)

### Étape 3 --- Identifier le type de scan

-   `nc -zv` souvent = **TCP connect scan**
-   `nc -u` = **UDP scan**
-   Tentatives rapides → **Nmap‑like scan**

------------------------------------------------------------------------

# 3 Analyse Technique

### Étape 4 --- Examiner les logs réseau sur la machine cible

Linux :

``` bash
grep "SYN" /var/log/syslog | tail -n 20
grep "connection attempt" /var/log/auth.log
```

Windows :

``` powershell
Get-WinEvent -LogName Security | findstr "5152 5156"
```

### Étape 5 --- Vérifier si l'activité est continue

``` bash
ss -tuna | grep <IP_source>
```

### Étape 6 --- Vérifier la réputation de l'IP source

-   AbuseIPDB\
-   VirusTotal\
-   GreyNoise

### Étape 7 --- Vérifier les processus suspects (si scan interne)

Linux :

``` bash
ps aux | grep nc
```

Windows :

``` powershell
Get-Process | Where-Object {$_.Name -like "*nc*"}
```

------------------------------------------------------------------------

# 4 Containment (Confinement)

### Option 1 --- Blocage immédiat de l'IP source

``` bash
sudo iptables -A INPUT -s <IP> -j DROP
```

ou

``` bash
ufw deny from <IP>
```

### Option 2 --- Activer Active Response (automatique Wazuh)

Ajouter dans `ossec.conf` coté manager:

``` xml
<active-response>
  <command>kill-process</command>
  <location>local</location>
  <rules_id>5716,8801,8802</rules_id>
</active-response>
```

### Option 3 --- Si scan interne : isoler la machine

-   Déconnecter du réseau\
-   Passer en VLAN quarantaine

------------------------------------------------------------------------

# 5 Remédiation

### Étape 1 --- Vérifier configuration firewall

-   Désactiver ports non utilisés\
-   Activer rate‑limiting :\

``` bash
iptables -A INPUT -p tcp --syn -m limit --limit 10/s -j ACCEPT
```

### Étape 2 --- Chercher présence d'outils de scan

``` bash
which nc
which nmap
```

### Étape 3 --- Analyse de compromission

-   Rechercher connexions sortantes\
-   Rechercher élévation de privilèges\
-   Vérifier comptes utilisateurs

------------------------------------------------------------------------

# 6 Clôture & Rapport

### Le rapport doit contenir :

-   Date / heure d'apparition\
-   IP source & réputation\
-   Ports scannés\
-   Machine ciblée\
-   Preuves (logs, captures)\
-   Actions de confinement\
-   Actions de remédiation\
-   Risque final : **Reconnaissance / Pré‑attaque**

