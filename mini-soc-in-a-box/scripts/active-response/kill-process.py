#!/usr/bin/python3
# ==================================================
# WAZUH ACTIVE RESPONSE - KILL MALICIOUS PROCESS
# Termine automatiquement un processus détecté
# ==================================================

import os
import sys
import json
import datetime
from pathlib import PureWindowsPath, PurePosixPath
import signal
import subprocess

# ==================================================
# ACTIVE RESPONSE LOG FILE
# ==================================================
if os.name == 'nt':
    LOG_FILE = "C:\\Program Files (x86)\\ossec-agent\\active-response\\active-responses.log"
else:
    LOG_FILE = "/var/ossec/logs/active-responses.log"

# ==================================================
# COMMAND TYPES
# ==================================================
ADD_COMMAND = 0       # Lancer la réponse
DELETE_COMMAND = 1    # Supprimer la réponse
CONTINUE_COMMAND = 2  # Continuer l’exécution
ABORT_COMMAND = 3     # Abandonner

OS_SUCCESS = 0
OS_INVALID = -1

# ==================================================
# MESSAGE STRUCTURE
# ==================================================
class message:
    def __init__(self):
        self.alert = ""
        self.command = 0

# ==================================================
# DEBUG LOGGING
# ==================================================
def write_debug_file(ar_name, msg):
    with open(LOG_FILE, mode="a") as log_file:
        ar_name_posix = str(
            PurePosixPath(
                PureWindowsPath(ar_name[ar_name.find("active-response"):])
            )
        )
        log_file.write(
            datetime.datetime.now().strftime('%Y/%m/%d %H:%M:%S')
            + " " + ar_name_posix + ": " + msg + "\n"
        )

# ==================================================
# READ & VALIDATE ALERT MESSAGE
# ==================================================
def setup_and_check_message(argv):
    # Lire l’alerte depuis stdin
    input_str = ""
    for line in sys.stdin:
        input_str = line
        break

    write_debug_file(argv[0], input_str)

    # Décodage JSON
    try:
        data = json.loads(input_str)
    except ValueError:
        write_debug_file(argv[0], 'Invalid JSON format')
        message.command = OS_INVALID
        return message

    message.alert = data

    # Identifier la commande
    command = data.get("command")

    if command == "add":
        message.command = ADD_COMMAND
    elif command == "delete":
        message.command = DELETE_COMMAND
    else:
        message.command = OS_INVALID
        write_debug_file(argv[0], 'Invalid command')

    return message

# ==================================================
# CHECK DUPLICATE EXECUTION (ANTI-LOOP)
# ==================================================
def send_keys_and_check_message(argv, keys):
    keys_msg = json.dumps({
        "version": 1,
        "origin": {"name": argv[0], "module": "active-response"},
        "command": "check_keys",
        "parameters": {"keys": keys}
    })

    write_debug_file(argv[0], keys_msg)

    # Envoyer à Wazuh
    print(keys_msg)
    sys.stdout.flush()

    # Lire la réponse
    input_str = ""
    while True:
        line = sys.stdin.readline()
        if line:
            input_str = line
            break

    write_debug_file(argv[0], input_str)

    try:
        data = json.loads(input_str)
    except ValueError:
        write_debug_file(argv[0], 'Invalid JSON response')
        return message

    action = data.get("command")

    if action == "continue":
        return CONTINUE_COMMAND
    elif action == "abort":
        return ABORT_COMMAND

    write_debug_file(argv[0], "Invalid command response")
    return OS_INVALID

# ==================================================
# PROCESS TERMINATION FUNCTIONS
# ==================================================
def kill_process_by_pid(pid):
    # Kill process using PID
    try:
        os.kill(int(pid), signal.SIGKILL)
        return True
    except Exception:
        return False

def kill_process_by_name(name):
    # Kill process using name
    try:
        subprocess.call(["pkill", "-f", name])
        return True
    except Exception:
        return False

# ==================================================
# MAIN ACTIVE RESPONSE LOGIC
# ==================================================
def main(argv):
    write_debug_file(argv[0], "Started")

    msg = setup_and_check_message(argv)

    if msg.command < 0:
        sys.exit(OS_INVALID)

    # ==============================================
    # ADD COMMAND → TERMINATE PROCESS
    # ==============================================
    if msg.command == ADD_COMMAND:
        alert = msg.alert["parameters"]["alert"]

        # Extraction des données Auditd
        audit_data = alert.get("data", {}).get("audit", {})
        pid = audit_data.get("pid")
        proc_name = audit_data.get("command") or audit_data.get("exe")

        # Fallback via full_log si nécessaire
        if not proc_name:
            full_log = alert.get("full_log", "")
            if full_log:
                proc_name = full_log.split()[0]

        # Vérification des données extraites
        if not pid and not proc_name:
            write_debug_file(argv[0], "ERROR: No PID or process name found")
            sys.exit(OS_INVALID)

        # Clé anti-boucle
        keys = [str(pid)] if pid else [proc_name]

        write_debug_file(argv[0], f"Process identified: {keys}")

        # Vérifier exécution précédente
        action = send_keys_and_check_message(argv, keys)

        if action != CONTINUE_COMMAND:
            write_debug_file(argv[0], "Aborted")
            sys.exit(OS_SUCCESS)

        # ==========================================
        # PROCESS TERMINATION
        # ==========================================
        result = False
        if pid:
            result = kill_process_by_pid(pid)
        elif proc_name:
            result = kill_process_by_name(proc_name)

        if result:
            write_debug_file(argv[0], f"Process terminated successfully: {keys}")
        else:
            write_debug_file(argv[0], f"Failed to terminate process: {keys}")

    # ==============================================
    # DELETE COMMAND → NO ACTION (STATELESS)
    # ==============================================
    elif msg.command == DELETE_COMMAND:
        write_debug_file(argv[0], "No delete action required")

    else:
        write_debug_file(argv[0], "Invalid command")

    write_debug_file(argv[0], "Ended")
    sys.exit(OS_SUCCESS)

# ==================================================
# ENTRY POINT
# ==================================================
if __name__ == "__main__":
    main(sys.argv)
