# IE-* (Index Exclude) is a flag used to prefix folders that should be excluded from indexing.
#!/bin/bash

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

    cd ..

    if ! command -v tree &> /dev/null; then
        exit 1
    fi

    mkdir -p "$TARGET_DIR"

    {
        printf "PROJECT ARCHIVE: %s\n" "$(date)"
        printf -- "------------------------------------------------\n\n"
        printf "I. DIRECTORY STRUCTURE\n"
        tree -I '.*|IE-*'
        printf "\n--\n\n"
        printf "II. FILE CONTENTS\n\n"
    } > "$OUTPUT_FILE"

    find . \( -path '*/.*' -o -path '*/IE-*' \) -prune -o -type f -print | while read -r file; do

        local normalized_file=$(echo "$file" | sed 's|^\./||')

        if [[ "$normalized_file" == *"$SCRIPT_NAME" || "$file" == "$OUTPUT_FILE" ]]; then
            continue
        fi

        local mime_type=$(file --mime-type -b "$file")

        if [[ "$mime_type" == text/* ]] || [[ "$mime_type" == "application/json" ]] || [[ "$mime_type" == "application/javascript" ]] || [[ "$mime_type" == "application/xml" ]]; then
            {
                printf "================================================\n"
                printf " PATH: %s\n" "$normalized_file"
                printf "================================================\n"
                cat "$file"
                printf "\n\n"
            } >> "$OUTPUT_FILE"
        fi
    done

    notify "Archive Complete" "Process finished successfully. Check /Information/codebase.txt"
}

main "$@"
