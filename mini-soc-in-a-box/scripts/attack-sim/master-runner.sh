#!/bin/bash
# master-runner.sh
# Orchestration de toutes les simulations d'attaque du Mini-SOC

BASE_DIR="$HOME/scripts/attack-sim"
LOG_DIR="$BASE_DIR/logs"
mkdir -p "$LOG_DIR"

RUN_LOG="$LOG_DIR/master-runner-$(date +%F-%H%M%S).log"

echo "=== Mini-SOC Lab - Attack Simulation Suite ===" | tee -a "$RUN_LOG"
echo "Starting all 13 attack scenarios..." | tee -a "$RUN_LOG"
echo "" | tee -a "$RUN_LOG"

start_all=$(date +%s)

# Liste des scénarios (nom lisible | chemin du script)
scenarios=(
  "01 - Discovery & Recon|$BASE_DIR/attack-sim-01-discovery.sh"
  "02 - Port Scanning|$BASE_DIR/attack-sim-02-port-scanning.sh"
  "03 - SSH Brute Force|$BASE_DIR/attack-sim-03-ssh-brute-force.sh"
  "04 - Web SQL Injection|$BASE_DIR/Web_Exploitation/attack-sim-04-web-sql-injection.sh"
  "05 - Web XSS|$BASE_DIR/Web_Exploitation/attack-sim-05-web-xss.sh"
  "06 - Web Command Injection|$BASE_DIR/Web_Exploitation/attack-sim-06-web-command-injection.sh"
  "07 - Web XXE Injection|$BASE_DIR/Web_Exploitation/attack-sim-07-web-xxe-injection.sh"
  "08 - Web SSRF Injection|$BASE_DIR/Web_Exploitation/attack-sim-08-web-ssrf-injection.sh"
  "09 - Privilege Escalation|$BASE_DIR/Escalation/attack-sim-09-privilege-escalation.sh"
  "10 - Persistence Mechanisms|$BASE_DIR/Persistence/attack-sim-10-persistence-mechanisms.sh"
  "11 - Lateral Movement|$BASE_DIR/attack-sim-11-lateral-movement.sh"
  "12 - Defense Evasion|$BASE_DIR/Defense_Evasion/attack-sim-12-defense-evasion.sh"
  "13 - Data Exfiltration|$BASE_DIR/Data_Exfiltration/attack-sim-13-data-exfiltration.sh"
)

for entry in "${scenarios[@]}"; do
  IFS="|" read -r label script_path <<< "$entry"

  if [ ! -f "$script_path" ]; then
    echo "[$(date +%T)] [SKIP] $label (script absent: $script_path)" | tee -a "$RUN_LOG"
    continue
  fi

  if [ ! -x "$script_path" ]; then
    chmod +x "$script_path" 2>/dev/null || true
  fi

  echo "[$(date +%T)] [RUN ] $label -> $script_path" | tee -a "$RUN_LOG"
  start_scenario=$(date +%s)

  # Exécuter le script et capturer la sortie dans le log
  bash "$script_path" >>"$RUN_LOG" 2>&1

  end_scenario=$(date +%s)
  duration=$(( end_scenario - start_scenario ))
  echo "[$(date +%T)] [DONE] $label (duration: ${duration}s)" | tee -a "$RUN_LOG"
  echo "" | tee -a "$RUN_LOG"

  sleep 2
done

end_all=$(date +%s)
total=$(( end_all - start_all ))

echo "" | tee -a "$RUN_LOG"
echo "=== All attacks simulated ===" | tee -a "$RUN_LOG"
echo "Total duration: ${total}s" | tee -a "$RUN_LOG"
echo "Log file: $RUN_LOG" | tee -a "$RUN_LOG"
echo "Check UI at http://localhost:5173 for real-time alerts" | tee -a "$RUN_LOG"

# (Option) Petit message de “cleanup” manuel
echo ""
echo "Pour remettre le lab au propre, tu peux ensuite purger les tables events/alerts/network_flows"
echo "ou supprimer les fichiers de simulation dans /tmp sur tes VMs (cron_backdoor_sim, etc.)."
