#!/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'


echo "Enter the start and end time for deletion."
echo "Format: YYYY-MM-DD HH:MM (e.g., 2025-07-22 15:30)"
read -rp "Start time: " start_time
read -rp "End time:   " end_time

# Basic validation of the date/time strings
if ! date -d "$start_time" >/dev/null 2>&1 || ! date -d "$end_time" >/dev/null 2>&1; then
    echo "Error: Invalid date format." >&2
    exit 1
fi

echo "Searching for directories created between '$start_time' and '$end_time'..."
# To prevent accidental deletion of system files, this search is restricted to directories
# that match the naming pattern (*_DDMMYY) from the previous script.
mapfile -t dirs_to_delete < <(find /home /tmp /var /opt -type d -name "*_??????*" -newermt "$start_time" ! -newermt "$end_time" 2>/dev/null)

if (( ${#dirs_to_delete[@]} == 0 )); then
echo "No directories matching the criteria found."
exit 0
fi

echo "The following directories (and all their contents) will be deleted:"
printf '%s\n' "${dirs_to_delete[@]}"
read -rp "Are you sure? (y/N): " confirm
if [[ "$confirm" != [yY] ]]; then
echo "Aborted."
exit 0
fi

for dir in "${dirs_to_delete[@]}"; do
    rm -rf "$dir"
    echo "Deleted: $dir"
done

echo "Cleanup by date and time complete."
