#!/bin/bash

# --------------------------------------------------
# Script : nikto-scan.sh
# --------------------------------------------------
# Description :
#   Lance un scan de vulnérabilités web avec Nikto
#   sur une cible fournie en argument.
#
# Objectif SOC :
#   - Simuler une attaque de reconnaissance web
#   - Générer des logs HTTP suspects
#   - Tester la détection (Teler / Wazuh / IDS)
#
# Utilisation :
#   ./nikto-scan.sh <IP> <SITE>
#
# Exemple :
#   ./nikto-scan.sh 192.168.56.102 dvwa
#
# Prérequis :
#   - Nikto installé
#   - Accès réseau vers la cible
# --------------------------------------------------

# --------------------------------------------------
# Vérification des arguments
# --------------------------------------------------
if [ $# -ne 2 ]; then
    echo "Usage : $0 <IP> <SITE>"
    echo "Exemple : $0 192.168.56.102 dvwa"
    exit 1
fi

# --------------------------------------------------
# Récupération des arguments
# --------------------------------------------------
TARGET_IP="$1"
TARGET_SITE="$2"

# Construction de l’URL cible
TARGET_URL="http://${TARGET_IP}/${TARGET_SITE}"

# --------------------------------------------------
# Lancement du scan Nikto
# --------------------------------------------------
echo "[*] Démarrage du scan Nikto"
echo "[*] Cible : $TARGET_URL"
echo ""

./nikto.pl -h "$TARGET_URL"

# --------------------------------------------------
# Fin du scan
# --------------------------------------------------
echo ""
echo "[*] Scan Nikto terminé."
