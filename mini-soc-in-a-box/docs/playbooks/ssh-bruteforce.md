# Brute-Force SSH détecté par Wazuh

## Objectif

Identifier, analyser et répondre à une attaque de type brute-force SSH
détectée par une règle Wazuh.

------------------------------------------------------------------------

# 1 Déclencheur (Trigger)

Wazuh génère une alerte du type :

-   **Rule ID :** 5710, 5712, 5720 (selon OS)
-   **Niveau :** 8 → 10
-   **Message :** `sshd: authentication failure` ou
    `Multiple failed logins`
-   **Source log :** `/var/log/auth.log` ou `/var/log/secure`

------------------------------------------------------------------------

# 2 Actions Immédiates (Triage)

### Étape 1 --- Vérifier l'alerte dans Wazuh Dashboard

-   Confirmer que l'alerte vient de SSH.
-   Vérifier :
    -   l'IP source\
    -   le nombre de tentatives\
    -   l'utilisateur ciblé\
    -   le système attaqué

### Étape 2 --- Vérifier la présence d'un succès de connexion

Dans Wazuh (ou via logs de l'agent) : - Chercher : **"Accepted
password"** ou **"Accepted publickey"** - Si réussite → risque
**critique** → escalade immédiate.

------------------------------------------------------------------------

# 2 Analyse Technique

### Étape 3 --- Vérifier la réputation de l'IP attaquante

-   AbuseIPDB\
-   VirusTotal\
-   Shodan

### Étape 4 --- Vérifier les logs SSH directement sur l'agent

``` bash
grep "Failed password" /var/log/auth.log | tail -n 20
grep "Accepted" /var/log/auth.log
lastb | head
```

### Étape 5 --- Vérifier si l'utilisateur visé existe

``` bash
cat /etc/passwd
```

### Étape 6 --- Vérifier si un blocage automatique Wazuh (Active Response) s'est déclenché

``` bash
cat /var/ossec/logs/active-responses.log
```

------------------------------------------------------------------------

# 4 Containment (Confinement)

Selon le niveau du risque :

### **Option 1 --- Blocage manuel de l'IP**

``` bash
sudo ufw deny from <IP>
# ou
sudo iptables -A INPUT -s <IP> -j DROP
```

### **Option 2 --- Activer Active Response Wazuh**

(Blocage automatique des IP par Wazuh)

Ajouter dans `ossec.conf` coté manager:

``` xml
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>5710,5712,5720</rules_id>
</active-response>
```

------------------------------------------------------------------------

# 5 Remédiation

### Hardening SSH

Changer : - le port SSH - désactiver mot de passe :
`PasswordAuthentication no` - activer les clés SSH - installer Fail2ban

### Vérifier les comptes système

``` bash
awk -F: '{ print $1, $3, $7 }' /etc/passwd
```

### Forcer changement mot de passe si suspicion

``` bash
passwd <user>
```

------------------------------------------------------------------------

# 6 Clôture et Documentation

### Rédiger un rapport :

-   Heure de l'incident\
-   Logs collectés\
-   IP attaquante et réputation\
-   Actions prises\
-   Mesures de prévention

