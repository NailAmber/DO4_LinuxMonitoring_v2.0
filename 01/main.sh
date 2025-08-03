#!/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
  cat <<EOF
Usage: $0 <abs_path> <num_dirs> <dir_letters(≤7)> <files_per_dir> <file_letters(≤7).ext_letters(≤3)> <size_kb (e.g. 7 or 7kb, ≤100kb)>

Example:
  $0 /opt/test 4 az 5 azaz.az 7kb
EOF
  exit 1
}

# ---- Arguments ----
[[ $# -eq 6 ]] || usage
TARGET_DIR=$1
NUM_DIRS=$2
DIR_LETTERS=$3
FILES_PER_DIR=$4
FILE_PARAM=$5
SIZE_PARAM=$6

# ---- Normalize and validate size ----
# strip optional “kb” or “KB”
if [[ "$SIZE_PARAM" =~ ^([0-9]{1,3})([kK][bB])?$ ]]; then
  SIZE_KB=${BASH_REMATCH[1]}
else
  echo "Error: size_kb must be a number up to 100, with optional 'kb' suffix"
  exit 1
fi

(( SIZE_KB >= 1 && SIZE_KB <= 100 )) || {
  echo "Error: size_kb must be between 1 and 100"
  exit 1
}

# ---- Validate other params ----
[[ "$TARGET_DIR" = /* ]]                                 || { echo "Error: path must be absolute"; exit 1; }
[[ "$NUM_DIRS" =~ ^[1-9][0-9]*$ ]]                       || { echo "Error: num_dirs must be a positive integer"; exit 1; }
[[ ${#DIR_LETTERS} -le 7 && "$DIR_LETTERS" =~ ^[A-Za-z]+$ ]] || { echo "Error: dir_letters must be ≤7 letters"; exit 1; }
[[ "$FILES_PER_DIR" =~ ^[1-9][0-9]*$ ]]                  || { echo "Error: files_per_dir must be a positive integer"; exit 1; }

if [[ "$FILE_PARAM" =~ ^([A-Za-z]{1,7})\.([A-Za-z]{1,3})$ ]]; then
  FILE_LETTERS=${BASH_REMATCH[1]}
  EXT_LETTERS=${BASH_REMATCH[2]}
else
  echo "Error: file_letters.ext_letters must match name(≤7 letters).ext(≤3 letters)"
  exit 1
fi

[[ -d "$TARGET_DIR" ]]                                  || { echo "Error: target directory does not exist"; exit 1; }

LOGFILE="$TARGET_DIR/creation_$(date +%d%m%y).log"
touch "$LOGFILE"

# ---- Helpers ----
timestamp() { date +"%Y-%m-%d %H:%M:%S"; }
check_space() {
  local avail_kb
  avail_kb=$(df --output=avail / | tail -1)
  (( avail_kb >= 1024*1024 )) || { echo "Less than 1 GiB left on / → stopping."; exit 0; }
}

make_core_name() {
  local letters=$1
  local core="$letters"
  while (( ${#core} < 4 )); do
    core+="${letters: -1}"
  done
  echo "$core"
}

# ---- Main loop ----
run_date=$(date +%d%m%y)
dir_core=$(make_core_name "$DIR_LETTERS")
file_core=$(make_core_name "$FILE_LETTERS")

for (( i=1; i<=NUM_DIRS; i++ )); do
  check_space

  last="${dir_core: -1}"
  folder_name="${dir_core}$(printf '%*s' $((i-1)) '' | tr ' ' "$last")_${run_date}"
  full_dir="$TARGET_DIR/$folder_name"
  mkdir -p "$full_dir"
  echo "[$(timestamp)] Created dir: $full_dir" >>"$LOGFILE"

  for (( j=1; j<=FILES_PER_DIR; j++ )); do
    check_space

    file_last="${file_core: -1}"
    fname_base="${file_core}$(printf '%*s' $((j-1)) '' | tr ' ' "$file_last")"
    fname="${fname_base}_${run_date}.${EXT_LETTERS}"
    full_file="$full_dir/$fname"

    dd if=/dev/zero of="$full_file" bs=1K count="$SIZE_KB" status=none
    echo "[$(timestamp)] Created file: $full_file (${SIZE_KB}K)" >>"$LOGFILE"
  done
done

echo "Done. Log written to $LOGFILE."
