#!/bin/bash
# Network Traffic Analyzer with real-time alerts
# Usage: ./traffic_analyzer.bash [duration]
# Example: ./traffic_analyzer.bash 30

show_usage() {
    echo "Network Traffic Analyzer - Real-time traffic analysis"
    echo "Usage: ./traffic_analyzer.bash [duration]"
    echo "  duration - Analysis duration in seconds (default: 60)"
    echo "Example: ./traffic_analyzer.bash 30"
}

analyze_traffic() {
    local duration=${1:-60}
    local capture_file="/tmp/capture_$$.pcap"
    
    echo "Starting traffic capture for $duration seconds..."
    echo "Press Ctrl+C to stop early"
    
    # Start capture in background
    timeout $duration tcpdump -i any -w "$capture_file" >/dev/null 2>&1 &
    local pid=$!
    
    # Show progress
    for ((i=1; i<=duration; i++)); do
        echo -ne "Capturing... $i/$duration seconds\r"
        sleep 1
    done
    echo
    
    wait $pid
    
    echo "Analysis Results:"
    echo "================="
    
    echo "Top Talkers:"
    tcpdump -r "$capture_file" 2>/dev/null | awk '{print $3}' | cut -d. -f1-4 | sort | uniq -c | sort -nr | head -10
    
    echo -e "\nProtocol Distribution:"
    tcpdump -r "$capture_file" 2>/dev/null | awk '{print $5}' | cut -d. -f1 | sort | uniq -c
    
    echo -e "\nSuspicious Activity:"
    tcpdump -r "$capture_file" 2>/dev/null | grep -E "(port 23|port 445|port 22.*Failed)" && echo "ALERT: Suspicious activity detected"
    
    # Cleanup
    rm -f "$capture_file"
}

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

analyze_traffic "$@"
