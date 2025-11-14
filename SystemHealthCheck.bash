
#!/bin/bash

# Comprehensive System Health Check
run_health_check() {
    echo "=== SYSTEM HEALTH CHECK ==="
    echo "Run at: $(date)"
    echo
    
    # System information
    echo "=== SYSTEM INFORMATION ==="
    echo "Hostname: $(hostname)"
    echo "OS: $(uname -s) $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo
    
    # CPU and Memory
    echo "=== CPU & MEMORY ==="
    echo "CPU Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory Usage:"
    free -h
    echo
    
    # Disk space
    echo "=== DISK SPACE ==="
    df -h | grep -E '(/|/home|/var)'
    echo
    
    # Services status
    echo "=== SERVICES STATUS ==="
    services=("ssh" "nginx" "apache2" "mysql" "docker")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "✅ $service: \033[1;32mRUNNING\033[0m"
        else
            echo -e "❌ $service: \033[1;31mSTOPPED\033[0m"
        fi
    done
    echo
    
    # Network connectivity
    echo "=== NETWORK CONNECTIVITY ==="
    if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        echo -e "Internet: \033[1;32mCONNECTED\033[0m"
    else
        echo -e "Internet: \033[1;31mDISCONNECTED\033[0m"
    fi
    
    # Recent errors in logs
    echo
    echo "=== RECENT ERRORS ==="
    grep -i "error\|failed" /var/log/syslog 2>/dev/null | tail -5
    
    echo
    echo "Health check complete!"
}

# Schedule regular health checks
schedule_health_check() {
    local interval_minutes=${1:-60}
    
    echo "Scheduling health checks every $interval_minutes minutes..."
    
    while true; do
        run_health_check
        echo "Next check in $interval_minutes minutes..."
        echo
        sleep $((interval_minutes * 60))
    done
}

main() {
    case ${1:-"run"} in
        run)
            run_health_check
            ;;
        schedule)
            schedule_health_check "$2"
            ;;
        *)
            echo "Usage: $0 [run|schedule [interval]]"
            ;;
    esac
}

main "$@"
