#!/bin/bash
# ==========================================================
# WAZUH ACTIVE RESPONSE - FIREWALL NFTABLES
# ==========================================================
# Script utilisé pour bloquer / débloquer une IP
# via nftables depuis une alerte Wazuh
#
# Arguments :
#   $1 = Adresse IP à bloquer
#   $2 = action ("unblock" pour débloquer)
# ==========================================================

IP="$1"          # IP source détectée par Wazuh
ACTION="$2"      # Action : blocage ou déblocage
TABLE="filter"   # Table nftables
CHAIN="input"    # Chaîne INPUT

# ==========================================================
# Vérification de l’IP
# ==========================================================
if [ -z "$IP" ]; then
  # Pas d’IP → rien à faire
  exit 0
fi

# ==========================================================
# BLOCAGE DE L’IP
# ==========================================================
if [ "$ACTION" != "unblock" ]; then

  # Vérifie si la règle existe déjà
  nft list ruleset | grep -q "ip saddr $IP drop"
  if [ $? -eq 0 ]; then
    echo "$IP est déjà bloquée"
    exit 0
  fi

  # Ajout de la règle nftables
  nft add rule $TABLE $CHAIN ip saddr $IP drop

  echo "Bloqué $IP"
  logger "Wazuh active response: blocked $IP via nftables"

# ==========================================================
# DÉBLOCAGE DE L’IP
# ==========================================================
else

  # Récupération du handle de la règle nftables
  HANDLE=$(sudo nft -a list chain ip $TABLE $CHAIN \
           | grep "ip saddr $IP drop" \
           | awk '{print $NF}')

  if [ -z "$HANDLE" ]; then
    echo "$IP n'est pas bloquée"
    exit 0
  fi

  # Suppression de la règle
  nft delete rule $TABLE $CHAIN handle $HANDLE

  echo "Débloqué $IP"
  logger "Wazuh active response: unblocked $IP via nftables"
fi
