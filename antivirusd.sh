#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <dir> <malicious_dir> <interval_secs>"
    exit 1
fi

DIR="$1"
MALICIOUS_DIR="$2"
INTERVAL="$3"

LAST_INFO="directory_info.last"
NEW_INFO="directory_info.new"
WHITELIST_FILE=".whitelist"

if [ ! -d "$DIR" ]; then
    echo "Error: Monitored directory '$DIR' does not exist."
    exit 1
fi

mkdir -p "$MALICIOUS_DIR"
touch "$WHITELIST_FILE"

BAD_EXTENSIONS=("exe" "bat" "vbs" "scr" "ps1")
BAD_KEYWORDS=("virus" "trojan" "malware" "worm" "ransomware")

is_whitelisted(){
    local filename="$1"
    if [ -f "$WHITELIST_FILE" ]; then
        grep -Fxq "$filename" "$WHITELIST_FILE" && return 0
    fi
    return 1
}

scan_file(){
    local filepath="$1"
    local filename="$(basename="$filepath")"

    if is_whitelisted "$filename"; then
        return 0
    fi

    local IS_MALICIOUS=0
    
    local ext="${filename##*.}"

    if [ "$ext" != "$filename" ]; then
        for extension in "${BAD_EXTENSIONS}"; do
            if [ "$ext" = "$extension" ]; then
                IS_MALICIOUS=1
                break
            fi
        done
    fi

    if [ "$IS_MALICIOUS" -eq 0 ] && [ -f "$filepath" ]; then
        local pattern=$(IFS='|'; echo "${BAD_KEYWORDS[*]}")
        if  grep -qiE "$pattern" "$filepath" 2>/dev/null; then
            IS_MALICIOUS=1
        fi
    fi

    if [ "$IS_MALICIOUS" -eq 1 ]; then
        echo "$filename is malicious and it is DELETED"
        cp "$filepath" "$MALICIOUS_DIR/$filename"
        rm -f "$filepath"
    fi
}
scan_directory(){
    for file in "$DIR"/*; do
        if [ -f "$file" ]; then
            scan_file "$file"
        fi
    done
}

if [ ! -f "$LAST_INFO" ]; then
    echo "starting first scan.."
    scan_directory
    ls -l "$DIR" > "$LAST_INFO"
fi

while true; do
    sleep "$INTERVAL" 
    echo "starting new scan.."
    ls -l "$DIR" > "$NEW_INFO"
    if ! cmp -s "$LAST_INFO" "$NEW_INFO"; then
        scan_directory
        ls -l "$DIR" > "$LAST_INFO"
    fi
done