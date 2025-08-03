#!/usr/bin/bash

# --- Finalization trap ---
# This function will execute when the script exits, ensuring cleanup and reporting.
finish() {
     END_TIME_FMT=$(date +"%Y-%m-%d %H:%M:%S")
     END_TIME_S=$(date +%s)
     # Handle case where START_TIME_S might not be set if script fails early
     DURATION=$((END_TIME_S - ${START_TIME_S:-$END_TIME_S}))
     echo "---------------------------------"
     echo "Gathering finished."
     echo "Start time: ${START_TIME_FMT:-"N/A"}"
     echo "End time:   $END_TIME_FMT"
     echo "Total duration: ${DURATION}s"
}
trap finish EXIT

START_TIME_FMT=$(date +"%Y-%m-%d %H:%M:%S")
START_TIME_S=$(date +%s)
echo 'Gathering started.'
while true; do 
     ./metrics.sh; sleep 3; done
