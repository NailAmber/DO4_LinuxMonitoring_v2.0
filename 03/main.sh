#!/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
  cat <<EOF
Usage: $0 <mode>

Deletes files and folders created by the 02/main.sh script.

Modes:
  1   Clean using a log file.
  2   Clean by creation date and time range.
  3   Clean by folder name mask (e.g., aazz_DDMMYY).
EOF
  exit 1
}

# ---- Arguments ----
[[ $# -eq 1 ]] || usage
MODE=$1

# ---- Functions for each mode ----

# Deletes all directories listed in a log file from 02/main.sh
clean_by_log() {
 ./clean_by_log.sh
}

# Deletes directories created in a specific time window that also match the naming scheme
clean_by_datetime() {
  ./clean_by_datetime.sh
}

# Deletes directories matching the name mask used by 02/main.sh
clean_by_mask() {
  ./clean_by_mask.sh
}


# ---- Main logic ----
case "$MODE" in
  1)
    clean_by_log
    ;;
  2)
    clean_by_datetime
    ;;
  3)
    clean_by_mask
    ;;
  *)
    echo "Error: Invalid mode '$MODE'." >&2
    usage
    ;;
esac

exit 0
