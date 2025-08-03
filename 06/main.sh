#!/usr/bin/bash

LOG_DIR="../04/logs"
REPORT_DIR="."
REPORT_FILE="$REPORT_DIR/report.html"

# Check if the log directory exists
if [ ! -d "$LOG_DIR" ]; then
  echo "Log directory not found: $LOG_DIR"
  exit 1
fi

# Generate the GoAccess report
goaccess "$LOG_DIR"/*.log -o "$REPORT_FILE" --log-format=COMBINED

echo "GoAccess report generated: $REPORT_FILE"
