#!/usr/bin/bash

# --- CPU ---
# Get CPU usage by comparing /proc/stat over a 1-second interval.
read cpu user nice system idle iowait irq softirq steal < <(grep '^cpu ' /proc/stat)
prev_total=$((user+nice+system+idle+iowait+irq+softirq))
prev_idle=$idle

sleep 1

read cpu user nice system idle iowait irq softirq steal < <(grep '^cpu ' /proc/stat)
curr_total=$((user+nice+system+idle+iowait+irq+softirq))
curr_idle=$idle

total_diff=$((curr_total-prev_total))
idle_diff=$((curr_idle-prev_idle))

# Handle division by zero if total_diff is 0
if [ $total_diff -eq 0 ]; then
  cpu_usage="0.00"
else
  cpu_usage=$(awk -v total_diff=$total_diff -v idle_diff=$idle_diff 'BEGIN {printf "%.2f", 100 * (total_diff - idle_diff) / total_diff}')
fi


# --- RAM ---
# Get memory usage from /proc/meminfo
mem_total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
mem_available_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
mem_used_kb=$((mem_total_kb - mem_available_kb))
mem_used_percent=$(awk -v used=$mem_used_kb -v total=$mem_total_kb 'BEGIN { if (total > 0) { printf "%.2f", (used/total)*100 } else { print "0.00" } }')


# --- Disk ---
# Get root filesystem usage
disk_size_kb=$(df /mnt/c | awk 'NR==2 {print $2}')
disk_used_kb=$(df /mnt/c | awk 'NR==2 {print $3}')


# --- HTML Output ---
# Create the HTML file in Prometheus format
# The path needs to be absolute for the script to work from anywhere (e.g., via cron)
METRICS_FILE="/home/nailambe/DO4_LinuxMonitoring_v2.0.ID_356280-1/src/09/metrics/index.html"

cat <<EOF > "$METRICS_FILE"
# HELP my_cpu_usage CPU usage percentage
# TYPE my_cpu_usage gauge
my_cpu_usage{instance="localhost"} $cpu_usage
# HELP my_mem_usage_percent Memory usage percentage
# TYPE my_mem_usage_percent gauge
my_mem_usage_percent{instance="localhost"} $mem_used_percent
# HELP my_disk_size Disk capacity for root filesystem
# TYPE my_disk_size gauge
my_disk_size{instance="localhost"} $disk_size_kb
# HELP my_disk_avail Disk used capacity for root filesystem
# TYPE my_disk_avail gauge
my_disk_used{instance="localhost"} $disk_used_kb
EOF