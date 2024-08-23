
#!/bin/bash

# Function to display the top 10 most used applications
show_top_apps() {
  echo "Top 10 CPU Consuming Applications:"
  ps aux --sort=-%cpu | head -n 11
  echo ""
  echo "Top 10 Memory Consuming Applications:"
  ps aux --sort=-%mem | head -n 11
  echo ""
}

# Function to monitor network statistics
show_network_stats() {
  echo "Network Monitoring:"
  echo "Concurrent Connections: $(netstat -an | grep ESTABLISHED | wc -l)"
  echo "Packet Drops by Interface:"
  netstat -i | grep -v 'Iface\|Kernel' | awk '{print $1 " " $4}'
  echo "Data In/Out:"
  ifstat -i eth0 1 1 | awk 'NR==3 {print $1 " " $2}'
  echo ""
}

# Function to display disk usage
show_disk_usage() {
  echo "Disk Usage by Mounted Partitions:"
  df -h | awk '$5 > 80 {print $0}'
  echo ""
}

# Function to show system load
show_system_load() {
  echo "System Load:"
  uptime | awk '{print "Load Average (1/5/15 min): " $9, $10, $11}'
  echo "CPU Usage Breakdown:"
  mpstat | grep -A 5 "%idle" | tail -n 1
  echo ""
}

# Function to display memory usage
show_memory_usage() {
  echo "Memory Usage:"
  free -m | awk 'NR==2{printf "Memory Usage: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }'
  echo "Swap Usage:"
  free -m | awk 'NR==3{printf "Swap Usage: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }'
  echo ""
}

# Function to monitor processes
show_processes() {
  echo "Number of Active Processes: $(ps aux | wc -l)"
  echo "Top 5 CPU Consuming Processes:"
  ps aux --sort=-%cpu | head -n 6
  echo "Top 5 Memory Consuming Processes:"
  ps aux --sort=-%mem | head -n 6
  echo ""
}

# Function to monitor essential services
show_service_status() {
  echo "Service Status:"
  for service in sshd nginx iptables; do
    systemctl is-active $service
  done
  echo ""
}

# Handle command-line switches
case "$1" in
  -cpu) show_top_apps ;;
  -memory) show_memory_usage ;;
  -network) show_network_stats ;;
  -disk) show_disk_usage ;;
  -processes) show_processes ;;
  -services) show_service_status ;;
  *)
    # Default: Show full dashboard
    while true; do
      clear
      show_top_apps
      show_network_stats
      show_disk_usage
      show_system_load
      show_memory_usage
      show_processes
      show_service_status
      sleep 5
    done
    ;;
esac

