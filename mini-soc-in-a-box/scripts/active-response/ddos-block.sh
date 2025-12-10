#!/usr/bin/env bash
#Bloque l'IP source d'une attaque DDOS avec iptables

set -euo pipefail

[[ ${EUID:-$(id -u)} -eq 0 ]] || exec sudo -E "$0" "$@"

attacker_ip="${1:-}"

if [[ -z "$attacker_ip" ]]; then
  echo "Usage: $0 <IP_ATTAQUANTE>" >&2
  exit 1
fi

# Valider format IP
if [[ ! "$attacker_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  exit 1
fi

# Vérifier si déjà bloquée
if iptables -C INPUT -s "$attacker_ip" -j DROP 2>/dev/null; then
  exit 0
fi

# Bloquer l'IP
iptables -I INPUT -s "$attacker_ip" -j DROP

# Log simple
echo "$(date '+%F %T') - BLOCKED: $attacker_ip" >> /var/ossec/ddos_blocks.log 2>/dev/null || true