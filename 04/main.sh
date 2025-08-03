#!/usr/bin/bash
#
# This script generates 5 mock Nginx log files in the combined format.
# Each file corresponds to one day of traffic.

set -euo pipefail
IFS=$'\n\t'

# --- HTTP Status Code Meanings ---
# 200 OK: The request has succeeded.
# 201 Created: The request has been fulfilled and has resulted in one or more new resources being created.
# 400 Bad Request: The server cannot or will not process the request due to something that is perceived to be a client error.
# 401 Unauthorized: The client must authenticate itself to get the requested response.
# 403 Forbidden: The client does not have access rights to the content.
# 404 Not Found: The server can not find the requested resource.
# 500 Internal Server Error: The server has encountered a situation it doesn't know how to handle.
# 501 Not Implemented: The request method is not supported by the server and cannot be handled.
# 502 Bad Gateway: The server, while acting as a gateway or proxy, received an invalid response from the upstream server.
# 503 Service Unavailable: The server is not ready to handle the request.

echo "Starting log generation..."

# --- Configuration ---
LOG_DIR="./logs"
NUM_FILES=5 # Generate 5 log files

# --- Data Arrays for Random Selection ---
METHODS=("GET" "POST" "PUT" "PATCH" "DELETE")
STATUS_CODES=(200 201 400 401 403 404 500 501 502 503)
URLS=("/index.html" "/about.html" "/contact.html" "/products/1" "/products/2" "/api/v1/users" "/api/v1/posts" "/login" "/logout" "/admin/dashboard")
USER_AGENTS=(
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15"
  "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0"
  "Opera/9.80 (Windows NT 6.1; WOW64) Presto/2.12.388 Version/12.18"
  "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; AS; rv:11.0) like Gecko"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Edg/91.0.864.59"
  "Googlebot/2.1 (+http://www.google.com/bot.html)"
  "curl/7.68.0"
)

# --- Helper Functions ---

# Generates a random valid IPv4 address
rand_ip() {
  echo "$((RANDOM % 256)).$((RANDOM % 256)).$((RANDOM % 256)).$((RANDOM % 256))"
}

# Selects a random element from an array
rand_element() {
  local arr=("$@")
  echo "${arr[$((RANDOM % ${#arr[@]}))]}"
}

# --- Main Loop ---

# Create a directory for the logs if it doesn't exist
mkdir -p "$LOG_DIR"

# Loop to create 5 log files for 5 consecutive days
for i in $(seq 0 $((NUM_FILES - 1))); do
  # Calculate the date for the current log file (today - i days)
  log_date=$(date -d "-$i days" +%Y-%m-%d)
  log_file="$LOG_DIR/access_${log_date}.log"
  echo "Generating $log_file..."

  # Number of entries for this day (100-1000)
  num_entries=$((RANDOM % 901 + 100))

  # Start time for the day (00:00:00)
  current_time_s=$(date -d "$log_date 00:00:00" +%s)

  for ((j=0; j<num_entries; j++)); do
    # Increment time by a random number of seconds (e.g., 1 to 90s)
    # This ensures timestamps are always ascending.
    current_time_s=$((current_time_s + RANDOM % 90 + 1))
    # Format for Nginx log: 22/Jul/2025:15:04:05 +0000
    log_time=$(date -d "@$current_time_s" +'%d/%b/%Y:%H:%M:%S %z')

    # Generate random data for the log entry
    ip=$(rand_ip)
    method=$(rand_element "${METHODS[@]}")
    url=$(rand_element "${URLS[@]}")
    status=$(rand_element "${STATUS_CODES[@]}")
    user_agent=$(rand_element "${USER_AGENTS[@]}")
    bytes=$((RANDOM % 4000 + 100)) # Random size from 100 to 4099 bytes

    # Assemble the log line
    printf '%s - - [%s] "%s %s HTTP/1.1" %d %d "-" "%s"\n' \
      "$ip" "$log_time" "$method" "$url" "$status" "$bytes" "$user_agent" >> "$log_file"
  done
done

echo "Log generation finished. Files are in the $LOG_DIR directory."

