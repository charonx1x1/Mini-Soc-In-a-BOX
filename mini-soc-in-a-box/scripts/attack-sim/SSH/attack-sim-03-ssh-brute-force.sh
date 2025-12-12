#!/bin/bash
# attack-sim-03-ssh-brute-force.sh

source "$HOME/.supabase-env"

ATTACKER_IP="192.168.64.7"
TARGET_IP="192.168.64.10"

echo "[*] Lancement de 10 tentatives SSH simulées vers $TARGET_IP..."

for i in {1..10}; do
  echo "  - tentative $i"

  # 1) Event dans 'events'
  curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
    -H "apikey: $SUPABASE_SERVICE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d "{
      \"source_ip\":\"$ATTACKER_IP\",
      \"dest_ip\":\"$TARGET_IP\",
      \"event_type\":\"ssh_failed_login\",
      \"severity\":\"high\",
      \"description\":\"SSH failed login attempt $i\",
      \"mitre_technique\":\"T1110\"
    }" >/dev/null
done

# 2) Event de succès dans 'events'
curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$ATTACKER_IP\",
    \"dest_ip\":\"$TARGET_IP\",
    \"event_type\":\"ssh_success\",
    \"severity\":\"critical\",
    \"description\":\"SSH brute force succeeded - account compromise\",
    \"mitre_technique\":\"T1110\"
  }" >/dev/null

# 3) Flow réseau SSH dans 'network_flows' (pour /network)
BYTES=$((RANDOM % 900000 + 100000))
PACKETS=$((RANDOM % 2000 + 200))
DURATION=$((RANDOM % 60000 + 5000))
SCORE=$((RANDOM % 30 + 70))

curl -s -X POST "$SUPABASE_URL/rest/v1/network_flows" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"src_ip\": \"$ATTACKER_IP\",
    \"dst_ip\": \"$TARGET_IP\",
    \"src_port\": 54321,
    \"dst_port\": 22,
    \"protocol\": \"tcp\",
    \"bytes_sent\": $BYTES,
    \"packets_sent\": $PACKETS,
    \"duration_ms\": $DURATION,
    \"service\": \"ssh\",
    \"is_anomalous\": true,
    \"threat_score\": $SCORE
  }" >/dev/null

# 4) Alerte dans 'alerts' (pour le daily report)
curl -s -X POST "$SUPABASE_URL/rest/v1/alerts" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"title\": \"SSH brute force detected\",
    \"description\": \"Multiple SSH failed logins from $ATTACKER_IP to $TARGET_IP, then success\",
    \"severity\": \"critical\",
    \"status\": \"open\",
    \"mitre_technique\": \"T1110\"
  }" >/dev/null

echo "[+] SSH brute force attack simulated"
