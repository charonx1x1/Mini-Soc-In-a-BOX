# Détection & Réponse à un Scan Nikto

## Objectif

Détecter, analyser et répondre à un scan automatisé réalisé avec
**Nikto**, identifié via des logs web (Apache/Nginx) analysés par un
outil de détection comme **Teler**, puis transmis en Syslog à un SIEM
tel que **Wazuh**, avec possibilité de blocage automatique via Active
Response.

------------------------------------------------------------------------

# 1 Déclencheur (Trigger)

### Sources de détection possibles

-   **Teler** détecte un pattern anormal dans les logs web.
-   Les logs Apache/Nginx sont envoyés en **Syslog** vers Wazuh.
-   Une règle Wazuh match un comportement typique Nikto.

### Indicateurs typiques d'un scan Nikto

-   User-Agent :

        Nikto/2.1.X

-   Multiples requêtes très rapides vers des endpoints sensibles :

    -   `/phpinfo.php`
    -   `/server-status`
    -   `/test/`
    -   `/cgi-bin/`
    -   `/admin/`
    -   `/robots.txt`

-   Enumération agressive :

    -   recherche de fichiers backup (`.bak`, `.old`, `.zip`)
    -   tests de vulnérabilités connues

-   HTTP anomalies :

    -   50+ requêtes en quelques secondes
    -   nombreux codes 404/403

### Exemple de log web

    "GET /phpinfo.php HTTP/1.1" 200 - "-" "Nikto/2.1.6"

------------------------------------------------------------------------

# 2 Triage (Validation initiale)

### Étape 1 --- Confirmer la détection Teler

    sudo cat /var/log/teler/teler.log | grep -i nikto

### Étape 2 --- Vérifier la remontée SIEM

Depuis Wazuh Dashboard : - IP source - Fréquence des requêtes -
User‑Agent - Type d'URL ciblées - Règle Wazuh déclenchée

### Étape 3 --- Identifier la sévérité

-   **Scan externe** → risque recon / pré‑attaque\
-   **Scan interne** → risque critique (analyse latérale &
    compromission)

------------------------------------------------------------------------

# 3 Analyse Technique

### Étape 4 --- Examiner les logs web bruts

    sudo tail -n 100 /var/log/apache2/access.log
    sudo tail -n 100 /var/log/nginx/access.log

Points à vérifier : - modèle du User-Agent - volume des requêtes -
endpoints ciblés - répétitions cycliques (signature Nikto)

------------------------------------------------------------------------

### Étape 5 --- Analyse des logs Teler (post‑parsing)

    sudo cat /var/log/teler/alerts.log

Rechercher : - tags type *Recon*, *Fuzzing*, *Scanner* - patterns
suspects détectés par Teler

------------------------------------------------------------------------

### Étape 6 --- Réputation de l'IP

-   AbuseIPDB\
-   VirusTotal\
-   GreyNoise (fort taux de détection Nikto)

------------------------------------------------------------------------

### Étape 7 --- Vérifier Active Response

    sudo cat /var/ossec/logs/active-responses.log | grep firewall-drop

------------------------------------------------------------------------

# 4 Containment (Confinement)

### Option 1 --- Blocage automatique Wazuh (Active Response)

Exemple dans `ossec.conf` :

``` xml
<active-response>
    <command>firewall-drop</command>
    <location>local</location>
    <rules_id>8801, 8802, 100200</rules_id>
</active-response>
```

(*100200 = règle personnalisée Nikto si utilisée*)

### Option 2 --- Blocage manuel immédiat

    sudo iptables -A INPUT -s <IP_ATTACKER> -j DROP

ou

    sudo ufw deny from <IP_ATTACKER>

### Option 3 --- Si l'IP est interne

-   isoler la machine suspecte\
-   désactiver son interface réseau\
-   escalader vers l'équipe sécurité

------------------------------------------------------------------------

# 5 Remédiation

### Étape 1 --- Hardening du serveur web

-   désactiver pages sensibles (`/server-status`, `/test`, `/phpinfo`)
-   activer *rate limiting*
-   limiter les méthodes HTTP autorisées
-   désactiver les répertoires listables

### Étape 2 --- Mettre à jour

-   serveur web (Apache/Nginx)
-   modules / extensions
-   librairies exposées

### Étape 3 --- Vérifier d'éventuelles tentatives d'exploitation

-   recherche d'upload de fichiers suspects
-   recherche d'exécution de commandes anormales
-   analyse des logs d'erreur :

```{=html}
<!-- -->
```
    sudo tail -n 100 /var/log/apache2/error.log
    sudo tail -n 100 /var/log/nginx/error.log

### Étape 4 --- Mise en place d'un WAF (optionnel)

-   ModSecurity
-   OWASP CRS

------------------------------------------------------------------------

# 6 Clôture & Documentation

Le rapport doit inclure : - Timestamp du scan\
- IP source & réputation\
- Type de scan Nikto détecté\
- Patterns identifiés\
- Règles SIEM déclenchées\
- Actions de confinement\
- Indicateurs éventuels d'exploitation\
- Niveau de risque final

### Conclusion possible

-   **Incident de reconnaissance précoce**, aucun signe d'exploitation.
    → clôture.\
    ou\
-   **Suspicion d'exploitation → escalade IR & forensic.**

