#!/bin/bash
# attack-sim-09-privilege-escalation.sh
# Privilege escalation simulation

source "$HOME/.supabase-env"

HOST_IP="192.168.64.7"     # machine où a lieu la privesc (ubuntu-nad)
USER_IP="192.168.64.7"     # même machine (local privesc)

echo "[*] Privilege escalation simulation on $HOST_IP..."

# 1) Générer des logs sudo réels (pour Wazuh)
for i in {1..3}; do
  sudo -n ls /root >/dev/null 2>&1 || true
done

# 2) Events privesc dans 'events' (Supabase)

# sudo misconfiguration / abuse
curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$USER_IP\",
    \"dest_ip\":\"$HOST_IP\",
    \"event_type\":\"sudo_attempt\",
    \"severity\":\"high\",
    \"description\":\"Sudo misconfiguration exploit (NOPASSWD / misused sudo rule)\",
    \"mitre_technique\":\"T1548\"
  }" >/dev/null

# SUID abuse
curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$USER_IP\",
    \"dest_ip\":\"$HOST_IP\",
    \"event_type\":\"suid_abuse\",
    \"severity\":\"high\",
    \"description\":\"SUID binary exploited for privilege escalation\",
    \"mitre_technique\":\"T1548\"
  }" >/dev/null

# Kernel exploit
curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$USER_IP\",
    \"dest_ip\":\"$HOST_IP\",
    \"event_type\":\"kernel_exploit\",
    \"severity\":\"critical\",
    \"description\":\"Kernel vulnerability exploited for privilege escalation\",
    \"mitre_technique\":\"T1548\"
  }" >/dev/null

# Root access obtenu
curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$USER_IP\",
    \"dest_ip\":\"$HOST_IP\",
    \"event_type\":\"root_access\",
    \"severity\":\"critical\",
    \"description\":\"Root access gained after privilege escalation chain\",
    \"mitre_technique\":\"T1548\"
  }" >/dev/null

# 3) Alerte pour le daily report ('alerts')

curl -s -X POST "$SUPABASE_URL/rest/v1/alerts" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"title\": \"Privilege escalation chain detected\",
    \"description\": \"Sudo misuse, SUID abuse, possible kernel exploit et root access sur $HOST_IP\",
    \"severity\": \"critical\",
    \"status\": \"open\",
    \"mitre_technique\": \"T1548\"
  }" >/dev/null

echo \"[+] Privilege escalation attack simulated\"1~#!/bin/bash
# attack-sim-09-privilege-escalation.sh
# Privilege escalation simulation

source "$HOME/.supabase-env"

HOST_IP="192.168.64.7"     
USER_IP="192.168.64.7"     

echo "[*] Privilege escalation simulation on $HOST_IP..."

# 1) Générer des logs sudo réels (pour Wazuh)
for i in {1..3}; do
  sudo -n ls /root >/dev/null 2>&1 || true
done

# 2) Events privesc dans 'events' (Supabase)

# sudo misconfiguration / abuse
curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$USER_IP\",
    \"dest_ip\":\"$HOST_IP\",
    \"event_type\":\"sudo_attempt\",
    \"severity\":\"high\",
    \"description\":\"Sudo misconfiguration exploit (NOPASSWD / misused sudo rule)\",
    \"mitre_technique\":\"T1548\"
  }" >/dev/null

# SUID abuse
curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$USER_IP\",
    \"dest_ip\":\"$HOST_IP\",
    \"event_type\":\"suid_abuse\",
    \"severity\":\"high\",
    \"description\":\"SUID binary exploited for privilege escalation\",
    \"mitre_technique\":\"T1548\"
  }" >/dev/null

# Kernel exploit
curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$USER_IP\",
    \"dest_ip\":\"$HOST_IP\",
    \"event_type\":\"kernel_exploit\",
    \"severity\":\"critical\",
    \"description\":\"Kernel vulnerability exploited for privilege escalation\",
    \"mitre_technique\":\"T1548\"
  }" >/dev/null

# Root access obtenu
curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$USER_IP\",
    \"dest_ip\":\"$HOST_IP\",
    \"event_type\":\"root_access\",
    \"severity\":\"critical\",
    \"description\":\"Root access gained after privilege escalation chain\",
    \"mitre_technique\":\"T1548\"
  }" >/dev/null

# 3) Alerte pour le daily report ('alerts')

curl -s -X POST "$SUPABASE_URL/rest/v1/alerts" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"title\": \"Privilege escalation chain detected\",
    \"description\": \"Sudo misuse, SUID abuse, possible kernel exploit et root access sur $HOST_IP\",
    \"severity\": \"critical\",
    \"status\": \"open\",
    \"mitre_technique\": \"T1548\"
  }" >/dev/null

echo \"[+] Privilege escalation attack simulated\"
