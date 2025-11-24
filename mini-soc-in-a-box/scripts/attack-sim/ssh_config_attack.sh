#!/usr/bin/env bash

#Objectif : simuler une modification "risky" de la conf SSH pour générer des événements détectables.
#Mode: --apply (ajoute un fichier 99-lab.conf) | --revert (supprime et recharge le service)

set -Eeuo pipefail
IFS=$'\n\t'

usage(){ cat <<'USAGE'
Usage:
  ssh_config_attack.sh --apply
  ssh_config_attack.sh --revert
Notes:
  - Nécessite sudo (modif de /etc/ssh).
  - Fichier utilisé: /etc/ssh/sshd_config.d/99-lab.conf
USAGE
}

log(){ printf '[%s] %s\n' "$(date +'%F %T')" "$*"; }
require(){ command -v "$1" >/dev/null || { echo "Dépendance manquante: $1"; exit 127; }; }

# Dépendances requises
require sshd
require systemctl
require sed
require tee

LAB_PATH="/etc/ssh/sshd_config.d/99-lab.conf"
MAIN_CFG="/etc/ssh/sshd_config"

ensure_root(){
  if [[ $EUID -ne 0 ]]; then
    log "sudo requis: relance automatiqument avec sudo…"
    exec sudo --preserve-env=PATH "$0" "$@"
  fi
}

apply_changes(){
  log "Application de la modification SSH (lab)…"
  if [[ -d "/etc/ssh/sshd_config.d" ]]; then
    # On ajoute un snippet dédié au lab 
    cat <<'CFG' | tee "$LAB_PATH" >/dev/null
    PermitRootLogin yes
    PasswordAuthentication yes
    Port 2222
CFG
    chmod 0644 "$LAB_PATH"
  fi
  # Vérifie la syntaxe avant de recharger
  if ! sshd -t; then
    log "Erreur de syntaxe SSHD ! On annule."
    [[ -f "$LAB_PATH" ]] && rm -f "$LAB_PATH"
    exit 1
  fi

  # Recharge le service
  systemctl reload ssh || systemctl restart ssh
  log "Modification appliquée et SSH rechargé."
}

revert_changes(){
  log "Restauration de la configuration SSH…"
  if [[ -f "$LAB_PATH" ]]; then
    rm -f "$LAB_PATH"
  # Vérifie la syntaxe avant reload
  fi
  if ! sshd -t; then
    log "Attention: sshd -t échoue après revert. Vérifie $MAIN_CFG."
    exit 1
  fi

  systemctl reload ssh || systemctl restart ssh
  log "Restauration effectuée. SSH rechargé."
}

main(){
  [[ $# -eq 1 ]] || { usage; exit 1; }
  case "$1" in
    --apply)  ensure_root "$@"; apply_changes ;;
    --revert) ensure_root "$@"; revert_changes ;;
    -h|--help|"") usage 0 ;;
  esac
}

main "$@"
