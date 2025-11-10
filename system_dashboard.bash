
#!/bin/bash
# Advanced System Dashboard - Real-time monitoring
# Usage: ./system_dashboard.bash

show_usage() {
    echo "System Dashboard - Real-time monitoring"
    echo "Usage: ./system_dashboard.bash"
    echo "Features: CPU, Memory, Disk, Process, Network monitoring"
    echo "Press Ctrl+C to exit"
}

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

echo "Starting System Dashboard... (Press Ctrl+C to exit)"
echo "================================================"

while true; do
    clear
    echo "SYSTEM DASHBOARD - $(date)"
    echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')% | Memory: $(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2}') | Disk: $(df -h / | awk 'NR==2{print $5}')"
    echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Top Processes:"
    ps aux --sort=-%cpu | head -6
    echo "Network Connections: $(netstat -tun | wc -l)"
    sleep 2
done
