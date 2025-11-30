#!/usr/bin/env bash

set -euo pipefail

log(){ echo "[$(date +'%F %T')] $*"; }

[[ ${EUID:-$(id -u)} -eq 0 ]] || exec sudo -E "$0" "$@"

svc="${1:-evil}"

if systemctl list-unit-files | grep -q "^${svc}\.service"; then
  log "Stop/disable ${svc}.service"
  systemctl stop "${svc}.service" || true
  systemctl disable "${svc}.service" || true
  mkdir -p /var/ossec/quarantine
  f="/etc/systemd/system/${svc}.service"
  if [[ -f "$f" ]]; then
    mv "$f" "/var/ossec/quarantine/${svc}.service.$(date +%F_%H-%M-%S)"
  fi
  systemctl daemon-reload
  log "Service ${svc} neutralisé."
else
  log "Service ${svc} introuvable."
fi
