#!/bin/bash

# --------------------------------------------------
# Script : snort-scan.sh
# --------------------------------------------------
# Description :
#   Ce script exécute plusieurs types de scans réseau
#   à l’aide de Nmap afin de générer du trafic réseau
#   détectable par un IDS/IPS (ex: Snort).
#
# Usage :
#   ./snort-scan.sh <target>
#
# Argument :
#   $1 -> Adresse IP ou plage réseau cible
#
# Objectif SOC :
#   - Générer des scans SYN, TCP connect et ACK
#   - Tester la détection des scans réseau
#   - Valider les règles IDS (Snort / Suricata)
# --------------------------------------------------

# Adresse IP ou plage réseau cible
target=$1

# Nom du fichier de sortie contenant les résultats des scans
output_file="nmap_scans_results.txt"

# Liste des types de scans Nmap à exécuter
# -sS : SYN scan
# -sT : TCP connect scan
# -sA : ACK scan
scan_types=("-sS" "-sT" "-sA")

# --------------------------------------------------
# Fonction : Exécuter un ping vers la cible
# Objectif :
#   Vérifier la connectivité et générer du trafic ICMP
# --------------------------------------------------
function run_ping {
    local target="$1"

    echo "Running ping on $target..."
    ping "$target" -c 5
}

# --------------------------------------------------
# Fonction : Exécuter un scan Nmap
# Arguments :
#   $1 -> Cible
#   $2 -> Type de scan
#   $3 -> Fichier de sortie
# Objectif :
#   Générer du trafic réseau suspect analysable
# --------------------------------------------------
function run_nmap_scan {
    local target="$1"
    local scan_type="$2"
    local output_file="$3"

    echo -e "\nRunning Nmap scan on $target with scan type: $scan_type..."
    sudo nmap "$scan_type" "$target" -p1-3306 -oN "$output_file"
    echo "Scan on $target with scan type: $scan_type completed. Results saved in $output_file"
}

# --------------------------------------------------
# Initialisation du fichier de sortie
# --------------------------------------------------
echo "Nmap Scan Results for $target" > "$output_file"

# --------------------------------------------------
# Exécution du ping vers la cible
# --------------------------------------------------
run_ping "$target"

# --------------------------------------------------
# Exécution des différents scans Nmap définis
# --------------------------------------------------
for scan_type in "${scan_types[@]}"; do
    run_nmap_scan "$target" "$scan_type" "$output_file"
done

# --------------------------------------------------
# Fin de l'exécution du script
# --------------------------------------------------
echo "All Nmap scans on $target completed. Combined results saved in $output_file"

