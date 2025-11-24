#!/usr/bin/env bash
set -Eeuo pipefail 

require(){ command -v "$1" >/dev/null 2>&1 || { printf 'Missing dependency: %s\n' "$1" >&2; exit 127; }; }
require nmap

TARGET="${1:-}"
PORTS="${2:-22,80,111,139,445,3306,5432,8080}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 <TARGET_IP> [PORTS]" >&2
  exit 1
fi

echo "[*] Scanning $TARGET on ports: $PORTS"
# -sT: TCP connect (génère des logs côté cible)
# -Pn: ne fait pas de ping préalable
# -T4: vitesse raisonnable
# --open: n’affiche que les ports ouverts
# --reason: indique la raison (utile pour lire)
nmap -sT -Pn -T4 -p "$PORTS" --open --reason "$TARGET"
echo "[✓] Done."
