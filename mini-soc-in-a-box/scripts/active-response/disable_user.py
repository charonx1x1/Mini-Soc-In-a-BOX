#!/usr/bin/python3
# ================================================
# WAZUH ACTIVE RESPONSE - CUSTOM USER BLOCK
# Blocage automatique de comptes après alertes
# ================================================

import os
import sys
import json
import datetime
from pathlib import PureWindowsPath, PurePosixPath

# ================================================
# LOG ACTIVE RESPONSE
# ================================================
if os.name == 'nt':
    LOG_FILE = "C:\\Program Files (x86)\\ossec-agent\\active-response\\active-responses.log"
else:
    LOG_FILE = "/var/ossec/logs/active-responses.log"

# ================================================
# COMMAND TYPES
# ================================================
ADD_COMMAND = 0       # Ajout de la réponse
DELETE_COMMAND = 1    # Suppression de la réponse
CONTINUE_COMMAND = 2  # Continuer l’exécution
ABORT_COMMAND = 3     # Abandonner

OS_SUCCESS = 0
OS_INVALID = -1

# ================================================
# MESSAGE STRUCTURE
# ================================================
class message:
    def __init__(self):
        self.alert = ""
        self.command = 0

# ================================================
# DEBUG LOGGING
# ================================================
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

# ================================================
# READ & VALIDATE INPUT MESSAGE
# ================================================
def setup_and_check_message(argv):

    # Lire l’alerte envoyée par Wazuh via stdin
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

    # Identifier la commande Wazuh
    command = data.get("command")

    if command == "add":
        message.command = ADD_COMMAND
    elif command == "delete":
        message.command = DELETE_COMMAND
    else:
        message.command = OS_INVALID
        write_debug_file(argv[0], 'Invalid command')

    return message

# ================================================
# CHECK DUPLICATE KEYS (ANTI-LOOP)
# ================================================
def send_keys_and_check_message(argv, keys):

    # Construire la requête check_keys
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
    else:
        write_debug_file(argv[0], "Invalid command response")
        return OS_INVALID

# ================================================
# MAIN ACTIVE RESPONSE LOGIC
# ================================================
def main(argv):

    write_debug_file(argv[0], "Started")

    # Lecture et validation de l’alerte
    msg = setup_and_check_message(argv)

    if msg.command < 0:
        sys.exit(OS_INVALID)

    # ============================================
    # ADD COMMAND → BLOCK USER
    # ============================================
    if msg.command == ADD_COMMAND:

        alert = msg.alert["parameters"]["alert"]

        # Générer une clé unique (anti-boucle)
        event_id = alert["id"]
        user = alert["data"]["dstuser"]
        keys = [user + "_" + event_id]

        # Vérifier si la réponse a déjà été exécutée
        action = send_keys_and_check_message(argv, keys)

        if action != CONTINUE_COMMAND:
            write_debug_file(argv[0], "Aborted")
            sys.exit(OS_SUCCESS)

        # ========================================
        # IDENTIFICATION DE L’UTILISATEUR À BLOQUER
        # ========================================
        data = alert.get("data", {})
        src = data.get("srcuser")
        dst = data.get("dstuser")

        # Priorité à srcuser si présent
        if src and src not in ["", "root"]:
            user = src
        else:
            user = dst

        # Sécurité : ne jamais bloquer root
        if user in ["root", "mini-soc"]:
            write_debug_file(argv[0], "Refusing to block protected account")
            sys.exit(OS_SUCCESS)

        write_debug_file(argv[0], f"Blocking user {user}")

        # Verrouillage du compte
        os.system(f"passwd -l {user}")

        # Fermeture des sessions actives
        os.system(f"pkill -KILL -u {user}")

    # ============================================
    # DELETE COMMAND → UNBLOCK USER
    # ============================================
    elif msg.command == DELETE_COMMAND:

        alert = msg.alert["parameters"]["alert"]
        data = alert.get("data", {})

        src = data.get("srcuser")
        dst = data.get("dstuser")

        if src and src not in ["", "root"]:
            user = src
        else:
            user = dst

        if user == "root":
            write_debug_file(argv[0], "Refusing to unlock root")
            sys.exit(OS_SUCCESS)

        write_debug_file(argv[0], f"Unlocking user {user}")

        # Déverrouillage du compte
        os.system(f"passwd -u {user}")

    write_debug_file(argv[0], "Ended")
    sys.exit(OS_SUCCESS)

# ================================================
# ENTRY POINT
# ================================================
if __name__ == "__main__":
    main(sys.argv)
