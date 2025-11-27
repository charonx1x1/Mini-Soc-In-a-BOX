#!/usr/bin/env bash
#supprime /etc/cron.d/z99-backdoor et recharge cron

set -euo pipefail
log(){ echo "[$(date +'%F %T')] $*"; }

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then exec sudo -E "$0" "$@"; fi

LAB_FILE="/etc/cron.d/z99-backdoor"
if [[ -f "$LAB_FILE" ]]; then
  log "Quarantaine $LAB_FILE"
  mkdir -p /var/ossec/quarantine
  ts="$(date +'%F_%H-%M-%S')"
  mv "$LAB_FILE" "/var/ossec/quarantine/z99-backdoor.$ts"
  chmod 000 "/var/ossec/quarantine/z99-backdoor.$ts"
  if command -v systemctl >/dev/null; then
    systemctl reload cron 2>/dev/null || systemctl restart cron
  else
    service cron reload 2>/dev/null || service cron restart
  fi
  log "Backdoor cron retirée."
else
  log "Aucun fichier lab à retirer."
fi
