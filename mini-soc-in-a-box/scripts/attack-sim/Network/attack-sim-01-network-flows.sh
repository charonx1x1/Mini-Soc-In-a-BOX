#!/bin/bash
# attack-sim-01-network-flows.sh

source "$HOME/.supabase-env"

ATTACKER_IP="192.168.64.7"
TARGET_IP="192.168.64.10"
TARGET_PORT=22

for i in {1..5}; do
  BYTES=$((RANDOM % 900000 + 100000))
  PACKETS=$((RANDOM % 2000 + 200))
  DURATION=$((RANDOM % 60000 + 5000))
  SCORE=$((RANDOM % 30 + 70))

  echo "[*] flow $i -> $ATTACKER_IP -> $TARGET_IP:$TARGET_PORT (score=$SCORE)"

  curl -s -X POST "$SUPABASE_URL/rest/v1/network_flows" \
    -H "apikey: $SUPABASE_SERVICE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d "{
      \"src_ip\": \"$ATTACKER_IP\",
      \"dst_ip\": \"$TARGET_IP\",
      \"src_port\": 54321,
      \"dst_port\": $TARGET_PORT,
      \"protocol\": \"tcp\",
      \"bytes_sent\": $BYTES,
      \"packets_sent\": $PACKETS,
      \"duration_ms\": $DURATION,
      \"service\": \"ssh\",
      \"is_anomalous\": true,
      \"threat_score\": $SCORE
    }" >/dev/null
done

echo "[+] Network flows insérés dans network_flows"
