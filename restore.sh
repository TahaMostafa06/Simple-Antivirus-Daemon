#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <dir> <malicious_dir>"
    exit 1
fi

DIR="$1"
MALICIOUS_DIR="$2"
WHITELIST_FILE=".whitelist"

mkdir -p "$DIR"
mkdir -p "$MALICIOUS_DIR"
touch "$WHITELIST_FILE"

shopt -s nullglob
initial_files=("$DIR"/*)
shopt -u nullglob

if [ "${#initial_files[@]}" -eq 0 ]; then
    echo "The monitored directory '$DIR' is empty."
fi

while true; do
    shopt -s nullglob
    files=("$MALICIOUS_DIR"/*)
    shopt -u nullglob

    if [ "${#files[@]}" -eq 0 ]; then
        echo "No malicious files to review."
        break
    fi

    for idx in "${!files[@]}"; do
        echo "$((idx + 1)). $(basename "${files[idx]}")"
    done

    read -rp "Select a file by number" choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#files[@]}" ]; then
        echo "Invalid choice. Please select a valid number."
        continue
    fi

    selected_index=$((choice - 1))
    selected_filepath="${files[selected_index]}"
    selected_filename="$(basename "$selected_filepath")"

    echo ""
    echo "File selected: $selected_filename"
    echo "Options:"
    echo "1. Restore"
    echo "2. Delete"
    echo "3. Quit"
    read -rp "Choose an option [1-3]: " opt

    if [ "$opt" -eq 1 ]; then
        mv "$selected_filepath" "$DIR/"
        echo "File '$selected_filename' restored to '$DIR'."
        echo "$selected_filename" >> "$WHITELIST_FILE"
    elif [ "$opt" -eq 2 ]; then
        rm -f "$selected_filepath"
        echo "File '$selected_filename' deleted."
    else
        echo "Exiting."
    fi
done