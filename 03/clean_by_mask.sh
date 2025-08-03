#!/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'


echo "Searching for directories matching the name mask '..._DDMMYY'..."
# The regex finds directories in common locations whose names consist of at least 5 letters,
# followed by an underscore and 6 digits, at the end of the path.
# maxdepth is used to limit search time and scope.
mapfile -t dirs_to_delete < <(find /home /tmp /var /opt -maxdepth 5 -type d -regextype posix-extended -regex '.*/[a-zA-Z]{5,}_[0-9]{6}$' 2>/dev/null)

if (( ${#dirs_to_delete[@]} == 0 )); then
echo "No directories matching the name mask found."
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

echo "Cleanup by name mask complete."
