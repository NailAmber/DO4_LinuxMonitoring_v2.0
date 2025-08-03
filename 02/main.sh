#!/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- Finalization trap ---
# This function will execute when the script exits, ensuring cleanup and reporting.
finish() {
  END_TIME_FMT=$(date +"%Y-%m-%d %H:%M:%S")
  END_TIME_S=$(date +%s)
  # Handle case where START_TIME_S might not be set if script fails early
  DURATION=$((END_TIME_S - ${START_TIME_S:-$END_TIME_S}))

  {
    echo "---------------------------------"
    echo "Script finished."
    echo "Start time: ${START_TIME_FMT:-"N/A"}"
    echo "End time:   $END_TIME_FMT"
    echo "Total duration: ${DURATION}s"
  } | tee -a "${LOGFILE:-/dev/null}"
  
  if [[ -n "${LOGFILE:-}" ]]; then
    echo "Log written to $LOGFILE"
  fi
}
trap finish EXIT

usage() {
  cat <<EOF
Usage: $0 <dir_letters(≤7)> <file_letters(≤7).ext_letters(≤3)> <size_mb (e.g. 3Mb, ≤100)>

Example:
  $0 az az.az 3Mb
EOF
  exit 1
}

# ---- Arguments ----
[[ $# -eq 3 ]] || usage
DIR_LETTERS=$1
FILE_PARAM=$2
SIZE_PARAM=$3

# ---- Global vars ----
START_TIME_FMT=$(date +"%Y-%m-%d %H:%M:%S")
START_TIME_S=$(date +%s)
LOGFILE="$(pwd)/creation_$(date +%d%m%y).log"
touch "$LOGFILE"
echo "Script started at $START_TIME_FMT" > "$LOGFILE"
echo "---" >> "$LOGFILE"

# ---- Normalize and validate size ----
if [[ "$SIZE_PARAM" =~ ^([0-9]{1,3})([mM][bB])?$ ]]; then
  SIZE_MB=${BASH_REMATCH[1]}
else
  echo "Error: size must be a number followed by 'Mb' (e.g. 3Mb)"
  usage
fi

(( SIZE_MB >= 1 && SIZE_MB <= 100 )) || {
  echo "Error: size must be between 1 and 100"
  exit 1
}

# ---- Validate other params ----
[[ ${#DIR_LETTERS} -ge 1 && ${#DIR_LETTERS} -le 7 && "$DIR_LETTERS" =~ ^[A-Za-z]+$ ]] || {
  echo "Error: dir_letters must be 1-7 English letters"
  exit 1
}

if [[ "$FILE_PARAM" =~ ^([A-Za-z]{1,7})\.([A-Za-z]{1,3})$ ]]; then
  FILE_LETTERS=${BASH_REMATCH[1]}
  EXT_LETTERS=${BASH_REMATCH[2]}
else
  echo "Error: file parameter must be name(≤7 letters).ext(≤3 letters)"
  exit 1
fi

# ---- Helpers ----
timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

check_space() {
  # Available space in KiB
  local avail_kb
  avail_kb=$(df --output=avail / | tail -1)
  # Stop if less than 1 GiB (1024*1024 KiB) is available
  (( avail_kb > 1024*1024 )) || {
    echo "Stopping: Less than 1GiB of free space left on '/'."
    exit 0 # Exit gracefully, trap will run
  }
}

# Generates a base name of at least 5 characters
make_base_name() {
  local letters=$1
  local name="$letters"
  while (( ${#name} < 5 )); do
    name+="${letters: -1}" # Append last character
  done
  echo "$name"
}

# ---- Main Logic ----
echo "Searching for writable directories... this may take a moment."
# Find potential parent directories. Search common user-writable locations.
# Using -maxdepth 3 to keep the search reasonably fast.
declare -a parent_dirs
mapfile -t parent_dirs < <(find /home /tmp /var /opt -maxdepth 3 -type d -writable 2>/dev/null | grep -vE '/(s?bin|proc|sys|dev|run)' | shuf)

if (( ${#parent_dirs[@]} == 0 )); then
  echo "Error: Could not find any writable directories outside of /sbin, /bin." >&2
  echo "Please try running as a different user or check permissions." >&2
  exit 1
fi
echo "Found ${#parent_dirs[@]} potential locations. Starting generation..."

dir_base_name=$(make_base_name "$DIR_LETTERS")
file_base_name=$(make_base_name "$FILE_LETTERS")
run_date=$(date +%d%m%y)

# Loop to create up to 100 directories
for (( i=1; i<=100; i++ )); do
  check_space

  # Pick a random parent directory from the list
  target_parent_dir=${parent_dirs[$((RANDOM % ${#parent_dirs[@]}))]}

  # Generate unique folder name by appending the last character of the base name
  last_char_dir="${dir_base_name: -1}"
  folder_name="${dir_base_name}$(printf '%*s' $((i-1)) '' | tr ' ' "$last_char_dir")_${run_date}"
  full_dir="$target_parent_dir/$folder_name"
  
  mkdir -p "$full_dir"
  echo "[$(timestamp)] Created dir: $full_dir" >>"$LOGFILE"

  # Random number of files for this directory (e.g., 10 to 100)
  num_files=$((RANDOM % 91 + 10))

  for (( j=1; j<=num_files; j++ )); do
    check_space

    # Generate unique file name
    last_char_file="${file_base_name: -1}"
    fname_base="${file_base_name}$(printf '%*s' $((j-1)) '' | tr ' ' "$last_char_file")"
    fname="${fname_base}_${run_date}.${EXT_LETTERS}"
    full_file="$full_dir/$fname"

    # Create the file with specified size in MB
    dd if=/dev/zero of="$full_file" bs=1M count="$SIZE_MB" status=none
    echo "[$(timestamp)] Created file: $full_file (${SIZE_MB}MB)" >>"$LOGFILE"
  done
done
