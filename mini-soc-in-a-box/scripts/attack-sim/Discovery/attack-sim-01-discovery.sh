#!/bin/bash
# attack-sim-01-discovery.sh

source "$HOME/.supabase-env"

ATTACKER_IP="192.168.64.7"
TARGET_HOST="192.168.64.10"
TARGET_NET="192.168.64.0/24"

curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "[
    {
      \"source_ip\":\"$ATTACKER_IP\",
      \"dest_ip\":\"$TARGET_NET\",
      \"event_type\":\"discovery\",
      \"severity\":\"low\",
      \"description\":\"Network discovery scan on $TARGET_NET\"
    },
    {
      \"source_ip\":\"$ATTACKER_IP\",
      \"dest_ip\":\"$TARGET_HOST\",
      \"event_type\":\"service_enum\",
      \"severity\":\"medium\",
      \"description\":\"Service enumeration on $TARGET_HOST\"
    },
    {
      \"source_ip\":\"$ATTACKER_IP\",
      \"dest_ip\":\"$TARGET_HOST\",
      \"event_type\":\"vuln_scan\",
      \"severity\":\"high\",
      \"description\":\"Vulnerability scanning on $TARGET_HOST\"
    }
  ]" >/dev/null

echo "[+] Discovery events inserted"
