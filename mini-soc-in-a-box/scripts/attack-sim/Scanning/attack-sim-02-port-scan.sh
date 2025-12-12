#!/bin/bash

source "$HOME/.supabase-env"

ATTACKER_IP="192.168.64.7"
TARGET_IP="192.168.64.10"

for port in 22 80 443 3306 5432 8080; do
  curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
    -H "apikey: $SUPABASE_SERVICE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d "{
      \"source_ip\":\"$ATTACKER_IP\",
      \"dest_ip\":\"$TARGET_IP\",
      \"event_type\":\"port_scan\",
      \"severity\":\"medium\",
      \"description\":\"Port $port scan detected on $TARGET_IP\",
      \"mitre_technique\":\"T1046\"
    }" >/dev/null
done

echo "[+] Port scanning attack simulated"
