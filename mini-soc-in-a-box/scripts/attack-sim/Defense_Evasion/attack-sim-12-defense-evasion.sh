#!/bin/bash
# attack-sim-11-lateral-movement.sh
# Lateral movement simulation

source "$HOME/.supabase-env"

ATTACKER_IP="192.168.64.9"   
TARGETS=("192.168.64.7" "192.168.64.10" "192.168.64.20")

echo "[*] Lateral movement simulation depuis $ATTACKER_IP..."

# 1) Events de lateral movement dans 'events' (Supabase)
for host in "${TARGETS[@]}"; do
  echo "  - tentative de mouvement latéral vers $host"

  curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
    -H "apikey: $SUPABASE_SERVICE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d "{
      \"source_ip\":\"$ATTACKER_IP\",
      \"dest_ip\":\"$host\",
      \"event_type\":\"lateral_movement\",
      \"severity\":\"critical\",
      \"description\":\"Lateral movement attempt to $host\",
      \"mitre_technique\":\"T1570\"
    }" >/dev/null
done

# 2) Abus de compte de service / pivot final
PIVOT_HOST="${TARGETS[-1]}"

curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$ATTACKER_IP\",
    \"dest_ip\":\"$PIVOT_HOST\",
    \"event_type\":\"service_account_abuse\",
    \"severity\":\"critical\",
    \"description\":\"Service account compromised for pivoting on $PIVOT_HOST\",
    \"mitre_technique\":\"T1078\"
  }" >/dev/null

# 3) Flow réseau “Zeek-like” pour /network
BYTES=$((RANDOM % 1200000 + 300000))
PACKETS=$((RANDOM % 5000 + 800))
DURATION=$((RANDOM % 90000 + 10000))
SCORE=$((RANDOM % 20 + 80))

curl -s -X POST "$SUPABASE_URL/rest/v1/network_flows" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"src_ip\": \"$ATTACKER_IP\",
    \"dst_ip\": \"$PIVOT_HOST\",
    \"src_port\": 54400,
    \"dst_port\": 22,
    \"protocol\": \"tcp\",
    \"bytes_sent\": $BYTES,
    \"packets_sent\": $PACKETS,
    \"duration_ms\": $DURATION,
    \"service\": \"ssh\",
    \"is_anomalous\": true,
    \"threat_score\": $SCORE
  }" >/dev/null

# 4) Alerte pour le daily report ('alerts')
curl -s -X POST "$SUPABASE_URL/rest/v1/alerts" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"title\": \"Lateral movement and service account abuse detected\",
    \"description\": \"Multiple lateral movement attempts depuis $ATTACKER_IP vers ${TARGETS[*]} avec abus de compte de service sur $PIVOT_HOST\",
    \"severity\": \"critical\",
    \"status\": \"open\",
    \"mitre_technique\": \"T1570,T1078\"
  }" >/dev/null

echo "[+] Lateral movement attack simulated"
