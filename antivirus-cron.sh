#!/usr/bin env bash

DIR="${1:-$HOME/test_folder}"
MALICIOUS_DIR="${2:-$HOME/quarantine_folder}"
WHITELIST_FILE="${3:-.whitelist}"

mkdir -p "$DIR"
mkdir -p "MALICIOUS_DIR"
touch "$WHITELIST_FILE"

shopt -s nullglob
for file in "$DIR"/*; do
    if [ -f "$file" ]; then
        FILENAME="$(basename "$file")"
        if grep -Fxq "$FILENAME" "$WHITELIST_FILE"; then
            continue
        fi
        IS_MALICIOUS=0
        if ["$FILENAME" in *.exe *.bat *.vbs *.scr *.ps1]; then
            IS_MALICIOUS=1
        fi
        if grep -qiE "virus|trojan|malware|worm|ransomware" "$file"; then
            IS_MALICIOUS=1
        fi
        if [ "$IS_MALICIOUS" -eq 1 ]; then
            echo "$(date: '+%Y-%m-%d %H:%M:%S') - $FILENAME is malicious and it is DELETED."
            cp "$file" "$MALICIOUS_DIR/"
            rm -f "file"
        fi
    fi
done
shopt -u nullglob