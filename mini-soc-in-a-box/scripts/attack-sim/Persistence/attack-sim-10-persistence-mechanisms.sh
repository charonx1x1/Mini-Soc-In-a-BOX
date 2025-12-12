#!/bin/bash
# attack-sim-10-persistence-mechanisms.sh
# Persistence mechanisms simulation

source "$HOME/.supabase-env"

ATTACKER_IP="192.168.64.9"   
HOST_IP="192.168.64.7"       

echo "[*] Persistence simulation on $HOST_IP..."

# 1) Simu légère sur le système (fichiers dans /tmp, pas de vrai backdoor)
echo "*/5 * * * * /usr/bin/echo 'ping' > /tmp/.cron_backdoor.log # MALICIOUS_CRON_SIM" \
  > /tmp/cron_backdoor_sim

cat > /tmp/systemd_persistence_sim.service <<EOF
[Unit]
Description=Malicious systemd backdoor (simulation)

[Service]
Type=simple
ExecStart=/usr/bin/echo "systemd backdoor running"

[Install]
WantedBy=multi-user.target
EOF

echo "ssh-rsa AAAA... attacker@lab # MALICIOUS_SSH_KEY_SIM" > /tmp/ssh_key_inject_sim
echo "# MALICIOUS_RC_SIM: backdoor command here" > /tmp/rc_file_mod_sim

# 2) Events dans 'events' (Supabase)

curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$ATTACKER_IP\",
    \"dest_ip\":\"$HOST_IP\",
    \"event_type\":\"cron_backdoor\",
    \"severity\":\"high\",
    \"description\":\"Malicious cron job created (simulation)\",
    \"mitre_technique\":\"T1053\"
  }" >/dev/null

curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$ATTACKER_IP\",
    \"dest_ip\":\"$HOST_IP\",
    \"event_type\":\"systemd_persistence\",
    \"severity\":\"high\",
    \"description\":\"Systemd service backdoor installed (simulation)\",
    \"mitre_technique\":\"T1543\"
  }" >/dev/null

curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$ATTACKER_IP\",
    \"dest_ip\":\"$HOST_IP\",
    \"event_type\":\"ssh_key_inject\",
    \"severity\":\"high\",
    \"description\":\"SSH key injected in authorized_keys (simulation)\",
    \"mitre_technique\":\"T1098\"
  }" >/dev/null

curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"source_ip\":\"$ATTACKER_IP\",
    \"dest_ip\":\"$HOST_IP\",
    \"event_type\":\"rc_file_mod\",
    \"severity\":\"high\",
    \"description\":\"Shell rc file modified for backdoor (simulation)\",
    \"mitre_technique\":\"T1546\"
  }" >/dev/null

# 3) Alerte pour le daily report ('alerts')

curl -s -X POST "$SUPABASE_URL/rest/v1/alerts" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "{
    \"title\": \"Persistence mechanisms detected\",
    \"description\": \"Cron backdoor, systemd persistence, SSH key injection et rc file modification sur $HOST_IP (simulation)\",
    \"severity\": \"high\",
    \"status\": \"open\",
    \"mitre_technique\": \"T1053,T1543,T1098,T1546\"
  }" >/dev/null

echo "[+] Persistence attack simulated"
