#!/bin/bash

# any folder/file appened with 'IE-' means index exclude, and will not be listed at all in the index
# this script must be run in a subfolder to the root called 'Tools' and not anywhere else

set -e

readonly TARGET_DIR="./Information"
readonly OUTPUT_FILE="$TARGET_DIR/codebase.txt"
readonly SCRIPT_NAME=$(basename "$0")

notify() {
    local title="$1"
    local message="$2"
    if command -v notify-send &> /dev/null; then
        notify-send "$title" "$message"
    elif command -v osascript &> /dev/null; then
        osascript -e "display notification \"$message\" with title \"$title\""
    elif command -v powershell.exe &> /dev/null; then
        powershell.exe -Command "New-BTPersonalNotification -NotificationTitle '$title' -NotificationText '$message'" &> /dev/null || \
        powershell.exe -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('$message', '$title')" &> /dev/null
    fi
}

main() {
    trap 'notify "Archive Failed" "The script encountered an error."; exit 1' ERR

    if [[ "$(basename "$PWD")" != "Tools" ]]; then
        printf "[ERROR] Script must be run from the 'Tools' directory.\n" >&2
        exit 1
    fi

    cd ..

    if ! command -v tree &> /dev/null; then
        printf "[ERROR] 'tree' command not found.\n" >&2
        exit 1
    fi

    mkdir -p "$TARGET_DIR"

    {
        printf "PROJECT ARCHIVE: %s\n" "$(date)"
        printf -- "------------------------------------------------\n\n"
        printf "I. DIRECTORY STRUCTURE\n"
        tree -I '.*|node_modules|*IE-*'
        printf "\n--\n\n"
        printf "II. FILE CONTENTS\n\n"
    } > "$OUTPUT_FILE"

    find . -path '*/node_modules' -prune -o -path '*/.*' -prune -o -name '*IE-*' -prune -o -type f -print | while read -r file; do
        local normalized_file=$(echo "$file" | sed 's|^\./||')

        if [[ "$normalized_file" == *"$SCRIPT_NAME" || "$file" == "$OUTPUT_FILE" ]]; then
            continue
        fi

        {
            printf "================================================\n"
            printf " PATH: %s\n" "$normalized_file"
            printf "================================================\n"
        } >> "$OUTPUT_FILE"

        if [[ "$file" =~ \.(md|png)$ ]]; then
            printf "[Content intentionally omitted for documentation/image format]\n" >> "$OUTPUT_FILE"
        else
            if file "$file" | grep -qE 'text|JSON|source|empty|XML|script'; then
                cat "$file" >> "$OUTPUT_FILE"
            else
                printf "[Binary or non-standard text format skipped]\n" >> "$OUTPUT_FILE"
            fi
        fi

        printf "\n\n" >> "$OUTPUT_FILE"
    done

    notify "Archive Complete" "Process finished successfully."
    printf "[SUCCESS] Archive generated at %s\n" "$OUTPUT_FILE"
}

main "$@"
