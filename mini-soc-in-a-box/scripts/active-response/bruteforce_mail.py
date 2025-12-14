#!/usr/bin/env python3
import os
import json
import subprocess
import smtplib
from email.message import EmailMessage

CONTAINER = os.environ.get("WAZUH_CONTAINER", "wazuh.manager")
LOG_PATH = "/var/ossec/logs/alerts/alerts.json"
RULE_IDS = {"5712", "5763"}

SMTP_HOST = "smtp.gmail.com"
SMTP_PORT = 587
SMTP_USER = os.environ.get("ALERT_EMAIL_USER")
SMTP_PASS = os.environ.get("ALERT_EMAIL_PASS")
TO_EMAIL  = os.environ.get("ALERT_EMAIL_TO", SMTP_USER)


def get_alert_lines():
  cmd = ["docker", "exec", CONTAINER, "tail", "-n", "200", LOG_PATH]
  out = subprocess.check_output(cmd, text=True)
  res = []
  for line in out.splitlines():
    try:
      j = json.loads(line)
    except Exception:
      continue
    rid = str(j.get("rule", {}).get("id", ""))
    if rid in RULE_IDS:
      res.append(line)
  return res


def send_mail(lines):
  msg = EmailMessage()
  msg["From"] = SMTP_USER
  msg["To"] = TO_EMAIL
  msg["Subject"] = "Alerte brute-force Wazuh (règles 5712/5763)"

  if lines:
    body = "Dernières alertes brute-force:\n\n" + "\n".join(lines)
  else:
    body = "Aucune alerte brute-force (5712/5763) trouvée."
  msg.set_content(body)

  with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as s:
    s.starttls()
    s.login(SMTP_USER, SMTP_PASS)
    s.send_message(msg)


def main():
  lines = get_alert_lines()
  send_mail(lines)


if __name__ == "__main__":
  main()
