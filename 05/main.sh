#!/usr/bin/bash
#
# This script parses Nginx log files from the '../04/logs' directory using awk.

set -euo pipefail
IFS=$'\n\t'

LOG_DIR="../04/logs"

usage() {
  cat <<EOF
Usage: $0 <mode>

Parses log files in '$LOG_DIR'.

Modes:
  1   Output all entries sorted by response code.
  2   Output all unique IPs.
  3   Output all requests with errors (4xx or 5xx codes).
  4   Output all unique IPs that had errors.
EOF
  exit 1
}

# --- Argument and Prerequisite Check ---
[[ $# -eq 1 ]] || usage

if ! ls "$LOG_DIR"/access_*.log &>/dev/null; then
  echo "Error: No log files found in '$LOG_DIR'." >&2
  echo "Please run the log generator script from Part 4 first." >&2
  exit 1
fi

MODE=$1

# --- Main Logic ---

# We use `cat` to feed all log files into the processing pipeline at once.
case "$MODE" in
  1)
    echo "--- All entries sorted by response code ---"
    cat "$LOG_DIR"/access_*.log | sort -n -k9
    ;;
  2)
    echo "--- All unique IPs ---"
    cat "$LOG_DIR"/access_*.log | awk '{print $1}' | sort -u
    ;;
  3)
    echo "--- All requests with errors (4xx or 5xx) ---"
    cat "$LOG_DIR"/access_*.log | awk '$9 ~ /^[45]/'
    ;;
  4)
    echo "--- All unique IPs with errors ---"
    cat "$LOG_DIR"/access_*.log | awk '$9 ~ /^[45]/' | awk '{print $1}' | sort -u
    ;;
  *)
    echo "Error: Invalid mode '$MODE'." >&2
    usage
    ;;
esac
