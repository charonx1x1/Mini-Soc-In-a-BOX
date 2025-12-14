#!/usr/bin/python3
# ==================================================
# WAZUH ACTIVE RESPONSE - TEST / VALIDATION SCRIPT
# ==================================================
# Ce script est utilisé pour vérifier le bon
# déclenchement d’un Active Response Wazuh
# ==================================================

import os
import sys
import json
import datetime
from pathlib import PureWindowsPath, PurePosixPath

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
ADD_COMMAND = 0       # Exécution de l’Active Response
DELETE_COMMAND = 1    # Suppression / rollback
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
# DEBUG LOGGING FUNCTION
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
    # Lecture de l’alerte depuis stdin
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

    # Identifier le type de commande
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
# ANTI-LOOP MECHANISM (check_keys)
# ==================================================
def send_keys_and_check_message(argv, keys):
    keys_msg = json.dumps({
        "version": 1,
        "origin": {
            "name": argv[0],
            "module": "active-response"
        },
        "command": "check_keys",
        "parameters": {
            "keys": keys
        }
    })

    write_debug_file(argv[0], keys_msg)

    # Envoi à Wazuh
    print(keys_msg)
    sys.stdout.flush()

    # Lecture de la réponse
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
# MAIN ACTIVE RESPONSE LOGIC
# ==================================================
def main(argv):
    write_debug_file(argv[0], "Started")

    # Validation de l’alerte
    msg = setup_and_check_message(argv)

    if msg.command < 0:
        sys.exit(OS_INVALID)

    # ==============================================
    # ADD COMMAND → ACTION PRINCIPALE
    # ==============================================
    if msg.command == ADD_COMMAND:

        # Récupération de l’alerte
        alert = msg.alert["parameters"]["alert"]

        # Utilisation de l’ID de règle comme clé anti-boucle
        keys = [alert["rule"]["id"]]

        # Vérifier si l’AR peut s’exécuter
        action = send_keys_and_check_message(argv, keys)

        if action != CONTINUE_COMMAND:
            write_debug_file(argv[0], "Aborted")
            sys.exit(OS_SUCCESS)

        # ==========================================
        # ACTION DE TEST
        # ==========================================
        # Écriture d’un fichier de preuve
        with open("ar-test-result.txt", mode="a") as test_file:
            test_file.write(
                "Active response triggered by rule ID: <"
                + str(keys) + ">\n"
            )

        # Log dans ossec.log
        import logging
        logging.basicConfig(
            filename='/var/ossec/logs/ossec.log',
            level=logging.INFO
        )
        logging.info(
            "Custom AR add executed successfully"
        )

    # ==============================================
    # DELETE COMMAND → CLEANUP
    # ==============================================
    elif msg.command == DELETE_COMMAND:
        if os.path.exists("ar-test-result.txt"):
            os.remove("ar-test-result.txt")

    else:
        write_debug_file(argv[0], "Invalid command")

    write_debug_file(argv[0], "Ended")
    sys.exit(OS_SUCCESS)

# ==================================================
# ENTRY POINT
# ==================================================
if __name__ == "__main__":
    main(sys.argv)
