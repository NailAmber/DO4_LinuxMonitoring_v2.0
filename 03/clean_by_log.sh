#!/usr/bin bash
set -euo pipefail
IFS=$'\n\t'

read -rp "Enter the absolute path to the log file: " logfile_path
if [[ ! -f "$logfile_path" ]]; then
echo "Error: Log file not found at '$logfile_path'" >&2
exit 1
fi

echo "Parsing log file to find directories..."
# Extract directory paths from lines containing "Created dir: "
# The `sed` command extracts everything after that specific string.
# `sort -r` is a good practice to ensure nested directories are removed from inside out,
# though `rm -rf` makes it less critical.
mapfile -t dirs_to_delete < <(grep 'Created dir:' "$logfile_path" | sed 's/.*Created dir: //' | sort -r)

if (( ${#dirs_to_delete[@]} == 0 )); then
echo "No directories found in the log file to delete."
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
if [[ -d "$dir" ]]; then
    rm -rf "$dir"
    echo "Deleted: $dir"
else
    echo "Warning: Directory not found (already deleted?): $dir"
fi
done

echo "Cleanup by log file complete."