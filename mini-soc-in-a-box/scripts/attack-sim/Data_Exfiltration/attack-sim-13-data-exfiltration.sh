#!/bin/bash
# attack-sim-13-data-exfiltration.sh
# Data exfiltration simulation

source "$HOME/.supabase-env"

# On considère que l'exfil part de la machine interne vers Internet
INTERNAL_HOST="192.168.64.7"   # ubuntu-nad (source des données)
EXTERNAL_IP="8.8.8.8"          # IP externe (simulée)
ATTACKER_IP="192.168.64.9"     # nad_att (toi) pour contexte UI

echo "[*] Data exfiltration simulation from $INTERNAL_HOST to $EXTERNAL_IP..."

# 1) Events d'exfiltration dans 'events' (Supabase)

# Gros transfert de fichier
curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$INTERNAL_HOST\",
    \"dest_ip\":\"$EXTERNAL_IP\",
    \"event_type\":\"file_transfer\",
    \"severity\":\"critical\",
    \"description\":\"Large file transfer to external IP $EXTERNAL_IP\",
    \"mitre_technique\":\"T1020\"
  }" >/dev/null

# Dump de base de données
curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$INTERNAL_HOST\",
    \"dest_ip\":\"$EXTERNAL_IP\",
    \"event_type\":\"db_dump\",
    \"severity\":\"critical\",
    \"description\":\"Database dump exfiltration to $EXTERNAL_IP\",
    \"mitre_technique\":\"T1005\"
  }" >/dev/null

# Archive compressée
curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$INTERNAL_HOST\",
    \"dest_ip\":\"$EXTERNAL_IP\",
    \"event_type\":\"compressed_archive\",
    \"severity\":\"critical\",
    \"description\":\"Compressed archive sent externally\",
    \"mitre_technique\":\"T1560\"
  }" >/dev/null

# DNS tunneling
curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$INTERNAL_HOST\",
    \"dest_ip\":\"$EXTERNAL_IP\",
    \"event_type\":\"dns_tunnel\",
    \"severity\":\"critical\",
    \"description\":\"DNS tunneling detected for exfil\",
    \"mitre_technique\":\"T1048\"
  }" >/dev/null

# 2) Flow réseau “Zeek-like” dans 'network_flows' (pour /network)

BYTES=$((RANDOM % 5000000 + 2000000))   # 2–7 Mo pour simuler un gros transfert
PACKETS=$((RANDOM % 9000 + 2000))
DURATION=$((RANDOM % 120000 + 20000))
SCORE=$((RANDOM % 15 + 85))

curl -s -X POST "$SUPABASE_URL/rest/v1/network_flows" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"src_ip\": \"$INTERNAL_HOST\",
    \"dst_ip\": \"$EXTERNAL_IP\",
    \"src_port\": 55000,
    \"dst_port\": 443,
    \"protocol\": \"tcp\",
    \"bytes_sent\": $BYTES,
    \"packets_sent\": $PACKETS,
    \"duration_ms\": $DURATION,
    \"service\": \"https\",
    \"is_anomalous\": true,
    \"threat_score\": $SCORE
  }" >/dev/null

# 3) Alerte pour le daily report ('alerts')

curl -s -X POST "$SUPABASE_URL/rest/v1/alerts" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"title\": \"Data exfiltration to external IP detected\",
    \"description\": \"Large file transfer, DB dump, compressed archive et DNS tunneling depuis $INTERNAL_HOST vers $EXTERNAL_IP\",
    \"severity\": \"critical\",
    \"status\": \"open\",
    \"mitre_technique\": \"T1020,T1005,T1560,T1048\"
  }" >/dev/null

echo "[+] Data exfiltration attack simulated"
